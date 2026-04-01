import 'dart:ui';

enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  marathi('mr', 'मराठी');

  const AppLanguage(this.code, this.nativeLabel);

  final String code;
  final String nativeLabel;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
