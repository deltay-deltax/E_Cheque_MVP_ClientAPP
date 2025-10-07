import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? fillColor;
  final bool isEnabled;
  final Color? textColor;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.fillColor,
    this.isEnabled = true,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveFillColor = isEnabled
        ? (fillColor ?? AppColors.primaryBlue)
        : AppColors.buttonDisabled;
    final Color effectiveTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveFillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isEnabled ? 3 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: effectiveTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
