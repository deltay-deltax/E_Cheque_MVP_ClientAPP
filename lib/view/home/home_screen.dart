import 'package:echeque_mvp/view/home/quick_actions_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'profile_screen.dart';
import '../../view_model/home_view_model.dart';
import '../../core/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'e_cheque_screen.dart';
import 'cheque_history_screen.dart';
import 'cheque_received_screen.dart';
import '../../services/cheque_service.dart';
import '../tracker/transaction_history_screen.dart';
import '../tracker/add_expense_screen.dart';
import '../tracker/analytics_screen.dart';
import '../tracker/add_category_screen.dart';
import '../auth/bank_link_guard.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BankLinkGuard(
      child: ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            // Process any due cheques after the first frame when Home loads
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ChequeService.instance.processDueCheques();
            });
            return Scaffold(
              backgroundColor: AppColors.white,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: AppColors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.black87,
                    ),
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: UserService.instance.streamCurrentUser(),
                          builder: (context, snap) {
                            String initials = 'U';
                            final data = snap.data?.data();
                            final name =
                                (data?['fullName'] ??
                                        data?['displayName'] ??
                                        '')
                                    as String?;
                            if (name != null && name.trim().isNotEmpty) {
                              final parts = name.trim().split(RegExp(r"\s+"));
                              final first = parts.isNotEmpty ? parts.first : '';
                              final last = parts.length > 1 ? parts.last : '';
                              final i1 = first.isNotEmpty ? first[0] : '';
                              final i2 = last.isNotEmpty ? last[0] : '';
                              initials = (i1 + i2).toUpperCase();
                            }
                            return CircleAvatar(
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: UserService.instance.streamCurrentUser(),
                          builder: (context, snap) {
                            final data = snap.data?.data();
                            final name =
                                (data?['fullName'] ??
                                        data?['displayName'] ??
                                        '')
                                    as String?;
                            final displayName =
                                (name != null && name.trim().isNotEmpty)
                                ? name.trim()
                                : 'User';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome back,",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Balance card: prefer bankUsers by accountNumber, then users/{uid}.bank.balance, then fallback sum
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: UserService.instance.streamCurrentUser(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data();
                            debugPrint(
                              '[Home] user stream update: hasData=${snapshot.hasData} bankLinked=${data?['bankLinked']}',
                            );
                            final bankLinked =
                                (data?['bankLinked'] as bool?) ?? false;
                            if (!bankLinked) return const SizedBox.shrink();
                            final bank =
                                (data?['bank'] as Map<String, dynamic>?) ?? {};
                            final acct = bank['accountNumber']?.toString();
                            final userDocBal = (bank['balance'] as num?)
                                ?.toDouble();
                            final bankUsersUid =
                                (bank['uid'] as String?) ??
                                FirebaseAuth.instance.currentUser?.uid;
                            debugPrint(
                              '[Home] derived acct=$acct userDocBal=$userDocBal bankUsersUid=$bankUsersUid',
                            );
                            return StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: (() {
                                // Prefer to listen by account number to match admin-seeded bankUsers docs
                                if (acct != null && acct.isNotEmpty) {
                                  return FirebaseFirestore.instance
                                      .collection('bankUsers')
                                      .where('accountNumber', isEqualTo: acct)
                                      .limit(1)
                                      .snapshots()
                                      .map(
                                        (qs) => qs.docs.isNotEmpty
                                            ? qs.docs.first
                                            : null,
                                      )
                                      .where((doc) => doc != null)
                                      .cast<
                                        DocumentSnapshot<Map<String, dynamic>>
                                      >();
                                }
                                // Fallback to doc by uid if no account number available
                                if (bankUsersUid == null) {
                                  return const Stream<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >.empty();
                                }
                                return FirebaseFirestore.instance
                                    .collection('bankUsers')
                                    .doc(bankUsersUid)
                                    .snapshots();
                              })(),
                              builder: (context, buSnap) {
                                final buBal =
                                    (buSnap.data?.data()?['balance'] as num?)
                                        ?.toDouble();
                                debugPrint(
                                  '[Home] bankUsers snapshot: exists=${buSnap.data?.exists} byAcct=${acct != null && acct.isNotEmpty} buBal=$buBal',
                                );
                                final preferredBal = buBal ?? userDocBal;
                                final preferredBalStr = preferredBal != null
                                    ? '₹${preferredBal.toStringAsFixed(2)}'
                                    : null;
                                return StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: (() {
                                    final uid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    if (uid == null) {
                                      return const Stream<
                                        QuerySnapshot<Map<String, dynamic>>
                                      >.empty();
                                    }
                                    return FirebaseFirestore.instance
                                        .collection('transactions')
                                        .where('userId', isEqualTo: uid)
                                        .orderBy('at', descending: true)
                                        .limit(500)
                                        .snapshots();
                                  })(),
                                  builder: (context, txSnap) {
                                    String? liveBalanceStr;
                                    final docs = txSnap.data?.docs ?? const [];
                                    if (txSnap.hasError) {
                                      debugPrint(
                                        '[Home] tx stream error: ${txSnap.error}',
                                      );
                                    }
                                    debugPrint(
                                      '[Home] tx stream update: count=${docs.length} state=${txSnap.connectionState}',
                                    );
                                    if (docs.isNotEmpty) {
                                      double sum = 0;
                                      double pendingImpact = 0;
                                      for (final d in docs) {
                                        final dd = d.data();
                                        final dir =
                                            (dd['direction'] as String?) ??
                                            'debit';
                                        final amt =
                                            ((dd['amount'] as num?) ?? 0)
                                                .toDouble();
                                        final status =
                                            (dd['status'] as String?) ??
                                            'Completed';
                                        final source =
                                            (dd['source'] as String?) ?? '';
                                        if (status == 'Completed') {
                                          sum += dir == 'credit' ? amt : -amt;
                                        } else if (status == 'Pending' &&
                                            source != 'cheque') {
                                          // Apply optimistic pending impact for non-cheque tx (e.g., mobile send)
                                          pendingImpact += dir == 'credit'
                                              ? amt
                                              : -amt;
                                        }
                                      }
                                      liveBalanceStr =
                                          '₹${sum.toStringAsFixed(2)}';
                                      debugPrint(
                                        '[Home] computed live balance from tx = $liveBalanceStr',
                                      );
                                      if (preferredBal != null) {
                                        final eff =
                                            preferredBal + pendingImpact;
                                        debugPrint(
                                          '[Home] pendingImpact(non-cheque)=$pendingImpact effectiveDisplayed=$eff',
                                        );
                                        final effStr =
                                            '₹${eff.toStringAsFixed(2)}';
                                        return _BalanceCard(
                                          vm: vm,
                                          overrideBalance: effStr,
                                          overrideAccountNumber: acct,
                                        );
                                      }
                                    }
                                    debugPrint(
                                      '[Home] preferredBalStr=$preferredBalStr using=${preferredBalStr ?? liveBalanceStr}',
                                    );
                                    return _BalanceCard(
                                      vm: vm,
                                      overrideBalance:
                                          preferredBalStr ?? liveBalanceStr,
                                      overrideAccountNumber: acct,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Hide link card once bank is linked and PIN set
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: UserService.instance.streamCurrentUser(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data();
                            final bankLinked =
                                (data?['bankLinked'] as bool?) ?? false;
                            final pinSet = (() {
                              final legacy =
                                  (data?['transactionPinHash'] as String?) !=
                                  null;
                              final obj =
                                  data?['transactionPin']
                                      as Map<String, dynamic>?;
                              final v2 = (obj?['hash'] as String?) != null;
                              return legacy || v2;
                            })();
                            if (bankLinked && pinSet) {
                              return const SizedBox.shrink();
                            }
                            return const _LinkCard();
                          },
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _QuickActionsGrid(vm: vm),
                        const SizedBox(height: 15),
                        Text(
                          "This Month",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, 1);
                            final end = DateTime(now.year, now.month + 1, 1);
                            return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: (() {
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) {
                                  return const Stream<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >.empty();
                                }
                                return FirebaseFirestore.instance
                                    .collection('transactions')
                                    .where('userId', isEqualTo: uid)
                                    .where(
                                      'at',
                                      isGreaterThanOrEqualTo:
                                          Timestamp.fromDate(start),
                                    )
                                    .where(
                                      'at',
                                      isLessThan: Timestamp.fromDate(end),
                                    )
                                    .snapshots();
                              })(),
                              builder: (context, snap) {
                                double monthIncome = 0;
                                double monthExpense = 0;
                                final docs = snap.data?.docs ?? const [];
                                for (final d in docs) {
                                  final data = d.data();
                                  final dir =
                                      (data['direction'] as String?) ?? 'debit';
                                  final amt = ((data['amount'] as num?) ?? 0)
                                      .toDouble();
                                  if (dir == 'credit')
                                    monthIncome += amt;
                                  else
                                    monthExpense += amt;
                                }
                                final incomeCard = SummaryCard(
                                  'Income',
                                  '₹${monthIncome.toStringAsFixed(2)}',
                                  Icons.arrow_upward,
                                  const Color(0xFF10B981),
                                  '',
                                );
                                final expenseCard = SummaryCard(
                                  'Expenses',
                                  '₹${monthExpense.toStringAsFixed(2)}',
                                  Icons.arrow_downward,
                                  Colors.red,
                                  '',
                                );
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _InfoCard(data: incomeCard),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _InfoCard(data: expenseCard),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _InfoCard(data: vm.summaryCards[2]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoCard(data: vm.summaryCards[3]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 9),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: (() {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) {
                              return Stream<
                                QuerySnapshot<Map<String, dynamic>>
                              >.empty();
                            }
                            return FirebaseFirestore.instance
                                .collection('transactions')
                                .where('userId', isEqualTo: uid)
                                .orderBy('at', descending: true)
                                .limit(3)
                                .snapshots();
                          })(),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return const Text(
                                'Unable to load recent transactions. Please ensure Firestore index exists for userId+at.',
                                style: TextStyle(color: Colors.redAccent),
                              );
                            }
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            final docs = snap.data?.docs ?? const [];
                            if (docs.isEmpty) {
                              return const Text(
                                'No recent transactions',
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            return Column(
                              children: docs.map((d) {
                                final data = d.data();
                                final dir =
                                    (data['direction'] as String?) ?? 'debit';
                                final incoming = dir == 'credit';
                                final amount = ((data['amount'] as num?) ?? 0)
                                    .toDouble();
                                final note =
                                    (data['note'] as String?) ??
                                    (data['source'] as String? ??
                                        'Transaction');
                                final atTs = data['at'];
                                String time = '';
                                if (atTs is Timestamp) {
                                  final dt = atTs.toDate();
                                  time =
                                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                }
                                return _TransactionCard(
                                  data: TransactionCardData(
                                    note,
                                    incoming ? 'Income' : 'Payment',
                                    time.isEmpty ? '—' : time,
                                    (incoming ? '+₹' : '-₹') +
                                        amount.toStringAsFixed(2),
                                    incoming ? 'Income' : 'Expense',
                                    incoming
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    incoming
                                        ? const Color(0xFF10B981)
                                        : Colors.red,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primaryBlue,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    builder: (_) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddExpenseScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 10,
                                            color: Colors.black12.withOpacity(
                                              0.05,
                                            ),
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.add_circle,
                                            color: Color(0xFF2563EB),
                                            size: 28,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Add Expense',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddCategoryScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 10,
                                            color: Colors.black12.withOpacity(
                                              0.05,
                                            ),
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.category,
                                            color: Color(0xFF2563EB),
                                            size: 28,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Add Category',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: _buildBottomNav(context, 0),
            );
          },
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------
/// 🧭 Bottom Navigation Builder
/// -----------------------------------------------------------
Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    onTap: (idx) {
      if (idx == currentIndex) return;
      switch (idx) {
        case 0:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          break;
        case 1:
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ChatScreen()));
          break;
        case 2:
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
          break;
        case 3:
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          break;
      }
    },
    selectedItemColor: AppColors.primaryBlue,
    unselectedItemColor: AppColors.grey600,
    backgroundColor: AppColors.white,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
      BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
    ],
  );
}

/// -----------------------------------------------------------
/// 📱 Temporary Nav Scaffold Pages
/// -----------------------------------------------------------
class _NavPageScaffold extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final String message;
  const _NavPageScaffold({
    required this.title,
    required this.selectedIndex,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(message, style: const TextStyle(fontSize: 18))),
      bottomNavigationBar: _buildBottomNav(context, selectedIndex),
    );
  }
}

/// -----------------------------------------------------------
/// 💳 Balance Card
/// -----------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  final HomeViewModel vm;
  final String? overrideBalance;
  final String? overrideAccountNumber;
  const _BalanceCard({
    required this.vm,
    this.overrideBalance,
    this.overrideAccountNumber,
  });

  String _todayString() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    return "$dd/$mm/$yyyy";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                vm.mainCardSubtitle,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF456EDE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      vm.mainCardRate,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            overrideBalance ?? vm.totalBalance,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            vm.availableToSpend,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Account Number",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.90),
                ),
              ),
              // Right-side label removed as requested (was: "Valid Thru")
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                overrideAccountNumber ?? vm.mainAccountNumber,
                style: const TextStyle(fontSize: 17, color: Colors.white),
              ),
              Text(
                _todayString(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------
/// 🏦 Link Bank Card
/// -----------------------------------------------------------
class _LinkCard extends StatelessWidget {
  const _LinkCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.bankInfo),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blueBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blueBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Link your bank account",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Get a complete view of your finances",
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 24),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------
/// ⚡ Quick Actions Grid
/// -----------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  final HomeViewModel vm;
  const _QuickActionsGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 11,
      mainAxisSpacing: 11,
      childAspectRatio: 0.9,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: vm.quickActions
          .map(
            (a) => _ActionItem(
              icon: a.icon,
              text: a.text,
              bgColor: a.bgColor,
              iconColor: a.iconColor,
              onTap: () {
                final key = a.text.replaceAll(RegExp(r'\s+'), ' ').trim();
                switch (key) {
                  case 'E-Cheque':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EChequeScreen()),
                    );
                    break;
                  case 'E-cheque History':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChequeHistoryScreen(),
                      ),
                    );
                    break;
                  case 'Received Cheque':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReceivedChequesScreen(),
                      ),
                    );
                    break;
                  case 'Transactions':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(),
                      ),
                    );
                    break;
                  case 'More':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuickActionsScreen(),
                      ),
                    );
                    break;
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coming soon: ${a.text}')),
                    );
                }
              },
            ),
          )
          .toList(),
    );
  }
}

/// -----------------------------------------------------------
/// 🎯 Action Item
/// -----------------------------------------------------------
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;
  const _ActionItem({
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color: Colors.black12.withOpacity(0.06),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------
/// 📊 Info Card
/// -----------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final SummaryCard data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 3),
            color: Colors.black12.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 19, color: data.color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.percent,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: data.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            data.value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------
/// 💰 Transaction Card
/// -----------------------------------------------------------
class _TransactionCard extends StatelessWidget {
  final TransactionCardData data;
  const _TransactionCard({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final isIncome = data.type == "Income";
    final typeColor = isIncome ? AppColors.primaryGreen : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            blurRadius: 11,
            color: Colors.black12.withOpacity(0.03),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: data.color.withOpacity(0.13),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      data.category,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      " • ${data.time}",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                  fontSize: 16,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: Text(
                  data.type,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
