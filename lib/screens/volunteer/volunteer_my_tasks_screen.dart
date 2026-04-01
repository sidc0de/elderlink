import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/help_request.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';

class VolunteerMyTasksScreen extends StatefulWidget {
  final bool embedded;

  const VolunteerMyTasksScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<VolunteerMyTasksScreen> createState() => _VolunteerMyTasksScreenState();
}

class _VolunteerMyTasksScreenState extends State<VolunteerMyTasksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  int _selectedTab = 0;
  bool _isLoading = true;
  List<HelpRequest> _tasks = [];

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
    _loadTasks();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    await MockAuthService.instance.signInAs(UserRole.volunteer);
    final volunteer = MockAuthService.instance.currentUser;
    final items = await RequestRepository.instance.fetchVolunteerAssignedRequests(
      volunteer.id,
    );
    if (!mounted) return;
    setState(() {
      _tasks = items;
      _isLoading = false;
    });
  }

  List<_VolunteerTaskItem> get _filteredTasks {
    final mapped = _tasks.map(_mapTask).toList();
    switch (_selectedTab) {
      case 1:
        return mapped
            .where((task) => task.status != _TaskStatus.completed)
            .toList();
      case 2:
        return mapped
            .where((task) => task.status == _TaskStatus.completed)
            .toList();
      default:
        return mapped;
    }
  }

  _VolunteerTaskItem _mapTask(HelpRequest task) {
    return _VolunteerTaskItem(
      elderName: task.elderName,
      elderInitials: task.elderInitials,
      elderColor: task.elderColor,
      title: task.title,
      subtitle: task.subtitle,
      status: _statusFromRequest(task.status),
      category: task.category,
    );
  }

  _TaskStatus _statusFromRequest(RequestStatus status) {
    switch (status) {
      case RequestStatus.completed:
        return _TaskStatus.completed;
      case RequestStatus.inProgress:
        return _TaskStatus.inProgress;
      case RequestStatus.pending:
      case RequestStatus.accepted:
      case RequestStatus.cancelled:
        return _TaskStatus.upcoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? AppLoadingState(
            color: ElderLinkTheme.purple,
            message: 'Loading your tasks...',
          )
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppScreenHeader(
                        title: 'My Tasks',
                        subtitle:
                            'Track accepted requests and completed support',
                      ),
                      const SizedBox(height: 16),
                      AppSummaryCard(
                        icon: Icons.checklist_rounded,
                        iconColor: ElderLinkTheme.purple,
                        iconBackground: const Color(0xFFF3EEFF),
                        title: '${_tasks.length} task updates',
                        subtitle: 'See what is upcoming, active, and completed',
                      ),
                      const SizedBox(height: 12),
                      _TaskTabs(
                        selectedTab: _selectedTab,
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                    ],
                  ),
                ),
              ),
              if (_filteredTasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    emoji: '🗂️',
                    title: 'No tasks here yet',
                    subtitle:
                        'Accepted and completed requests will appear here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _filteredTasks.length - 1 ? 0 : 12,
                        ),
                        child: _TaskCard(task: _filteredTasks[index]),
                      );
                    },
                  ),
                ),
            ],
          );

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: body,
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

class _TaskTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _TaskTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = ['All', 'Active', 'Completed'];

    return Row(
      children: [
        const Expanded(child: AppSectionLabel(title: 'Task Status')),
        ...List.generate(
          tabs.length,
          (index) => Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: selectedTab == index,
              onSelected: (_) => onChanged(index),
              selectedColor: ElderLinkTheme.purple,
              labelStyle: TextStyle(
                color: selectedTab == index
                    ? Colors.white
                    : ElderLinkTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selectedTab == index
                    ? ElderLinkTheme.purple
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

class _TaskCard extends StatelessWidget {
  final _VolunteerTaskItem task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                initials: task.elderInitials,
                color: task.elderColor,
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.elderName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 14),
          AppCategoryChip(category: task.category),
          const SizedBox(height: 10),
          Text(task.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(task.subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _TaskStatus.upcoming:
        return const AppPill(
          label: 'Upcoming',
          textColor: Color(0xFFF9A825),
          backgroundColor: Color(0xFFFFF8E1),
        );
      case _TaskStatus.inProgress:
        return const AppPill(
          label: 'In Progress',
          textColor: ElderLinkTheme.purple,
          backgroundColor: Color(0xFFF3EEFF),
        );
      case _TaskStatus.completed:
        return const AppPill(
          label: 'Completed',
          textColor: ElderLinkTheme.statusAcceptedText,
          backgroundColor: ElderLinkTheme.statusAccepted,
        );
    }
  }
}

enum _TaskStatus { upcoming, inProgress, completed }

class _VolunteerTaskItem {
  final String elderName;
  final String elderInitials;
  final Color elderColor;
  final String title;
  final String subtitle;
  final _TaskStatus status;
  final RequestCategory category;

  const _VolunteerTaskItem({
    required this.elderName,
    required this.elderInitials,
    required this.elderColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.category,
  });
}
