import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReceiptPdf {
  static Future<Uint8List> build(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final isVerified = (data['status']?.toString() == 'cashed_out') || (data['verifiedAt'] != null);

    String _kv(String k, String v) => '$k: $v';

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (ctx) => [
          pw.Text('Receipt', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(6)),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_kv('Created', (data['createdAt'] as String?) ?? '-')),
                if (data['serverTime'] != null) pw.Text('Server time recorded'),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Account Information', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(_kv('Account Holder', (data['accountHolderName'] as String?) ?? '')),
          pw.Text(_kv('Account No.', (data['accountNo'] as String?) ?? '')),
          pw.Text(_kv('Account Type', (data['accountType'] as String?) ?? '')),
          pw.SizedBox(height: 12),
          pw.Text('Amount', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('INR ${(data['amount'] ?? 0).toString()} ', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
          if ((data['amountInWords'] as String? ?? '').isNotEmpty) pw.Text('In Words  ${data['amountInWords']}'),
          pw.SizedBox(height: 20),
          pw.Text('Signatures', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Issuer Signature: ___________________________'),
        ],
        footer: (ctx) => isVerified
            ? pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Verified', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
              )
            : pw.SizedBox(),
      ),
    );

    return doc.save();
  }
}
