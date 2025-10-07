import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_set_success_view_model.dart';

class PinSetSuccessScreen extends StatelessWidget {
  const PinSetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PinSetSuccessViewModel(),
      child: Consumer<PinSetSuccessViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.primaryBlue,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Success",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
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
                    child: const Icon(
                      Icons.check,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    vm.successText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    vm.bodyText,
                    style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => vm.goToHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "GO TO HOME",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
