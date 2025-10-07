import 'package:echeque_mvp/view/widgets/pin_entry_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_service.dart';

class ConfirmPinScreen extends StatelessWidget {
  const ConfirmPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final createdPin = ModalRoute.of(context)?.settings.arguments as String?;
    return ChangeNotifierProvider<PinViewModel>(
      create: (_) => PinViewModel()..setCurrentStep(2),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Consumer<PinViewModel>(
          builder: (context, vm, _) {
            return PinEntryView(
              vm: vm,
              title: "Confirm your PIN",
              message: "Enter your 4-digit code again to confirm it's correct.",
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = context.read<PinViewModel>().pin;
                  if (confirm.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter 4 digits')),
                    );
                    return;
                  }
                  if (createdPin == null || createdPin != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PINs don't match")),
                    );
                    return;
                  }
                  try {
                    await UserService.instance.setTransactionPin(confirm);
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.pinSetSuccess,
                      (route) => route.settings.name == AppRoutes.home,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save PIN: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
