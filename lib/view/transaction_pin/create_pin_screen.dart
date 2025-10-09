import 'package:echeque_mvp/view/widgets/pin_entry_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';
import '../../core/routes/app_routes.dart';

class CreatePinScreen extends StatelessWidget {
  const CreatePinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PinViewModel>(
      create: (_) => PinViewModel()..setCurrentStep(1),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Consumer<PinViewModel>(
          builder: (context, vm, _) {
            return PinEntryView(
              vm: vm,
              title: "Create your new PIN",
              message:
                  "Set your personal 4-digit code. It will be used for secure and fast sign in.",
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
                onPressed: () {
                  final pin = vm.pin;
                  // Debug: print created PIN (remove in production)
                  // ignore: avoid_print
                  print('[CreatePinScreen] createdPin="$pin" len=${pin.length}');
                  if (pin.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter 4 digits')),
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pinConfirm,
                    arguments: pin,
                  );
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
              )),
            ),
          ),
        ),
      ),
    );
  }
}
