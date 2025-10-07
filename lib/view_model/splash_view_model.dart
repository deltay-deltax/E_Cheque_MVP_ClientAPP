import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  int _currentIndex = 0; // 0-based for 4 splash screens

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void next() {
    if (_currentIndex < 3) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}
