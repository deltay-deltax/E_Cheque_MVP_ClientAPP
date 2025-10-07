import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_indicator.dart';

class Splash3Screen extends StatelessWidget {
  const Splash3Screen({super.key});

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
                  backgroundColor: AppColors.yellowBackground,
                  child: Icon(
                    Icons.receipt_long,
                    size: 60,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "E-Cheque Management",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 10, 10, 10),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 25,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    text: "Streamline your ",
                    children: [
                      TextSpan(
                        text: "digital payments",
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Easily create, send, and track e-cheques. Securely manage your transactions and enjoy a seamless digital payment experience.",
                  style: TextStyle(fontSize: 16, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 100),
                OnboardingIndicator(
                  currentIndex: 3,
                  activeColor: AppColors.primaryYellow,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Previous",
                        fillColor: const Color.fromARGB(169, 245, 245, 245),
                        textColor: AppColors.darkText,
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/splash2'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: "Next",
                        fillColor: AppColors.primaryYellow,
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/splash4'),
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
