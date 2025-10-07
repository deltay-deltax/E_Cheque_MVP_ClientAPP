import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<Map<String, dynamic>?> findByAccount(String accountNumber) async {
    if (accountNumber.isEmpty) return null;
    final q = await _bankUsers
        .where('accountNumber', isEqualTo: accountNumber)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }
}
