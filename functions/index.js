// -------------------- Admin API (see adminApi below) --------------------
// -------------------- Admin API (Multiplex) --------------------
export const adminApi = onRequest({ region: "asia-south1", cors: true, timeoutSeconds: 120, memory: "512MiB", secrets: ["ADMIN_SECRET"] }, async (req, res) => {
  // Always set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, x-admin-key');
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }
  // Allow simple GET for health checks
  if (req.method === 'GET') {
    return res.status(200).json({ ok: true });
  }
  try {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const keyFromHeader = req.get('x-admin-key') || '';
    const keyFromQuery = (req.query.key || '').toString();
    const bodyRaw = typeof req.body === 'string' ? req.body : (req.body || {});
    const bodyParsed = typeof bodyRaw === 'string' ? (()=>{ try { return JSON.parse(bodyRaw);} catch { return {}; }})() : bodyRaw;
    const keyFromBody = (bodyParsed.adminKey || '').toString();
    const provided = keyFromHeader || keyFromQuery || keyFromBody;
    const expected = process.env.ADMIN_SECRET || process.env.admin_secret;
    if (!expected) return res.status(500).json({ error: 'Server not configured: ADMIN_SECRET missing' });
    if (!provided || provided !== expected) return res.status(401).json({ error: 'Unauthorized' });

    const body = bodyParsed;
    const action = String(body.action || '').trim();

    async function handleSaveBankUser() {
      const required = ['fullName','email','phone','accountNumber','accountType','bankName','branch','ifsc','balance'];
      for (const f of required) if (body[f] === undefined || body[f] === null || body[f] === '') return res.status(400).json({ error: `Missing field: ${f}` });
      const providedUid = body.uid ? String(body.uid) : '';
      const balance = Number(body.balance);
      if (Number.isNaN(balance)) return res.status(400).json({ error: 'balance must be a number' });
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
        await ref.set({ uid: ref.id }, { merge: true });
        return res.status(200).json({ ok: true, id: ref.id });
      }
    }

    async function handleListReceipts() {
      const limit = Math.min(Number(body.limit || 100), 500);
      const q = await db.collection('receipts').orderBy('serverTime', 'desc').limit(limit).get();
      const items = q.docs.map(d => ({ id: d.id, ...d.data() }));
      return res.status(200).json({ ok: true, items });
    }

    async function handleReceiptPdf() {
      const id = String(body.receiptId || '');
      if (!id) return res.status(400).json({ error: 'receiptId required' });
      const snap = await db.collection('receipts').doc(id).get();
      if (!snap.exists) return res.status(404).json({ error: 'not_found' });
      const d = snap.data() || {};
      const doc = new PDFDocument({ size: 'A4', margin: 40 });
      const chunks = [];
      doc.on('data', (c) => chunks.push(c));
      const done = new Promise((resolve) => doc.on('end', resolve));

      doc.fontSize(20).text('Cash Receipt', { align: 'left' });
      doc.moveDown(0.4);
      doc.fontSize(11).text(`Receipt ID: ${id}`);
      doc.text(`Created: ${d.createdAt || ''}`);
      doc.moveDown(0.6);

      doc.fontSize(12).fillColor('#1f2937').text('Account Information', { underline: true });
      doc.moveDown(0.2).fillColor('black');
      doc.text(`Account Holder: ${d.accountHolderName || ''}`);
      doc.text(`Account No.: ${d.accountNo || ''}`);
      doc.text(`Account Type: ${d.accountType || ''}`);
      doc.moveDown(0.6);

      const amountStr = String(d.amount || '0');
      doc.fontSize(12).fillColor('#1f2937').text('Amount', { underline: true });
      doc.moveDown(0.2).fillColor('green').text(`INR ${amountStr}`);
      if (d.amountInWords) doc.fillColor('black').text(`In Words  ${d.amountInWords}`);
      doc.moveDown(1.0);
      doc.fillColor('#1f2937').text('Signatures', { underline: true });
      doc.moveDown(0.2).fillColor('black');
      doc.text('Issuer Signature: __________________');

      doc.end();
      await done;
      const b64 = Buffer.concat(chunks).toString('base64');
      return res.status(200).json({ ok: true, pdf: b64 });
    }

    async function handleVerifyReceipt() {
      const id = String(body.receiptId || '');
      if (!id) return res.status(400).json({ error: 'receiptId required' });
      const receiptRef = db.collection('receipts').doc(id);
      let txId = null;
      // Resolve sender bankUsers ref outside the transaction (prefer same user's account number on the receipt)
      let senderBURefOutside = null;
      let resolvedAccountNoOutside = null;
      try {
        const receiptOutside = await receiptRef.get();
        const rOutside = receiptOutside.data() || {};
        const userIdOutside = rOutside.userId || null;
        const acctFromReceipt = rOutside.accountNo || rOutside.accountNumber || null;
        resolvedAccountNoOutside = acctFromReceipt || null;
        logger.info('verifyReceipt: loaded outside', { id, userIdOutside, acctFromReceipt });
        if (userIdOutside) {
          // Prefer receipt account; fall back to robust resolver by uid
          senderBURefOutside = await resolveBankUserRefFor(String(userIdOutside), acctFromReceipt || undefined);
          if (senderBURefOutside) {
            const sdoc = await senderBURefOutside.get();
            resolvedAccountNoOutside = sdoc.get('accountNumber') || acctFromReceipt || resolvedAccountNoOutside;
          }
          logger.info('verifyReceipt: resolved bankUsers ref', { accountNumber: resolvedAccountNoOutside, found: !!senderBURefOutside });
        }
      } catch (e) {
        // best-effort; continue without bankUsers mirror if resolution fails
        logger.error('verifyReceipt: pre-resolve failed', { err: e?.message || String(e) });
      }
      await db.runTransaction(async (t) => {
        const snap = await t.get(receiptRef);
        if (!snap.exists) throw new Error('not_found');
        const r = snap.data() || {};
        if ((r.status || 'created') === 'cashed_out') return; // idempotent
        const userId = r.userId;
        const amount = Number(r.amount || 0);
        const receiptAcct = r.accountNo || r.accountNumber || null;
        if (!userId || !(amount > 0)) throw new Error('invalid_payload');

        const userRef = db.collection('users').doc(String(userId));
        const userSnap = await t.get(userRef);
        const bank = userSnap.get('bank') || {};
        const bal = Number(bank.balance || 0);
        const accountUsed = receiptAcct || bank.accountNumber || resolvedAccountNoOutside || null;
        // Pre-read bankUsers snapshot BEFORE any writes (to satisfy Firestore transaction rules)
        const buRefInTx = senderBURefOutside || db.collection('bankUsers').doc(String(userId));
        const buSnapInTx = await t.get(buRefInTx);
        logger.info('verifyReceipt: tx begin', { id, userId, amount, accountUsed });

        const now = admin.firestore.FieldValue.serverTimestamp();
        // Create debit transaction
        const txRef = db.collection('transactions').doc();
        txId = txRef.id;
        t.set(txRef, {
          userId,
          direction: 'debit',
          amount,
          at: now,
          source: 'cash_receipt',
          status: 'Completed',
          processedByCF: true,
          details: { receiptId: id, fromAccount: accountUsed },
        });

        // Deduct user balance
        t.set(userRef, { bank: { ...bank, balance: bal - amount } }, { merge: true });

        // Mirror bankUsers balance using the pre-read snapshot
        try {
          const beforeBal = Number((buSnapInTx.get('balance') ?? 0)) || 0;
          const acctOnDoc = buSnapInTx.get('accountNumber') || null;
          const mirrorUpdate = { balance: beforeBal - amount };
          if (!acctOnDoc && accountUsed) mirrorUpdate.accountNumber = String(accountUsed);
          t.set(buRefInTx, mirrorUpdate, { merge: true });
          logger.info('verifyReceipt: mirrored bankUsers balance', { accountNumber: accountUsed, before: beforeBal, after: beforeBal - amount, docPath: buRefInTx.path });
        } catch (e) {
          logger.error('verifyReceipt: mirror bankUsers failed', { accountNumber: accountUsed, err: e?.message || String(e) });
        }

        // Mark receipt cashed out
        t.set(receiptRef, { status: 'cashed_out', verifiedAt: now, verifiedBy: 'admin', transactionId: txId }, { merge: true });
      });
      return res.status(200).json({ ok: true, id, txId });
    }

    async function handleListDeposits() {
      const limit = Math.min(Number(body.limit || 100), 500);
      const q = await db.collection('deposits').orderBy('createdAt', 'desc').limit(limit).get();
      const items = q.docs.map(d => ({ id: d.id, ...d.data() }));
      return res.status(200).json({ ok: true, items });
    }

    async function handleDepositGet() {
      const id = String(body.depositId || '');
      if (!id) return res.status(400).json({ error: 'depositId required' });
      const snap = await db.collection('deposits').doc(id).get();
      if (!snap.exists) return res.status(404).json({ error: 'not_found' });
      return res.status(200).json({ ok: true, id, data: snap.data() });
    }

    async function handleDepositPdf() {
      const id = String(body.depositId || '');
      const bankCopy = Boolean(body.bankCopy);
      if (!id) return res.status(400).json({ error: 'depositId required' });
      const snap = await db.collection('deposits').doc(id).get();
      if (!snap.exists) return res.status(404).json({ error: 'not_found' });
      const d = snap.data() || {};
      // Build a simple PDF using INR text to avoid Unicode issues
      const doc = new PDFDocument({ size: 'A4', margin: 40 });
      const chunks = [];
      doc.on('data', (c) => chunks.push(c));
      const done = new Promise((resolve) => doc.on('end', resolve));

      doc.fontSize(20).text('Cash Deposit Slip' + (bankCopy ? ' - Bank Copy' : ''), { align: 'left' });
      doc.moveDown(0.4);
      doc.fontSize(11).text(`Receipt No.: ${d.slipNo || id}`);
      doc.text(`Date: ${d.slipDate || ''}`);
      doc.moveDown(0.6);

      doc.fontSize(12).fillColor('#1f2937').text('Bank & Depositor Details', { underline: true });
      doc.moveDown(0.2).fillColor('black');
      doc.text(`Depositor: ${d.depositorName || ''}`);
      doc.text(`Address: ${d.depositorAddress || ''}`);
      doc.text(`Contact: ${d.depositorContact || ''}`);
      doc.moveDown(0.6);

      doc.fontSize(12).fillColor('#1f2937').text('Account Holder Details', { underline: true });
      doc.moveDown(0.2).fillColor('black');
      doc.text(`Name: ${d.accountHolderName || ''}`);
      doc.text(`Account No.: ${d.accountNo || ''}`);
      doc.text(`Account Type: ${d.accountType || ''}`);
      doc.moveDown(0.6);

      const amountStr = String(d.depositAmount || d.cashBreakdownTotal || '0');
      doc.fontSize(12).fillColor('#1f2937').text('Deposit Amount', { underline: true });
      doc.moveDown(0.2).fillColor('green').text(`Amount  INR ${amountStr}`, { continued: false });
      if (d.amountInWords) doc.fillColor('black').text(`In Words  ${d.amountInWords}`);
      doc.moveDown(0.6);

      // Cash breakdown table
      doc.fontSize(12).fillColor('#1f2937').text('Cash Breakdown', { underline: true });
      doc.moveDown(0.2).fillColor('black');
      const cb = d.cashBreakdown || {};
      const rows = Object.keys(cb).map(k => ({ denom: Number(k), qty: Number(cb[k] || 0) })).filter(r => r.denom > 0);
      rows.sort((a,b)=>b.denom-a.denom);
      doc.text('Denomination      Quantity      Amount');
      rows.forEach(r => {
        const amt = (r.denom * r.qty).toFixed(2);
        doc.text(`${r.denom.toString().padStart(4,' ')}                ${r.qty.toString().padStart(3,' ')}         INR ${amt}`);
      });
      doc.moveDown(0.2);
      doc.text(`Total: INR ${String(d.cashBreakdownTotal || amountStr)}`);
      doc.moveDown(0.6);

      if (bankCopy) {
        doc.fontSize(12).fillColor('#1f2937').text('Bank Authorization', { underline: true });
        doc.moveDown(0.2).fillColor('black');
        doc.text('Bank Stamp: __________________');
        doc.text('Authorised Signatory: __________________');
      } else {
        doc.fontSize(12).fillColor('#1f2937').text('Signatures', { underline: true });
        doc.moveDown(0.2).fillColor('black');
        doc.text('Depositor Signature: __________________');
        doc.text('Authorised Signatory: __________________');
      }

      doc.end();
      await done;
      const b64 = Buffer.concat(chunks).toString('base64');
      return res.status(200).json({ ok: true, pdf: b64 });
    }

    async function resolveBankUserRefByAccount(accountNo) {
      const qs = await db.collection('bankUsers').where('accountNumber', '==', String(accountNo)).limit(1).get();
      return qs.empty ? null : qs.docs[0].ref;
    }

    // Robust resolver: try by explicit account number, then by user's bank.uid mapping,
    // then by bankUsers.uid==auth uid, then by email.
    async function resolveBankUserRefFor(uid, accountNumber) {
      if (accountNumber) {
        const byAcct = await db.collection('bankUsers').where('accountNumber', '==', String(accountNumber)).limit(1).get();
        if (!byAcct.empty) return byAcct.docs[0].ref;
      }
      const userDoc = await db.collection('users').doc(String(uid)).get();
      const userAcct = userDoc.get('bank.accountNumber');
      if (!accountNumber && userAcct) {
        const byAcct2 = await db.collection('bankUsers').where('accountNumber', '==', String(userAcct)).limit(1).get();
        if (!byAcct2.empty) return byAcct2.docs[0].ref;
      }
      const bUid = userDoc.get('bank.uid');
      if (bUid) return db.collection('bankUsers').doc(String(bUid));
      let q = await db.collection('bankUsers').where('uid', '==', String(uid)).limit(1).get();
      if (!q.empty) return q.docs[0].ref;
      const email = userDoc.get('email');
      if (email) {
        q = await db.collection('bankUsers').where('email', '==', email).limit(1).get();
        if (!q.empty) return q.docs[0].ref;
      }
      return null;
    }

    async function handleVerifyDeposit() {
      const id = String(body.depositId || '');
      if (!id) return res.status(400).json({ error: 'depositId required' });
      const depRef = db.collection('deposits').doc(id);
      let senderTxId = null;
      let receiverTxId = null;

      // Resolve receiver bank user ref OUTSIDE the transaction (by account number)
      // and sender bankUsers ref via sender's accountNumber so we can read the docs
      // inside the transaction without additional queries.
      const depOutside = await depRef.get();
      const depDataOutside = depOutside.data() || {};
      const accountNoOutside = depDataOutside.accountNo || depDataOutside.accountNumber || null;
      const senderUidOutside = depDataOutside.userId || null;
      let receiverBURefOutside = null;
      let senderBURefOutside = null;
      if (senderUidOutside) {
        const senderUserOutsideRef = db.collection('users').doc(String(senderUidOutside));
        const senderUserOutsideSnap = await senderUserOutsideRef.get();
        const senderAcctOutside = senderUserOutsideSnap.get('bank.accountNumber');
        if (senderAcctOutside) {
          senderBURefOutside = await resolveBankUserRefByAccount(String(senderAcctOutside));
        }
      }
      if (accountNoOutside) {
        receiverBURefOutside = await resolveBankUserRefByAccount(accountNoOutside);
      }

      await db.runTransaction(async (t) => {
        // READS (all before writes)
        const depSnap = await t.get(depRef);
        if (!depSnap.exists) throw new Error('not_found');
        const d = depSnap.data() || {};
        if ((d.status || 'Pending') === 'Verified') return; // idempotent
        const amount = Number(d.depositAmount || d.cashBreakdownTotal || 0);
        if (!(amount > 0)) throw new Error('invalid_amount');
        const senderUid = d.userId || null;
        const accountNo = d.accountNo || d.accountNumber || null;
        if (!senderUid || !accountNo) throw new Error('missing_user_or_account');

        const senderRef = db.collection('users').doc(senderUid);
        const senderSnap = await t.get(senderRef);
        const senderBank = senderSnap.get('bank') || {};
        const senderBal = Number(senderBank.balance || 0);

        let receiverUid = null;
        let receiverRef = null;
        let receiverSnap = null;
        let receiverBank = {};
        let receiverBal = 0;
        let receiverBURef = receiverBURefOutside;
        let receiverBUSnap = null;
        let senderBURef = senderBURefOutside;
        let senderBUSnap = null;
        if (senderBURef) {
          senderBUSnap = await t.get(senderBURef);
        }
        if (receiverBURef) {
          receiverBUSnap = await t.get(receiverBURef);
          receiverUid = receiverBUSnap.get('uid') || null;
        }
        if (receiverUid && receiverUid !== senderUid) {
          receiverRef = db.collection('users').doc(String(receiverUid));
          receiverSnap = await t.get(receiverRef);
          receiverBank = receiverSnap.get('bank') || {};
          receiverBal = Number(receiverBank.balance || 0);
        }

        // WRITES
        const now = admin.firestore.FieldValue.serverTimestamp();

        // Sender debit transaction
        const senderTxRef = db.collection('transactions').doc();
        senderTxId = senderTxRef.id;
        t.set(senderTxRef, {
          userId: senderUid,
          direction: 'debit',
          amount,
          at: now,
          source: 'cash_deposit',
          status: 'Completed',
          processedByCF: true,
          details: { toAccount: accountNo, depositId: id },
        });

        // Receiver credit transaction (if resolved)
        if (receiverRef) {
          const receiverTxRef = db.collection('transactions').doc();
          receiverTxId = receiverTxRef.id;
          t.set(receiverTxRef, {
            userId: String(receiverUid),
            direction: 'credit',
            amount,
            at: now,
            source: 'cash_deposit',
            status: 'Completed',
            processedByCF: true,
            details: { fromUser: senderUid, depositId: id, toAccount: accountNo },
          });
        }

        // Update balances
        t.set(
          senderRef,
          { bank: { ...senderBank, balance: senderBal - amount } },
          { merge: true }
        );
        if (receiverRef) {
          t.set(
            receiverRef,
            { bank: { ...receiverBank, balance: receiverBal + amount, accountNumber: receiverBank.accountNumber || accountNo } },
            { merge: true }
          );
        }
        if (receiverBURef && receiverBUSnap) {
          const rbuBal = Number((receiverBUSnap.get('balance') ?? 0)) || 0;
          t.set(receiverBURef, { balance: rbuBal + amount }, { merge: true });
        }
        if (senderBURef && senderBUSnap) {
          const sbuBal = Number((senderBUSnap.get('balance') ?? 0)) || 0;
          t.set(senderBURef, { balance: sbuBal - amount }, { merge: true });
        }

        // Mark deposit verified
        t.set(depRef, {
          status: 'Verified',
          verifiedAt: now,
          verifiedBy: 'admin',
          transactionId: receiverTxId || senderTxId,
        }, { merge: true });
      });
      return res.status(200).json({ ok: true, id, senderTxId, receiverTxId });
    }

    if (action === 'saveBankUser') return await handleSaveBankUser();
    if (action === 'listDeposits') return await handleListDeposits();
    if (action === 'depositGet') return await handleDepositGet();
    if (action === 'verifyDeposit') return await handleVerifyDeposit();
    if (action === 'depositPdf') return await handleDepositPdf();
    if (action === 'listReceipts') return await handleListReceipts();
    if (action === 'receiptPdf') return await handleReceiptPdf();
    if (action === 'verifyReceipt') return await handleVerifyReceipt();
    return res.status(400).json({ error: 'unknown_action' });
  } catch (e) {
    const msg = e?.message || String(e);
    logger.error('adminApi failed', { err: msg });
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
import PDFDocument from "pdfkit";

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
