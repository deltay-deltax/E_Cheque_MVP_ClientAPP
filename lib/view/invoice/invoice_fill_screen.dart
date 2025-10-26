import 'package:echeque_mvp/view/widgets/invoice_input_field.dart';
import 'package:echeque_mvp/services/invoice_service.dart';
import 'package:echeque_mvp/view/invoice/invoice_pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/invoice_view_model.dart';

class NewInvoiceScreen extends StatelessWidget {
  const NewInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceViewModel(),
      child: Consumer<InvoiceViewModel>(
        builder: (context, vm, _) {
          final invoiceDateController = TextEditingController(
            text: vm.invoiceDate == null
                ? "Select Date"
                : "${vm.invoiceDate?.toLocal()?.toString().split(' ')[0]}",
          );
          return Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            appBar: AppBar(
              backgroundColor: Color(0xFFF7F9FC),
              elevation: 0,
              centerTitle: true,
              title: Text(
                "New Invoice",
                style: TextStyle(
                  color: Color(0xFF2272E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
              leading: BackButton(color: Colors.black),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InvoiceListScreen(),
                      ),
                    );
                  },
                  child: const Text('View Invoices'),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Invoice No. & Date
                Row(
                  children: [
                    Expanded(
                      child: InvoiceInputField(
                        hint: "",
                        controller: TextEditingController(text: vm.invoiceNo),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InvoiceInputField(
                        hint: "Select Date",
                        controller: invoiceDateController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2010),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) vm.setInvoiceDate(picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Bill To
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bill To",
                        style: TextStyle(
                          color: Color(0xFF2272E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InvoiceInputField(
                        hint: "Client Name",
                        initialValue: vm.clientName,
                        onChanged: (v) => vm.setField(name: v),
                      ),
                      const SizedBox(height: 10),
                      InvoiceInputField(
                        hint: "Email Address",
                        initialValue: vm.clientEmail,
                        type: TextInputType.emailAddress,
                        onChanged: (v) => vm.setField(email: v),
                      ),
                      const SizedBox(height: 10),
                      InvoiceInputField(
                        hint: "Phone Number",
                        initialValue: vm.clientPhone,
                        type: TextInputType.phone,
                        onChanged: (v) => vm.setField(phone: v),
                      ),
                      const SizedBox(height: 10),
                      InvoiceInputField(
                        hint: "Address",
                        initialValue: vm.clientAddress,
                        maxLines: 2,
                        onChanged: (v) => vm.setField(address: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Items
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Items",
                        style: TextStyle(
                          color: Color(0xFF2272E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      ...vm.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InvoiceInputField(
                                hint: "Item Description",
                                initialValue: item.description,
                                onChanged: (v) => vm.updateItem(i, desc: v),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: InvoiceInputField(
                                      hint: "1",
                                      initialValue: "${item.qty}",
                                      type: TextInputType.number,
                                      onChanged: (v) => vm.updateItem(i, qty: int.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: InvoiceInputField(
                                      hint: "0.00",
                                      initialValue: "${item.price}",
                                      type: TextInputType.number,
                                      onChanged: (v) => vm.updateItem(i, price: double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      "₹${(item.qty * item.price).toStringAsFixed(2)}",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      // Add Item
                      GestureDetector(
                        onTap: vm.addItem,
                        child: Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFE5F0FF),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: Color(0xFF2272E5)),
                              SizedBox(width: 6),
                              Text(
                                "Add Item",
                                style: TextStyle(
                                  color: Color(0xFF2272E5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Totals
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Subtotal",
                            style: TextStyle(
                              color: Color(0xFF9098A4),
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            "₹${vm.subtotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Color(0xFF9098A4),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tax (8%)",
                            style: TextStyle(
                              color: Color(0xFF9098A4),
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            "₹${vm.tax.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Color(0xFF9098A4),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                          Text(
                            "₹${vm.total.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Notes
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notes", style: TextStyle(color: Color(0xFF9098A4))),
                      InvoiceInputField(
                        hint: "Add any notes for the client...",
                        initialValue: vm.notes,
                        maxLines: 3,
                        onChanged: (v) => vm.setField(notes: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final data = {
                        'invoiceNo': vm.invoiceNo,
                        'invoiceDate': vm.invoiceDate?.toIso8601String() ?? '',
                        'clientName': vm.clientName,
                        'clientEmail': vm.clientEmail,
                        'clientPhone': vm.clientPhone,
                        'clientAddress': vm.clientAddress,
                        'items': vm.items
                            .map(
                              (e) => {
                                'description': e.description,
                                'qty': e.qty,
                                'price': e.price,
                              },
                            )
                            .toList(),
                        'subtotal': vm.subtotal,
                        'tax': vm.tax,
                        'total': vm.total,
                        'notes': vm.notes,
                      };
                      await InvoiceService.instance.createInvoice(data);
                      vm.reset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice created successfully')),
                        );
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const InvoiceListScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2272E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Create & Download Invoice",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: InvoiceService.instance.streamUserInvoices(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No invoices'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = items[i];
              final title = (d['invoiceNo'] ?? '') as String;
              final total = ((d['total'] as num?) ?? 0).toDouble();
              return ListTile(
                title: Text(title.isEmpty ? 'Invoice ${d['id']}' : title),
                subtitle: Text('₹${total.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvoicePdfPreviewScreen(data: d)),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    final bytes = await InvoicePdf.build(d);
                    await Printing.sharePdf(bytes: bytes, filename: '${title.isEmpty ? d['id'] : title}.pdf');
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

class InvoicePdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const InvoicePdfPreviewScreen({super.key, required this.data});
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
