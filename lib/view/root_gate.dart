import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import '../core/services/prefs_service.dart';
import 'home/initial_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Prefetch minimal data needed for Home to render without flicker
      final db = FirebaseFirestore.instance;
      final uid = user.uid;
      final start = DateTime.now();
      try {
        final tasks = <Future<void>>[];
        tasks.add(() async {
          try { await db.collection('users').doc(uid).get(); } catch (_) {}
        }());
        tasks.add(() async {
          try { await db.collection('bankUsers').doc(uid).get(); } catch (_) {}
        }());
        tasks.add(() async {
          try {
            await db
                .collection('transactions')
                .where('userId', isEqualTo: uid)
                .orderBy('at', descending: true)
                .limit(20)
                .get();
          } catch (_) {}
        }());
        await Future.wait(tasks).timeout(const Duration(seconds: 3));
      } catch (_) {}
      // Ensure loader is visible at least ~400ms to avoid flash
      final elapsed = DateTime.now().difference(start);
      if (elapsed.inMilliseconds < 400) {
        await Future.delayed(Duration(milliseconds: 400 - elapsed.inMilliseconds));
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: InitialLoader(),
    );
  }
}
