import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_indicator.dart';

class Splash1Screen extends StatelessWidget {
  const Splash1Screen({super.key});

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
                        padding: const EdgeInsets.only(top: 10.0),
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
                  backgroundColor: AppColors.blueBackground,
                  child: Icon(
                    Icons.home,
                    size: 60,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Welcome to FinTech\n Pro",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    letterSpacing: -1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                    text: "Your personal finance ",
                    children: [
                      TextSpan(
                        text: "companion for smarter money management",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Take control of your financial future with our comprehensive suite of tools designed to help you save, invest, and grow your wealth.",
                  style: TextStyle(fontSize: 16, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),

                Text(
                  "Key Features",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 60),
                OnboardingIndicator(
                  currentIndex: 1,
                  activeColor: AppColors.primaryBlue,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "Next",
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/splash2'),
                  fillColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
