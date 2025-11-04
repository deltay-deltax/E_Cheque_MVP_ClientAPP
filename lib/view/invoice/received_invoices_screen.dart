import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/receipt_service.dart';
import 'invoice_pdf.dart';

class ReceivedInvoicesScreen extends StatelessWidget {
  const ReceivedInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received Invoices')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ReceiptService.instance.streamUserReceivedInvoices(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No received invoices'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = items[i];
              final amt = ((d['total'] as num?) ?? (d['amount'] as num? ?? 0)).toDouble();
              final sender = ((d['fromName'] as String?) ?? (d['clientName'] as String?) ?? 'Sender').trim();
              final title = 'From $sender';
              return ListTile(
                title: Text(title),
                subtitle: Text('₹${amt.toStringAsFixed(2)}'),
                onTap: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PdfPreviewWrapper(data: d),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    final bytes = await InvoicePdf.build(d);
                    final name = ((d['fromName'] as String?) ?? (d['clientName'] as String?) ?? '').trim();
                    final file = name.isEmpty ? 'Received invoice.pdf' : 'Received from $name.pdf';
                    await Printing.sharePdf(bytes: bytes, filename: file);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PdfPreviewWrapper extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PdfPreviewWrapper({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Preview')),
      body: PdfPreview(
        build: (format) => InvoicePdf.build(data),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
