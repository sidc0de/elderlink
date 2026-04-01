import 'package:flutter/material.dart';

import '../../main.dart';
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

  int _selectedTab = 0;

  final List<_TimelineEntry> _entries = const [
    _TimelineEntry(
      emoji: '✅',
      title: 'Medicine pickup completed',
      subtitle: 'Rohit Kumar delivered medicines from Apollo Pharmacy',
      timeAgo: '2 hours ago',
      bgColor: ElderLinkTheme.statusAccepted,
      accentColor: ElderLinkTheme.statusAcceptedText,
    ),
    _TimelineEntry(
      emoji: '😊',
      title: 'Mood check-in logged',
      subtitle: 'Sunita reported feeling happy this morning',
      timeAgo: 'Today, 9:15 AM',
      bgColor: Color(0xFFFFF5F2),
      accentColor: ElderLinkTheme.orange,
    ),
    _TimelineEntry(
      emoji: '🙋',
      title: 'Volunteer accepted request',
      subtitle: 'Ananya P. accepted the vegetable pickup request',
      timeAgo: 'This morning',
      bgColor: Color(0xFFF3EEFF),
      accentColor: ElderLinkTheme.purple,
    ),
    _TimelineEntry(
      emoji: '💬',
      title: 'New conversation started',
      subtitle: 'Rohit shared an ETA update in messages',
      timeAgo: 'Yesterday',
      bgColor: ElderLinkTheme.statusCompleted,
      accentColor: ElderLinkTheme.statusCompletedText,
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

  List<_TimelineEntry> get _filteredEntries {
    switch (_selectedTab) {
      case 1:
        return _entries.where((entry) => entry.emoji == '✅').toList();
      default:
        return _entries;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            'Track your elder’s updates and completed help',
                      ),
                      const SizedBox(height: 16),
                      AppSummaryCard(
                        icon: Icons.timeline_rounded,
                        iconColor: ElderLinkTheme.deepBlue,
                        iconBackground: const Color(0xFFF0F4FF),
                        title: '${_entries.length} recent updates',
                        subtitle:
                            'A quick view of support activity and wellbeing',
                      ),
                      const SizedBox(height: 12),
                      _TimelineTabs(
                        selectedTab: _selectedTab,
                        onChanged: (value) =>
                            setState(() => _selectedTab = value),
                      ),
                    ],
                  ),
                ),
              ),
              if (_filteredEntries.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    emoji: '📖',
                    title: 'No updates here yet',
                    subtitle:
                        'Completed support activity will appear here for your review.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _filteredEntries.length - 1 ? 0 : 12,
                        ),
                        child: _TimelineCard(entry: _filteredEntries[index]),
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

class _TimelineCard extends StatelessWidget {
  final _TimelineEntry entry;

  const _TimelineCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(entry.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  entry.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: entry.accentColor,
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

class _TimelineEntry {
  final String emoji;
  final String title;
  final String subtitle;
  final String timeAgo;
  final Color bgColor;
  final Color accentColor;

  const _TimelineEntry({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.bgColor,
    required this.accentColor,
  });
}
