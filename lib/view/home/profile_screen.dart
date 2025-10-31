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
import '../tools/currency_converter_screen.dart';
import '../tools/tax_calculator_screen.dart';
import 'package:echeque_mvp/localization/translation_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TranslationProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tp.translateVisible([
        'Profile',
        'Account Settings',
        'Personal Information',
        'View or update your details',
        'Security Settings',
        'Notification Preferences',
        'Customize alerts',
        'Language',
        'Choose your preferred language',
        'Financial Tools',
        'Budget Planner',
        'Track your spending',
        'Currency Converter',
        'Check exchange rates',
        'Bill Payment',
        'Pay your bills easily',
        'Tax Calculator',
        'Estimate your taxes',
        'Auto Fill Forms',
        'Speed up your applications',
        'Support & Help',
        'Contact Us',
        'Get help and support',
        'Privacy Policy',
        'Read our privacy terms',
        'Logout',
        'Home',
        'Chat',
        'Analytics',
        'Profile',
        'Choose Language',
      ]);
    });
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
              tp.t('Profile'),
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

              Text(
                tp.t('Account Settings'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              ProfileTile(
                icon: Icons.person,
                title: tp.t('Personal Information'),
                subtitle: tp.t('View or update your details'),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
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
              ProfileTile(
                icon: Icons.shield,
                title: tp.t('Security Settings'),
                subtitle: '—',
              ),
              ProfileTile(
                icon: Icons.notifications,
                title: tp.t('Notification Preferences'),
                subtitle: tp.t('Customize alerts'),
              ),
              ProfileTile(
                icon: Icons.language,
                title: tp.t('Language'),
                subtitle: tp.t('Choose your preferred language'),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    builder: (_) => const _LanguageSheet(),
                  );
                },
              ),
              const SizedBox(height: 16),

              Text(
                tp.t('Financial Tools'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              ProfileTile(
                icon: Icons.fact_check,
                title: tp.t('Budget Planner'),
                subtitle: tp.t('Track your spending'),
              ),
              ProfileTile(
                icon: Icons.sync_alt,
                title: tp.t('Currency Converter'),
                subtitle: tp.t('Check exchange rates'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurrencyConverterScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.receipt_long,
                title: tp.t('Bill Payment'),
                subtitle: tp.t('Pay your bills easily'),
              ),
              ProfileTile(
                icon: Icons.calculate,
                title: tp.t('Tax Calculator'),
                subtitle: tp.t('Estimate your taxes'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaxCalculatorScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.assignment,
                title: tp.t('Auto Fill Forms'),
                subtitle: tp.t('Speed up your applications'),
              ),
              const SizedBox(height: 16),

              Text(
                tp.t('Support & Help'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              ProfileTile(
                icon: Icons.help,
                title: tp.t('Contact Us'),
                subtitle: tp.t('Get help and support'),
              ),
              ProfileTile(
                icon: Icons.policy,
                title: tp.t('Privacy Policy'),
                subtitle: tp.t('Read our privacy terms'),
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
                  child: Text(
                    tp.t('Logout'),
                    style: const TextStyle(
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
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => ChatScreen()));
                  break;
                case 2:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: context.watch<TranslationProvider>().t('Home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat),
                label: context.watch<TranslationProvider>().t('Chat'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.analytics),
                label: context.watch<TranslationProvider>().t('Analytics'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: context.watch<TranslationProvider>().t('Profile'),
              ),
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

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final tp = context.read<TranslationProvider>();
    final options = const [
      {'code': 'en', 'label': 'English'},
      {'code': 'hi', 'label': 'हिन्दी (Hindi)'},
      {'code': 'kn', 'label': 'ಕನ್ನಡ (Kannada)'},
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.read<TranslationProvider>().t('Choose Language'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ...options.map(
              (o) => ListTile(
                leading: const Icon(Icons.language),
                title: Text(o['label'] as String),
                trailing: tp.lang == o['code']
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  final visible = <String>[
                    'Profile',
                    'Account Settings',
                    'Personal Information',
                    'View or update your details',
                    'Security Settings',
                    'Notification Preferences',
                    'Customize alerts',
                    'Language',
                    'Choose your preferred language',
                    'Financial Tools',
                    'Budget Planner',
                    'Track your spending',
                    'Currency Converter',
                    'Check exchange rates',
                    'Bill Payment',
                    'Pay your bills easily',
                    'Tax Calculator',
                    'Estimate your taxes',
                    'Auto Fill Forms',
                    'Speed up your applications',
                    'Support & Help',
                    'Contact Us',
                    'Get help and support',
                    'Privacy Policy',
                    'Read our privacy terms',
                    'Logout',
                  ];
                  await tp.setLanguage(o['code'] as String, prefetch: visible);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
