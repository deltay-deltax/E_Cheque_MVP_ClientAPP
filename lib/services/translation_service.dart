import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class TranslationService {
  TranslationService._();
  static final instance = TranslationService._();

  static const _boxName = 'translations';
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  String _cacheKey(String target, String text) => '$target::${text.trim()}';

  String? getCached(String target, String text) {
    final key = _cacheKey(target, text);
    return _box?.get(key) as String?;
  }

  Future<void> setCached(String target, String text, String translated) async {
    final key = _cacheKey(target, text);
    await _box?.put(key, translated);
  }

  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    required String apiKey,
    String sourceLang = 'en',
  }) async {
    await init();
    final result = <String, String>{};

    // Return from cache where available
    final missing = <String>[];
    for (final t in texts) {
      final cached = getCached(targetLang, t);
      if (cached != null && cached.isNotEmpty) {
        result[t] = cached;
      } else {
        missing.add(t);
      }
    }
    if (missing.isEmpty) return result;

    final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2'
        '?key=${Uri.encodeQueryComponent(apiKey)}');
    final body = {
      'q': missing,
      'target': targetLang,
      'format': 'text',
      // 'source': sourceLang, // optional, auto-detect if omitted
    };

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('translate_api_http_${resp.statusCode}: ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final translations = data?['translations'] as List<dynamic>?;
    if (translations == null) {
      throw Exception('translate_api_invalid_response');
    }

    for (var i = 0; i < missing.length && i < translations.length; i++) {
      final original = missing[i];
      final t = (translations[i] as Map<String, dynamic>)['translatedText'] as String? ?? '';
      if (t.isNotEmpty) {
        result[original] = t;
        await setCached(targetLang, original, t);
      }
    }
    return result;
  }
}
