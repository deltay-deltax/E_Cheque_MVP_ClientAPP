import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceiptService {
  ReceiptService._();
  static final instance = ReceiptService._();

  Future<void> createReceipt(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final payload = {
      ...data,
      'userId': uid,
      'createdAt': now.toIso8601String(),
      'serverTime': FieldValue.serverTimestamp(),
      'status': 'created',
    };
    await FirebaseFirestore.instance
        .collection('receipts')
        .add(payload);
  }

  Stream<List<Map<String, dynamic>>> streamUserReceipts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('receipts')
        .where('userId', isEqualTo: uid)
        .orderBy('serverTime', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
