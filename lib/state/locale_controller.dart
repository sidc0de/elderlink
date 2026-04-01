import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._(this._language);

  static const _prefsKey = 'elderlink.locale';

  AppLanguage _language;

  Locale get locale => _language.locale;
  AppLanguage get language => _language;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? AppLanguage.english.code;
    return LocaleController._(AppLanguage.fromCode(code));
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}
