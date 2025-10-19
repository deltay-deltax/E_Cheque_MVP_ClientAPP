// -------------------- Admin HTTPS: Create/Update bankUsers --------------------
export const createOrUpdateBankUser = onRequest({ region: "asia-south1", cors: true, timeoutSeconds: 120, memory: "256MiB", secrets: ["ADMIN_SECRET"] }, async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, x-admin-key');
    return res.status(204).send('');
  }
  try {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }
    res.set('Access-Control-Allow-Origin', '*');

    const keyFromHeader = req.get('x-admin-key') || '';
    const keyFromQuery = (req.query.key || '').toString();
    const provided = keyFromHeader || keyFromQuery;
    const expected = process.env.ADMIN_SECRET || process.env.admin_secret;
    if (!expected) {
      return res.status(500).json({ error: 'Server not configured: ADMIN_SECRET missing' });
    }
    if (!provided || provided !== expected) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const required = ['fullName','email','phone','accountNumber','accountType','bankName','branch','ifsc','balance'];
    for (const f of required) {
      if (body[f] === undefined || body[f] === null || body[f] === '') {
        return res.status(400).json({ error: `Missing field: ${f}` });
      }
    }
    const providedUid = body.uid ? String(body.uid) : '';
    const balance = Number(body.balance);
    if (Number.isNaN(balance)) {
      return res.status(400).json({ error: 'balance must be a number' });
    }

    const data = {
      fullName: String(body.fullName),
      email: String(body.email),
      phone: String(body.phone),
      accountNumber: String(body.accountNumber),
      accountType: String(body.accountType),
      bankName: String(body.bankName),
      branch: String(body.branch),
      ifsc: String(body.ifsc),
      balance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (providedUid) {
      data.uid = providedUid;
      await db.collection('bankUsers').doc(providedUid).set(data, { merge: true });
      return res.status(200).json({ ok: true, id: providedUid });
    } else {
      const ref = await db.collection('bankUsers').add(data);
      // back-fill uid field to equal doc id for consistency
      await ref.set({ uid: ref.id }, { merge: true });
      return res.status(200).json({ ok: true, id: ref.id });
    }
  } catch (e) {
    const msg = e?.message || String(e);
    logger.error('createOrUpdateBankUser failed', { err: msg });
    return res.status(500).json({ error: msg });
  }
});
// -------------------- Transactions: Status Transition -> Completed --------------------
export const onTransactionStatusUpdated = onDocumentUpdated(
  {
    document: "transactions/{txId}",
    region: "asia-south1",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const txId = event.params.txId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only act on transition to Completed and only once
    if (!(before.status !== "Completed" && after.status === "Completed")) return;
    if (after.processedByCF === true) return;
    if (after.direction !== "debit") return;
    if (after.source !== "cheque") return; // only cheques use status transition

    const senderUid = after.userId;
    const amount = Number(after.amount || 0);
    if (!senderUid || !(amount > 0)) return;

    const now = admin.firestore.FieldValue.serverTimestamp();
    // Prefer account-number mapping if present on the transaction
    async function resolveBankUserRefFor(uid, accountNumber) {
      if (accountNumber) {
        const byAcct = await db.collection("bankUsers").where("accountNumber", "==", String(accountNumber)).limit(1).get();
        if (!byAcct.empty) return byAcct.docs[0].ref;
      }
      const userDoc = await db.collection("users").doc(uid).get();
      const userAcct = userDoc.get("bank.accountNumber");
      if (!accountNumber && userAcct) {
        const byAcct2 = await db.collection("bankUsers").where("accountNumber", "==", String(userAcct)).limit(1).get();
        if (!byAcct2.empty) return byAcct2.docs[0].ref;
      }
      const bUid = userDoc.get("bank.uid");
      if (bUid) return db.collection("bankUsers").doc(String(bUid));
      let q = await db.collection("bankUsers").where("uid", "==", uid).limit(1).get();
      if (!q.empty) return q.docs[0].ref;
      const email = userDoc.get("email");
      if (email) {
        q = await db.collection("bankUsers").where("email", "==", email).limit(1).get();
        if (!q.empty) return q.docs[0].ref;
      }
      return db.collection("bankUsers").doc(uid);
    }

    const fromAccount = after?.details?.fromAccount || after.fromAccount || after.accountNumber || null;
    const toAccount = after?.details?.toAccount || after.toAccount || null;
    const senderBankUserRef = await resolveBankUserRefFor(senderUid, fromAccount);

    // Try resolve receiver (best-effort)
    let receiverUid = after.counterpartyUid || null;
    if (!receiverUid) {
      const method = after.method;
      const d = after.details || {};
      if (method === "mobile") {
        const upiOrPhone = d.upiOrPhone;
        if (upiOrPhone) {
          let q = await db.collection("bankUsers").where("phone", "==", upiOrPhone).limit(1).get();
          if (!q.empty) receiverUid = q.docs[0].get("uid") || q.docs[0].id;
          if (!receiverUid) {
            q = await db.collection("bankUsers").where("upi", "==", upiOrPhone).limit(1).get();
            if (!q.empty) receiverUid = q.docs[0].get("uid") || q.docs[0].id;
          }
        }
      } else if (method === "bank_transfer") {
        const acct = d.toAccount;
        if (acct) {
          const q = await db.collection("bankUsers").where("accountNumber", "==", acct).limit(1).get();
          if (!q.empty) receiverUid = q.docs[0].get("uid") || q.docs[0].id;
        }
      }
    }

    await db.runTransaction(async (t) => {
      const txRef = db.collection("transactions").doc(txId);
      const freshSnap = await t.get(txRef);
      const fresh = freshSnap.data() || {};
      if (fresh.processedByCF === true) return;

      const senderRef = db.collection("users").doc(senderUid);
      const senderSnap = await t.get(senderRef);
      const senderBank = senderSnap.get("bank") || {};
      const senderBal = Number(senderBank.balance || 0);

      if (senderBal < amount) {
        t.update(txRef, { status: "Failed", failureReason: "insufficient_funds", processedByCF: true });
        return;
      }

      // Deduct sender
      t.set(senderRef, { bank: { ...senderBank, balance: senderBal - amount } }, { merge: true });

      // Mirror bankUsers balance
      const sMirror = await t.get(senderBankUserRef);
      const sBal = Number((sMirror.get("balance") ?? 0)) || 0;
      t.set(senderBankUserRef, { balance: sBal - amount }, { merge: true });

      // Credit receiver (if known and not same)
      if (receiverUid && receiverUid !== senderUid) {
        const receiverRef = db.collection("users").doc(receiverUid);
        const rSnap = await t.get(receiverRef);
        const rBank = rSnap.get("bank") || {};
        const rBal = Number(rBank.balance || 0);
        t.set(receiverRef, { bank: { ...rBank, balance: rBal + amount } }, { merge: true });

        const receiverBankUserRef2 = (toAccount
          ? (await (async () => { const q=await db.collection("bankUsers").where("accountNumber","==",String(toAccount)).limit(1).get(); return q.empty? null : q.docs[0].ref; })())
          : null) || receiverBankUserRef || db.collection("bankUsers").doc(receiverUid);
        const rbMirror = await t.get(receiverBankUserRef2);
        const rb = Number((rbMirror.get("balance") ?? 0)) || 0;
        t.set(receiverBankUserRef2, { balance: rb + amount }, { merge: true });
      }

      t.update(txRef, { processedByCF: true });
    });

    logger.info("Processed tx status update", { txId, senderUid, amount });
  }
);
// -------------------- Imports --------------------
import admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";

