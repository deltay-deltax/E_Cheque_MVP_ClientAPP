import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
    } catch (_) {
      // ignore error silently
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: UserService.instance.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['fullName']?.toString() ?? d['displayName']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Email: ${d['email'] ?? '-'}'),
                    if (d['phone'] != null) Text('Phone: ${d['phone']}'),
                    if (d['bank'] != null) ...[
                      const SizedBox(height: 6),
                      const Text('Linked Bank:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Bank: ${d['bank']['bankName'] ?? '-'}'),
                      Text('Account: ${d['bank']['accountNumber'] ?? '-'}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

