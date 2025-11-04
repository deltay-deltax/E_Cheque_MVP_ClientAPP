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

  // Normalize phone like +919876543210
  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    if (phone.startsWith('+')) return phone; // fallback
    return '+$digits';
  }

  // Resolve a user by phone from users collection: prefer users.bank.phone
  Future<String?> _resolveUidByPhone(String phone) async {
    final db = FirebaseFirestore.instance;
    final norm = _normalizePhone(phone);
    try {
      final byBank = await db
          .collection('users')
          .where('bank.phone', isEqualTo: norm)
          .limit(1)
          .get();
      if (byBank.docs.isNotEmpty) return byBank.docs.first.id;
    } catch (_) {}
    try {
      final byRoot = await db
          .collection('users')
          .where('phone', isEqualTo: norm)
          .limit(1)
          .get();
      if (byRoot.docs.isNotEmpty) return byRoot.docs.first.id;
    } catch (_) {}
    return null;
  }

  // Deliver an invoice-like payload to receiver's inbox subcollection
  Future<bool> deliverToReceiverInvoice({
    required Map<String, dynamic> invoiceData,
    required String receiverPhone,
  }) async {
    final db = FirebaseFirestore.instance;
    final toUid = await _resolveUidByPhone(receiverPhone);
    if (toUid == null) return false;
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    String? fromName = FirebaseAuth.instance.currentUser?.displayName;
    try {
      if ((fromName == null || fromName.trim().isEmpty) && fromUid != null) {
        final u = await db.collection('users').doc(fromUid).get();
        final data = u.data();
        final n = (data?['fullName'] as String?) ?? (data?['displayName'] as String?);
        if (n != null && n.trim().isNotEmpty) fromName = n.trim();
      }
    } catch (_) {}
    try {
      await db
          .collection('users')
          .doc(toUid)
          .collection('received_invoices')
          .add({
        ...invoiceData,
        if (fromUid != null) 'fromUid': fromUid,
        if (fromName != null) 'fromName': fromName,
        'toUid': toUid,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // Inbox stream for the signed-in user
  Stream<List<Map<String, dynamic>>> streamUserReceivedInvoices() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('received_invoices')
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}

