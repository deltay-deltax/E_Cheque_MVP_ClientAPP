import 'package:flutter/material.dart';
import '../../view_model/analytics_view_model.dart';

class AnalyticsCategoryCard extends StatelessWidget {
  final AnalyticsCategory cat;
  const AnalyticsCategoryCard({required this.cat, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cat.color,
            child: Icon(
              cat.icon,
              color: Colors.black.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cat.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '-₹${cat.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.red[400],
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
