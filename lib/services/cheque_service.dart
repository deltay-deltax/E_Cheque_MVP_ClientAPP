import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChequeService {
  ChequeService._();
  static final ChequeService instance = ChequeService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _userChequesRef(String uid) =>
      _db.collection('users').doc(uid).collection('cheques');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates a cheque under users/{uid}/cheques with an auto ID and a unique cheque number.
  /// Also increments users/{uid}.nextChequeNo in a transaction.
  Future<String> createCheque({
    required String payee,
    required String amount,
    required DateTime date,
    required String bankName,
    String? notes,
    String? signaturePath,
    String status = 'pending',
    String? receiverPhone,
    String? receiverAccount,
  }) async {
    final uid = _uid;
    // Resolve receiver uid ahead of time to include in the cheque document
    String? resolvedReceiverUid;
    try {
      resolvedReceiverUid = await _findUserByAccountOrPhone(
        account: receiverAccount,
        phone: receiverPhone,
      );
    } catch (_) {}

    String chequeNoVal = '';
    double issuerBalAtCreate = 0.0;
    final newId = await _db.runTransaction((txn) async {
      final userDocRef = _userDoc(uid);
      final userSnap = await txn.get(userDocRef);
      int nextNo = (userSnap.data()?['nextChequeNo'] as int?) ?? 100000; // start at 100000
      final chequeNo = (nextNo).toString();
      chequeNoVal = chequeNo;
      issuerBalAtCreate = ((userSnap.data()?['bank'] as Map<String, dynamic>?)?['balance'] as num?)?.toDouble() ?? 0.0;

      // Prepare cheque data
      final newChequeRef = _userChequesRef(uid).doc();
      final data = {
        'payee': payee,
        'amount': double.tryParse(amount) ?? 0.0,
        'date': Timestamp.fromDate(date),
        'bankName': bankName,
        'notes': notes ?? '',
        'signaturePath': signaturePath ?? '',
        'status': status, // pending | cleared | rejected | bounced
        'createdAt': FieldValue.serverTimestamp(),
        'chequeNo': chequeNo,
        'issuerUid': uid,
        'receiverPhone': receiverPhone ?? '',
        'receiverAccount': receiverAccount ?? '',
        if (resolvedReceiverUid != null) 'receiverUid': resolvedReceiverUid,
      };

      txn.set(newChequeRef, data);
      txn.update(userDocRef, {'nextChequeNo': nextNo + 1});

      return newChequeRef.id;
    });
    // Mirror to receiver inbox if resolved and not self
    if (resolvedReceiverUid != null && resolvedReceiverUid != uid) {
      final inboxRef = _userDoc(resolvedReceiverUid).collection('inboxCheques').doc(newId);
      await inboxRef.set({
        'id': newId,
        'issuerUid': uid,
        'issuerName': _auth.currentUser?.displayName ?? '',
        'issuerBalance': issuerBalAtCreate,
        'payee': payee,
        'amount': double.tryParse(amount) ?? 0.0,
        'date': Timestamp.fromDate(date),
        'bankName': bankName,
        'notes': notes ?? '',
        'signaturePath': signaturePath ?? '',
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'chequeNo': chequeNoVal,
      });
    }
    return newId;
  }

  Future<String?> _findUserByAccountOrPhone({String? account, String? phone}) async {
    if (account != null && account.isNotEmpty) {
      final q = await _db
          .collection('users')
          .where('bank.accountNumber', isEqualTo: account)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }
    if (phone != null && phone.isNotEmpty) {
      final q = await _db
          .collection('users')
          .where('bank.phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }
    return null;
  }

  Future<void> processDueCheques() async {
    final uid = _uid;
    final now = DateTime.now();
    final pendingSnap = await _userChequesRef(uid)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final d in pendingSnap.docs) {
      final data = d.data();
      final ts = data['date'] as Timestamp?;
      if (ts == null) continue;
      final dueDate = ts.toDate();
      if (!dueDate.isAfter(now)) {
        // due or past due
        String newStatus = 'pending';
        await _db.runTransaction((txn) async {
          final issuerRef = _userDoc(uid);
          final issuerDoc = await txn.get(issuerRef);
          final issuerBal = ((issuerDoc.data()?['bank'] as Map<String, dynamic>?)?['balance'] as num?)?.toDouble() ?? 0.0;
          final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;

          if (issuerBal >= amt) {
            // Deduct from issuer
            txn.set(issuerRef, {
              'bank': {
                'balance': issuerBal - amt,
              }
            }, SetOptions(merge: true));
            newStatus = 'cleared';
          } else {
            newStatus = 'bounced';
          }

          final updates = {
            'status': newStatus,
          };
          txn.update(d.reference, updates);
          // If receiverUid exists, also update inbox status (separate write after txn)
        });
        final receiverUid = (data['receiverUid'] as String?);
        if (receiverUid != null && receiverUid.isNotEmpty && receiverUid != uid) {
          try {
            await _userDoc(receiverUid).collection('inboxCheques').doc(d.id).update({'status': newStatus});
          } catch (_) {}
        }
      }
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserCheques({String? uid}) {
    final u = uid ?? _uid;
    return _userChequesRef(u)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<Map<String, dynamic>?> getChequeById(String chequeId, {String? uid}) async {
    final u = uid ?? _uid;
    final doc = await _userChequesRef(u).doc(chequeId).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Stream<List<Map<String, dynamic>>> streamReceivedChequesFor({String? phone, String? account}) {
    // This method is deprecated in favor of streamInboxCheques(uid)
    return const Stream<List<Map<String, dynamic>>>.empty();
  }

  Stream<List<Map<String, dynamic>>> streamInboxCheques(String uid) {
    return _userDoc(uid)
        .collection('inboxCheques')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}
