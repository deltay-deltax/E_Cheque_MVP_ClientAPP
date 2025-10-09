import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../view_model/pin_view_model.dart';

class PinEntryView extends StatelessWidget {
  final PinViewModel vm;
  final String title;
  final String message;
  final bool showForgot;

  const PinEntryView({
    required this.vm,
    required this.title,
    required this.message,
    this.showForgot = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.blueBackground,
              child: Icon(Icons.lock, size: 48, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 28),
            NumPad(vm: vm, showForgot: showForgot),
          ],
        ),
      ),
    );
  }
}

class NumPad extends StatelessWidget {
  final PinViewModel vm;
  final bool showForgot;

  const NumPad({required this.vm, this.showForgot = false, super.key});

  Widget buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => vm.addDigit(number),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNumberButton("1"),
            buildNumberButton("2"),
            buildNumberButton("3"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNumberButton("4"),
            buildNumberButton("5"),
            buildNumberButton("6"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNumberButton("7"),
            buildNumberButton("8"),
            buildNumberButton("9"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (showForgot)
              TextButton(
                onPressed: () {},
                child: Text(
                  "Forgot PIN?",
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              )
            else
              const SizedBox(width: 80),
            buildNumberButton("0"),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () => vm.removeDigit(),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 32,
                      color: AppColors.darkText,
                    ),
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
