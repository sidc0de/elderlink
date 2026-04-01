import 'package:flutter/material.dart';

import '../../main.dart';
import '../../ui/app_ui.dart';

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

  final List<_Conversation> _conversations = const [
    _Conversation(
      name: 'Rohit K.',
      initials: 'RK',
      lastMessage: 'I have picked up your medicines and will reach in 15 mins.',
      time: '11:24 AM',
      avatarColor: ElderLinkTheme.orange,
      unreadCount: 2,
      isOnline: true,
    ),
    _Conversation(
      name: 'Ananya P.',
      initials: 'AP',
      lastMessage: 'Would you like me to also bring fruits from the market?',
      time: 'Yesterday',
      avatarColor: ElderLinkTheme.purple,
      unreadCount: 0,
      isOnline: false,
    ),
    _Conversation(
      name: 'Meera S.',
      initials: 'MS',
      lastMessage:
          'Doctor visit is marked complete. Hope you are feeling better.',
      time: 'Sun',
      avatarColor: ElderLinkTheme.orangeLight,
      unreadCount: 0,
      isOnline: true,
    ),
    _Conversation(
      name: 'Family Group',
      initials: 'FG',
      lastMessage: 'We will check in again this evening. Take care.',
      time: 'Sat',
      avatarColor: ElderLinkTheme.purpleLight,
      unreadCount: 1,
      isOnline: false,
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _conversations
        .where((conversation) => conversation.unreadCount > 0)
        .length;

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const AppScreenHeader(
                title: 'Messages',
                subtitle: 'Stay in touch with volunteers and family',
              ),
              const SizedBox(height: 16),
              AppSummaryCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: ElderLinkTheme.orange,
                iconBackground: const Color(0xFFFFF0EB),
                title: '$unreadCount active chats',
                subtitle: 'Quick updates from your care circle',
                trailing: const AppPill(
                  label: 'Reply fast',
                  textColor: ElderLinkTheme.orange,
                  backgroundColor: Color(0xFFFFF5F2),
                ),
              ),
              const SizedBox(height: 12),
              ..._conversations.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _conversations.length - 1 ? 0 : 12,
                      ),
                      child: _ConversationCard(conversation: entry.value),
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

class _ConversationCard extends StatelessWidget {
  final _Conversation conversation;

  const _ConversationCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            initials: conversation.initials,
            color: conversation.avatarColor,
            showOnline: conversation.isOnline,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      conversation.time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  conversation.lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (conversation.unreadCount > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: ElderLinkTheme.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Conversation {
  final String name;
  final String initials;
  final String lastMessage;
  final String time;
  final Color avatarColor;
  final int unreadCount;
  final bool isOnline;

  const _Conversation({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.time,
    required this.avatarColor,
    required this.unreadCount,
    required this.isOnline,
  });
}
