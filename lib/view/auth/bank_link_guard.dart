import 'package:flutter/material.dart';

class BankLinkGuard extends StatelessWidget {
  final Widget child;
  const BankLinkGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Pass-through: always render child
    return child;
  }
}
