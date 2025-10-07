import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';

class PinSetSuccessViewModel extends ChangeNotifier {
  String successText = "PIN Set!";
  String bodyText = "Your transaction PIN has been set successfully";

  void goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }
}
