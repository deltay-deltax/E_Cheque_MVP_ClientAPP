import 'package:flutter/material.dart';
import '../../view_model/transactions_view_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionItem tx;

  const TransactionCard({required this.tx, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.018)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: tx.bgColor,
            child: Icon(
              tx.icon,
              color: tx.incoming ? Color(0xFF10B981) : Color(0xFFF87171),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF16202C),
                  ),
                ),
                Text(
                  tx.subtitle,
                  style: TextStyle(color: Color(0xFF818181), fontSize: 13),
                ),
                Row(
                  children: [
                    Text(
                      tx.date,
                      style: TextStyle(color: Color(0xFF818181), fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF58D985).withOpacity(.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.status,
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (tx.incoming ? "+₹" : "-₹") + tx.amount.toStringAsFixed(2),
                style: TextStyle(
                  color: tx.incoming ? Color(0xFF22C55E) : Color(0xFFF87171),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: tx.incoming
                      ? Color(0xFF22C55E).withOpacity(.08)
                      : Color(0xFFF87171).withOpacity(.13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.incoming ? "Income" : "Expense",
                  style: TextStyle(
                    color: tx.incoming ? Color(0xFF22C55E) : Color(0xFFF87171),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
