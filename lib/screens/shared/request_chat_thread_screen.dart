import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/chat_thread.dart';
import '../../repositories/chat_repository.dart';
import '../../services/mock_auth_service.dart';

class RequestChatThreadScreen extends StatefulWidget {
  final String threadId;

  const RequestChatThreadScreen({
    super.key,
    required this.threadId,
  });

  @override
  State<RequestChatThreadScreen> createState() => _RequestChatThreadScreenState();
}

class _RequestChatThreadScreenState extends State<RequestChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatRepository _chatRepository;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository.instance;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _chatRepository.sendMessage(threadId: widget.threadId, text: text);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 96,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MockAuthService.instance.currentUser;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: AnimatedBuilder(
          animation: _chatRepository,
          builder: (context, _) {
            final thread = _chatRepository.getThreadById(widget.threadId);
            if (thread == null) {
              return Text(l10n.t('chat'));
            }
            final request = _chatRepository.getRequestSnapshot(thread.requestId);
            final name =
                _chatRepository.displayNameForThread(thread, currentUser.role);
            final roleLabel =
                currentUser.role == UserRole.elder
                    ? l10n.t('volunteerRole')
                    : l10n.t('elderRole');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  request == null
                      ? roleLabel
                      : request.isEmergency
                          ? '$roleLabel - ${l10n.t('emergencyAssistance')}'
                          : '$roleLabel - ${request.category.localizedLabel(l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _chatRepository,
                builder: (context, _) {
                  final thread = _chatRepository.getThreadById(widget.threadId);
                  if (thread == null) {
                    return Center(child: Text(l10n.t('chatUnavailable')));
                  }
                  if (!_chatRepository.isParticipant(thread, currentUser.id)) {
                    return Center(child: Text(l10n.t('chatAccessDenied')));
                  }

                  final request =
                      _chatRepository.getRequestSnapshot(thread.requestId);
                  final messages = thread.messages;
                  if (!_initialScrollDone && messages.isNotEmpty) {
                    _initialScrollDone = true;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToLatest());
                  }

                  return Column(
                    children: [
                      if (request != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: ElderLinkTheme.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF152033).withOpacity(0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: request.category.bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  request.category.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.title,
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ElderLinkTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                  child: Text(
                                    request.isEmergency
                                      ? l10n.t('urgent')
                                      : _statusLabel(request.status),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ElderLinkTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: messages.isEmpty
                              ? const _ChatEmptyState(key: ValueKey('empty-chat'))
                              : ListView.builder(
                                  key: const ValueKey('chat-messages'),
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 18),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMine =
                                        message.senderId == currentUser.id;
                                    final showSpacing =
                                        index == 0 ||
                                        messages[index - 1].senderId !=
                                            message.senderId;

                                    return _AnimatedChatBubble(
                                      key: ValueKey(message.id),
                                      delay: Duration(milliseconds: index * 35),
                                      child: _ChatBubble(
                                        message: message,
                                        isMine: isMine,
                                        showTopSpacing: showSpacing,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: ElderLinkTheme.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF152033).withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ElderLinkTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: ElderLinkTheme.borderLight.withOpacity(0.9),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: l10n.t('typeMessage'),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: ElderLinkTheme.orange,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: ElderLinkTheme.orange.withOpacity(0.24),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _send,
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(RequestStatus status) {
    final l10n = context.l10n;
    switch (status) {
      case RequestStatus.pending:
        return l10n.t('pendingStatusTitle');
      case RequestStatus.accepted:
        return l10n.t('acceptedStatusTitle');
      case RequestStatus.inProgress:
        return l10n.t('inProgressStatusTitle');
      case RequestStatus.completed:
        return l10n.t('completedStatusTitle');
      case RequestStatus.cancelled:
        return l10n.t('cancelledStatusTitle');
    }
  }
}

class _AnimatedChatBubble extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedChatBubble({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTopSpacing;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.showTopSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine ? ElderLinkTheme.orange : Colors.white;
    final textColor = isMine ? Colors.white : ElderLinkTheme.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 8),
      bottomRight: Radius.circular(isMine ? 8 : 20),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: showTopSpacing ? 10 : 4,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              border: isMine
                  ? null
                  : Border.all(color: ElderLinkTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? ElderLinkTheme.orange.withOpacity(0.12)
                      : const Color(0xFF152033).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _formatTimestamp(context, message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ElderLinkTheme.textSecondary.withOpacity(0.9),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final l10n = AppLocalizations.of(context);
    final period =
        timestamp.hour >= 12 ? l10n.t('pmShort') : l10n.t('amShort');
    return '$hour:$minute $period';
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: ElderLinkTheme.orange,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.t('noMessagesYet'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('sendQuickUpdateStartConversation'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
