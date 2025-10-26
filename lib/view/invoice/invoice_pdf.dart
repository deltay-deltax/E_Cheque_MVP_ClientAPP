import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class InvoicePdf {
  static Future<Uint8List> build(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final items = (data['items'] as List<dynamic>? ?? []);
    final subtotal = (data['subtotal'] as num? ?? 0).toDouble();
    final tax = (data['tax'] as num? ?? 0).toDouble();
    final total = (data['total'] as num? ?? 0).toDouble();

    pw.Widget _kv(String k, String v) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(k), pw.Text(v)],
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (ctx) => [
          pw.Text('Invoice', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Invoice No: ${data['invoiceNo'] ?? ''}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${data['invoiceDate'] ?? ''}', style: const pw.TextStyle(fontSize: 12)),
              ]),
            ]),
          ),
          pw.SizedBox(height: 12),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Client Details', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('${data['clientName'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${data['clientAddress'] ?? ''}'),
                pw.Text('${data['clientEmail'] ?? ''}'),
                pw.Text('${data['clientPhone'] ?? ''}'),
              ]),
            ),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Invoice Items', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300)),
            columnWidths: {
              0: const pw.FlexColumnWidth(6),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              ...items.map<pw.TableRow>((it) {
                final q = (it['qty'] as num? ?? 0).toInt();
                final p = (it['price'] as num? ?? 0).toDouble();
                final amt = q * p;
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${it['description'] ?? ''}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$q')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${p.toStringAsFixed(2)}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${amt.toStringAsFixed(2)}')),
                ]);
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          _kv('Subtotal', 'INR ${subtotal.toStringAsFixed(2)}'),
          _kv('GST', 'INR ${tax.toStringAsFixed(2)}'),
          pw.Text('Total  INR ${total.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
          if ((data['notes'] as String? ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Notes', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
            pw.Text('${data['notes']}'),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
