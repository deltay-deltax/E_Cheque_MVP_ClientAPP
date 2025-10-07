import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_indicator.dart';

class Splash4Screen extends StatelessWidget {
  const Splash4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 65,
                  backgroundColor: AppColors.greenBackground,
                  child: Icon(
                    Icons.shield,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Secure & Private",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                    text: "Your data is protected with ",
                    children: [
                      TextSpan(
                        text: "bank-level security",
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Rest easy knowing your financial information is encrypted and protected with the highest security standards.",
                  style: TextStyle(fontSize: 16, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 200),
                OnboardingIndicator(
                  currentIndex: 4,
                  activeColor: AppColors.primaryGreen,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Previous",
                        textColor: AppColors.darkText,
                        fillColor: const Color.fromARGB(169, 245, 245, 245),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/splash3'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: "Get Started",
                        fillColor: AppColors.primaryGreen,
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
