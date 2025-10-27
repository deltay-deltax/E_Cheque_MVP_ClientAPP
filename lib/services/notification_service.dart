import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userNotifs(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Future<void> send({
    required String toUid,
    required String type, // e.g. tx_sent, tx_received, cheque_cleared, cheque_bounced, deposit_verified, receipt_cashed
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final now = FieldValue.serverTimestamp();
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    await _userNotifs(toUid).add({
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},
      'createdAt': now,
      'read': false,
      if (fromUid != null) 'fromUid': fromUid,
      'toUid': toUid,
    });
  }

  Stream<int> streamUnreadCount(String uid) {
    return _userNotifs(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll(String uid) {
    return _userNotifs(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String uid, String docId) async {
    await _userNotifs(uid).doc(docId).update({'read': true});
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _userNotifs(uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
