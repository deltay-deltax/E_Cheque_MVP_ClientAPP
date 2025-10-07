import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_indicator.dart';

class Splash2Screen extends StatelessWidget {
  const Splash2Screen({super.key});

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
                    Icons.pie_chart,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Smart Budgeting",
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
                    text: "Create and track budgets ",
                    children: [
                      TextSpan(
                        text: "effortlessly",
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
                  "Set financial goals, track your spending, and stay on top of your budget with intelligent insights and personalized recommendations.",
                  style: TextStyle(fontSize: 16, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 200),
                OnboardingIndicator(
                  currentIndex: 2,
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
                            Navigator.pushReplacementNamed(context, '/splash1'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: "Next",
                        fillColor: AppColors.primaryGreen,
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/splash3'),
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
