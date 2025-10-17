import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/categories_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // UI state
  String selectedName = "Travelling";
  String writeName = "";
  String amount = "";
  final TextEditingController amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool hasInvoice = false;

  // Categories from Firestore
  StreamSubscription<List<Category>>? _catSub;
  List<Category> _categories = [];

  ExpenseViewModel() {
    _init();
    amountController.addListener(() {
      if (amountController.text != amount) {
        amount = amountController.text;
      }
    });
  }

  Future<void> _init() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await CategoriesService.instance.ensureDefaultCategories(uid);
    _catSub?.cancel();
    _catSub = CategoriesService.instance
        .streamUserCategories(uid)
        .listen((cats) {
      _categories = cats;
      // If selectedName not in categories, pick first default
      final names = expenseNames;
      if (names.isNotEmpty && !names.contains(selectedName)) {
        selectedName = names.first;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _catSub?.cancel();
    super.dispose();
  }

  // Expose current category names for dropdown
  List<String> get expenseNames => _categories.map((c) => c.name).toList();

  void setSelectedName(String name) {
    selectedName = name;
    notifyListeners();
  }

  void setWriteName(String val) {
    writeName = val;
    notifyListeners();
  }

  void setAmount(String val) {
    amount = val;
    if (amountController.text != val) {
      amountController.text = val;
      amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: amountController.text.length),
      );
    }
    notifyListeners();
  }

  void clearAmount() {
    amount = "";
    amountController.clear();
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addInvoice() {
    hasInvoice = true;
    notifyListeners();
  }

  // Persist expense as a transaction document
  Future<void> saveExpense() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final parsedAmount = double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final category = _categories.firstWhere(
      (c) => c.name == selectedName,
      orElse: () => Category(
        id: '',
        userId: uid,
        name: selectedName,
        color: '#2563EB',
        icon: 'category',
        createdAt: Timestamp.now(),
      ),
    );

    await _db.collection('transactions').add({
      'userId': uid,
      'amount': parsedAmount,
      'direction': 'debit',
      'status': 'Completed',
      'source': 'manual',
      'note': writeName.isNotEmpty ? writeName : selectedName,
      'payeeName': writeName,
      'categoryId': category.id,
      'categoryName': category.name,
      'at': Timestamp.fromDate(selectedDate),
    });
  }

  // Category icon helper for dropdown visuals
  IconData iconForCategoryName(String name) {
    try {
      final c = _categories.firstWhere((e) => e.name == name);
      switch (c.icon) {
        case 'flight':
          return Icons.flight;
        case 'checkroom':
          return Icons.checkroom;
        case 'restaurant':
          return Icons.fastfood;
        case 'home':
          return Icons.home;
        default:
          return Icons.category;
      }
    } catch (_) {
      return Icons.category;
    }
  }
}
