import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OnboardingIndicator extends StatelessWidget {
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;

  const OnboardingIndicator({
    required this.currentIndex,
    this.activeColor = AppColors.primaryBlue,
    this.inactiveColor = AppColors.indicatorInactive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final bool isActive = currentIndex == index + 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
