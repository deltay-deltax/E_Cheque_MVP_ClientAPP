import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum TransactionType { all, income, expense, pending }

class TransactionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final double amount;
  final bool incoming;
  final String date;
  final String status;
  final TransactionType type;

  TransactionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.amount,
    required this.incoming,
    required this.date,
    required this.status,
    required this.type,
  });
}

class TransactionsViewModel extends ChangeNotifier {
  TransactionType selectedType = TransactionType.all;
  String searchText = "";
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final List<TransactionItem> _items = [];

  TransactionsViewModel() {
    _init();
  }

  Future<void> _init() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _sub?.cancel();
    _sub = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('at', descending: true)
        .snapshots()
        .listen((snap) {
      _items
        ..clear()
        ..addAll(snap.docs.map(_fromDoc));
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void setType(TransactionType type) {
    selectedType = type;
    notifyListeners();
  }

  void search(String s) {
    searchText = s;
    notifyListeners();
  }

  double get totalBalance {
    double bal = 0;
    for (final t in _items) {
      bal += t.incoming ? t.amount : -t.amount;
    }
    return bal;
  }

  List<TransactionItem> get transactions => List.unmodifiable(_items);

  List<TransactionItem> get filteredTransactions {
    var results = transactions;
    if (selectedType != TransactionType.all) {
      results = results.where((t) => t.type == selectedType).toList();
    }
    if (searchText.trim().isNotEmpty) {
      final query = searchText.toLowerCase();
      results = results
          .where(
            (t) =>
                t.title.toLowerCase().contains(query) ||
                t.subtitle.toLowerCase().contains(query),
          )
          .toList();
    }
    return results;
  }

  TransactionItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final dir = (data['direction'] as String?) ?? 'debit';
    final incoming = dir == 'credit';
    final amount = ((data['amount'] as num?) ?? 0).toDouble();
    final note = (data['note'] as String?) ?? (data['source'] as String? ?? 'Transaction');
    final bankName = (data['bankName'] as String?) ?? '';
    final categoryName = (data['categoryName'] as String?) ?? '';
    final atTs = data['at'];
    String dateStr = '';
    if (atTs is Timestamp) {
      final dt = atTs.toDate();
      dateStr = _friendlyTime(dt);
    }
    final type = incoming ? TransactionType.income : TransactionType.expense;
    return TransactionItem(
      title: note,
      subtitle: categoryName.isNotEmpty
          ? categoryName
          : (bankName.isNotEmpty ? bankName : (incoming ? 'Income' : 'Payment')),
      icon: incoming ? Icons.arrow_downward : Icons.arrow_upward,
      bgColor: incoming ? const Color(0xFFE6FFF4) : const Color(0xFFFFE3E2),
      amount: amount,
      incoming: incoming,
      date: dateStr,
      status: 'Completed',
      type: type,
    );
  }

  String _friendlyTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
