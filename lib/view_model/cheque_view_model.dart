import 'package:flutter/material.dart';

class ChequeViewModel extends ChangeNotifier {
  String payee = '';
  String amount = '';
  DateTime? date;
  String bankName = '';
  String notes = '';
  String signaturePath = '';

  void setPayee(String value) {
    payee = value;
    notifyListeners();
  }

  void setAmount(String value) {
    amount = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  void setBankName(String value) {
    bankName = value;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  void setSignaturePath(String path) {
    signaturePath = path;
    notifyListeners();
  }

  Future<void> submitCheque() async {
    // Implement E-Cheque upload and validation logic here
  }
}
