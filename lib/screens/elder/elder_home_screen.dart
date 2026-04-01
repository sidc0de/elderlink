import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/help_request.dart';
import '../../repositories/dashboard_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import '../../ui/language_selector.dart';
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
  int _selectedNavIndex = 0;
  int _selectedTab = 0;
  int? _selectedMood;
  bool _isLoading = true;
  DateTime? _lastSyncedAt;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  List<HelpRequest> _requests = [];

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Tired'},
  ];

  @override
  void initState() {
    super.initState();
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
    _loadDashboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<HelpRequest> get _filteredRequests {
    switch (_selectedTab) {
      case 1:
        return _requests
            .where((r) =>
                r.status == RequestStatus.pending ||
                r.status == RequestStatus.accepted ||
                r.status == RequestStatus.inProgress)
            .toList();
      case 2:
        return _requests
            .where((r) => r.status == RequestStatus.completed)
            .toList();
      default:
        return _requests;
    }
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await MockAuthService.instance.signInAs(UserRole.elder);
    final response = await DashboardRepository.instance.fetchElderDashboard();

    if (!mounted) return;
    setState(() {
      _requests = response.requests;
      _lastSyncedAt = response.syncedAt;
      _isLoading = false;
    });
  }

  String get _syncLabel {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) return 'Syncing updates...';

    final difference = DateTime.now().difference(syncedAt);
    if (difference.inMinutes < 1) {
      return 'Updated just now';
    }
    if (difference.inHours < 1) {
      return 'Updated ${difference.inMinutes} min ago';
    }
    return 'Updated ${difference.inHours}h ago';
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
      body: _selectedNavIndex == 0 && _isLoading
          ? _buildLoadingState()
          : _buildCurrentScreen(),
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
        return RefreshIndicator(
          color: ElderLinkTheme.orange,
          onRefresh: _loadDashboard,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildSummaryCard()),
                  SliverToBoxAdapter(child: _buildTabRow()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final list = _filteredRequests;
                        if (i >= list.length) return null;
                        return _RequestCard(
                          request: list[i],
                          onTap: () => _showDetailSheet(list[i]),
                        );
                      },
                      childCount: _filteredRequests.length,
                    ),
                  ),
                  if (_filteredRequests.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildLoadingState() {
    return AppLoadingState(
      color: ElderLinkTheme.orange,
      message: context.l10n.t('fetchingLatestRequests'),
    );
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
                      const Text('Sunita Deshpande 👋',
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
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 22),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: ElderLinkTheme.darkNavy,
                                  shape: BoxShape.circle),
                            ),
                          ),
                        ],
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
                                  '${_moods[i]['emoji']} Mood logged: ${_moods[i]['label']}',
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
                    onTap: _showSosDialog,
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🆘', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text('SOS',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: ElderLinkTheme.orange)),
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

  Widget _buildSummaryCard() {
    final activeCount = _requests
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
                  Text('$activeCount active requests',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textPrimary)),
                  SizedBox(height: 2),
                  Text('Live status synced from your care network',
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
        if (mounted) {
          await _loadDashboard();
        }
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
      builder: (_) => _RequestDetailSheet(request: request),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
  const _RequestDetailSheet({required this.request});

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
            const Text('Assigned Volunteer',
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
                    const Text('⭐ 4.9 rating · 24 tasks done',
                        style: TextStyle(
                            fontSize: 12, color: ElderLinkTheme.textSecondary)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: ElderLinkTheme.purple, size: 20),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (request.status == RequestStatus.completed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ElderLinkTheme.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      content: const Text('⭐ Thank you for rating!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }
              },
              child: Text(request.status == RequestStatus.completed
                  ? '⭐ Rate Volunteer'
                  : 'Close'),
            ),
          ),
        ],
      ),
    );
  }
}
