import 'package:flutter/material.dart';

class DepositSlipViewModel extends ChangeNotifier {
  String slipNo = "AUT0-12345";
  DateTime? slipDate = DateTime.now();

  String depositorName = "";
  String depositorContact = "";
  String depositorAddress = "";

  String accountHolderName = "";
  String accountNo = "";
  String accountType = "Savings";

  Map<int, int> cashBreakdown = {2000: 0, 500: 0, 200: 0, 100: 0, 1: 0};
  double get cashBreakdownTotal =>
      cashBreakdown.entries.fold(0.0, (sum, e) => sum + e.key * e.value);

  String amountInWords = "";

  final List<String> depositPurposeOptions = [
    "Own Account",
    "Third Party",
    "Loan",
    "Others",
  ];

  List<String> selectedPurposes = [];
  bool agreed = false;

  String depositorSignature = "";
  String bankStaffSignature = "";

  void setSlipDate(DateTime d) {
    slipDate = d;
    notifyListeners();
  }

  void setAccountType(String value) {
    accountType = value;
    notifyListeners();
  }

  void setField({
    String? depositorName,
    String? depositorContact,
    String? depositorAddress,
    String? accountHolderName,
    String? accountNo,
  }) {
    if (depositorName != null) this.depositorName = depositorName;
    if (depositorContact != null) this.depositorContact = depositorContact;
    if (depositorAddress != null) this.depositorAddress = depositorAddress;
    if (accountHolderName != null) this.accountHolderName = accountHolderName;
    if (accountNo != null) this.accountNo = accountNo;
    notifyListeners();
  }

  void updateCash(int denom, int count) {
    cashBreakdown[denom] = count;
    // update amount in words whenever cash changes
    amountInWords = _toIndianWords(cashBreakdownTotal);
    notifyListeners();
  }

  void agree(bool v) {
    agreed = v;
    notifyListeners();
  }

  void selectPurpose(String p) {
    if (selectedPurposes.contains(p))
      selectedPurposes.remove(p);
    else
      selectedPurposes.add(p);
    notifyListeners();
  }

  void setDepositorSignature(String s) {
    depositorSignature = s;
    notifyListeners();
  }

  void setBankStaffSignature(String s) {
    bankStaffSignature = s;
    notifyListeners();
  }

  // Converts number to words in Indian numbering system (basic implementation)
  String _toIndianWords(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    String rupeesPart = rupees == 0 ? "Zero" : _convertIntToIndianWords(rupees);
    String paisePart = paise > 0 ? " and ${_convertIntToIndianWords(paise)} Paise" : "";
    return "$rupeesPart Rupees$paisePart only";
  }

  static const List<String> _ones = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
    "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
  ];
  static const List<String> _tens = [
    "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
  ];

  String _twoDigitsToWords(int n) {
    if (n < 20) return _ones[n];
    final ten = n ~/ 10;
    final one = n % 10;
    return _tens[ten] + (one != 0 ? " ${_ones[one]}" : "");
  }

  String _convertIntToIndianWords(int n) {
    if (n == 0) return "Zero";
    String result = "";

    int crore = n ~/ 10000000; n %= 10000000;
    int lakh = n ~/ 100000; n %= 100000;
    int thousand = n ~/ 1000; n %= 1000;
    int hundred = n ~/ 100; n %= 100;
    int rest = n;

    if (crore > 0) result += "${_convertIntToIndianWords(crore)} Crore";
    if (lakh > 0) result += (result.isEmpty ? "" : " ") + "${_convertIntToIndianWords(lakh)} Lakh";
    if (thousand > 0) result += (result.isEmpty ? "" : " ") + "${_convertIntToIndianWords(thousand)} Thousand";
    if (hundred > 0) result += (result.isEmpty ? "" : " ") + "${_ones[hundred]} Hundred";
    if (rest > 0) {
      if (result.isNotEmpty) result += " and ";
      result += _twoDigitsToWords(rest);
    }
    return result;
  }

  void reset() {
    slipNo = "AUT0-12345";
    slipDate = DateTime.now();
    depositorName = "";
    depositorContact = "";
    depositorAddress = "";
    accountHolderName = "";
    accountNo = "";
    accountType = "Savings";
    cashBreakdown = {2000: 0, 500: 0, 200: 0, 100: 0, 1: 0};
    amountInWords = _toIndianWords(cashBreakdownTotal);
    selectedPurposes = [];
    agreed = false;
    notifyListeners();
  }
}
