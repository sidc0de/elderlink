import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../login_screen.dart';
import '../../ui/app_ui.dart';
import '../../ui/language_selector.dart';

class FamilySettingsScreen extends StatefulWidget {
  final bool embedded;

  const FamilySettingsScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppScreenHeader(
                title: context.l10n.t('settings'),
                subtitle: context.l10n.t('settingsSubtitle'),
              ),
              const SizedBox(height: 16),
              const _ProfileCard(),
              const SizedBox(height: 12),
              const _SettingsCard(),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      body: content,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const _ProfileBadge(),
          const SizedBox(height: 14),
          const Text(
            'Arjun Deshpande',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'arjun.deshpande@elderlink.app',
            style: TextStyle(
              fontSize: 13,
              color: ElderLinkTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppInlineBanner(
            icon: Icons.shield_outlined,
            title: context.l10n.t('primaryFamilyContact'),
            subtitle: context.l10n.t('primaryFamilyContactSubtitle'),
            color: ElderLinkTheme.deepBlue,
            backgroundColor: const Color(0xFFF0F4FF),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ElderLinkTheme.darkNavy, ElderLinkTheme.deepBlue],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'AD',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return AppSettingsGroup(
      children: [
        AppSettingsTile(
          icon: Icons.person_outline_rounded,
          title: context.l10n.t('familyProfile'),
          subtitle: context.l10n.t('familyProfileSubtitle'),
          accentColor: ElderLinkTheme.deepBlue,
          iconBackground: const Color(0xFFF0F4FF),
        ),
        const Divider(height: 1),
        LanguageSettingsTile(
          subtitle: context.l10n.t('settingsLanguageSubtitle'),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.notifications_outlined,
          title: context.l10n.t('alertsNotifications'),
          subtitle: context.l10n.t('alertsNotificationsSubtitle'),
          accentColor: ElderLinkTheme.deepBlue,
          iconBackground: const Color(0xFFF0F4FF),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.help_outline_rounded,
          title: context.l10n.t('helpSupport'),
          subtitle: context.l10n.t('helpSupportSubtitle'),
          accentColor: ElderLinkTheme.deepBlue,
          iconBackground: const Color(0xFFF0F4FF),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.logout_rounded,
          title: context.l10n.t('logout'),
          subtitle: context.l10n.t('logoutSubtitle'),
          accentColor: ElderLinkTheme.orange,
          iconBackground: const Color(0xFFFFF5F2),
          isDestructive: true,
          onTap: () => performMockLogout(context),
        ),
      ],
    );
  }
}
