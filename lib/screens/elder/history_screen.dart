import 'package:flutter/material.dart';

import '../../main.dart';
import '../../ui/app_ui.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;

  const HistoryScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _selectedTab = 0;

  final List<_HistoryRequest> _requests = const [
    _HistoryRequest(
      title: 'Buy vegetables from market',
      subtitle: 'Local market · Yesterday',
      category: RequestCategory.grocery,
      volunteerName: 'Ananya P.',
      volunteerInitials: 'AP',
      volunteerColor: ElderLinkTheme.purple,
    ),
    _HistoryRequest(
      title: 'Doctor visit at Ruby Hall',
      subtitle: 'Ruby Hall Clinic · 2 days ago',
      category: RequestCategory.doctorVisit,
      volunteerName: 'Meera S.',
      volunteerInitials: 'MS',
      volunteerColor: ElderLinkTheme.orangeLight,
    ),
    _HistoryRequest(
      title: 'Morning medicines pickup',
      subtitle: 'Apollo Pharmacy · Last week',
      category: RequestCategory.medicine,
      volunteerName: 'Rohit K.',
      volunteerInitials: 'RK',
      volunteerColor: ElderLinkTheme.orange,
    ),
  ];

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

  List<_HistoryRequest> get _filteredRequests => _requests;

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppScreenHeader(
                        title: 'History',
                        subtitle: 'A record of your completed support requests',
                      ),
                      const SizedBox(height: 16),
                      AppSummaryCard(
                        icon: Icons.history_rounded,
                        iconColor: ElderLinkTheme.statusCompletedText,
                        iconBackground: ElderLinkTheme.statusCompleted,
                        title: '${_requests.length} completed requests',
                        subtitle:
                            'All your recent support activity in one place',
                      ),
                      const SizedBox(height: 12),
                      _HistoryTabs(
                        selectedTab: _selectedTab,
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                    ],
                  ),
                ),
              ),
              if (requests.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    emoji: '📚',
                    title: 'No history yet',
                    subtitle:
                        'Completed requests will appear here for quick review.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == requests.length - 1 ? 0 : 12,
                        ),
                        child: _HistoryRequestCard(request: requests[index]),
                      );
                    },
                  ),
                ),
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

class _HistoryTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _HistoryTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = ['All', 'Completed'];

    return Row(
      children: [
        const Expanded(
          child: AppSectionLabel(title: 'Activity'),
        ),
        ...List.generate(
          tabs.length,
          (index) => Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: selectedTab == index,
              onSelected: (_) => onChanged(index),
              selectedColor: ElderLinkTheme.orange,
              labelStyle: TextStyle(
                color: selectedTab == index
                    ? Colors.white
                    : ElderLinkTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selectedTab == index
                    ? ElderLinkTheme.orange
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

class _HistoryRequestCard extends StatelessWidget {
  final _HistoryRequest request;

  const _HistoryRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppCategoryChip(category: request.category),
              const Spacer(),
              const AppRequestStatusChip(status: RequestStatus.completed),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            request.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AppAvatar(
                initials: request.volunteerInitials,
                color: request.volunteerColor,
                radius: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.volunteerName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const AppPill(
                label: 'Rated 4.9',
                textColor: ElderLinkTheme.orange,
                backgroundColor: Color(0xFFFFF5F2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRequest {
  final String title;
  final String subtitle;
  final RequestCategory category;
  final String volunteerName;
  final String volunteerInitials;
  final Color volunteerColor;

  const _HistoryRequest({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.volunteerName,
    required this.volunteerInitials,
    required this.volunteerColor,
  });
}
