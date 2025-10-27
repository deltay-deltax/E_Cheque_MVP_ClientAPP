import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  String userName = "Aaditya Gupta";
  String totalBalance = "₹2,045,628.80";
  String mainCardRate = "+2.5%";
  String mainAccountNumber = "**** **** **** 4589";
  String mainAccountValidThru = "12/28";
  String availableToSpend = "Available to spend";
  String mainCardSubtitle = "Total Balance";

  bool showBalance = false;
  void toggleShowBalance() {
    showBalance = !showBalance;
    notifyListeners();
  }

  List<QuickAction> quickActions = [
    // Row 1
    QuickAction(
      "E-Cheque",
      Icons.receipt_long,
      Color(0xFFEFF3FF),
      Color(0xFF2563EB),
    ),
    QuickAction(
      "E-cheque History",
      Icons.call_received,
      Color(0xFFE6FFF4),
      Color(0xFF10B981),
    ),
    QuickAction(
      "Received Cheque",
      Icons.assignment_turned_in,
      Color(0xFFFFF7E6),
      Color(0xFFF59E0B),
    ),
    QuickAction(
      "Stop Cheque",
      Icons.remove_circle,
      Color(0xFFFFE7E5),
      Color(0xFFEF4444),
    ),

    //Row 2
    QuickAction(
      "Deposit",
      Icons.account_balance_wallet,
      Color(0xFFFFF7E6),
      Color(0xFFF59E0B),
    ),
    QuickAction("Receipt", Icons.receipt, Color(0xFFEFF3FF), Color(0xFF2563EB)),

    // Row 3
    QuickAction("Send Money", Icons.send, Color(0xFFE6FFF4), Color(0xFF10B981)),
    QuickAction(
      "Auto Forms",
      Icons.article,
      Color(0xFFF3ECFF),
      Color(0xFF7C3AED),
    ),
    QuickAction("More", Icons.more_horiz, Color(0xFFEEEEEE), Color(0xFF757575)),
  ];

  List<SummaryCard> summaryCards = [
    SummaryCard(
      "Income",
      "₹4,37,125",
      Icons.arrow_upward,
      Color(0xFF10B981),
      "+15%",
    ),
    SummaryCard(
      "Expenses",
      "₹1,77,390",
      Icons.arrow_downward,
      Colors.red,
      "−5%",
    ),
    SummaryCard(
      "Savings",
      "₹0.00",
      Icons.savings_outlined,
      Color(0xFF10B981),
      "",
    ),
    SummaryCard(
      "Investments",
      "₹0.00",
      Icons.trending_up,
      Color(0xFF10B981),
      "",
    ),
  ];

  List<TransactionCardData> transactions = [
    TransactionCardData(
      "Groceries",
      "Shopping",
      "10:45 AM",
      "-₹6,286.50",
      "Expense",
      Icons.shopping_cart,
      Colors.red,
    ),
    TransactionCardData(
      "Salary",
      "Freelance",
      "09:30 AM",
      "₹1,00,000.00",
      "Income",
      Icons.work_outline,
      Color(0xFF10B981),
    ),
    TransactionCardData(
      "Cinema",
      "Entertainment",
      "Yesterday",
      "-₹2,500.00",
      "Expense",
      Icons.movie_outlined,
      Colors.red,
    ),
  ];
}

class QuickAction {
  final String text;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  QuickAction(this.text, this.icon, this.bgColor, this.iconColor);
}

class SummaryCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String percent;
  SummaryCard(this.label, this.value, this.icon, this.color, this.percent);
}

class TransactionCardData {
  final String label;
  final String category;
  final String time;
  final String value;
  final String type;
  final IconData icon;
  final Color color;
  TransactionCardData(
    this.label,
    this.category,
    this.time,
    this.value,
    this.type,
    this.icon,
    this.color,
  );
}
