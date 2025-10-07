import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../core/services/prefs_service.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final remembered = await PrefsService.instance.getRememberMe();
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (remembered && user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.splash1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
