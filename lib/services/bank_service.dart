import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class BankService {
  BankService._();
  static final instance = BankService._();

  final _bankUsers = FirebaseFirestore.instance.collection('bankUsers');

  Future<Map<String, dynamic>?> findByPhone(String phone) async {
    if (phone.isEmpty) return null;
    final q = await _bankUsers.where('phone', isEqualTo: phone).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  Future<List<Map<String, dynamic>>> searchByPhonePrefix(String prefix, {int limit = 5}) async {
    if (prefix.isEmpty) return [];
    final end = prefix.substring(0, prefix.length - 1) + String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);
    final q = await _bankUsers
        .where('phone', isGreaterThanOrEqualTo: prefix)
        .where('phone', isLessThan: end)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> searchByUpiPrefix(String prefix, {int limit = 5}) async {
    if (prefix.isEmpty) return [];
    final end = prefix.substring(0, prefix.length - 1) + String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);
    final q = await _bankUsers
        .where('upi', isGreaterThanOrEqualTo: prefix)
        .where('upi', isLessThan: end)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<Map<String, dynamic>?> findByAccount(String accountNumber) async {
    if (accountNumber.isEmpty) return null;
    final q = await _bankUsers
        .where('accountNumber', isEqualTo: accountNumber)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  Future<Map<String, dynamic>?> findByEmail(String email) async {
    if (email.isEmpty) return null;
    final q = await _bankUsers.where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  Stream<Map<String, dynamic>?> streamByEmail(String email) {
    if (email.isEmpty) return const Stream<Map<String, dynamic>?>.empty();
    return _bankUsers.where('email', isEqualTo: email).limit(1).snapshots().map(
      (snap) => snap.docs.isEmpty ? null : snap.docs.first.data(),
    );
  }

  Stream<Map<String, dynamic>?> streamByAccount(String accountNumber) {
    if (accountNumber.isEmpty) return const Stream<Map<String, dynamic>?>.empty();
    return _bankUsers.where('accountNumber', isEqualTo: accountNumber).limit(1).snapshots().map(
      (snap) => snap.docs.isEmpty ? null : snap.docs.first.data(),
    );
  }

  Future<void> setTransactionPinForAccount(String accountNumber, String pin) async {
    if (pin.length != 4) {
      throw Exception('invalid_pin');
    }
    final q = await _bankUsers
        .where('accountNumber', isEqualTo: accountNumber)
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      throw Exception('bank_account_not_found');
    }
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _bankUsers.doc(q.docs.first.id).set({
      'transactionPinHash': hash,
      'transactionPinSetAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

