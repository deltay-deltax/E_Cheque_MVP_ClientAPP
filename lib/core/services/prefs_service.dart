import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService._();
  static final instance = PrefsService._();

  static const _kRememberMe = 'remember_me';
  static const _kLastKnownBalance = 'last_known_balance';

  Future<void> setRememberMe(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRememberMe, value);
  }

  Future<bool> getRememberMe() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRememberMe) ?? false;
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kRememberMe);
  }

  Future<void> setLastKnownBalance(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastKnownBalance, value);
  }

  Future<String?> getLastKnownBalance() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastKnownBalance);
  }
}
