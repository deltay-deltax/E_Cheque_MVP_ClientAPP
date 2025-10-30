import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
    double? amount, // optional amount to display in UI
    DateTime? occurredAt, // optional event time separate from createdAt
    Map<String, dynamic>? data,
  }) async {
    final now = FieldValue.serverTimestamp();
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    await _userNotifs(toUid).add({
      'type': type,
      'title': title,
      'body': body,
      if (amount != null) 'amount': amount,
      if (occurredAt != null) 'occurredAt': Timestamp.fromDate(occurredAt),
      'data': data ?? {},
      'createdAt': now,
      'read': false,
      if (fromUid != null) 'fromUid': fromUid,
      'toUid': toUid,
    });
  }

  final Set<String> _watchingUids = <String>{};
  StreamSubscription? _depSub; // listens to user's own deposits
  // Removed receiver-side deposits watcher due to Firestore rules; rely on transactions
  StreamSubscription? _recSub; // listens to user's receipts
  StreamSubscription? _txDepSub; // listens to user's transactions for deposit sources

  void startUserOutcomeWatchers() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_watchingUids.contains(uid)) return;
    _watchingUids.add(uid);

    // Watch deposits CREATED BY this user and notify when verified; also ensure tx exists (sender debit already handled by CF; this is receiver credit fallback for same user scenario)
    _depSub = FirebaseFirestore.instance
        .collection('deposits')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((qs) async {
      final now = DateTime.now();
      for (final d in qs.docChanges) {
        final data = d.doc.data() ?? {};
        final status = (data['status'] as String?) ?? '';
        if (status.toLowerCase() == 'verified') {
          final amt = ((data['depositAmount'] as num?) ?? (data['cashBreakdownTotal'] as num?) ?? 0).toDouble();
          final slipNo = (data['slipNo'] as String?) ?? d.doc.id;
          // Ensure a transaction exists for this verified deposit
          final txSnap = await FirebaseFirestore.instance
              .collection('transactions')
              .where('userId', isEqualTo: uid)
              .where('source', isEqualTo: 'deposit')
              .where('depositId', isEqualTo: d.doc.id)
              .limit(1)
              .get();
          if (txSnap.docs.isEmpty) {
            await FirebaseFirestore.instance.collection('transactions').add({
              'userId': uid,
              'direction': 'credit',
              'amount': amt,
              'at': FieldValue.serverTimestamp(),
              'source': 'deposit',
              'method': 'cash',
              'status': 'Completed',
              'note': 'Cash deposit $slipNo',
              'depositId': d.doc.id,
            });
          }
          await sendOnce(
            toUid: uid,
            type: 'deposit_verified',
            title: 'Deposit verified',
            body: 'Your deposit $slipNo has been verified',
            amount: amt,
            occurredAt: now,
            uniqueFieldPath: 'data.depositId',
            uniqueValue: d.doc.id,
            data: {'depositId': d.doc.id, 'slipNo': slipNo},
          );
        }
      }
    });

    // Receiver notifications are derived from transactions stream below

    // Watch receipts (self cash) and notify when cashed out
    _recSub = FirebaseFirestore.instance
        .collection('receipts')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((qs) async {
      final now = DateTime.now();
      for (final d in qs.docChanges) {
        final data = d.doc.data() ?? {};
        final status = (data['status'] as String?) ?? '';
        if (status.toLowerCase().contains('cash')) {
          final amt = ((data['amount'] as num?) ?? 0).toDouble();
          await sendOnce(
            toUid: uid,
            type: 'receipt_cashed',
            title: 'Cash receipt cashed out',
            body: 'Your cash receipt has been cashed out',
            amount: amt,
            occurredAt: now,
            uniqueFieldPath: 'data.receiptId',
            uniqueValue: d.doc.id,
            data: {'receiptId': d.doc.id},
          );
        }
      }
    });

    // Watch transactions for deposit sources to produce notifications reliably for both sender/receiver
    _txDepSub = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .where('source', whereIn: ['cash_deposit', 'deposit'])
        .snapshots()
        .listen((qs) async {
      for (final ch in qs.docChanges) {
        final t = ch.doc.data() ?? {};
        final depId = (t['details']?['depositId'] as String?) ?? (t['depositId'] as String?);
        if (depId == null) continue;
        final amt = ((t['amount'] as num?) ?? 0).toDouble();
        final dir = (t['direction'] as String?) ?? 'debit';
        final at = t['at'];
        DateTime? when;
        if (at is Timestamp) when = at.toDate();
        if (dir == 'credit') {
          await sendOnce(
            toUid: uid,
            type: 'deposit_received',
            title: 'Deposit received',
            body: 'Cash deposit credited',
            amount: amt,
            occurredAt: when,
            uniqueFieldPath: 'data.depositId',
            uniqueValue: depId,
            data: {'depositId': depId},
          );
        } else {
          await sendOnce(
            toUid: uid,
            type: 'deposit_posted',
            title: 'Deposit posted',
            body: 'Your cash deposit was posted',
            amount: amt,
            occurredAt: when,
            uniqueFieldPath: 'data.depositId',
            uniqueValue: depId,
            data: {'depositId': depId},
          );
        }
      }
    });
  }

  Future<void> sendOnce({
    required String toUid,
    required String type,
    required String title,
    required String body,
    required String uniqueFieldPath, // e.g. 'data.depositId'
    required String uniqueValue,
    double? amount,
    DateTime? occurredAt,
    Map<String, dynamic>? data,
  }) async {
    final existing = await _userNotifs(toUid)
        .where('type', isEqualTo: type)
        .where(uniqueFieldPath, isEqualTo: uniqueValue)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _userNotifs(toUid).add({
      'type': type,
      'title': title,
      'body': body,
      if (amount != null) 'amount': amount,
      if (occurredAt != null) 'occurredAt': Timestamp.fromDate(occurredAt),
      'data': {
        ...(data ?? {}),
        // nested fields under 'data' support querying like where('data.depositId', ...)
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'toUid': toUid,
      if (FirebaseAuth.instance.currentUser?.uid != null)
        'fromUid': FirebaseAuth.instance.currentUser!.uid,
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
