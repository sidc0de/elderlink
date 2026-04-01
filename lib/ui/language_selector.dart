import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../state/locale_controller.dart';
import 'app_ui.dart';

class LanguageSelectorButton extends StatelessWidget {
  final bool compact;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final String? label;

  const LanguageSelectorButton({
    super.key,
    this.compact = false,
    this.foregroundColor,
    this.backgroundColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final localeController = context.watch<LocaleController>();
    final currentLanguage = localeController.language.nativeLabel;
    final foreground = foregroundColor ?? ElderLinkTheme.textPrimary;
    final background = backgroundColor ?? Colors.white;

    return InkWell(
      onTap: () => showLanguageSelectorSheet(context),
      borderRadius: BorderRadius.circular(compact ? 12 : 16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          border: Border.all(color: ElderLinkTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded,
                color: foreground, size: compact ? 18 : 20),
            const SizedBox(width: 8),
            if (!compact && label != null) ...[
              Text(
                label!,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              compact ? context.l10n.t('languageChipLabel') : currentLanguage,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLanguageSelectorSheet(BuildContext context) {
  final l10n = context.l10n;
  final localeController = context.read<LocaleController>();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return AppBottomSheetScaffold(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBottomSheetHandle(),
            const SizedBox(height: 18),
            Text(
              l10n.t('languageSelectorTitle'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('languageSelectorSubtitle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ...AppLanguage.values.map((language) {
              final isSelected = localeController.language == language;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () async {
                    await localeController.setLanguage(language);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.l10n.t('languageUpdated'))),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF5F2)
                          : ElderLinkTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? ElderLinkTheme.orange
                            : ElderLinkTheme.borderLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            language.nativeLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? ElderLinkTheme.orange
                                  : ElderLinkTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: ElderLinkTheme.orange,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

class LanguageSettingsTile extends StatelessWidget {
  final String subtitle;

  const LanguageSettingsTile({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleController>().language.nativeLabel;

    return AppSettingsTile(
      icon: Icons.translate_rounded,
      title: context.l10n.t('language'),
      subtitle: '$subtitle · $language',
      accentColor: ElderLinkTheme.orange,
      iconBackground: const Color(0xFFFFF5F2),
      onTap: () => showLanguageSelectorSheet(context),
    );
  }
}
