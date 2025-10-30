import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/key.dart';

class TranslationProvider extends ChangeNotifier {
  final TranslationService _svc = TranslationService.instance;

  String _lang = 'en';
  String get lang => _lang;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // In-memory session cache to avoid repetitive box reads
  final Map<String, String> _mem = {};

  Future<void> init() async {
    await _svc.init();
  }

  // Switch language, optionally prefetch a set of visible strings
  Future<void> setLanguage(String code, {List<String> prefetch = const []}) async {
    if (code == _lang && prefetch.isEmpty) return;
    _lang = code;
    _error = null;
    _loading = prefetch.isNotEmpty;
    notifyListeners();

    try {
      await _svc.init();
      if (prefetch.isNotEmpty) {
        final apiKey = AppSecrets.googleTranslateApiKey.trim();
        if (apiKey.isEmpty) throw Exception('translate_api_key_missing');
        final res = await _svc.translateBatch(texts: prefetch, targetLang: _lang, apiKey: apiKey);
        _mem.addAll(res.map((k, v) => MapEntry(_memKey(_lang, k), v)));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Translate a single string using cache; returns original if not available
  String t(String text) {
    if (_lang == 'en') return text;
    final key = _memKey(_lang, text);
    // memory cache first
    final inMem = _mem[key];
    if (inMem != null) return inMem;
    // hive cache
    final cached = _svc.getCached(_lang, text);
    if (cached != null && cached.isNotEmpty) {
      _mem[key] = cached;
      return cached;
    }
    return text;
  }

  // Batch translate a group of strings for the current language
  Future<void> translateVisible(List<String> texts) async {
    if (_lang == 'en' || texts.isEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final apiKey = AppSecrets.googleTranslateApiKey.trim();
      if (apiKey.isEmpty) throw Exception('translate_api_key_missing');
      final res = await _svc.translateBatch(texts: texts, targetLang: _lang, apiKey: apiKey);
      _mem.addAll(res.map((k, v) => MapEntry(_memKey(_lang, k), v)));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _memKey(String lang, String text) => '$lang::$text';
}
