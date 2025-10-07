import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService._();
  static final instance = PrefsService._();

  static const _kRememberMe = 'remember_me';

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
}
