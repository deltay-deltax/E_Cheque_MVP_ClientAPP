import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';
import 'package:echeque_mvp/localization/translation_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final tp = context.watch<TranslationProvider>();
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(tp.t('Not signed in'))),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          tp.t('Notifications'),
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationService.instance.markAllRead(uid),
            child: Text(tp.t('Mark all read'), style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotificationService.instance.streamAll(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                tp.t('No notifications'),
                style: TextStyle(color: AppColors.grey600),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();
              final title = (data['title'] as String?) ?? '';
              final body = (data['body'] as String?) ?? '';
              final read = (data['read'] as bool?) ?? false;
              final amount = (data['amount'] as num?)?.toDouble();
              DateTime? when;
              final at = data['occurredAt'] ?? data['createdAt'];
              if (at is Timestamp) when = at.toDate();
              String meta = '';
              if (amount != null) meta += '₹${amount.toStringAsFixed(2)}';
              if (when != null) {
                final hh = when.hour.toString().padLeft(2, '0');
                final mm = when.minute.toString().padLeft(2, '0');
                final dd = when.day.toString().padLeft(2, '0');
                final mo = when.month.toString().padLeft(2, '0');
                final yyyy = when.year;
                meta += (meta.isNotEmpty ? ' • ' : '') + '$dd/$mo/$yyyy $hh:$mm';
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: read ? AppColors.grey200 : AppColors.primaryBlue.withOpacity(0.12),
                  child: Icon(
                    Icons.notifications,
                    color: read ? AppColors.grey600 : AppColors.primaryBlue,
                  ),
                ),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(meta, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      ),
                  ],
                ),
                trailing: read ? null : Icon(Icons.brightness_1, size: 10, color: AppColors.primaryBlue),
                onTap: () => NotificationService.instance.markAsRead(uid, d.id),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