// -------------------- Initialize --------------------
admin.initializeApp();

// -------------------- Transactions: Mirror + Balances --------------------
export const onTransactionCreate = onDocumentCreated(
  {
    document: "transactions/{txId}",
    region: "asia-south1",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const txId = event.params.txId;
    const tx = event.data?.data();
    if (!tx) return;

    // Immediately handle all non-cheque debit payments (mobile/bank/expense etc.)
    // Cheques are settled via onChequeStatusUpdated
    if (tx.direction !== "debit" || tx.source === "cheque") return;

    const senderUid = tx.userId;
    if (!senderUid) return;

    // Idempotency
    if (tx.processedByCF === true) return;

    // Resolve receiverUid if not provided using method/details
    async function resolveReceiverUidFromDetails(txDoc) {
      if (txDoc.counterpartyUid) return txDoc.counterpartyUid;
      const method = txDoc.method;
      const d = txDoc.details || {};
      if (method === "mobile") {
        const upiOrPhone = d.upiOrPhone;
        if (!upiOrPhone) return null;
        let q = await db.collection("bankUsers").where("phone", "==", upiOrPhone).limit(1).get();
        if (!q.empty) return q.docs[0].get("uid") || q.docs[0].id;
        q = await db.collection("bankUsers").where("upi", "==", upiOrPhone).limit(1).get();
        if (!q.empty) return q.docs[0].get("uid") || q.docs[0].id;
        return null;
      }
      if (method === "bank_transfer") {
        const acct = d.toAccount;
        if (!acct) return null;
        const q = await db.collection("bankUsers").where("accountNumber", "==", acct).limit(1).get();
        if (q.empty) return null;
        return q.docs[0].get("uid") || q.docs[0].id;
      }
      return null;
    }

    const receiverUid = await resolveReceiverUidFromDetails(tx);
    logger.info('onTransactionCreate: begin', {
      txId,
      senderUid,
      amount: Number(tx.amount || 0),
      source: tx.source,
      method: tx.method,
      fromAccount: tx?.details?.fromAccount || tx.fromAccount,
      toAccount: tx?.details?.toAccount || tx.toAccount,
    });

    const amount = Number(tx.amount || 0);
    if (!(amount > 0)) return;

    const now = admin.firestore.FieldValue.serverTimestamp();

    // Resolve bankUsers doc for sender; prefer explicit account number if provided
    async function resolveBankUserRefFor(uid, accountNumber) {
      if (accountNumber) {
        const byAcct = await db.collection("bankUsers").where("accountNumber", "==", String(accountNumber)).limit(1).get();
        if (!byAcct.empty) return byAcct.docs[0].ref;
      }
      // Try users/{uid}.bank.accountNumber
      const userDoc = await db.collection("users").doc(uid).get();
      const userAcct = userDoc.get("bank.accountNumber");
      if (!accountNumber && userAcct) {
        const byAcct2 = await db.collection("bankUsers").where("accountNumber", "==", String(userAcct)).limit(1).get();
        if (!byAcct2.empty) return byAcct2.docs[0].ref;
      }
      // Try users/{uid}.bank.uid mapping first
      const bUid = userDoc.get("bank.uid");
      if (bUid) return db.collection("bankUsers").doc(String(bUid));
      // Else try bankUsers where uid == auth uid
      let q = await db.collection("bankUsers").where("uid", "==", uid).limit(1).get();
      if (!q.empty) return q.docs[0].ref;
      // Else try bankUsers by email
      const email = userDoc.get("email");
      if (email) {
        q = await db.collection("bankUsers").where("email", "==", email).limit(1).get();
        if (!q.empty) return q.docs[0].ref;
      }
      // Fallback assume doc id == uid
      return db.collection("bankUsers").doc(uid);
    }

    const fromAccount = tx?.details?.fromAccount || tx.fromAccount || tx.accountNumber || null;
    const toAccount = tx?.details?.toAccount || tx.toAccount || null;
    const senderBankUserRef = await resolveBankUserRefFor(senderUid, fromAccount);
    const receiverBankUserRef = receiverUid ? await resolveBankUserRefFor(receiverUid, toAccount) : null;

    await db.runTransaction(async (t) => {
      const freshTxRef = db.collection("transactions").doc(txId);
      const senderRef = db.collection("users").doc(senderUid);
      const method = tx.method;

      // Pre-read everything needed BEFORE any writes
      const freshTxSnap = await t.get(freshTxRef);
      const senderSnap = await t.get(senderRef);
      const senderBankUserSnap = senderBankUserRef ? await t.get(senderBankUserRef) : null;

      let receiverRef = null;
      let receiverSnap = null;
      let receiverTxRef = null;
      let receiverTxSnap = null;
      const mirrorP2P = receiverUid && receiverUid !== senderUid && (method === "mobile" || method === "bank_transfer");
      if (mirrorP2P) {
        receiverRef = db.collection("users").doc(receiverUid);
        receiverSnap = await t.get(receiverRef);
        const mirrorId = `${txId}__to__${receiverUid}`;
        receiverTxRef = db.collection("transactions").doc(mirrorId);
        receiverTxSnap = await t.get(receiverTxRef);
      }
      const receiverBankUserSnap = receiverBankUserRef ? await t.get(receiverBankUserRef) : null;

      // Now process using the pre-read snapshots
      const fresh = freshTxSnap.data() || {};
      if (fresh.processedByCF === true) return; // idempotent

      const senderBank = senderSnap.get("bank") || {};
      const senderBal = Number(senderBank.balance || 0);

      if (senderBal < amount) {
        t.update(freshTxRef, {
          status: "Failed",
          failureReason: "insufficient_funds",
          processedByCF: true,
        });
        return;
      }

      // Deduct sender
      t.set(
        senderRef,
        { bank: { ...senderBank, balance: senderBal - amount } },
        { merge: true }
      );

      // Update sender bankUsers balance mirror if available
      if (senderBankUserRef && senderBankUserSnap) {
        const sBal = Number((senderBankUserSnap.get("balance") ?? 0)) || 0;
        t.set(senderBankUserRef, { balance: sBal - amount }, { merge: true });
      }

      // Mirror credit only for P2P methods (mobile/bank_transfer)
      if (mirrorP2P && receiverRef && receiverSnap) {
        const receiverBank = receiverSnap.get("bank") || {};
        const receiverBal = Number(receiverBank.balance || 0);

        if (!receiverTxSnap?.exists) {
          t.set(receiverTxRef, {
            userId: receiverUid,
            direction: "credit",
            amount,
            chequeId: tx.chequeId || "",
            chequeNo: tx.chequeNo || "",
            counterpartyUid: senderUid,
            bankName: tx.bankName || "",
            at: now,
            source: tx.source || (tx.method === "mobile" ? "mpay" : "bank"),
            method: tx.method || "mobile",
            status: "Completed",
            note: tx.note || `Received from ${senderUid}`,
            payeeName: tx.payeeName || "",
            details: tx.details || {},
            mirroredFrom: txId,
          });
        }

        // Credit receiver balance
        t.set(
          receiverRef,
          { bank: { ...receiverBank, balance: receiverBal + amount } },
          { merge: true }
        );

        // Update receiver bankUsers balance mirror if available
        if (receiverBankUserRef && receiverBankUserSnap) {
          const rBal = Number((receiverBankUserSnap.get("balance") ?? 0)) || 0;
          t.set(receiverBankUserRef, { balance: rBal + amount }, { merge: true });
        }
      }

      // Mark original tx processed
      t.update(freshTxRef, { processedByCF: true });
    });

    logger.info("onTransactionCreate: processed", { txId, senderUid, receiverUid, amount });
  }
);
const db = admin.firestore();

