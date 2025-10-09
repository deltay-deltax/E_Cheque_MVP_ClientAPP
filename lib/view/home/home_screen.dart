import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'profile_screen.dart';
import '../../view_model/home_view_model.dart';
import '../../core/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import 'e_cheque_screen.dart';
import 'cheque_history_screen.dart';
import 'cheque_received_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
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
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: const Text(
                      "AG",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                      Text(
                        "Welcome back,",
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vm.userName,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _BalanceCard(vm: vm),
                      const SizedBox(height: 16),
                      // Hide link card once bank is linked and PIN set
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: UserService.instance.streamCurrentUser(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();
                          final bankLinked =
                              (data?['bankLinked'] as bool?) ?? false;
                          final pinSet = (() {
                            final legacy = (data?['transactionPinHash'] as String?) != null;
                            final obj = data?['transactionPin'] as Map<String, dynamic>?;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _InfoCard(data: vm.summaryCards[0])),
                          const SizedBox(width: 8),
                          Expanded(child: _InfoCard(data: vm.summaryCards[1])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _InfoCard(data: vm.summaryCards[2])),
                          const SizedBox(width: 8),
                          Expanded(child: _InfoCard(data: vm.summaryCards[3])),
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
                      ...vm.transactions
                          .map((t) => _TransactionCard(data: t))
                          .toList(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create action tapped')),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: _buildBottomNav(context, 0),
          );
        },
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const _NavPageScaffold(
                title: 'Chat',
                selectedIndex: 1,
                message: 'Chat (Coming soon)',
              ),
            ),
          );
          break;
        case 2:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const _NavPageScaffold(
                title: 'Analytics',
                selectedIndex: 2,
                message: 'Analytics (Coming soon)',
              ),
            ),
          );
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
  const _BalanceCard({required this.vm});

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
            vm.totalBalance,
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
                vm.mainAccountNumber,
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
                switch (a.text) {
                  case 'E-Cheque':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EChequeScreen()),
                    );
                    break;
                  case 'E-cheque History':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChequeHistoryScreen()),
                    );
                    break;
                  case 'Received Cheque':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReceivedChequesScreen()),
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
