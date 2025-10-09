import 'package:echeque_mvp/view/widgets/cheque_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/cheque_history_view_model.dart';
import '../../services/cheque_service.dart';
import 'view_cheque_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChequeHistoryScreen extends StatelessWidget {
  const ChequeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChequeHistoryViewModel(),
      child: Consumer<ChequeHistoryViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.grey100,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              "Cheques History",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            centerTitle: true,
            leading: BackButton(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.filter_alt, color: AppColors.primaryBlue),
                onPressed: () {},
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => vm.setFilter(false),
                          child: Text(
                            "All Cheques",
                            style: TextStyle(
                              color: vm.showOnlyPending
                                  ? AppColors.mutedText
                                  : AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: vm.showOnlyPending
                                ? AppColors.white
                                : AppColors.primaryGreen.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => vm.setFilter(true),
                          child: Text(
                            "Pending",
                            style: TextStyle(
                              color: vm.showOnlyPending
                                  ? AppColors.primaryGreen
                                  : AppColors.mutedText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: vm.showOnlyPending
                                ? AppColors.primaryGreen.withOpacity(0.12)
                                : AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChequeService.instance.streamUserCheques(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No cheques yet',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        ),
                      );
                    }
                    // Optional filter: show pending only
                    final filtered = vm.showOnlyPending
                        ? docs.where((d) => (d['status'] ?? 'pending') == 'pending').toList()
                        : docs;
                    return Column(
                      children: filtered.map((d) {
                        final statusStr = (d['status'] ?? 'pending') as String;
                        ChequeStatus status;
                        switch (statusStr) {
                          case 'cleared':
                            status = ChequeStatus.cleared;
                            break;
                          case 'rejected':
                            status = ChequeStatus.rejected;
                            break;
                          case 'bounced':
                            status = ChequeStatus.bounced;
                            break;
                          default:
                            status = ChequeStatus.pending;
                        }
                        final amount = (d['amount'] is num)
                            ? (d['amount'] as num).toDouble()
                            : double.tryParse('${d['amount']}') ?? 0.0;
                        final model = ChequeModel(
                          name: d['payee'] ?? 'Unknown',
                          subText: d['bankName'] ?? '',
                          amount: amount,
                          status: status,
                          dateText: _formatDate(d['date']),
                          id: d['id'],
                          chequeNo: d['chequeNo'],
                          extraDesc: null,
                        );
                        return ChequeCard(
                          model: model,
                          showActions: false,
                          onView: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ViewChequeScreen(chequeId: d['id'] as String),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusTotal(
                      "₹${vm.clearedTotal}",
                      "Total Cleared",
                      AppColors.primaryGreen,
                    ),
                    _StatusTotal(
                      "₹${vm.pendingTotal}",
                      "Pending",
                      AppColors.primaryYellow,
                    ),
                    _StatusTotal(
                      "₹${vm.rejectedTotal}",
                      "Rejected",
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
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

class _StatusTotal extends StatelessWidget {
  final String value, label;
  final Color color;

  const _StatusTotal(this.value, this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
