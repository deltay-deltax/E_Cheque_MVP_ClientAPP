import 'package:flutter/material.dart';

class ViewChequeViewModel extends ChangeNotifier {
  final String bankName = "Bank of Bharat";
  final String bankAddress = "123 Banking St, Capital City";
  final String chequeNo = "1234567890";
  final String date = "07/26/2024";
  final String payee = "Aaditya Gupta";
  final String amountNumber = "\$1,234.56";
  final String amountWords =
      "Rupees One thousand two hundred thirty-four & 56/100";
  final String memo = "";
  final String signatureName = "A. Gupta";
  final String microText = "*123456789*: 1234567890 | 0123";

  void shareCheque(BuildContext ctx) {
    // Implement share intent or copy link logic here
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text("Cheque shared!")));
  }
}
