import 'package:flutter/material.dart';

enum ChequeStatus { cleared, pending, bounced, rejected }

class ChequeModel {
  final String name;
  final String subText;
  final double amount;
  final ChequeStatus status;
  final String dateText;
  final String? time;
  final String? avatarUrl; // Could be null for org/company
  final String id;
  final String? chequeNo;
  final String? extraDesc;

  ChequeModel({
    required this.name,
    required this.subText,
    required this.amount,
    required this.status,
    required this.dateText,
    this.time,
    required this.id,
    this.avatarUrl,
    this.chequeNo,
    this.extraDesc,
  });
}

class ChequeHistoryViewModel extends ChangeNotifier {
  List<ChequeModel> receivedCheques = [
    ChequeModel(
      name: "John Mitchell",
      subText: "Business Partner",
      amount: 25000,
      status: ChequeStatus.cleared,
      dateText: "Dec 15, 2024 · 2:30 PM",
      id: "rc1",
      avatarUrl: null,
    ),
    ChequeModel(
      name: "Sarah Williams",
      subText: "Client Payment",
      amount: 18500,
      status: ChequeStatus.pending,
      dateText: "Dec 14, 2024 · 4:15 PM",
      id: "rc2",
    ),
    ChequeModel(
      name: "Michael Chen",
      subText: "Vendor Payment",
      amount: 12750,
      status: ChequeStatus.bounced,
      dateText: "Dec 13, 2024 · 11:20 AM",
      id: "rc3",
    ),
    ChequeModel(
      name: "Emma Rodriguez",
      subText: "Service Fee",
      amount: 8200,
      status: ChequeStatus.cleared,
      dateText: "Dec 12, 2024 · 9:45 AM",
      id: "rc4",
    ),
    ChequeModel(
      name: "David Thompson",
      subText: "Contract Payment",
      amount: 35000,
      status: ChequeStatus.pending,
      dateText: "Dec 11, 2024 · 11:10 AM",
      id: "rc5",
    ),
  ];

  List<ChequeModel> allCheques = [
    ChequeModel(
      name: "TechCorp Solutions",
      subText: "Invoice Payment",
      amount: 12450,
      status: ChequeStatus.cleared,
      dateText: "Dec 15, 2024",
      time: "2:30 PM",
      id: "c1",
      chequeNo: "001234",
    ),
    ChequeModel(
      name: "Global Industries",
      subText: "Service Payment",
      amount: 8750,
      status: ChequeStatus.pending,
      dateText: "Processing...",
      id: "c2",
      chequeNo: "001235",
    ),
    ChequeModel(
      name: "Metro Services",
      subText: "Contract Payment",
      amount: 5200,
      status: ChequeStatus.rejected,
      dateText: "Insufficient funds",
      id: "c3",
      chequeNo: "001236",
      extraDesc: "Yesterday",
    ),
    ChequeModel(
      name: "ABC Manufacturing",
      subText: "Product Payment",
      amount: 15800,
      status: ChequeStatus.cleared,
      dateText: "Dec 14, 2024",
      id: "c4",
      chequeNo: "001237",
    ),
    ChequeModel(
      name: "Digital Solutions Ltd",
      subText: "Consulting Fee",
      amount: 22300,
      status: ChequeStatus.pending,
      dateText: "Processing...",
      id: "c5",
      chequeNo: "001238",
    ),
  ];

  int get clearedTotal => 51000;
  int get pendingTotal => 31050;
  int get rejectedTotal => 5200;

  bool showOnlyPending = false;

  void setFilter(bool pending) {
    showOnlyPending = pending;
    notifyListeners();
  }

  List<ChequeModel> get filteredCheques => showOnlyPending
      ? allCheques.where((c) => c.status == ChequeStatus.pending).toList()
      : allCheques;
}
