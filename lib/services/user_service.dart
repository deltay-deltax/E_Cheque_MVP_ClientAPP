import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _users = FirebaseFirestore.instance.collection('users');

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<String?> currentUid() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> linkBankToUser(Map<String, dynamic> bankData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('not_authenticated');

    final payload = <String, dynamic>{
      'bankLinked': true,
      'bankLinkedAt': FieldValue.serverTimestamp(),
      'bank': {
        'accountNumber': bankData['accountNumber'],
        'bankName': bankData['bankName'],
        'accountType': bankData['accountType'],
        'ifsc': bankData['ifsc'],
        'branch': bankData['branch'],
        'phone': bankData['phone'],
        'balance': bankData['balance'],
      }
    };

    await _users.doc(uid).set(payload, SetOptions(merge: true));
  }

  Future<void> setTransactionPin(String pin) async {
    if (pin.length != 4) throw Exception('invalid_pin');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('not_authenticated');
    await _users.doc(uid).set({
      'transactionPinHash': _hashPin(pin),
      'transactionPinSetAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> verifyTransactionPin(String pin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('not_authenticated');
    final doc = await _users.doc(uid).get();
    final stored = doc.data()?['transactionPinHash'] as String?;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Return a stream that emits a single empty snapshot-like map
      return Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _users.doc(uid).snapshots();
  }
}
