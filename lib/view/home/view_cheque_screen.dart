import 'package:echeque_mvp/view/widgets/digital_cheque_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/view_cheque_view_model.dart';
import '../../services/cheque_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cheque_history_screen.dart';

class ViewChequeScreen extends StatelessWidget {
  final String chequeId;
  final String? issuerUid;
  const ViewChequeScreen({required this.chequeId, this.issuerUid, super.key});

  @override
  Widget build(BuildContext context) {
    final boundaryKey = GlobalKey();
    return ChangeNotifierProvider(
      create: (_) => ViewChequeViewModel(),
      child: Consumer<ViewChequeViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.grey100,
          appBar: AppBar(
            title: const Text(
              "Cheque",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: BackButton(color: Colors.black),
          ),
          body: FutureBuilder<Map<String, dynamic>?>(
            future: (() async {
              // 1) Try issuer's collection first if provided
              Map<String, dynamic>? d;
              if (issuerUid != null && issuerUid!.isNotEmpty) {
                try {
                  d = await ChequeService.instance.getChequeById(
                    chequeId,
                    uid: issuerUid,
                  );
                } catch (_) {
                  d = null;
                }
              }
              // 2) Then try current user's inbox mirror (receiver side)
              if (d == null) {
                try {
                  d = await ChequeService.instance.getInboxChequeById(chequeId);
                } catch (_) {
                  d = null;
                }
              }
              // 3) Fallback to current user's own collection (issuer side when opening self)
              d ??= await ChequeService.instance.getChequeById(chequeId);
              return d;
            })(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final d = snap.data;
              if (d == null) {
                return const Center(child: Text('Cheque not found'));
              }
              final dateText = _formatDate(d['date']);
              final amount = (d['amount'] is num)
                  ? (d['amount'] as num).toDouble()
                  : double.tryParse('${d['amount']}') ?? 0.0;
              final amountNumber = _formatAmount(amount);
              final amountWords = _amountInWordsIndian(amount);
              final shareData = {...d, 'date': dateText};
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                children: [
                  RepaintBoundary(
                    key: boundaryKey,
                    child: DigitalChequeCard(
                      bankName: d['bankName'] ?? '',
                      bankAddress: '',
                      chequeNo: d['chequeNo'] ?? '',
                      date: dateText,
                      payee: d['payee'] ?? '',
                      amountNumber: amountNumber,
                      amountWords: amountWords,
                      memo: d['notes'] ?? '',
                      signatureName: (d['signaturePath'] ?? '') as String,
                      microText: '*MICR*: ${d['chequeNo'] ?? ''}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "How to use this digital cheque",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  _ChequeStep(
                    step: 1,
                    title: "Share this cheque",
                    desc:
                        "Securely share this digital cheque with the recipient via email or a messaging app. They will receive a unique and secure link.",
                  ),
                  _ChequeStep(
                    step: 2,
                    title: "Recipient deposits the cheque",
                    desc:
                        "The recipient opens the link and follows the instructions to deposit the cheque into their bank account using their banking app’s mobile deposit feature.",
                  ),
                  _ChequeStep(
                    step: 3,
                    title: "Funds are transferred",
                    desc:
                        "Once the cheque is successfully deposited and cleared, the funds will be transferred from your account to the recipient’s account.",
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () => vm.shareCheque(
                        context,
                        shareData,
                        captureKey: boundaryKey,
                      ),
                      child: const Text(
                        "Share Cheque",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChequeStep extends StatelessWidget {
  final int step;
  final String title, desc;
  const _ChequeStep({
    required this.step,
    required this.title,
    required this.desc,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blueBackground,
            child: Text(
              step.toString(),
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 15, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(dynamic dateField) {
  try {
    if (dateField is Timestamp) {
      final d = dateField.toDate();
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
    if (dateField is DateTime) {
      final d = dateField;
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
    if (dateField is String) return dateField;
  } catch (_) {}
  return '';
}

String _formatAmount(double amount) {
  return "₹${amount.toStringAsFixed(2)}";
}

String _amountInWordsIndian(double amount) {
  // Supports up to crores with paise; rounds to 2 decimals for paise
  final rupees = amount.floor();
  final paise = ((amount - rupees) * 100).round();

  final ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  final tensNames = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String twoDigitWord(int n) {
    if (n == 0) return '';
    if (n < 20) return ones[n];
    final t = n ~/ 10;
    final o = n % 10;
    return o == 0 ? tensNames[t] : '${tensNames[t]} ${ones[o]}';
  }

  String threeDigitWord(int n) {
    final h = n ~/ 100;
    final rest = n % 100;
    final hPart = h > 0 ? '${ones[h]} Hundred' : '';
    final restPart = twoDigitWord(rest);
    if (hPart.isNotEmpty && restPart.isNotEmpty) return '$hPart ${restPart}';
    return hPart.isNotEmpty ? hPart : restPart;
  }

  if (rupees == 0 && paise == 0) {
    return 'Rupees Zero only';
  }

  int n = rupees;
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  final hundred = n; // up to 999

  final parts = <String>[];
  if (crore > 0) parts.add('${threeDigitWord(crore)} Crore');
  if (lakh > 0) parts.add('${threeDigitWord(lakh)} Lakh');
  if (thousand > 0) parts.add('${threeDigitWord(thousand)} Thousand');
  if (hundred > 0) parts.add(threeDigitWord(hundred));

  final rupeesWords = parts.join(' ').trim();
  final rupeesSection = rupeesWords.isEmpty ? 'Zero' : rupeesWords;
  if (paise > 0) {
    final paiseWords = twoDigitWord(paise);
    return 'Rupees $rupeesSection and ${paiseWords} Paise only';
  }
  return 'Rupees $rupeesSection only';
}
