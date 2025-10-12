import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewChequeViewModel extends ChangeNotifier {
  Future<void> shareCheque(BuildContext ctx, Map<String, dynamic> d) async {
    try {
      final bankName = (d['bankName'] ?? '').toString();
      final chequeNo = (d['chequeNo'] ?? '').toString();
      final date = (d['date'] ?? '').toString();
      final payee = (d['payee'] ?? '').toString();
      final amount = d['amount'];
      final amountNum = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;
      final amountNumber = "₹${amountNum.toStringAsFixed(2)}";
      final notes = (d['notes'] ?? '').toString();

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Digital Cheque', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Text('Bank: $bankName'),
                  pw.Text('Cheque No: $chequeNo'),
                  pw.Text('Date: $date'),
                  pw.SizedBox(height: 10),
                  pw.Text('Payee: $payee'),
                  pw.Text('Amount: $amountNumber'),
                  pw.SizedBox(height: 10),
                  pw.Text('Notes: $notes'),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'cheque_${chequeNo.isNotEmpty ? chequeNo : 'export'}.pdf');
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Failed to share cheque: $e')),
      );
    }
  }
}
