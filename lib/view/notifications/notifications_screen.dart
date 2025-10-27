import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationService.instance.markAllRead(uid),
            child: Text('Mark all read', style: TextStyle(color: AppColors.primaryBlue)),
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
                'No notifications',
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: read ? AppColors.grey200 : AppColors.primaryBlue.withOpacity(0.12),
                  child: Icon(
                    Icons.notifications,
                    color: read ? AppColors.grey600 : AppColors.primaryBlue,
                  ),
                ),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
                subtitle: Text(body),
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
