import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.onGoToLogin});
  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                offset: Offset(0, 5),
                color: Colors.black12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.check, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                "Congrats!!!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Your password set successfully",
                style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "GO TO LOGIN",
                onPressed: onGoToLogin,
                fillColor: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
