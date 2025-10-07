import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';

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
            return _PinEntryView(
              vm: vm,
              title: "Enter your PIN",
              message: "Enter your 4-digit PIN to access your account.",
              showForgot: true,
            );
          },
        ),
      ),
    );
  }
}

class _PinEntryView extends StatelessWidget {
  final PinViewModel vm;
  final String title;
  final String message;
  final bool showForgot;

  const _PinEntryView({
    required this.vm,
    required this.title,
    required this.message,
    this.showForgot = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.blueBackground,
          child: Icon(Icons.lock, size: 48, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            message,
            style: TextStyle(fontSize: 17, color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            bool filled = vm.pin.length > index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: filled ? AppColors.primaryBlue : AppColors.grey300,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        _NumPad(vm: vm, showForgot: showForgot),
      ],
    );
  }
}

class _NumPad extends StatelessWidget {
  final PinViewModel vm;
  final bool showForgot;

  const _NumPad({required this.vm, this.showForgot = false, super.key});

  @override
  Widget build(BuildContext context) {
    Widget _buildNumberButton(String number) {
      return GestureDetector(
        onTap: () {
          vm.addDigit(number);
        },
        child: SizedBox(
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),
          width: 80,
          height: 80,
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNumberButton("1"),
            _buildNumberButton("2"),
            _buildNumberButton("3"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNumberButton("4"),
            _buildNumberButton("5"),
            _buildNumberButton("6"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNumberButton("7"),
            _buildNumberButton("8"),
            _buildNumberButton("9"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (showForgot)
              TextButton(
                onPressed: () {
                  // TODO: handle forgot pin.
                },
                child: Text(
                  "Forgot PIN?",
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              )
            else
              const SizedBox(width: 80),
            _buildNumberButton("0"),
            GestureDetector(
              onTap: () => vm.removeDigit(),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 32,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
