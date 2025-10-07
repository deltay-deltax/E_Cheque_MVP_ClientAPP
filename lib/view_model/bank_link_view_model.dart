import 'package:flutter/material.dart';

class BankLinkViewModel extends ChangeNotifier {
  String mobileNumber = '';
  String regMobileNumber = '';
  String accHolderName = '';
  String accNumber = '';
  String ifsc = '';
  String bankName = '';
  String accType = 'Saving Account';

  void setMobileNumber(String n) {
    mobileNumber = n;
    notifyListeners();
  }

  // For the Add Account Modal
  void setRegMobileNumber(String n) {
    regMobileNumber = n;
    notifyListeners();
  }

  void setAccHolderName(String n) {
    accHolderName = n;
    notifyListeners();
  }

  void setAccNumber(String n) {
    accNumber = n;
    notifyListeners();
  }

  void setIfsc(String n) {
    ifsc = n;
    notifyListeners();
  }

  void setBankName(String n) {
    bankName = n;
    notifyListeners();
  }

  void setAccType(String? n) {
    if (n == null) return;
    accType = n;
    notifyListeners();
  }
}