// -------------------- Type JSDoc (for hints only) --------------------
/**
 * @typedef {Object} ChequeDoc
 * @property {number} amount
 * @property {admin.firestore.Timestamp|string} date
 * @property {string} bankName
 * @property {"pending"|"cleared"|"rejected"|"bounced"} status
 * @property {string} chequeNo
 * @property {string} issuerUid
 * @property {string=} receiverUid
 * @property {{completed?: boolean, at?: admin.firestore.Timestamp}=} settlement
 */

/**
 * @typedef {Object} TransactionDoc
 * @property {string} userId
 * @property {"debit"|"credit"} direction
 * @property {number} amount
 * @property {string} chequeId
 * @property {string} chequeNo
 * @property {string|null=} counterpartyUid
 * @property {string} bankName
 * @property {admin.firestore.FieldValue|admin.firestore.Timestamp} at
 * @property {"cheque"} source
 * @property {string=} note
 */

// -------------------- Constants --------------------
const TRANSACTIONS = "transactions";

export const onChequeCreated = onDocumentCreated(
  {
    document: "users/{issuerUid}/cheques/{chequeId}",
    region: "asia-south1",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const c = event.data?.data();
    if (!c) return;
    const { issuerUid, chequeId } = event.params;
    const status = c.status || "pending";
    if (status !== "pending") return;
    const amount = Number(c.amount) || 0;
    if (!(amount > 0)) return;
    const date = c.date;
    const nowTs = admin.firestore.Timestamp.now();
    let due = true;
    if (date && typeof date.toMillis === "function") {
      due = date.toMillis() <= nowTs.toMillis();
    }
    if (!due) return;

    const issuerRef = db.collection("users").doc(issuerUid);
    const chequeRef = issuerRef.collection("cheques").doc(chequeId);
    await db.runTransaction(async (t) => {
      const [chequeSnap, issuerSnap] = await Promise.all([
        t.get(chequeRef),
        t.get(issuerRef),
      ]);
      const cc = chequeSnap.data();
      if (!cc) return;
      if ((cc.status || "pending") !== "pending") return;
      const issuerBal = Number((issuerSnap.data()?.bank?.balance) ?? 0) || 0;
      const newStatus = issuerBal >= amount ? "cleared" : "bounced";
      t.set(chequeRef, { status: newStatus }, { merge: true });
    });
  }
);

