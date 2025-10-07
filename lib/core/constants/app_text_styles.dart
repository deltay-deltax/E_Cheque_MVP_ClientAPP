import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    color: AppColors.mutedText,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle highlighted = TextStyle(
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle highlightedYellow = TextStyle(
    color: AppColors.primaryYellow,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle highlightedGreen = TextStyle(
    color: AppColors.primaryGreen,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle description = TextStyle(
    fontSize: 16,
    color: AppColors.mutedText,
    height: 1.45,
  );

  static const TextStyle keyFeature = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.darkText,
  );

  static const TextStyle skipText = TextStyle(
    color: AppColors.mutedText,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonText = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  static const TextStyle prevBtn = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: AppColors.darkText,
  );
  static const TextStyle nextBtn = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 17,
    color: Colors.white,
  );
  static const TextStyle getStartedBtn = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 17,
    color: Colors.white,
  );

  static const TextStyle linkText = TextStyle(
    color: AppColors.primaryBlue,
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.w500,
  );
}
