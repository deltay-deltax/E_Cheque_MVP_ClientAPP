import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;

  const ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.grey100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.blueBackground,
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.mutedText, fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.grey300),
        onTap: onTap,
      ),
    );
  }
}
