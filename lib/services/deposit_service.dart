import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class DepositService {
  DepositService._();
  static final DepositService instance = DepositService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('deposits');

  Future<String> createDeposit(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('not_authenticated');
    final doc = await _col.add({
      ...data,
      'userId': uid,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      final amt = ((data['depositAmount'] as num?) ?? (data['cashBreakdownTotal'] as num?) ?? 0).toDouble();
      final slipNo = (data['slipNo'] as String?) ?? doc.id;
      await NotificationService.instance.send(
        toUid: uid,
        type: 'deposit_created',
        title: 'Deposit created',
        body: 'Deposit $slipNo of ₹$amt created',
        amount: amt,
        occurredAt: DateTime.now(),
        data: {
          'depositId': doc.id,
          'slipNo': slipNo,
        },
      );
    } catch (_) {}
    return doc.id;
  }

  Stream<List<Map<String, dynamic>>> streamUserDeposits() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}
