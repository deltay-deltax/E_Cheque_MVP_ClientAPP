import 'package:flutter/material.dart';

class QuickActionItem {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  QuickActionItem(this.title, this.icon, this.bgColor, this.iconColor);
}

class QuickActionsViewModel extends ChangeNotifier {
  List<QuickActionItem> get actions => [
    QuickActionItem(
      "Invoice ",
      Icons.description,
      Color(0xFFE6FFF4),
      Color(0xFF10B981),
    ),
    QuickActionItem(
      "Portfolio",
      Icons.show_chart,
      Color(0xFFE6FFF4),
      Color(0xFF10B981),
    ),

    QuickActionItem(
      "Confirmation",
      Icons.verified_outlined,
      Color(0xFFFFF7E6),
      Color(0xFFF59E0B),
    ),

    QuickActionItem(
      "E learning",
      Icons.school_outlined,
      Color(0xFFF3ECFF),
      Color(0xFF7C3AED),
    ),
    QuickActionItem(
      "Passbook",
      Icons.menu_book_outlined,
      Color(0xFFE8F0FF),
      Color(0xFF2563EB),
    ),
    QuickActionItem(
      "Recharge",
      Icons.phone_iphone,
      Color(0xFFF3ECFF),
      Color(0xFF9333EA),
    ),
    QuickActionItem(
      "Water",
      Icons.water_drop,
      Color(0xFFE0FBFF),
      Color(0xFF06B6D4),
    ),
    QuickActionItem(
      "Electricity",
      Icons.flash_on,
      Color(0xFFFFF7E6),
      Color(0xFFFBBF24),
    ),
    QuickActionItem(
      "Credit Card",
      Icons.credit_card,
      Color(0xFFFCE7F3),
      Color(0xFFEC4899),
    ),
    QuickActionItem(
      "Pay Loan",
      Icons.account_balance,
      Color(0xFFE6FFF4),
      Color(0xFF10B981),
    ),
    QuickActionItem(
      "Scan & Pay",
      Icons.qr_code_2,
      Color(0xFFFFF4E6),
      Color(0xFFF59E42),
    ),
    QuickActionItem(
      "Savings",
      Icons.savings,
      Color(0xFFF0FDF4),
      Color(0xFF22C55E),
    ),

    // Added bank-related forms and utilities
    QuickActionItem(
      "Change Mail",
      Icons.alternate_email,
      Color(0xFFFCE7F3),
      Color(0xFFDB2777),
    ),
    QuickActionItem(
      "Change No.",
      Icons.phone_android_outlined,
      Color(0xFFE0FBFF),
      Color(0xFF06B6D4),
    ),

    QuickActionItem(
      "Stable Coins",
      Icons.currency_bitcoin,
      Color(0xFFE8EAF6),
      Color(0xFF3F51B5),
    ),
    QuickActionItem(
      "Forex",
      Icons.currency_exchange,
      Color(0xFFE8EAF6),
      Color(0xFF3F51B5),
    ),
    QuickActionItem(
      "Other Forms",
      Icons.description_outlined,
      Color(0xFFE8EAF6),
      Color(0xFF3F51B5),
    ),
  ];
}
