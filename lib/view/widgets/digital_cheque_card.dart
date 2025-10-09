import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DigitalChequeCard extends StatelessWidget {
  final String bankName,
      bankAddress,
      chequeNo,
      date,
      payee,
      amountNumber,
      amountWords,
      memo,
      signatureName,
      microText;

  const DigitalChequeCard({
    super.key,
    required this.bankName,
    required this.bankAddress,
    required this.chequeNo,
    required this.date,
    required this.payee,
    required this.amountNumber,
    required this.amountWords,
    required this.memo,
    required this.signatureName,
    required this.microText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(blurRadius: 16, color: Colors.black12.withOpacity(0.035)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      bankAddress,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "CHEQUE NO.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  Text(
                    chequeNo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "DATE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pay to the order of",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedText,
                      ),
                    ),
                    Text(
                      payee,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "AMOUNT",
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      amountNumber,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              amountWords,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.mutedText,
              ),
            ),
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Memo",
                    style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                  ),
                  Text(
                    memo,
                    style: TextStyle(color: AppColors.darkText, fontSize: 15),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Signature",
                    style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                  ),
                  Text(
                    signatureName,
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontStyle: FontStyle.italic,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            microText,
            style: TextStyle(letterSpacing: 1.6, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
