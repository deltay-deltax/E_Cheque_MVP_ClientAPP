import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewChequeViewModel extends ChangeNotifier {
  Future<void> shareCheque(BuildContext ctx, Map<String, dynamic> d, {GlobalKey? captureKey}) async {
    try {
      // If a capture key is provided, try to snapshot the on-screen cheque widget
      if (captureKey != null && captureKey.currentContext != null) {
        final boundary = captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          final pngBytes = byteData?.buffer.asUint8List();
          if (pngBytes != null) {
            final pdf = pw.Document();
            final imageProvider = pw.MemoryImage(pngBytes);
            pdf.addPage(
              pw.Page(
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
                    ),
                  );
                },
              ),
            );

            final chequeNo = (d['chequeNo'] ?? '').toString();
            final bytes = await pdf.save();
            await Printing.sharePdf(bytes: bytes, filename: 'cheque_${chequeNo.isNotEmpty ? chequeNo : 'export'}.pdf');
            return;
          }
        }
      }

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
