import 'package:flutter/widgets.dart';

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  String get languageCode => locale.languageCode;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': appLocalizationsEn,
    'hi': appLocalizationsHi,
    'mr': appLocalizationsMr,
  };

  String t(String key) {
    final languageMap =
        _localizedValues[languageCode] ?? _localizedValues['en']!;
    return languageMap[key] ?? _localizedValues['en']![key] ?? key;
  }

  String updatedJustNow() => t('updatedJustNow');

  String updatedMinutesAgo(int minutes) =>
      _format(t('updatedMinutesAgo'), {'count': '$minutes'});

  String updatedHoursAgo(int hours) =>
      _format(t('updatedHoursAgo'), {'count': '$hours'});

  String activeLastSeen(String value) =>
      _format(t('activeLastSeen'), {'value': value});

  String moodLogged(String emoji, String label) =>
      _format(t('moodLogged'), {'emoji': emoji, 'label': label});

  String acceptedTask(String title) =>
      _format(t('acceptedTask'), {'title': title});

  String activeCountLabel(int count, String singularKey, String pluralKey) {
    if (count == 1) {
      return _format(t(singularKey), {'count': '$count'});
    }
    return _format(t(pluralKey), {'count': '$count'});
  }

  String requestCompletedCount(int count) => activeCountLabel(
      count, 'completedRequestSingular', 'completedRequestPlural');

  String taskUpdatesCount(int count) =>
      activeCountLabel(count, 'taskUpdateSingular', 'taskUpdatePlural');

  String activeChatsCount(int count) =>
      activeCountLabel(count, 'activeChatSingular', 'activeChatPlural');

  String activeThreadsCount(int count) =>
      activeCountLabel(count, 'activeThreadSingular', 'activeThreadPlural');

  String recentUpdatesCount(int count) =>
      activeCountLabel(count, 'recentUpdateSingular', 'recentUpdatePlural');

  String activeRequestsCount(int count) =>
      activeCountLabel(count, 'activeRequestSingular', 'activeRequestPlural');

  String _format(String template, Map<String, String> values) {
    var output = template;
    values.forEach((key, value) {
      output = output.replaceAll('{$key}', value);
    });
    return output;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
