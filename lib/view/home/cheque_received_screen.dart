import 'package:echeque_mvp/view/widgets/cheque_card.dart';
import 'view_cheque_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/cheque_history_view_model.dart';
import '../../services/cheque_service.dart';

class ReceivedChequesScreen extends StatelessWidget {
  const ReceivedChequesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          "Received Cheques",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: (() {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null)
              return const Stream<List<Map<String, dynamic>>>.empty();
            return ChequeService.instance.streamInboxCheques(uid);
          })(),
          builder: (context, chequeSnap) {
            if (!chequeSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = chequeSnap.data!;
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No received cheques yet',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              );
            }
            final models = docs.map((d) {
              final statusStr = (d['status'] as String? ?? 'pending')
                  .toLowerCase();
              ChequeStatus status;
              switch (statusStr) {
                case 'cleared':
                  status = ChequeStatus.cleared;
                  break;
                case 'bounced':
                  status = ChequeStatus.bounced;
                  break;
                case 'rejected':
                  status = ChequeStatus.rejected;
                  break;
                default:
                  status = ChequeStatus.pending;
              }
              final dateTs = d['date'] as dynamic;
              String dateText = '';
              if (dateTs is Timestamp) {
                final dt = dateTs.toDate();
                dateText = '${dt.day}/${dt.month}/${dt.year}';
              }
              return ChequeModel(
                name: d['issuerName']?.toString() ?? 'Unknown Sender',
                subText: d['bankName']?.toString() ?? '',
                amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
                status: status,
                dateText: dateText,
                id: d['id']?.toString() ?? '',
                chequeNo: d['chequeNo']?.toString(),
              );
            }).toList();

            // Totals header
            final clearedCount = docs
                .where(
                  (d) =>
                      (d['status']?.toString().toLowerCase() ?? '') ==
                      'cleared',
                )
                .length;
            final pendingCount = docs
                .where(
                  (d) =>
                      (d['status']?.toString().toLowerCase() ?? '') ==
                      'pending',
                )
                .length;
            final rejectedCount = docs
                .where(
                  (d) =>
                      (d['status']?.toString().toLowerCase() ?? '') ==
                      'rejected',
                )
                .length;

            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
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
                        _StatusChip(
                          label: 'Cleared',
                          count: clearedCount,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(
                          label: 'Pending',
                          count: pendingCount,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(
                          label: 'Rejected',
                          count: rejectedCount,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.filter_alt, size: 19),
                        label: Text("Filter"),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey200,
                          foregroundColor: AppColors.darkText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.sort, size: 19),
                        label: Text("Sort"),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey200,
                          foregroundColor: AppColors.darkText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(models.length, (i) {
                  final m = models[i];
                  final src = docs[i];
                  final issuerUid = src['issuerUid']?.toString();
                  final amount = (src['amount'] as num?)?.toDouble() ?? 0.0;
                  if (issuerUid == null || issuerUid.isEmpty) {
                    Color? dot;
                    final issuerBal =
                        (src['issuerBalance'] as num?)?.toDouble() ?? 0.0;
                    if (m.status == ChequeStatus.cleared) {
                      dot = Colors.grey;
                    } else {
                      final band = issuerBal * 0.9; // 90% reachable band
                      if (amount > issuerBal) {
                        dot = Colors.red;
                      } else if (amount >= band) {
                        dot = AppColors.primaryYellow;
                      } else {
                        dot = AppColors.primaryGreen;
                      }
                    }
                    debugPrint("[Received] (no user stream) id=${m.id} amount=$amount issuerBal=$issuerBal dot=${dot == Colors.red ? 'red' : dot == AppColors.primaryYellow ? 'yellow' : dot == AppColors.primaryGreen ? 'green' : dot == Colors.grey ? 'grey' : 'none'}");
                    return ChequeCard(
                      model: m,
                      showActions: false,
                      statusDotColor: dot,
                      onView: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ViewChequeScreen(
                              chequeId: m.id,
                              issuerUid: issuerUid,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(issuerUid)
                        .snapshots(),
                    builder: (context, userSnap) {
                      final u = userSnap.data?.data();
                      final hasIssuerBal = u != null && (u['bank'] is Map) && ((u['bank'] as Map)['balance'] != null);
                      final issuerBal = hasIssuerBal
                          ? (((u['bank'] as Map<String, dynamic>)['balance'] as num).toDouble())
                          : ((src['issuerBalance'] as num?)?.toDouble() ?? 0.0);
                      if (userSnap.connectionState == ConnectionState.active) {
                        debugPrint("[Received] balance snapshot: hasIssuerBal=$hasIssuerBal issuerBal=$issuerBal for uid=$issuerUid");
                      }
                      Color? dot;
                      if (m.status == ChequeStatus.cleared) {
                        dot = Colors.grey;
                      } else if (!hasIssuerBal) {
                        dot = null; // avoid wrong color until balance present
                      } else {
                        final band = issuerBal * 0.9; // 90% reachable band
                        if (amount > issuerBal) {
                          dot = Colors.red;
                        } else if (amount >= band) {
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
                                      : (dot == Colors.grey ? 'grey' : dot.toString()))));
                      debugPrint("[Received] cheque id=${m.id} amount=$amount issuerBal=$issuerBal dot=$colorName status=${m.status}");
                      return ChequeCard(
                        model: m,
                        showActions: false,
                        statusDotColor: dot,
                        onView: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ViewChequeScreen(
                                chequeId: m.id,
                                issuerUid: issuerUid,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusChip({
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
        border: Border.all(color: color.withOpacity(0.25)),
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