// -------------------- Firestore Trigger --------------------
export const onChequeStatusUpdated = onDocumentUpdated(
  {
    document: "users/{issuerUid}/cheques/{chequeId}",
    region: "asia-south1",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Process only when status changes to 'cleared'
    if (!(before.status !== "cleared" && after.status === "cleared")) return;

    const { issuerUid, chequeId } = event.params;

    // Skip if already settled
    if (after.settlement?.completed) {
      logger.info("Already settled, skipping", { issuerUid, chequeId });
      return;
    }

    const receiverUid =
      after.receiverUid && after.receiverUid !== issuerUid
        ? after.receiverUid
        : undefined;

    const amount = Number(after.amount) || 0;
    if (amount <= 0) {
      logger.warn("Invalid amount, skip settlement", {
        issuerUid,
        chequeId,
        amount,
      });
      return;
    }

    const issuerRef = db.collection("users").doc(issuerUid);
    const chequeRef = issuerRef.collection("cheques").doc(chequeId);

    await db.runTransaction(async (txn) => {
      // Reads first
      const chequeSnap = await txn.get(chequeRef);
      const c = chequeSnap.data();
      if (!c) throw new Error("Cheque not found in txn");
      if (c.settlement?.completed) return;

      const issuerUserRef = db.collection("users").doc(issuerUid);
      const issuerUserSnap = await txn.get(issuerUserRef);
      const issuerData = issuerUserSnap.data() || {};
      const issuerBank = issuerData.bank || {};
      const issuerBal = Number(issuerBank.balance ?? 0) || 0;
      const issuerAccount = issuerBank.accountNumber || null;

      let receiverUserRef = null;
      let receiverUserSnap = null;
      let receiverData = null;
      let receiverBank = {};
      let receiverBal = 0;
      let receiverAccount = null;
      if (receiverUid) {
        receiverUserRef = db.collection("users").doc(receiverUid);
        receiverUserSnap = await txn.get(receiverUserRef);
        receiverData = receiverUserSnap.data() || {};
        receiverBank = receiverData.bank || {};
        receiverBal = Number(receiverBank.balance ?? 0) || 0;
        receiverAccount = receiverBank.accountNumber || null;
      }

      // Resolve bankUsers by accountNumber within txn
      let issuerBUSnap = null;
      let issuerBURef = null;
      if (issuerAccount) {
        const q = db.collection("bankUsers").where("accountNumber", "==", String(issuerAccount)).limit(1);
        const qs = await txn.get(q);
        if (!qs.empty) {
          issuerBUSnap = qs.docs[0];
          issuerBURef = issuerBUSnap.ref;
        }
      }
      let receiverBUSnap = null;
      let receiverBURef = null;
      if (receiverAccount) {
        const q2 = db.collection("bankUsers").where("accountNumber", "==", String(receiverAccount)).limit(1);
        const qs2 = await txn.get(q2);
        if (!qs2.empty) {
          receiverBUSnap = qs2.docs[0];
          receiverBURef = receiverBUSnap.ref;
        }
      }

      // Writes after all reads
      const now = admin.firestore.FieldValue.serverTimestamp();

      // Create issuer transaction
      txn.set(db.collection(TRANSACTIONS).doc(), {
        userId: issuerUid,
        direction: "debit",
        amount,
        chequeId,
        chequeNo: c.chequeNo,
        counterpartyUid: receiverUid ?? null,
        bankName: c.bankName,
        at: now,
        source: "cheque",
        note: "Cheque cleared",
        status: "Completed",
        processedByCF: true,
        details: {
          fromAccount: issuerAccount,
          toAccount: receiverAccount,
        },
      });

      // Create receiver transaction
      if (receiverUid) {
        txn.set(db.collection(TRANSACTIONS).doc(), {
          userId: receiverUid,
          direction: "credit",
          amount,
          chequeId,
          chequeNo: c.chequeNo,
          counterpartyUid: issuerUid,
          bankName: c.bankName,
          at: now,
          source: "cheque",
          note: "Cheque cleared",
          status: "Completed",
          processedByCF: true,
          details: {
            fromAccount: issuerAccount,
            toAccount: receiverAccount,
          },
        });
      }

      // Update issuer user balance
      txn.set(issuerUserRef, { bank: { ...issuerBank, balance: issuerBal - amount } }, { merge: true });
      // Update issuer bankUsers mirror if available
      if (issuerBURef) {
        const buBal = Number((issuerBUSnap?.get("balance") ?? 0)) || 0;
        txn.set(issuerBURef, { balance: buBal - amount }, { merge: true });
      }

      if (receiverUid) {
        // Update receiver user balance
        txn.set(receiverUserRef, { bank: { ...receiverBank, balance: receiverBal + amount } }, { merge: true });
        // Update receiver bankUsers mirror if available
        if (receiverBURef) {
          const rbuBal = Number((receiverBUSnap?.get("balance") ?? 0)) || 0;
          txn.set(receiverBURef, { balance: rbuBal + amount }, { merge: true });
        }
      }

      // Mark settlement completed
      txn.set(chequeRef, { settlement: { completed: true, at: now } }, { merge: true });
    });

    // Try syncing receiver’s inbox status
    if (receiverUid) {
      try {
        await db
          .collection("users")
          .doc(receiverUid)
          .collection("inboxCheques")
          .doc(chequeId)
          .set({ status: "cleared" }, { merge: true });
      } catch (e) {
        const errMsg = e?.message ?? String(e);
        logger.warn("Inbox sync failed", { receiverUid, chequeId, err: errMsg });
      }
    }

    logger.info("Settlement complete", { issuerUid, chequeId, amount });
  }
);

