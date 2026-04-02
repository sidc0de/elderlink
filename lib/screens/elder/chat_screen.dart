import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/chat_thread.dart';
import '../../repositories/chat_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import '../shared/request_chat_thread_screen.dart';

class ChatScreen extends StatefulWidget {
  final bool embedded;

  const ChatScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final ChatRepository _chatRepository;

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository.instance;
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

  String get _elderId => MockAuthService.instance.userForRole(UserRole.elder).id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _chatRepository,
            builder: (context, _) {
              final conversations = _chatRepository.getElderThreads(_elderId);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  AppScreenHeader(
                    title: l10n.t('messages'),
                    subtitle: l10n.t('messagesSubtitle'),
                  ),
                  const SizedBox(height: 16),
                  AppSummaryCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: ElderLinkTheme.orange,
                    iconBackground: const Color(0xFFFFF0EB),
                    title: l10n.activeThreadsCount(conversations.length),
                    subtitle: l10n.t('sharedChatsSyncedHere'),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: conversations.isEmpty
                        ? AppEmptyState(
                            key: const ValueKey('chat-empty'),
                            emoji: '💬',
                            title: l10n.t('noChatsYetTitle'),
                            subtitle: l10n.t('noChatsYetSubtitle'),
                          )
                        : Column(
                            key: const ValueKey('chat-list'),
                            children: conversations.asMap().entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == conversations.length - 1
                                      ? 0
                                      : 12,
                                ),
                                child: _ConversationCard(
                                  thread: entry.value,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestChatThreadScreen(
                                          threadId: entry.value.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              );
            },
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

class _ConversationCard extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ChatRepository.instance;
    final request = repository.getRequestSnapshot(thread.requestId);
    final lastMessage = thread.messages.isEmpty ? null : thread.messages.last;
    final name = repository.displayNameForThread(thread, UserRole.elder);
    final initials = repository.displayInitialsForThread(thread, UserRole.elder);
    final avatarColor =
        Color(repository.displayColorValueForThread(thread, UserRole.elder));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ElderLinkTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF152033).withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarColor.withOpacity(0.18),
                    width: 2,
                  ),
                ),
                child: AppAvatar(
                  initials: initials,
                  color: avatarColor,
                  showOnline: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatThreadTime(context, thread.updatedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    if (request != null) ...[
                      const SizedBox(height: 6),
                      if (request.isEmergency)
                        AppEmergencyBadge(label: l10n.t('urgent'))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: request.category.bgColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            request.category.label,
                            style: TextStyle(
                              color: request.category.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      lastMessage?.text ?? l10n.t('startConversation'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ElderLinkTheme.textPrimary,
                            height: 1.45,
                          ),
                    ),
                    if (request != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 14,
                            color: ElderLinkTheme.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              request.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: ElderLinkTheme.textSecondary,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatThreadTime(BuildContext context, DateTime updatedAt) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    if (difference.inDays > 0) {
      return l10n.format('daysAgoShort', {'count': '${difference.inDays}'});
    }
    if (difference.inHours > 0) {
      return l10n.format('hoursAgoShort', {'count': '${difference.inHours}'});
    }
    if (difference.inMinutes > 0) {
      return l10n.format('minutesAgoShort', {'count': '${difference.inMinutes}'});
    }
    return l10n.t('now');
  }
}
