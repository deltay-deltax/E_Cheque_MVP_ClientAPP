import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';
import '../widgets/pin_entry_view.dart';

class EnterPinScreen extends StatelessWidget {
  const EnterPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PinViewModel>(
      create: (_) => PinViewModel()..setCurrentStep(0),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Consumer<PinViewModel>(
          builder: (context, vm, _) {
            return PinEntryView(
              vm: vm,
              title: "Enter your PIN",
              message: "Enter your 4-digit PIN to access your account.",
              showForgot: true,
              onComplete: (pin) => Navigator.of(context).pop(pin),
            );
          },
        ),
      ),
    );
  }
}
