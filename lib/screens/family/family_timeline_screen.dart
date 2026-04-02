import 'package:flutter/material.dart';

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
                      const AppScreenHeader(
                        title: 'Timeline',
                        subtitle:
                            'Track your elder’s updates and support progress',
                      ),
                      const SizedBox(height: 16),
                      AppSummaryCard(
                        icon: Icons.timeline_rounded,
                        iconColor: ElderLinkTheme.deepBlue,
                        iconBackground: const Color(0xFFF0F4FF),
                        title: '${_events.length} recent updates',
                        subtitle:
                            'Live request activity from the shared request feed',
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
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    emoji: '📖',
                    title: 'No updates here yet',
                    subtitle:
                        'Request status changes will appear here for your review.',
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
    const tabs = ['All', 'Completed'];

    return Row(
      children: [
        const Expanded(child: AppSectionLabel(title: 'Recent Activity')),
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

  String _timeAgo() {
    final difference = DateTime.now().difference(event.createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays} days ago';
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
                  _timeAgo(),
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
