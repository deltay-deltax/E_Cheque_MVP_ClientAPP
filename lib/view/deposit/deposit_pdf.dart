import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class DepositPdf {
  static Future<Uint8List> build(Map<String, dynamic> data, {bool bankCopy = false}) async {
    final doc = pw.Document();

    final denom = (data['cashBreakdown'] as Map<String, dynamic>? ?? {});
    final entries = denom.entries
        .map((e) => MapEntry<int, int>(int.tryParse(e.key.toString()) ?? 0, (e.value as num?)?.toInt() ?? 0))
        .where((e) => e.key > 0)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    pw.Widget _sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(t, style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
        );

    pw.Widget _kv(String k, String v) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(k), pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
        );

    final isVerified = (data['status']?.toString() == 'Verified') || (data['verifiedAt'] != null);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (ctx) => [
          pw.Text('Cash Deposit Slip', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(6)),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Receipt No.: ${data['slipNo'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${data['slipDate'] ?? ''}')
            ]),
          ),
          if (bankCopy) ...[
            _sectionTitle('Bank Internal Details'),
            _kv('Transaction ID', data['transactionId'] ?? '-'),
            _kv('Teller ID', data['tellerId'] ?? '-'),
          ],
          _sectionTitle('Bank & Depositor Details'),
          _kv('Depositor', data['depositorName'] ?? ''),
          _kv('Address', data['depositorAddress'] ?? ''),
          _kv('Contact', data['depositorContact'] ?? ''),
          if (data['pan'] != null && (data['pan'] as String).isNotEmpty) _kv('PAN', data['pan']),
          _sectionTitle('Account Holder Details'),
          _kv('Name', data['accountHolderName'] ?? ''),
          _kv('Account No.', data['accountNo'] ?? ''),
          _kv('Account Type', data['accountType'] ?? ''),
          _sectionTitle('Deposit Amount'),
          pw.Text('Amount  INR ${(data['depositAmount'] ?? '0')} ', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
          if ((data['amountInWords'] as String? ?? '').isNotEmpty) pw.Text('In Words  ${data['amountInWords']}'),
          _sectionTitle('Cash Breakdown'),
          pw.Table(
            border: pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
            columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(3)},
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Denomination', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              ...entries.map((e) {
                final amt = e.key * e.value;
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${e.key}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.value}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${amt.toStringAsFixed(2)}')),
                ]);
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 6),
          _kv('Total', 'INR ${data['cashBreakdownTotal'] ?? '0.00'}'),
          _sectionTitle('Purpose'),
          pw.Text((data['selectedPurposes'] as List<dynamic>? ?? []).join(', ')),
          if (bankCopy) ...[
            _sectionTitle('Bank Authorization'),
            pw.Text('Bank Stamp: ____________'),
            pw.SizedBox(height: 6),
            pw.Text('Authorised Signatory: ____________'),
          ] else ...[
            _sectionTitle('Signatures'),
            pw.Text('Depositor Signature: ____________'),
            pw.SizedBox(height: 6),
            pw.Text('Authorised Signatory: ____________'),
          ],
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
