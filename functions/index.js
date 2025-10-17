// -------------------- Imports --------------------
import admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

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

    // Only handle Completed debit payments
    if (tx.direction !== "debit" || tx.status !== "Completed") return;

    const senderUid = tx.userId;
    if (!senderUid) return;

    // Idempotency
    if (tx.processedByCF === true) return;

    // Resolve receiverUid if not provided using method/details
    async function findUserUidByEmail(email) {
      if (!email) return null;
      const s = await db.collection("users").where("email", "==", email).limit(1).get();
      return s.empty ? null : s.docs[0].id;
    }

    async function resolveReceiverUidFromDetails(txDoc) {
      if (txDoc.counterpartyUid) return txDoc.counterpartyUid;
      const method = txDoc.method;
      const d = txDoc.details || {};
      if (method === "mobile") {
        const upiOrPhone = d.upiOrPhone;
        if (!upiOrPhone) return null;
        let q = await db.collection("bankUsers").where("phone", "==", upiOrPhone).limit(1).get();
        if (!q.empty) return findUserUidByEmail(q.docs[0].get("email"));
        q = await db.collection("bankUsers").where("upi", "==", upiOrPhone).limit(1).get();
        if (!q.empty) return findUserUidByEmail(q.docs[0].get("email"));
        return null;
      }
      if (method === "bank_transfer") {
        const acct = d.toAccount;
        if (!acct) return null;
        const q = await db.collection("bankUsers").where("accountNumber", "==", acct).limit(1).get();
        if (q.empty) return null;
        return findUserUidByEmail(q.docs[0].get("email"));
      }
      return null;
    }

    const receiverUid = await resolveReceiverUidFromDetails(tx);

    const amount = Number(tx.amount || 0);
    if (!(amount > 0)) return;

    const now = admin.firestore.FieldValue.serverTimestamp();

    // Pre-resolve bankUsers document refs for sender and receiver by email (if available)
    // so we can update them inside the transaction without running queries in the txn.
    let senderBankUserRef = null;
    let receiverBankUserRef = null;
    try {
      // Sender email -> bankUsers doc
      const senderUserSnap = await db.collection("users").doc(senderUid).get();
      const senderEmail = senderUserSnap.exists ? senderUserSnap.get("email") : null;
      if (senderEmail) {
        const sBu = await db.collection("bankUsers").where("email", "==", senderEmail).limit(1).get();
        if (!sBu.empty) senderBankUserRef = sBu.docs[0].ref;
      }

      // Receiver email -> bankUsers doc (if resolvable)
      if (receiverUid) {
        const receiverUserSnap = await db.collection("users").doc(receiverUid).get();
        const receiverEmail = receiverUserSnap.exists ? receiverUserSnap.get("email") : null;
        if (receiverEmail) {
          const rBu = await db.collection("bankUsers").where("email", "==", receiverEmail).limit(1).get();
          if (!rBu.empty) receiverBankUserRef = rBu.docs[0].ref;
        }
      }
    } catch (e) {
      logger.warn("bankUsers pre-lookup failed", { err: e?.message ?? String(e) });
    }

    await db.runTransaction(async (t) => {
      const freshTxRef = db.collection("transactions").doc(txId);
      const senderRef = db.collection("users").doc(senderUid);
      const [freshTxSnap, senderSnap] = await Promise.all([
        t.get(freshTxRef),
        t.get(senderRef),
      ]);

      const fresh = freshTxSnap.data() || {};
      if (fresh.processedByCF === true) return; // idempotent

      const senderBank = senderSnap.get("bank") || {};
      const senderBal = Number(senderBank.balance || 0);

      // Server-authoritative balance enforcement
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
      if (senderBankUserRef) {
        const senderBankUserSnap = await t.get(senderBankUserRef);
        const sBal = Number((senderBankUserSnap.get("balance") ?? 0)) || 0;
        t.set(
          senderBankUserRef,
          { balance: sBal - amount },
          { merge: true }
        );
      }

      // Mirror credit if resolvable
      if (receiverUid && receiverUid !== senderUid) {
        const receiverRef = db.collection("users").doc(receiverUid);
        const receiverSnap = await t.get(receiverRef);
        const receiverBank = receiverSnap.get("bank") || {};
        const receiverBal = Number(receiverBank.balance || 0);

        // Deterministic mirror id
        const mirrorId = `${txId}__to__${receiverUid}`;
        const receiverTxRef = db.collection("transactions").doc(mirrorId);
        const receiverTxSnap = await t.get(receiverTxRef);
        if (!receiverTxSnap.exists) {
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
        if (receiverBankUserRef) {
          const receiverBankUserSnap = await t.get(receiverBankUserRef);
          const rBal = Number((receiverBankUserSnap.get("balance") ?? 0)) || 0;
          t.set(
            receiverBankUserRef,
            { balance: rBal + amount },
            { merge: true }
          );
        }
      }

      // Mark original tx processed
      t.update(freshTxRef, { processedByCF: true });
    });

    logger.info("Processed tx", { txId, senderUid, receiverUid, amount });
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
      const chequeSnap = await txn.get(chequeRef);
      const c = chequeSnap.data();
      if (!c) throw new Error("Cheque not found in txn");
      if (c.settlement?.completed) return;

      const now = admin.firestore.FieldValue.serverTimestamp();

      // Create issuer transaction
      const issuerTx = {
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
      };
      txn.set(db.collection(TRANSACTIONS).doc(), issuerTx);

      // Create receiver transaction
      if (receiverUid) {
        const receiverTx = {
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
        };
        txn.set(db.collection(TRANSACTIONS).doc(), receiverTx);
      }

      // Mark settlement completed
      txn.set(
        chequeRef,
        { settlement: { completed: true, at: now } },
        { merge: true }
      );
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
