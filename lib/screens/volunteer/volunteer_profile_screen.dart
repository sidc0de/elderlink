import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../login_screen.dart';
import '../../ui/app_ui.dart';
import '../../ui/language_selector.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final bool embedded;

  const VolunteerProfileScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final RequestRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = RequestRepository.instance;
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
                title: context.l10n.t('profile'),
                subtitle: context.l10n.t('volunteerProfileSubtitle'),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _repository,
                builder: (context, _) => _ProfileCard(
                  stats: _repository.getVolunteerRatingStats(
                    MockAuthService.instance.userForRole(UserRole.volunteer).id,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _MenuCard(),
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
  final VolunteerRatingStats stats;

  const _ProfileCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const _ProfileBadge(),
          const SizedBox(height: 14),
          const Text(
            'Rohit Kumar',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'rohit.kumar@elderlink.app',
            style: TextStyle(
              fontSize: 13,
              color: ElderLinkTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppInlineBanner(
                  icon: Icons.star_rounded,
                  title: stats.totalRatings == 0
                      ? 'No ratings yet'
                      : '${stats.averageRating.toStringAsFixed(1)} average rating',
                  subtitle: '${stats.totalRatings} ratings received',
                  color: ElderLinkTheme.orange,
                  backgroundColor: const Color(0xFFFFF5F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppInlineBanner(
            icon: Icons.favorite_outline_rounded,
            title: context.l10n.t('trustedVolunteer'),
            subtitle:
                '${stats.completedTasksCount} completed tasks with shared community trust',
            color: ElderLinkTheme.purple,
            backgroundColor: const Color(0xFFF3EEFF),
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
          colors: [ElderLinkTheme.purple, ElderLinkTheme.purpleLight],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'RK',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard();

  @override
  Widget build(BuildContext context) {
    return AppSettingsGroup(
      children: [
        AppSettingsTile(
          icon: Icons.edit_outlined,
          title: context.l10n.t('editProfile'),
          subtitle: context.l10n.t('editProfileSubtitle'),
          accentColor: ElderLinkTheme.purple,
          iconBackground: const Color(0xFFF3EEFF),
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
          accentColor: ElderLinkTheme.purple,
          iconBackground: const Color(0xFFF3EEFF),
        ),
        const Divider(height: 1),
        AppSettingsTile(
          icon: Icons.help_outline_rounded,
          title: context.l10n.t('support'),
          subtitle: context.l10n.t('supportSubtitle'),
          accentColor: ElderLinkTheme.purple,
          iconBackground: const Color(0xFFF3EEFF),
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
