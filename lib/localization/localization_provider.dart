import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale_code';
  String _code = 'en';

  String get code => _code;
  Locale get locale => Locale(_code);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_prefsKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setCode(String code) async {
    if (_code == code) return;
    _code = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _code);
    notifyListeners();
  }
}
