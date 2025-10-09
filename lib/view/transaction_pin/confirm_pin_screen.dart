import 'package:echeque_mvp/view/widgets/pin_entry_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_service.dart';
import '../../services/bank_service.dart';

class ConfirmPinScreen extends StatelessWidget {
  final String? createdPin;
  const ConfirmPinScreen({super.key, this.createdPin});

  @override
  Widget build(BuildContext context) {
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
              child: Consumer<PinViewModel>(
                builder: (context, vm, _) => ElevatedButton(
                  onPressed: () async {
                    final confirm = vm.pin;
                    // Debug prints to analyze mismatch (remove in prod)
                    // ignore: avoid_print
                    print('[ConfirmPinScreen] createdPin="${createdPin}" len=${createdPin?.length}');
                    // ignore: avoid_print
                    print('[ConfirmPinScreen] confirm   ="$confirm" len=${confirm.length}');
                    if (confirm.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter 4 digits')),
                      );
                      return;
                    }
                    if (createdPin == null || createdPin.toString() != confirm.toString()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PINs don't match")),
                      );
                      return;
                    }
                    try {
                      // Save PIN under user document
                      await UserService.instance.setTransactionPin(confirm);

                      // Also save PIN under bankUsers using the user's linked account number
                      final userSnap = await UserService.instance.streamCurrentUser().first;
                      final accountNumber = (userSnap.data()?['bank']?['accountNumber'])?.toString();
                      if (accountNumber != null && accountNumber.isNotEmpty) {
                        await BankService.instance.setTransactionPinForAccount(accountNumber, confirm);
                      }

                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.pinSetSuccess,
                        (route) => false,
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
      ),
    );
  }
}
