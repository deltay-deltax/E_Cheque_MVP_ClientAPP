import 'package:echeque_mvp/view/widgets/cheque_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/cheque_history_view_model.dart';
import '../../services/cheque_service.dart';
import 'view_cheque_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            title: Text(
              "Cheques History",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (ctx) {
                      final padding = MediaQuery.of(ctx).viewInsets;
                      return Padding(
                        padding: EdgeInsets.only(bottom: padding.bottom),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: vm.clearFilters,
                                    child: const Text('Clear all'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: vm.setNameQuery,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Bank',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: vm.setBankQuery,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  vm.dateRange == null
                                      ? 'Pick date range'
                                      : '${vm.dateRange!.start.year}-${vm.dateRange!.start.month.toString().padLeft(2, '0')}-${vm.dateRange!.start.day.toString().padLeft(2, '0')}  to  ${vm.dateRange!.end.year}-${vm.dateRange!.end.month.toString().padLeft(2, '0')}-${vm.dateRange!.end.day.toString().padLeft(2, '0')}',
                                ),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDateRangePicker(
                                    context: ctx,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: DateTime(now.year + 5),
                                    initialDateRange: vm.dateRange,
                                  );
                                  vm.setDateRange(picked);
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Apply Filters'),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
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
                          style: TextButton.styleFrom(
                            backgroundColor: vm.showOnlyPending
                                ? AppColors.white
                                : AppColors.primaryGreen.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "All Cheques",
                            style: TextStyle(
                              color: vm.showOnlyPending
                                  ? AppColors.mutedText
                                  : AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => vm.setFilter(true),
                          style: TextButton.styleFrom(
                            backgroundColor: vm.showOnlyPending
                                ? AppColors.primaryGreen.withOpacity(0.12)
                                : AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "Pending",
                            style: TextStyle(
                              color: vm.showOnlyPending
                                  ? AppColors.primaryGreen
                                  : AppColors.mutedText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final userData = userSnap.data?.data();
                    final bool hasBalance =
                        userData != null &&
                        (userData['bank'] is Map) &&
                        ((userData['bank'] as Map)['balance'] != null);
                    final balance = hasBalance
                        ? (((userData!['bank']
                                      as Map<String, dynamic>)['balance']
                                  as num)
                              .toDouble())
                        : 0.0;
                    if (userSnap.connectionState == ConnectionState.active) {
                      debugPrint(
                        "[History] balance snapshot: hasBalance=$hasBalance balance=$balance",
                      );
                    }
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: ChequeService.instance.streamUserCheques(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No cheques yet',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: const [
                                    _StatusTotal(
                                      '₹0.00',
                                      'Total Cleared',
                                      AppColors.primaryGreen,
                                    ),
                                    SizedBox(width: 24),
                                    _StatusTotal(
                                      '₹0.00',
                                      'Pending',
                                      AppColors.primaryYellow,
                                    ),
                                    SizedBox(width: 24),
                                    _StatusTotal(
                                      '₹0.00',
                                      'Rejected',
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        // Apply filters
                        final filteredDocs = docs.where(vm.matchesDoc).toList();

                        final clearedCount = filteredDocs
                            .where(
                              (d) =>
                                  (d['status']?.toString().toLowerCase() ??
                                      '') ==
                                  'cleared',
                            )
                            .length;
                        final pendingCount = filteredDocs
                            .where(
                              (d) =>
                                  (d['status']?.toString().toLowerCase() ??
                                      '') ==
                                  'pending',
                            )
                            .length;
                        final rejectedCount = filteredDocs
                            .where(
                              (d) =>
                                  (d['status']?.toString().toLowerCase() ??
                                      '') ==
                                  'rejected',
                            )
                            .length;
                        final stoppedCount = filteredDocs
                            .where(
                              (d) =>
                                  (d['status']?.toString().toLowerCase() ??
                                      '') ==
                                  'stopped',
                            )
                            .length;

                        final filtered = filteredDocs;

                        final List<Widget> children = [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 8,
                                  color: Colors.black12.withOpacity(0.05),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _StatusChipH(
                                    label: 'Cleared',
                                    count: clearedCount,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusChipH(
                                    label: 'Pending',
                                    count: pendingCount,
                                    color: AppColors.primaryYellow,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusChipH(
                                    label: 'Rejected',
                                    count: rejectedCount,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusChipH(
                                    label: 'Stopped',
                                    count: stoppedCount,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ];

                        children.addAll(
                          filtered.map((d) {
                            final statusStr =
                                (d['status']?.toString().toLowerCase() ??
                                'pending');
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
                              case 'stopped':
                                status = ChequeStatus.stopped;
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

                            // Rule: cleared=grey; amount <= 90% of balance => green; 90%-100% => yellow; >100% => red
                            Color? dot;
                            if (status == ChequeStatus.cleared) {
                              dot = Colors.grey;
                            } else if (status == ChequeStatus.stopped) {
                              // Force red border for stopped cheques
                              dot = Colors.grey;
                            } else if (!hasBalance) {
                              dot =
                                  null; // avoid wrong color until balance loads
                            } else {
                              final reachableBand =
                                  balance * 0.9; // 90% of balance
                              if (amount > balance) {
                                dot = Colors.red;
                              } else if (amount >= reachableBand) {
                                dot = AppColors.primaryYellow;
                              } else {
                                dot = AppColors.primaryGreen;
                              }
                            }
                            final colorName = dot == null
                                ? 'none'
                                : (dot == Colors.red
                                      ? 'red'
                                      : (dot == AppColors.primaryYellow
                                            ? 'yellow'
                                            : (dot == AppColors.primaryGreen
                                                  ? 'green'
                                                  : (dot == Colors.grey
                                                        ? 'grey'
                                                        : dot.toString()))));
                            debugPrint(
                              "[History] cheque id=${d['id']} amount=$amount balance=$balance dot=$colorName status=$status",
                            );

                            return ChequeCard(
                              model: model,
                              showActions: false,
                              statusDotColor: dot,
                              onView: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ViewChequeScreen(
                                      chequeId: d['id'] as String,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );

                        // Compute real totals by summing amounts per status
                        double clearedTotal = 0,
                            pendingTotal = 0,
                            rejectedTotal = 0,
                            stoppedTotal = 0;
                        for (final d in filteredDocs) {
                          final statusStr =
                              (d['status']?.toString().toLowerCase() ??
                              'pending');
                          final amount = (d['amount'] is num)
                              ? (d['amount'] as num).toDouble()
                              : double.tryParse('${d['amount']}') ?? 0.0;
                          switch (statusStr) {
                            case 'cleared':
                              clearedTotal += amount;
                              break;
                            case 'rejected':
                              rejectedTotal += amount;
                              break;
                            case 'stopped':
                              stoppedTotal += amount;
                              break;
                            default:
                              if (statusStr == 'pending')
                                pendingTotal += amount;
                          }
                        }

                        children.add(const SizedBox(height: 16));
                        children.add(
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatusTotal(
                                  "₹${clearedTotal.toStringAsFixed(2)}",
                                  "Total Cleared",
                                  AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 24),
                                _StatusTotal(
                                  "₹${pendingTotal.toStringAsFixed(2)}",
                                  "Pending",
                                  AppColors.primaryYellow,
                                ),
                                const SizedBox(width: 24),
                                _StatusTotal(
                                  "₹${rejectedTotal.toStringAsFixed(2)}",
                                  "Rejected",
                                  Colors.red,
                                ),
                                const SizedBox(width: 24),
                                _StatusTotal(
                                  "₹${stoppedTotal.toStringAsFixed(2)}",
                                  "Stopped",
                                  Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
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

class _StatusChipH extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChipH({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.45), width: 0.25),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
