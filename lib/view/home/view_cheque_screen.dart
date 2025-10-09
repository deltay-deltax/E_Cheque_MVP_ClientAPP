import 'package:echeque_mvp/view/widgets/digital_cheque_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/view_cheque_view_model.dart';
import '../../services/cheque_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewChequeScreen extends StatelessWidget {
  final String chequeId;
  const ViewChequeScreen({required this.chequeId, super.key});

  @override
  Widget build(BuildContext context) {
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
            future: ChequeService.instance.getChequeById(chequeId),
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
              final amountWords = "Rupees ${amount.toStringAsFixed(2)}"; // TODO: convert to words if needed
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  DigitalChequeCard(
                    bankName: d['bankName'] ?? '',
                    bankAddress: '',
                    chequeNo: d['chequeNo'] ?? '',
                    date: dateText,
                    payee: d['payee'] ?? '',
                    amountNumber: amountNumber,
                    amountWords: amountWords,
                    memo: d['notes'] ?? '',
                    signatureName: '',
                    microText: '*MICR*: ${d['chequeNo'] ?? ''}',
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
                  onPressed: () => vm.shareCheque(context),
                  child: Text(
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
