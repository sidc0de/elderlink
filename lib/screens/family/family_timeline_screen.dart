import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';

class FamilyTimelineScreen extends StatefulWidget {
  final bool embedded;

  const FamilyTimelineScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<FamilyTimelineScreen> createState() => _FamilyTimelineScreenState();
}

class _FamilyTimelineScreenState extends State<FamilyTimelineScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final RequestRepository _repository;

  int _selectedTab = 0;
  List<RequestTimelineEvent> _events = const [];
  Set<String> _newEventIds = const {};

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
    _events = _repository.getTimelineEventsSnapshot(_currentElderId);
    _repository.addListener(_handleTimelineUpdate);
    _animController.forward();
  }

  @override
  void dispose() {
    _repository.removeListener(_handleTimelineUpdate);
    _animController.dispose();
    super.dispose();
  }

  String get _currentElderId =>
      MockAuthService.instance.userForRole(UserRole.elder).id;

  void _handleTimelineUpdate() {
    final nextEvents = _repository.getTimelineEventsSnapshot(_currentElderId);
    final currentIds = _events.map((event) => event.id).toSet();
    final addedIds = nextEvents
        .where((event) => !currentIds.contains(event.id))
        .map((event) => event.id)
        .toSet();

    if (!mounted) return;
    setState(() {
      _events = nextEvents;
      _newEventIds = addedIds;
    });
    if (addedIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _newEventIds = const {});
      });
    }
  }

  List<RequestTimelineEvent> _filteredEvents() {
    switch (_selectedTab) {
      case 1:
        return _events
            .where((event) => event.status == RequestStatus.completed)
            .toList();
      default:
        return _events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = _filteredEvents();

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppScreenHeader(
                        title: l10n.t('timeline'),
                        subtitle: l10n.t('timelineTrackSubtitle'),
                      ),
                      const SizedBox(height: 16),
                      AppSummaryCard(
                        icon: Icons.timeline_rounded,
                        iconColor: ElderLinkTheme.deepBlue,
                        iconBackground: const Color(0xFFF0F4FF),
                        title: l10n.recentUpdatesCount(_events.length),
                        subtitle: l10n.t('liveRequestActivitySharedFeed'),
                      ),
                      const SizedBox(height: 12),
                      _TimelineTabs(
                        selectedTab: _selectedTab,
                        onChanged: (value) => setState(() => _selectedTab = value),
                      ),
                    ],
                  ),
                ),
              ),
              if (events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    emoji: '📖',
                    title: l10n.t('noUpdatesYetTitle'),
                    subtitle: l10n.t('noUpdatesYetSubtitle'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == events.length - 1 ? 0 : 12,
                        ),
                        child: _AnimatedTimelineEntry(
                          key: ValueKey(event.id),
                          animateOnMount: _newEventIds.contains(event.id),
                          child: _TimelineCard(event: event),
                        ),
                      );
                    },
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

class _TimelineTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _TimelineTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [l10n.t('all'), l10n.t('completed')];

    return Row(
      children: [
        Expanded(child: AppSectionLabel(title: l10n.t('recentActivity'))),
        ...List.generate(
          tabs.length,
          (index) => Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: selectedTab == index,
              onSelected: (_) => onChanged(index),
              selectedColor: ElderLinkTheme.deepBlue,
              labelStyle: TextStyle(
                color: selectedTab == index
                    ? Colors.white
                    : ElderLinkTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selectedTab == index
                    ? ElderLinkTheme.deepBlue
                    : ElderLinkTheme.borderLight,
              ),
              backgroundColor: Colors.transparent,
              showCheckmark: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedTimelineEntry extends StatefulWidget {
  final Widget child;
  final bool animateOnMount;

  const _AnimatedTimelineEntry({
    super.key,
    required this.child,
    required this.animateOnMount,
  });

  @override
  State<_AnimatedTimelineEntry> createState() => _AnimatedTimelineEntryState();
}

class _AnimatedTimelineEntryState extends State<_AnimatedTimelineEntry> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _visible = !widget.animateOnMount;
    if (widget.animateOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final RequestTimelineEvent event;

  const _TimelineCard({required this.event});

  ({String emoji, Color bgColor, Color accentColor}) _meta() {
    final lowerTitle = event.title.toLowerCase();
    if (lowerTitle.contains('sos') || lowerTitle.contains('emergency')) {
      return (
        emoji: '🚨',
        bgColor: const Color(0xFFFFF0EB),
        accentColor: Colors.red,
      );
    }

    switch (event.status) {
      case RequestStatus.pending:
        return (
          emoji: '📝',
          bgColor: ElderLinkTheme.statusPending,
          accentColor: ElderLinkTheme.statusPendingText,
        );
      case RequestStatus.accepted:
        return (
          emoji: '🙋',
          bgColor: const Color(0xFFF3EEFF),
          accentColor: ElderLinkTheme.purple,
        );
      case RequestStatus.inProgress:
        return (
          emoji: '🚶',
          bgColor: ElderLinkTheme.statusCompleted,
          accentColor: ElderLinkTheme.statusCompletedText,
        );
      case RequestStatus.completed:
        return (
          emoji: '✅',
          bgColor: ElderLinkTheme.statusAccepted,
          accentColor: ElderLinkTheme.statusAcceptedText,
        );
      case RequestStatus.cancelled:
        return (
          emoji: '✖',
          bgColor: const Color(0xFFFCEBEB),
          accentColor: ElderLinkTheme.danger,
        );
    }
  }

  String _timeAgo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final difference = DateTime.now().difference(event.createdAt);
    if (difference.inMinutes < 1) return l10n.t('justNow');
    if (difference.inHours < 1) {
      return l10n.format('minutesAgoShort', {'count': '${difference.inMinutes}'});
    }
    if (difference.inDays < 1) {
      return l10n.format('hoursAgoShort', {'count': '${difference.inHours}'});
    }
    if (difference.inDays == 1) return l10n.t('yesterday');
    return l10n.format('daysAgo', {'count': '${difference.inDays}'});
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta();

    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: meta.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(meta.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  event.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  _timeAgo(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: meta.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