// -------------------- Scheduled Job --------------------
export const autoClearDueCheques = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "asia-south1",
    timeZone: "Asia/Kolkata",
    memory: "256MiB",
    timeoutSeconds: 180,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const q = await db
      .collectionGroup("cheques")
      .where("status", "==", "pending")
      .where("date", "<=", now)
      .limit(200)
      .get();

    if (q.empty) return;

    for (const doc of q.docs) {
      try {
        const c = doc.data();
        const chequeRef = doc.ref;
        const issuerUid = c.issuerUid;
        if (!issuerUid) continue;

        const issuerRef = db.collection("users").doc(issuerUid);

        await db.runTransaction(async (txn) => {
          const [chequeSnap, issuerSnap] = await Promise.all([
            txn.get(chequeRef),
            txn.get(issuerRef),
          ]);
          const cc = chequeSnap.data();
          if (!cc || cc.status !== "pending") return;

          const issuerData = issuerSnap.data() || {};
          const issuerBal = Number(issuerData?.bank?.balance ?? 0);
          const amt = Number(cc.amount) || 0;

          const newStatus = issuerBal >= amt ? "cleared" : "bounced";

          txn.set(chequeRef, { status: newStatus }, { merge: true });
          // Settlement handled automatically by onChequeStatusUpdated
        });
      } catch (e) {
        const errMsg = e?.message ?? String(e);
        logger.error("Failed processing due cheque", { id: doc.id, err: errMsg });
      }
    }
  }
);
