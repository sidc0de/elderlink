import 'package:flutter/material.dart';

import '../../main.dart';
import '../../ui/app_ui.dart';

class FamilyMessagesScreen extends StatefulWidget {
  final bool embedded;

  const FamilyMessagesScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<FamilyMessagesScreen> createState() => _FamilyMessagesScreenState();
}

class _FamilyMessagesScreenState extends State<FamilyMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<_MessageThread> _threads = const [
    _MessageThread(
      name: 'Sunita Deshpande',
      initials: 'SD',
      avatarColor: ElderLinkTheme.orange,
      preview: 'I am feeling much better today. Thank you for checking in.',
      time: '10:24 AM',
      unreadCount: 1,
      isOnline: true,
    ),
    _MessageThread(
      name: 'Rohit Kumar',
      initials: 'RK',
      avatarColor: ElderLinkTheme.deepBlue,
      preview: 'Medicine pickup is complete. I have shared the receipt.',
      time: '9:42 AM',
      unreadCount: 0,
      isOnline: true,
    ),
    _MessageThread(
      name: 'Ananya P.',
      initials: 'AP',
      avatarColor: ElderLinkTheme.purple,
      preview: 'Vegetables delivered safely. She also looked cheerful today.',
      time: 'Yesterday',
      unreadCount: 0,
      isOnline: false,
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
    final unreadCount =
        _threads.where((thread) => thread.unreadCount > 0).length;

    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const AppScreenHeader(
                title: 'Messages',
                subtitle: 'Conversations with your elder and volunteers',
              ),
              const SizedBox(height: 16),
              AppSummaryCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: ElderLinkTheme.purple,
                iconBackground: const Color(0xFFF3EEFF),
                title: '${_threads.length} active threads',
                subtitle: 'Check in quickly and stay updated on care tasks',
                trailing: AppPill(
                  label: '$unreadCount unread',
                  textColor: ElderLinkTheme.orange,
                  backgroundColor: const Color(0xFFFFF5F2),
                ),
              ),
              const SizedBox(height: 12),
              ..._threads.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _threads.length - 1 ? 0 : 12,
                      ),
                      child: _MessageCard(thread: entry.value),
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

class _MessageCard extends StatelessWidget {
  final _MessageThread thread;

  const _MessageCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            initials: thread.initials,
            color: thread.avatarColor,
            showOnline: thread.isOnline,
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
                        thread.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(thread.time,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  thread.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (thread.unreadCount > 0)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ElderLinkTheme.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${thread.unreadCount}',
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

class _MessageThread {
  final String name;
  final String initials;
  final Color avatarColor;
  final String preview;
  final String time;
  final int unreadCount;
  final bool isOnline;

  const _MessageThread({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.preview,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
  });
}
