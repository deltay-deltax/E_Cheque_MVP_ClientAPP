import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _users = FirebaseFirestore.instance.collection('users');

  // v2: salted + iterative hashing
  String _deriveHash(String pin, String salt, int iterations) {
    var bytes = utf8.encode('$salt:$pin');
    var out = sha256.convert(bytes).bytes;
    for (var i = 1; i < iterations; i++) {
      out = sha256.convert([...out, ...utf8.encode(salt)]).bytes;
    }
    return _bytesToHex(out);
  }

  String _randomSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _bytesToHex(List<int> bytes) {
    final StringBuffer sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

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
    const iterations = 20000;
    final salt = _randomSalt();
    final hash = _deriveHash(pin, salt, iterations);
    await _users.doc(uid).set({
      'transactionPin': {
        'hash': hash,
        'salt': salt,
        'iterations': iterations,
        'algo': 'sha256-iter',
        'setAt': FieldValue.serverTimestamp(),
      },
      'transactionPinHash': FieldValue.delete(), // cleanup legacy flat hash
      'pin': {
        'attempts': 0,
        'lockedUntil': null,
      },
    }, SetOptions(merge: true));
  }

  Future<bool> verifyTransactionPin(String pin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('not_authenticated');
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return false;

    // Lockout check
    final pinMeta = (data['pin'] as Map<String, dynamic>?) ?? {};
    final attempts = (pinMeta['attempts'] as int?) ?? 0;
    final lockedUntil = pinMeta['lockedUntil'];
    if (lockedUntil is Timestamp) {
      final now = DateTime.now();
      if (lockedUntil.toDate().isAfter(now)) {
        return false; // still locked
      }
    }

    // Support legacy flat hash for migration
    if (data.containsKey('transactionPinHash')) {
      final legacyStored = data['transactionPinHash'] as String?;
      final ok = legacyStored == sha256.convert(utf8.encode(pin)).toString();
      await _updateAttempts(uid, ok, attempts);
      return ok;
    }

    final pinObj = (data['transactionPin'] as Map<String, dynamic>?) ?? {};
    final salt = pinObj['salt'] as String?;
    final hash = pinObj['hash'] as String?;
    final iterations = (pinObj['iterations'] as int?) ?? 20000;
    if (salt == null || hash == null) return false;
    final candidate = _deriveHash(pin, salt, iterations);
    final ok = candidate == hash;
    await _updateAttempts(uid, ok, attempts);
    return ok;
  }

  Future<void> _updateAttempts(String uid, bool success, int currentAttempts) async {
    if (success) {
      await _users.doc(uid).set({
        'pin': {
          'attempts': 0,
          'lockedUntil': null,
        }
      }, SetOptions(merge: true));
    } else {
      final nextAttempts = currentAttempts + 1;
      final updates = <String, dynamic>{
        'pin': {
          'attempts': nextAttempts,
        }
      };
      if (nextAttempts >= 5) {
        final lockUntil = DateTime.now().add(const Duration(minutes: 15));
        updates['pin'] = {
          'attempts': 0,
          'lockedUntil': Timestamp.fromDate(lockUntil),
        };
      }
      await _users.doc(uid).set(updates, SetOptions(merge: true));
    }
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

