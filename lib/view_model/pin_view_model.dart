import 'package:flutter/material.dart';

class PinViewModel extends ChangeNotifier {
  String pin = "";
  String confirmedPin = "";
  int currentStep = 0; // 0-enter pin, 1-create pin, 2-confirm pin

  void addDigit(String digit) {
    if (pin.length < 4) {
      pin += digit;
      notifyListeners();
    }
  }

  void removeDigit() {
    if (pin.isNotEmpty) {
      pin = pin.substring(0, pin.length - 1);
      notifyListeners();
    }
  }

  void clearPin() {
    pin = "";
    notifyListeners();
  }

  void setConfirmedPin(String confirmed) {
    confirmedPin = confirmed;
    notifyListeners();
  }

  void setCurrentStep(int step) {
    currentStep = step;
    pin = "";
    notifyListeners();
  }

  bool get isPinComplete => pin.length == 4;
}
