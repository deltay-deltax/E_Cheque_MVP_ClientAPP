import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/routes/app_routes.dart';

class ProfileViewModel extends ChangeNotifier {
  final String name = "Aditya Gupta";
  final String memberType = "Premium Member";
  final int accounts = 3;
  final int cards = 2;
  final int memberSince = 2020;
  final bool needsKyc = true;

  void onKycPressed(BuildContext context) {
    // Navigate to KYC flow.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Navigate to KYC verification")));
  }

  void logout(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    });
  }
}
