import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../view_model/profile_view_model.dart';
import '../../services/user_service.dart';
import '../../services/bank_service.dart';
import '../widgets/profile_tile.dart';
import 'home_screen.dart';
import '../chat/chat_screen.dart';
import '../tracker/analytics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.grey100,
          appBar: AppBar(
            backgroundColor: AppColors.grey100,
            elevation: 0,
            centerTitle: true,
            leading: const BackButton(color: Colors.black),
            title: Text(
              'Profile',
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                onPressed: () {
                  // TODO: Add Edit Profile Navigation
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            children: [
              if (vm.needsKyc)
                _KycBanner(onPressed: () => vm.onKycPressed(context)),

              // Profile Header
              Container(
                margin: const EdgeInsets.only(bottom: 19),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: UserService.instance.streamCurrentUser(),
                      builder: (context, snap) {
                        final data = snap.data?.data() ?? {};
                        final name =
                            (data['fullName'] ?? data['displayName'] ?? '')
                                as String? ??
                            '';
                        final initials = name.isNotEmpty
                            ? name
                                  .trim()
                                  .split(RegExp(r"\s+"))
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join('')
                                  .toUpperCase()
                            : 'U';
                        final displayName = name.isNotEmpty ? name : 'User';
                        return Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.white,
                              radius: 40,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Text(
                'Account Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              ProfileTile(
                icon: Icons.person,
                title: 'Personal Information',
                subtitle: 'Update your personal detials ',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 16,
                        right: 16,
                        top: 12,
                      ),
                      child: const _PersonalInfoCard(),
                    ),
                  );
                },
              ),
              const ProfileTile(
                icon: Icons.shield,
                title: 'Security Settings',
                subtitle: 'Manage passwords and 2FA',
              ),
              const ProfileTile(
                icon: Icons.notifications,
                title: 'Notification Preferences',
                subtitle: 'Customize your alerts',
              ),
              const ProfileTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Choose your preferred language',
              ),
              const SizedBox(height: 16),

              const Text(
                'Financial Tools',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const ProfileTile(
                icon: Icons.fact_check,
                title: 'Budget Planner',
                subtitle: 'Track your spending',
              ),
              const ProfileTile(
                icon: Icons.sync_alt,
                title: 'Currency Converter',
                subtitle: 'Check exchange rates',
              ),
              const ProfileTile(
                icon: Icons.receipt_long,
                title: 'Bill Payment',
                subtitle: 'Pay your bills easily',
              ),
              const ProfileTile(
                icon: Icons.calculate,
                title: 'Tax Calculator',
                subtitle: 'Estimate your taxes',
              ),
              const ProfileTile(
                icon: Icons.assignment,
                title: 'Auto Fill Forms',
                subtitle: 'Speed up your applications',
              ),
              const SizedBox(height: 16),

              const Text(
                'Support and Help',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const ProfileTile(
                icon: Icons.help,
                title: 'Contact Us',
                subtitle: 'Get help and support',
              ),
              const ProfileTile(
                icon: Icons.policy,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy terms',
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => vm.logout(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.grey600,
            backgroundColor: AppColors.white,
            onTap: (idx) {
              if (idx == 3) return;
              switch (idx) {
                case 0:
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                  break;
                case 1:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen()),
                  );
                  break;
                case 2:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycBanner extends StatelessWidget {
  final VoidCallback onPressed;

  const _KycBanner({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2CB73), width: 1),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFCEBAE),
            child: Icon(Icons.verified_user, color: Color(0xFFCCA100)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your KYC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF856200),
                  ),
                ),
                Text(
                  'Complete KYC to access all features',
                  style: TextStyle(fontSize: 14, color: Color(0xFF856200)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFFCCA100)),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: UserService.instance.streamCurrentUser(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final udata = userSnap.data?.data() ?? {};
            final name =
                (udata['fullName'] ?? udata['displayName'] ?? '') as String;
            final email = (udata['email'] ?? '') as String;
            final phone =
                (udata['phone'] ?? udata['bank']?['phone'] ?? '')?.toString() ??
                '';
            final account = (udata['bank']?['accountNumber'])?.toString() ?? '';

            final bankStream = account.isNotEmpty
                ? BankService.instance.streamByAccount(account)
                : BankService.instance.streamByEmail(email);

            return StreamBuilder<Map<String, dynamic>?>(
              stream: bankStream,
              builder: (context, bankSnap) {
                final b = bankSnap.data ?? {};
                final bankName = b['bankName']?.toString() ?? '—';
                final acct =
                    (b['accountNumber']?.toString() ??
                    (account.isNotEmpty ? account : '—'));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      Icons.person,
                      'Name',
                      name.isNotEmpty ? name : '—',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.email,
                      'Email',
                      email.isNotEmpty ? email : '—',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.phone,
                      'Phone',
                      phone.isNotEmpty ? phone : '—',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.account_balance, 'Linked Bank', bankName),
                    const SizedBox(height: 6),
                    _infoRow(Icons.numbers, 'Account Number', acct),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
