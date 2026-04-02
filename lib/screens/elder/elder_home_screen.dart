import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/help_request.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import '../../ui/language_selector.dart';
import '../shared/request_chat_thread_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'post_request_screen.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
//  ELDER HOME SCREEN
// ─────────────────────────────────────────────
class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen>
    with SingleTickerProviderStateMixin {
  late final RequestRepository _requestRepository;
  int _selectedNavIndex = 0;
  int _selectedTab = 0;
  int? _selectedMood;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'labelKey': 'moodHappy'},
    {'emoji': '😐', 'labelKey': 'moodOkay'},
    {'emoji': '😔', 'labelKey': 'moodSad'},
    {'emoji': '😴', 'labelKey': 'moodTired'},
  ];

  @override
  void initState() {
    super.initState();
    _requestRepository = RequestRepository.instance;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _currentElderId =>
      MockAuthService.instance.userForRole(UserRole.elder).id;

  List<HelpRequest> _filteredRequests(List<HelpRequest> requests) {
    switch (_selectedTab) {
      case 1:
        return requests
            .where((r) =>
                r.status == RequestStatus.pending ||
                r.status == RequestStatus.accepted ||
                r.status == RequestStatus.inProgress)
            .toList();
      case 2:
        return requests
            .where((r) => r.status == RequestStatus.completed)
            .toList();
      default:
        return requests;
    }
  }

  String get _syncLabel {
    final l10n = context.l10n;
    final syncedAt = _requestRepository.lastUpdatedAt;

    final difference = DateTime.now().difference(syncedAt);
    if (difference.inMinutes < 1) {
      return l10n.updatedJustNow();
    }
    if (difference.inHours < 1) {
      return l10n.updatedMinutesAgo(difference.inMinutes);
    }
    return l10n.updatedHoursAgo(difference.inHours);
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Center(
                    child: Text('🆘', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.t('sendSosAlert'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ElderLinkTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('sendSosAlertSubtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnackbar(context.l10n.t('sosSent'), Colors.red);
                  },
                  child: Text(context.l10n.t('yesSendSos'),
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.t('cancel'))),
            ],
          ),
        ),
      ),
    );
  }

  void _showSosDialogV2() {
    showDialog(
      context: context,
      builder: (_) => _SosDialog(
        onConfirm: _handleSosConfirm,
      ),
    );
  }

  Future<void> _handleSosConfirm() async {
    final l10n = context.l10n;
    final request = await _requestRepository.triggerSos(
      locationLabel: 'Baner, Pune - ${l10n.t('locationSharedWithVolunteer')}',
    );
    if (!mounted || request == null) return;

    _showSnackbar(
      '${l10n.t('emergencyAlertSentTitle')} - ${l10n.t('volunteerOnWay')}',
      Colors.red,
    );

    final volunteerId = request.volunteerId;
    if (volunteerId == null) return;
    final thread = ChatRepository.instance.getOrCreateThreadForRequest(
      requestId: request.id,
      elderId: request.elderId,
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

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      body: _buildCurrentScreen(),
      floatingActionButton: _selectedNavIndex == 0 ? _buildFab() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedNavIndex) {
      case 1:
        return const ChatScreen(embedded: true);
      case 2:
        return const HistoryScreen(embedded: true);
      case 3:
        return const ProfileScreen(embedded: true);
      default:
        return AnimatedBuilder(
          animation: _requestRepository,
          builder: (context, _) {
            final requests =
                _requestRepository.getElderRequestsSnapshot(_currentElderId);
            final filteredRequests = _filteredRequests(requests);

            return RefreshIndicator(
              color: ElderLinkTheme.orange,
              onRefresh: () async => setState(() {}),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHero()),
                      SliverToBoxAdapter(child: _buildSummaryCard(requests)),
                      SliverToBoxAdapter(child: _buildTabRow()),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            if (i >= filteredRequests.length) return null;
                            return _RequestCard(
                              request: filteredRequests[i],
                              onTap: () =>
                                  _showDetailSheet(filteredRequests[i]),
                            );
                          },
                          childCount: filteredRequests.length,
                        ),
                      ),
                      if (filteredRequests.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyState()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ElderLinkTheme.orange, ElderLinkTheme.orangeLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.t('goodMorning'),
                          style:
                              TextStyle(fontSize: 13, color: Colors.white70)),
                      SizedBox(height: 2),
                      const Text('Ganesh Jagtap 👋',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text(_syncLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.78))),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageSelectorButton(
                        compact: true,
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.18),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.t('howFeelingToday'),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          _moods.length,
                          (i) => GestureDetector(
                            onTap: () {
                              setState(() => _selectedMood = i);
                              _showSnackbar(
                                  context.l10n.moodLogged(
                                    _moods[i]['emoji']!,
                                    context.l10n.t(_moods[i]['labelKey']!),
                                  ),
                                  ElderLinkTheme.orange);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _selectedMood == i
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_moods[i]['emoji']!,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSosDialogV2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🆘',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.t('sos'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: ElderLinkTheme.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<HelpRequest> requests) {
    final activeCount = requests
        .where((request) =>
            request.status == RequestStatus.pending ||
            request.status == RequestStatus.accepted ||
            request.status == RequestStatus.inProgress)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('📋', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.activeRequestsCount(activeCount),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textPrimary)),
                  SizedBox(height: 2),
                  Text(context.l10n.t('activeRequestsSyncedSubtitle'),
                      style: TextStyle(
                          fontSize: 12, color: ElderLinkTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(context.l10n.t('safe'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabRow() {
    final tabs = [
      context.l10n.t('all'),
      context.l10n.t('active'),
      context.l10n.t('completed'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(context.l10n.t('yourRequests'),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElderLinkTheme.textPrimary)),
          const Spacer(),
          ...List.generate(
            tabs.length,
            (i) => GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTab == i
                      ? ElderLinkTheme.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedTab == i
                        ? ElderLinkTheme.orange
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(tabs[i],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == i
                            ? Colors.white
                            : ElderLinkTheme.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      emoji: '🌟',
      title: context.l10n.t('noRequestsYet'),
      subtitle: context.l10n.t('postNewRequestHint'),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostRequestScreen()),
        );
      },
      backgroundColor: ElderLinkTheme.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(context.l10n.t('newRequestFab'),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      onTap: (index) => setState(() => _selectedNavIndex = index),
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: context.l10n.t('home')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: context.l10n.t('chat')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: context.l10n.t('history')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: context.l10n.t('profile')),
      ],
    );
  }

  void _showDetailSheet(HelpRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailSheet(
        request: request,
        onOpenChat: () => _openRequestChat(request),
        onRate: () => _showRatingSheet(request),
      ),
    );
  }

  void _openRequestChat(HelpRequest request) {
    final volunteerId = request.volunteerId;
    if (volunteerId == null) return;

    final thread = ChatRepository.instance.getOrCreateThreadForRequest(
      requestId: request.id,
      elderId: request.elderId,
      volunteerId: volunteerId,
    );
    if (thread == null) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestChatThreadScreen(threadId: thread.id),
      ),
    );
  }

  Future<void> _showRatingSheet(HelpRequest request) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RateVolunteerSheet(request: request),
    );
  }
}

