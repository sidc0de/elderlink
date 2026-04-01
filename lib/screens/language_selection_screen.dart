import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../state/locale_controller.dart';
import 'splash_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeController = context.watch<LocaleController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElderLinkTheme.darkNavy,
              ElderLinkTheme.midNavy,
              ElderLinkTheme.deepBlue,
            ],
            stops: [0.0, 0.62, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('firstScreenLanguageTitle'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.t('firstScreenLanguageSubtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 28),
                ...AppLanguage.values.map((language) {
                  final isSelected = localeController.language == language;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => localeController.setLanguage(language),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? ElderLinkTheme.orange
                                : Colors.white.withOpacity(0.12),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                language.nativeLabel,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? ElderLinkTheme.textPrimary
                                      : Colors.white,
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
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                      );
                    },
                    child: Text(l10n.t('done')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
