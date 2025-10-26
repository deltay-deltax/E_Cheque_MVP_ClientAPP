import 'package:flutter/material.dart';

class InvoiceItem {
  String description;
  int qty;
  double price;
  InvoiceItem({required this.description, this.qty = 1, this.price = 0});
}

class InvoiceViewModel extends ChangeNotifier {
  String invoiceNo = "INV-2024-001";
  DateTime? invoiceDate = DateTime.now();
  String clientName = "";
  String clientEmail = "";
  String clientPhone = "";
  String clientAddress = "";
  List<InvoiceItem> items = [InvoiceItem(description: "", qty: 1, price: 0)];
  String notes = "";

  double get subtotal =>
      items.fold(0.0, (prev, item) => prev + (item.qty * item.price));
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  void setInvoiceDate(DateTime d) {
    invoiceDate = d;
    notifyListeners();
  }

  void setField({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? notes,
  }) {
    if (name != null) clientName = name;
    if (email != null) clientEmail = email;
    if (phone != null) clientPhone = phone;
    if (address != null) clientAddress = address;
    if (notes != null) this.notes = notes;
    notifyListeners();
  }

  void updateItem(int i, {String? desc, int? qty, double? price}) {
    if (desc != null) items[i].description = desc;
    if (qty != null) items[i].qty = qty;
    if (price != null) items[i].price = price;
    notifyListeners();
  }

  void addItem() {
    items.add(InvoiceItem(description: "", qty: 1, price: 0));
    notifyListeners();
  }

  void reset() {
    invoiceNo = "INV-2024-001";
    invoiceDate = DateTime.now();
    clientName = "";
    clientEmail = "";
    clientPhone = "";
    clientAddress = "";
    items = [InvoiceItem(description: "", qty: 1, price: 0)];
    notes = "";
    notifyListeners();
  }
}