// ─────────────────────────────────────────────
//  REQUEST CARD
// ─────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(16),
        border: Border.all(
          color: request.isEmergency
              ? const Color(0xFFFFB4A1)
              : ElderLinkTheme.borderLight,
          width: request.isEmergency ? 1.6 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.isEmergency) ...[
              AppEmergencyBadge(label: context.l10n.t('sosActive')),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                _CategoryPill(category: request.category),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade300, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(request.subtitle,
                style: const TextStyle(
                    fontSize: 12, color: ElderLinkTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusBadge(status: request.status),
                const Spacer(),
                if (request.volunteerName != null) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: request.volunteerColor,
                    child: Text(request.volunteerInitials ?? '',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Text(request.volunteerName!,
                      style: const TextStyle(
                          fontSize: 12, color: ElderLinkTheme.textSecondary)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATEGORY PILL
// ─────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  final RequestCategory category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return AppCategoryChip(category: category);
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  static Map<String, dynamic> _cfg(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return {
          'bg': const Color(0xFFFFF8E1),
          'text': const Color(0xFFF9A825),
          'label': '⏳ Finding volunteer'
        };
      case RequestStatus.accepted:
        return {
          'bg': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
          'label': '✓ Volunteer found'
        };
      case RequestStatus.inProgress:
        return {
          'bg': const Color(0xFFE3F2FD),
          'text': const Color(0xFF1565C0),
          'label': '🚶 On the way'
        };
      case RequestStatus.completed:
        return {
          'bg': const Color(0xFFE3F2FD),
          'text': const Color(0xFF1565C0),
          'label': '✓ Completed'
        };
      case RequestStatus.cancelled:
        return {
          'bg': const Color(0xFFFCEBEB),
          'text': const Color(0xFFA32D2D),
          'label': '✕ Cancelled'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppRequestStatusChip(status: status);
  }
}

// ─────────────────────────────────────────────
//  REQUEST DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _RequestDetailSheet extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onOpenChat;
  final VoidCallback onRate;

  const _RequestDetailSheet({
    required this.request,
    required this.onOpenChat,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 20),
          _CategoryPill(category: request.category),
          const SizedBox(height: 12),
          Text(request.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElderLinkTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(request.subtitle,
              style: const TextStyle(
                  fontSize: 13, color: ElderLinkTheme.textSecondary)),
          const SizedBox(height: 16),
          _StatusBadge(status: request.status),
          if (request.volunteerName != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(context.l10n.t('assignedVolunteer'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: request.volunteerColor,
                  child: Text(request.volunteerInitials ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.volunteerName!,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ElderLinkTheme.textPrimary)),
                    Text(
                      '⭐ 4.9 ${context.l10n.t('rating')} · 24 ${context.l10n.t('tasksDone').toLowerCase()}',
                      style: const TextStyle(
                          fontSize: 12, color: ElderLinkTheme.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: onOpenChat,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: ElderLinkTheme.purple,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (request.status == RequestStatus.completed) {
                  Navigator.pop(context);
                  onRate();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(request.status == RequestStatus.completed
                  ? context.l10n.t('rateVolunteer')
                  : context.l10n.t('close')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const _SosDialog({required this.onConfirm});

  @override
  State<_SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<_SosDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    Navigator.pop(context);
    await widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final scale = 0.96 + (_controller.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red
                              .withOpacity(0.16 + (_controller.value * 0.12)),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              l10n.t('emergencyAlertSentTitle'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ElderLinkTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('emergencyAlertSentBody'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ElderLinkTheme.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('whatHappensNext'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• ${l10n.t('emergencyRequestCreated')}',
                    style: const TextStyle(
                        fontSize: 13, color: ElderLinkTheme.textPrimary),
                  ),
                  Text(
                    '• ${l10n.t('volunteerAssignedImmediately')}',
                    style: const TextStyle(
                        fontSize: 13, color: ElderLinkTheme.textPrimary),
                  ),
                  Text(
                    '• ${l10n.t('locationSharedWithVolunteer')}',
                    style: const TextStyle(
                        fontSize: 13, color: ElderLinkTheme.textPrimary),
                  ),
                  Text(
                    '• ${l10n.t('emergencyChatOpensAutomatically')}',
                    style: const TextStyle(
                        fontSize: 13, color: ElderLinkTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.t('sendEmergencyAlert')),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              child: Text(l10n.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateVolunteerSheet extends StatefulWidget {
  final HelpRequest request;

  const _RateVolunteerSheet({required this.request});

  @override
  State<_RateVolunteerSheet> createState() => _RateVolunteerSheetState();
}

class _RateVolunteerSheetState extends State<_RateVolunteerSheet> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await RequestRepository.instance.submitVolunteerRating(
      requestId: widget.request.id,
      rating: _selectedRating,
      feedback: _feedbackController.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ElderLinkTheme.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Text(
          context.l10n.t('thankYouForRating'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AppBottomSheetScaffold(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBottomSheetHandle(),
            const SizedBox(height: 20),
            Text(
              l10n.format('rateNamedVolunteer', {
                'name': widget.request.volunteerName ?? l10n.t('volunteerRole'),
              }),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = star),
                  icon: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: ElderLinkTheme.orange,
                    size: 34,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.t('shareShortNoteOptional'),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.t('submitRating')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

