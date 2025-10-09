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
  }) async {
    final uid = _uid;
    return _db.runTransaction((txn) async {
      final userDocRef = _userDoc(uid);
      final userSnap = await txn.get(userDocRef);
      int nextNo = (userSnap.data()?['nextChequeNo'] as int?) ?? 100000; // start at 100000
      final chequeNo = (nextNo).toString();

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
      };

      txn.set(newChequeRef, data);
      txn.update(userDocRef, {'nextChequeNo': nextNo + 1});

      return newChequeRef.id;
    });
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
}
