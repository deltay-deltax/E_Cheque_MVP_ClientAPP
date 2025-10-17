import 'package:flutter/material.dart';
import '../../view_model/analytics_view_model.dart';

class AnalyticsSummaryBox extends StatelessWidget {
  final AnalyticsCategory cat;
  const AnalyticsSummaryBox({required this.cat, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 7),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cat.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            "${cat.percent}%",
            style: TextStyle(
              color: cat.color == Color(0xFFEDE9FE)
                  ? Color(0xFF9C27B0)
                  : (cat.color == Color(0xFFE0E7FF)
                        ? Color(0xFF2563EB)
                        : Colors.redAccent),
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          Text(
            cat.summaryLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
