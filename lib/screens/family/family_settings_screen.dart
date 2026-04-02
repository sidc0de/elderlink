import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../services/mock_auth_service.dart';
import '../login_screen.dart';
import '../shared/edit_profile_screen.dart';
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
    final user = MockAuthService.instance.userForRole(UserRole.family);
    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppScreenHeader(
                title: context.l10n.t('profile'),
                subtitle: context.l10n.t('familyProfileSubtitle'),
              ),
              const SizedBox(height: 16),
              _ProfileCard(user: user),
              const SizedBox(height: 12),
              _SettingsCard(
                onEditProfile: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(
                        role: UserRole.family,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
                onLogout: () async {
                  final confirmed = await showLogoutConfirmationDialog(context);
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await performMockLogout(context);
                },
              ),
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
  final AppUser user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          _ProfileBadge(user: user),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email ?? '',
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
  final AppUser user;

  const _ProfileBadge({required this.user});

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
      child: Text(
        user.initials,
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
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const _SettingsCard({
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppSettingsGroup(
      children: [
        AppSettingsTile(
          icon: Icons.edit_outlined,
          title: context.l10n.t('editProfile'),
          subtitle: context.l10n.t('editProfileSubtitle'),
          accentColor: ElderLinkTheme.deepBlue,
          iconBackground: const Color(0xFFF0F4FF),
          onTap: onEditProfile,
        ),
        const Divider(height: 1),
        LanguageSettingsTile(
          subtitle: context.l10n.t('profileLanguageSubtitle'),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.logout_rounded,
          title: context.l10n.t('logout'),
          subtitle: context.l10n.t('logoutSubtitle'),
          accentColor: ElderLinkTheme.orange,
          iconBackground: const Color(0xFFFFF5F2),
          isDestructive: true,
          onTap: onLogout,
        ),
      ],
    );
  }
}
