import 'package:flutter/material.dart';

class ExpenseInvoiceBox extends StatelessWidget {
  final VoidCallback onAddInvoice;

  const ExpenseInvoiceBox({required this.onAddInvoice, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAddInvoice,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Color(0xFFD1D5DB),
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Color(0xFFF8FAFC),
        ),
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 30),
            SizedBox(width: 8),
            Text(
              "Add Invoice",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
