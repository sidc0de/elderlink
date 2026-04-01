import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../login_screen.dart';
import '../../ui/app_ui.dart';
import '../../ui/language_selector.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppScreenHeader(
                title: l10n.t('profile'),
                subtitle: l10n.t('profileSubtitle'),
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

    if (widget.embedded) {
      return content;
    }

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
            'Sunita Deshpande',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'sunita.deshpande@elderlink.app',
            style: TextStyle(
              fontSize: 13,
              color: ElderLinkTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppInlineBanner(
            icon: Icons.verified_user_outlined,
            title: context.l10n.t('verifiedAccount'),
            subtitle: context.l10n.t('verifiedAccountSubtitle'),
            color: ElderLinkTheme.orange,
            backgroundColor: const Color(0xFFFFF0EB),
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
          colors: [
            ElderLinkTheme.orange,
            ElderLinkTheme.orangeLight,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'SD',
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
          icon: Icons.edit_outlined,
          title: context.l10n.t('editProfile'),
          subtitle: context.l10n.t('editProfileSubtitle'),
          accentColor: ElderLinkTheme.orange,
          iconBackground: const Color(0xFFFFF0EB),
        ),
        const Divider(height: 1),
        LanguageSettingsTile(
          subtitle: context.l10n.t('profileLanguageSubtitle'),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.notifications_outlined,
          title: context.l10n.t('notifications'),
          subtitle: context.l10n.t('notificationsSubtitle'),
          accentColor: ElderLinkTheme.textPrimary,
          iconBackground: ElderLinkTheme.surfaceMuted,
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.help_outline_rounded,
          title: context.l10n.t('help'),
          subtitle: context.l10n.t('helpSubtitle'),
          accentColor: ElderLinkTheme.textPrimary,
          iconBackground: ElderLinkTheme.surfaceMuted,
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.logout_rounded,
          title: context.l10n.t('logout'),
          subtitle: context.l10n.t('logoutSubtitle'),
          accentColor: ElderLinkTheme.orange,
          iconBackground: const Color(0xFFFFF0EB),
          isDestructive: true,
          onTap: () => performMockLogout(context),
        ),
      ],
    );
  }
}
