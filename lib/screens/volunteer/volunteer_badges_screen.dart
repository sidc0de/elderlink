import 'package:flutter/material.dart';

import '../../main.dart';
import '../../ui/app_ui.dart';

class VolunteerBadgesScreen extends StatefulWidget {
  final bool embedded;

  const VolunteerBadgesScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<VolunteerBadgesScreen> createState() => _VolunteerBadgesScreenState();
}

class _VolunteerBadgesScreenState extends State<VolunteerBadgesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<_BadgeItem> _badges = const [
    _BadgeItem(
      emoji: '🌟',
      title: 'Trusted Helper',
      subtitle: 'Completed 10 support requests with 4.8+ rating',
      accentColor: ElderLinkTheme.purple,
      backgroundColor: Color(0xFFF3EEFF),
    ),
    _BadgeItem(
      emoji: '💊',
      title: 'Medicine Runner',
      subtitle: 'Handled 5 medicine pickups on time',
      accentColor: ElderLinkTheme.orange,
      backgroundColor: Color(0xFFFFF5F2),
    ),
    _BadgeItem(
      emoji: '🚶',
      title: 'Companion Care',
      subtitle: 'Supported 3 companionship visits this month',
      accentColor: ElderLinkTheme.statusAcceptedText,
      backgroundColor: ElderLinkTheme.statusAccepted,
    ),
  ];

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
              const AppScreenHeader(
                title: 'Badges',
                subtitle: 'Celebrate your impact and volunteer milestones',
              ),
              const SizedBox(height: 16),
              AppSummaryCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: ElderLinkTheme.purple,
                iconBackground: const Color(0xFFF3EEFF),
                title: '18 lives supported',
                subtitle:
                    'You are on one of the strongest helping streaks this month',
              ),
              const SizedBox(height: 12),
              ..._badges.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _badges.length - 1 ? 0 : 12,
                      ),
                      child: _BadgeCard(badge: entry.value),
                    ),
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

class _BadgeCard extends StatelessWidget {
  final _BadgeItem badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badge.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(badge.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(badge.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.verified_rounded, color: badge.accentColor),
        ],
      ),
    );
  }
}

class _BadgeItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;

  const _BadgeItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
  });
}
