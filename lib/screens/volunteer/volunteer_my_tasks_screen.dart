import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/help_request.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import '../shared/request_chat_thread_screen.dart';

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
  late final ChatRepository _chatRepository;
  late final RequestRepository _repository;
  late final String _volunteerId;

  int _selectedTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository.instance;
    _repository = RequestRepository.instance;
    _volunteerId = MockAuthService.instance.userForRole(UserRole.volunteer).id;
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
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<HelpRequest> _filteredTasks() {
    final tasks = _repository.getVolunteerAssignedRequestsSnapshot(_volunteerId);
    switch (_selectedTab) {
      case 1:
        return tasks
            .where((task) => task.status != RequestStatus.completed)
            .toList();
      case 2:
        return tasks
            .where((task) => task.status == RequestStatus.completed)
            .toList();
      default:
        return tasks;
    }
  }

  Future<void> _runAction(HelpRequest task) async {
    switch (task.status) {
      case RequestStatus.accepted:
        await _repository.startRequest(task.id);
        _showSnackbar('Task started: ${task.title}', ElderLinkTheme.purple);
        break;
      case RequestStatus.inProgress:
        await _repository.completeRequest(task.id);
        _showSnackbar('Task completed: ${task.title}', ElderLinkTheme.statusAcceptedText);
        break;
      default:
        break;
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _openChat(HelpRequest task) {
    final volunteerId = task.volunteerId;
    if (volunteerId == null) return;

    final thread = _chatRepository.getOrCreateThreadForRequest(
      requestId: task.id,
      elderId: task.elderId,
      volunteerId: volunteerId,
    );
    if (thread == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestChatThreadScreen(threadId: thread.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? AppLoadingState(
            color: ElderLinkTheme.purple,
            message: 'Loading your tasks...',
          )
        : AnimatedBuilder(
            animation: _repository,
            builder: (context, _) {
              final allTasks =
                  _repository.getVolunteerAssignedRequestsSnapshot(_volunteerId);
              final tasks = _filteredTasks();

              return CustomScrollView(
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
                            title: '${allTasks.length} task updates',
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
                  if (tasks.isEmpty)
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
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == tasks.length - 1 ? 0 : 12,
                            ),
                            child: _TaskCard(
                              task: tasks[index],
                              onAction: () => _runAction(tasks[index]),
                              onOpenChat: () => _openChat(tasks[index]),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
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
  final HelpRequest task;
  final VoidCallback onAction;
  final VoidCallback onOpenChat;

  const _TaskCard({
    required this.task,
    required this.onAction,
    required this.onOpenChat,
  });

  String? get _actionLabel {
    switch (task.status) {
      case RequestStatus.accepted:
        return 'Start Task';
      case RequestStatus.inProgress:
        return 'Mark Completed';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      border: Border.all(
        color: task.isEmergency
            ? const Color(0xFFFFB4A1)
            : ElderLinkTheme.borderLight,
        width: task.isEmergency ? 1.6 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.isEmergency) ...[
            const AppEmergencyBadge(label: 'Emergency'),
            const SizedBox(height: 12),
          ],
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
              AppRequestStatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 14),
          AppCategoryChip(category: task.category),
          const SizedBox(height: 10),
          Text(task.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(task.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_actionLabel != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElderLinkTheme.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                label: task.status == RequestStatus.completed
                    ? 'Completed'
                    : task.status == RequestStatus.cancelled
                        ? 'Cancelled'
                        : 'Waiting',
                textColor: task.status == RequestStatus.completed
                    ? ElderLinkTheme.statusAcceptedText
                    : ElderLinkTheme.textSecondary,
                backgroundColor: task.status == RequestStatus.completed
                    ? ElderLinkTheme.statusAccepted
                    : ElderLinkTheme.surfaceMuted,
              ),
            ),
        ],
      ),
    );
  }
}
