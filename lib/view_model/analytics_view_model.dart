import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/categories_service.dart';

class AnalyticsCategory {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final int percent;
  final int amount;
  final String summaryLabel;
  final String summaryDesc;
  AnalyticsCategory({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.percent,
    required this.amount,
    required this.summaryLabel,
    required this.summaryDesc,
  });
}

class AnalyticsViewModel extends ChangeNotifier {
  int monthIdx = DateTime.now().month - 1;
  int get totalTransactions => 496000;
  int chartMode = 0; // 0: last7 days, 1: weekday UPI

  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  int get currentMonthIndex => DateTime.now().month - 1;


  // Selected payee to drive header graph type
  String? selectedPayee;

  // Mock breakdown amounts per payee for the horizontal bar chart
  // In a real app this would be computed from transactions for the selected month
  final Map<String, double> _payeeBreakdown = const {
    'HDFC Bank': 8200,
    'RAJESH M': 2600,
    'VEENA S': 2100,
    'API INFO': 1400,
    'airtel': 1200,
    'Other Payees': 900,
  };

  List<MapEntry<String, double>> get payeeBreakdown => _payeeBreakdown.entries.toList();

  void selectPayee(String? name) {
    selectedPayee = name;
    notifyListeners();
  }

  // Firestore-driven analytics
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<List<Category>>? _catSub;
  List<Category> _categories = [];
  final List<double> _dailySpends = []; // debits per day for selected month
  Map<String, double> _payeeTotals = {};
  final Map<String, double> _categoryTotals = {}; // categoryId -> amount for month
  final List<double> _weekdayMobileSpends = List<double>.filled(7, 0.0); // Mon..Sun mobile spends
  double _incomeTotal = 0.0;
  double _expenseTotal = 0.0;
  bool _hasDataForMonth = false;

  List<double> get dailySpends => List.unmodifiable(_dailySpends);
  Map<String, double> get payeeTotals => _hasDataForMonth ? Map.unmodifiable(_payeeTotals) : const {};
  List<double> get weekdayMobileSpends => List.unmodifiable(_weekdayMobileSpends);
  double get incomeTotal => _incomeTotal;
  double get expenseTotal => _expenseTotal;
  double get netTotal => _incomeTotal - _expenseTotal;
  bool get hasDataForMonth => _hasDataForMonth;
  double get monthSpendTotal => _hasDataForMonth ? _expenseTotal : 0.0;

  AnalyticsViewModel() {
    _listenMonth();
    _listenCategories();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  void _listenMonth() {
    _sub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final year = now.year;
    final month = monthIdx + 1;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    _sub = _db
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('at', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .listen((snap) {
      _hasDataForMonth = snap.docs.isNotEmpty;
      final days = DateTime(year, month + 1, 0).day;
      _dailySpends
        ..clear()
        ..addAll(List<double>.filled(days, 0));
      final totals = <String, double>{};
      _categoryTotals.clear();
      for (int i = 0; i < 7; i++) {
        _weekdayMobileSpends[i] = 0.0;
      }
      _incomeTotal = 0.0;
      _expenseTotal = 0.0;
      for (final d in snap.docs) {
        final data = d.data();
        final dir = (data['direction'] as String?) ?? 'debit';
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final at = data['at'];
        if (at is! Timestamp) continue;
        final dt = at.toDate();
        final dayIdx = dt.day - 1;
        final isDebit = dir == 'debit';
        final method = (data['method'] as String?) ?? '';
        final payee = (data['payeeName'] as String?) ?? (data['note'] as String? ?? 'Other');
        final catId = (data['categoryId'] as String?) ?? '';
        if (isDebit) {
          if (dayIdx >= 0 && dayIdx < _dailySpends.length) {
            _dailySpends[dayIdx] += amount;
          }
          // Weekday mobile spends (UPI) aggregation: Monday=1..Sunday=7 mapped to 0..6
          if (method == 'mobile') {
            final wd = (dt.weekday - 1).clamp(0, 6);
            _weekdayMobileSpends[wd] += amount;
          }
          totals.update(payee, (v) => v + amount, ifAbsent: () => amount);
          if (catId.isNotEmpty) {
            _categoryTotals.update(catId, (v) => v + amount, ifAbsent: () => amount);
          }
          _expenseTotal += amount;
        } else if (dir == 'credit') {
          _incomeTotal += amount;
        }
      }
      _payeeTotals = totals;
      super.notifyListeners();
    });
  }

  void _listenCategories() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _catSub?.cancel();
    _catSub = CategoriesService.instance.streamUserCategories(uid).listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  void setMonth(int idx) {
    monthIdx = idx;
    _hasDataForMonth = false;
    _dailySpends.clear();
    _payeeTotals.clear();
    _categoryTotals.clear();
    _incomeTotal = 0.0;
    _expenseTotal = 0.0;
    notifyListeners();
    _listenMonth();
  }

  void setChartMode(int mode) {
    if (mode == chartMode) return;
    chartMode = mode;
    notifyListeners();
  }

  List<AnalyticsCategory> get categories {
    if (!_hasDataForMonth) return [];
    // Compute total spend for the month
    final total = _categoryTotals.values.fold<double>(0.0, (s, v) => s + v);
    // Map icon string to Material icon fallback for known defaults
    IconData _iconFor(String iconStr, String name) {
      switch (iconStr) {
        case 'flight':
          return Icons.flight;
        case 'checkroom':
          return Icons.checkroom;
        case 'restaurant':
          return Icons.fastfood;
        case 'home':
          return Icons.home;
        default:
          // Name-based hints
          final n = name.toLowerCase();
          if (n.contains('food')) return Icons.fastfood;
          if (n.contains('travel')) return Icons.flight;
          if (n.contains('house') || n.contains('home')) return Icons.home;
          if (n.contains('fashion') || n.contains('clothes')) return Icons.checkroom;
          return Icons.category;
      }
    }

    Color _colorFromHex(String hex) {
      final v = hex.replaceAll('#', '');
      final parsed = int.tryParse(v, radix: 16) ?? 0x2563EB;
      return Color(0xFF000000 | parsed).withOpacity(0.12); // soft pastel bg
    }

    // Build list joined with category meta
    final byId = {for (final c in _categories) c.id: c};
    final items = <AnalyticsCategory>[];
    _categoryTotals.forEach((catId, amount) {
      final c = byId[catId];
      final name = c?.name ?? 'Other';
      final icon = _iconFor(c?.icon ?? 'category', name);
      final color = _colorFromHex(c?.color ?? '#2563EB');
      final pct = total <= 0 ? 0 : ((amount / total) * 100).round();
      items.add(
        AnalyticsCategory(
          label: name,
          sublabel: '',
          icon: icon,
          color: color,
          percent: pct,
          amount: amount.round(),
          summaryLabel: '',
          summaryDesc: '',
        ),
      );
    });

    // If no spend, return empty to allow UI to show "No data"

    // Sort by amount desc
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}
