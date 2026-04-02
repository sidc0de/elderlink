import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import 'family_messages_screen.dart';
import 'family_settings_screen.dart';
import 'family_timeline_screen.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
class MoodEntry {
  final String day;
  final String emoji;
  final String label;
  final bool logged;

  const MoodEntry({
    required this.day,
    required this.emoji,
    required this.label,
    required this.logged,
  });
}

class ActivityEntry {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String timeAgo;
  final ActivityType type;

  const ActivityEntry({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
  });
}

enum ActivityType { taskCompleted, taskAccepted, sos, moodLogged, chat }

class LinkedElder {
  final String name;
  final String initials;
  final Color color;
  final String location;
  final String lastActive;
  final bool isOnline;
  final int activeRequests;
  final int completedTotal;

  const LinkedElder({
    required this.name,
    required this.initials,
    required this.color,
    required this.location,
    required this.lastActive,
    required this.isOnline,
    required this.activeRequests,
    required this.completedTotal,
  });
}

// ─────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────
const _elder = LinkedElder(
  name: 'Sunita Deshpande',
  initials: 'SD',
  color: ElderLinkTheme.orange,
  location: 'Baner, Pune',
  lastActive: '10 min ago',
  isOnline: true,
  activeRequests: 2,
  completedTotal: 14,
);

const List<MoodEntry> _moodWeek = [
  MoodEntry(day: 'Mon', emoji: '😊', label: 'Happy', logged: true),
  MoodEntry(day: 'Tue', emoji: '😴', label: 'Tired', logged: true),
  MoodEntry(day: 'Wed', emoji: '😊', label: 'Happy', logged: true),
  MoodEntry(day: 'Thu', emoji: '😐', label: 'Okay', logged: true),
  MoodEntry(day: 'Fri', emoji: '😊', label: 'Happy', logged: true),
  MoodEntry(day: 'Sat', emoji: '—', label: 'Not logged', logged: false),
  MoodEntry(day: 'Sun', emoji: '—', label: 'Not logged', logged: false),
];

final List<ActivityEntry> _activities = [
  ActivityEntry(
    icon: '✅',
    iconBg: const Color(0xFFEDFAF3),
    title: 'Medicine pickup completed',
    subtitle: 'Rohit Kumar · Apollo Pharmacy, Baner',
    timeAgo: '2 hours ago',
    type: ActivityType.taskCompleted,
  ),
  ActivityEntry(
    icon: '🙋',
    iconBg: const Color(0xFFF3EEFF),
    title: 'Volunteer accepted request',
    subtitle: 'Ananya P. will bring vegetables today',
    timeAgo: 'This morning',
    type: ActivityType.taskAccepted,
  ),
  ActivityEntry(
    icon: '😊',
    iconBg: const Color(0xFFFFF5F2),
    title: 'Mood check-in logged',
    subtitle: 'Feeling happy today',
    timeAgo: 'Today, 9:15 AM',
    type: ActivityType.moodLogged,
  ),
  ActivityEntry(
    icon: '✅',
    iconBg: const Color(0xFFEDFAF3),
    title: 'Grocery errand completed',
    subtitle: 'Ananya P. · Rated 5 stars',
    timeAgo: 'Yesterday',
    type: ActivityType.taskCompleted,
  ),
  ActivityEntry(
    icon: '🚗',
    iconBg: const Color(0xFFE3F2FD),
    title: 'Doctor visit transport done',
    subtitle: 'Ruby Hall Clinic · Successful',
    timeAgo: '2 days ago',
    type: ActivityType.taskCompleted,
  ),
  ActivityEntry(
    icon: '😐',
    iconBg: const Color(0xFFFFF8E1),
    title: 'Mood check-in logged',
    subtitle: 'Feeling okay',
    timeAgo: '2 days ago, 8:50 AM',
    type: ActivityType.moodLogged,
  ),
  ActivityEntry(
    icon: '💬',
    iconBg: const Color(0xFFF0F4FF),
    title: 'Chat with volunteer',
    subtitle: 'Rohit Kumar · 12 messages',
    timeAgo: '3 days ago',
    type: ActivityType.chat,
  ),
];

// ─────────────────────────────────────────────
//  FAMILY HOME SCREEN
// ─────────────────────────────────────────────
class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with SingleTickerProviderStateMixin {
  late final RequestRepository _requestRepository;
  int _bottomNavIndex = 0;
  bool _alertDismissed = false;
  bool _isLoading = true;
  DateTime? _lastSyncedAt;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  LinkedElder _elderData = _elder;
  List<MoodEntry> _moodData = _moodWeek;
  List<ActivityEntry> _activityData = _activities;

  @override
  void initState() {
    super.initState();
    _requestRepository = RequestRepository.instance;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _requestRepository.addListener(_handleRepositoryUpdate);
    _loadDashboard();
  }

  @override
  void dispose() {
    _requestRepository.removeListener(_handleRepositoryUpdate);
    _animController.dispose();
    super.dispose();
  }

  void _handleRepositoryUpdate() {
    if (!mounted) return;
    _loadDashboard();
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await MockAuthService.instance.signInAs(UserRole.family);
    final response = await DashboardRepository.instance.fetchFamilyDashboard();

    if (!mounted) return;
    setState(() {
      _elderData = LinkedElder(
        name: response.elder.name,
        initials: response.elder.initials,
        color: response.elder.color,
        location: response.elder.location,
        lastActive: response.elder.lastActive,
        isOnline: response.elder.isOnline,
        activeRequests: response.elder.activeRequests,
        completedTotal: response.elder.completedTotal,
      );
      _moodData = response.moods
          .map(
            (entry) => MoodEntry(
              day: entry.day,
              emoji: entry.emoji,
              label: entry.label,
              logged: entry.logged,
            ),
          )
          .toList();
      _activityData = response.activities
          .map(
            (entry) => ActivityEntry(
              icon: entry.icon,
              iconBg: entry.iconBg,
              title: entry.title,
              subtitle: entry.subtitle,
              timeAgo: entry.timeAgo,
              type: ActivityType.values.firstWhere(
                (value) => value.name == entry.type.name,
                orElse: () => ActivityType.chat,
              ),
            ),
          )
          .toList();
      _lastSyncedAt = response.syncedAt;
      _isLoading = false;
    });
  }

  String get _syncLabel {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) return 'Syncing family updates...';

    final difference = DateTime.now().difference(syncedAt);
    if (difference.inMinutes < 1) return 'Updated just now';
    if (difference.inHours < 1)
      return 'Updated ${difference.inMinutes} min ago';
    return 'Updated ${difference.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      body: _bottomNavIndex == 0 && _isLoading
          ? _buildLoadingState()
          : _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_bottomNavIndex) {
      case 1:
        return const FamilyTimelineScreen(embedded: true);
      case 2:
        return const FamilyMessagesScreen(embedded: true);
      case 3:
        return const FamilySettingsScreen(embedded: true);
      default:
        return RefreshIndicator(
          color: ElderLinkTheme.deepBlue,
          onRefresh: _loadDashboard,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildElderCard()),
                  SliverToBoxAdapter(child: _buildStatsRow()),
                  if (!_alertDismissed)
                    SliverToBoxAdapter(child: _buildAlertBanner()),
                  SliverToBoxAdapter(child: _buildMoodSection()),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  SliverToBoxAdapter(child: _buildActivityHeader()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ActivityCard(activity: _activityData[i]),
                      childCount: _activityData.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildLoadingState() {
    return AppLoadingState(
      color: ElderLinkTheme.deepBlue,
      message: context.l10n.t('familyDashboard'),
    );
  }

  // ── Dark navy hero ──
  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ElderLinkTheme.darkNavy,
            ElderLinkTheme.deepBlue,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Family Dashboard',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.65))),
                  const SizedBox(height: 3),
                  const Text('Arjun Deshpande',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_syncLabel,
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withOpacity(0.78))),
                ],
              ),
              const Spacer(),
              // Notification bell
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
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
                          color: ElderLinkTheme.orange, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Add elder button
              GestureDetector(
                onTap: () => _showSnackbar('➕ Add another elder — coming soon!',
                    ElderLinkTheme.deepBlue),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Elder profile card ──
  Widget _buildElderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _elderData.color.withOpacity(0.15),
                child: Text(_elderData.initials,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _elderData.color)),
              ),
              if (_elderData.isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: ElderLinkTheme.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_elderData.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ElderLinkTheme.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: ElderLinkTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text(_elderData.location,
                        style: const TextStyle(
                            fontSize: 12, color: ElderLinkTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: ElderLinkTheme.textSecondary,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text('Active ${_elderData.lastActive}',
                        style: const TextStyle(
                            fontSize: 12, color: ElderLinkTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _elderData.isOnline
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _elderData.isOnline ? '● Online' : '● Away',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    _elderData.isOnline ? const Color(0xFF2E7D32) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatCard(
            value: '${_elderData.activeRequests}',
            label: 'Active',
            sublabel: 'requests',
            iconEmoji: '📋',
            bgColor: const Color(0xFFFFF5F2),
            valueColor: ElderLinkTheme.orange,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: '${_elderData.completedTotal}',
            label: 'Completed',
            sublabel: 'all time',
            iconEmoji: '✅',
            bgColor: const Color(0xFFEDFAF3),
            valueColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: '5/7',
            label: 'Mood',
            sublabel: 'check-ins',
            iconEmoji: '😊',
            bgColor: const Color(0xFFF3EEFF),
            valueColor: ElderLinkTheme.purple,
          ),
        ],
      ),
    );
  }

  // ── Alert banner ──
  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD5C8), width: 1),
      ),
      child: Row(
        children: [
          const Text('💊', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medicine pickup confirmed',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElderLinkTheme.orange)),
                SizedBox(height: 2),
                Text('Rohit Kumar accepted · Arriving at 11 AM today',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC0693A))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _alertDismissed = true),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFFC0693A)),
          ),
        ],
      ),
    );
  }

  // ── Mood section ──
  Widget _buildMoodSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('This week\'s mood',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ElderLinkTheme.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showMoodHistorySheet(),
                child: const Text('View history',
                    style: TextStyle(
                        fontSize: 12,
                        color: ElderLinkTheme.orange,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day-by-day mood row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moodData.map((m) {
              return Expanded(
                child: GestureDetector(
                  onTap: m.logged
                      ? () => _showSnackbar('${m.emoji} ${m.day}: ${m.label}',
                          ElderLinkTheme.orange)
                      : null,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: m.logged
                              ? const Color(0xFFFFF5F2)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            m.logged ? m.emoji : '—',
                            style: TextStyle(
                                fontSize: m.logged ? 18 : 14,
                                color: m.logged ? null : Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(m.day,
                          style: const TextStyle(
                              fontSize: 10,
                              color: ElderLinkTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Mood summary bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('5 of 7 days logged · ',
                    style: TextStyle(
                        fontSize: 12, color: ElderLinkTheme.textSecondary)),
                const Text('Mostly happy this week 😊',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElderLinkTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ──
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _QuickActionBtn(
            emoji: '📞',
            label: 'Call Mum',
            color: const Color(0xFFEDFAF3),
            textColor: const Color(0xFF2E7D32),
            onTap: () =>
                _showSnackbar('📞 Calling Sunita...', ElderLinkTheme.green),
          ),
          const SizedBox(width: 10),
          _QuickActionBtn(
            emoji: '💬',
            label: 'Send Note',
            color: const Color(0xFFF3EEFF),
            textColor: ElderLinkTheme.purple,
            onTap: () => _showSendNoteSheet(),
          ),
          const SizedBox(width: 10),
          _QuickActionBtn(
            emoji: '📋',
            label: 'New Request',
            color: const Color(0xFFFFF5F2),
            textColor: ElderLinkTheme.orange,
            onTap: () => _showSnackbar(
                '📋 Posting on behalf — coming soon!', ElderLinkTheme.orange),
          ),
        ],
      ),
    );
  }

  // ── Activity header ──
  Widget _buildActivityHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          const Text('Recent Activity',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElderLinkTheme.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSnackbar(
                '📜 Full history — coming soon!', ElderLinkTheme.purple),
            child: const Text('See all',
                style: TextStyle(
                    fontSize: 12,
                    color: ElderLinkTheme.orange,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (i) => setState(() => _bottomNavIndex = i),
      selectedItemColor: ElderLinkTheme.deepBlue,
      unselectedItemColor: ElderLinkTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.timeline_rounded), label: 'Timeline'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Messages'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }

  // ── Mood history sheet ──
  void _showMoodHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MoodHistorySheet(),
    );
  }

  // ── Send note sheet ──
  void _showSendNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendNoteSheet(
        onSend: (msg) {
          Navigator.pop(context);
          _showSnackbar('💬 Note sent to Sunita!', ElderLinkTheme.purple);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final String iconEmoji;
  final Color bgColor;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.iconEmoji,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(iconEmoji, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valueColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textPrimary)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 10, color: ElderLinkTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK ACTION BUTTON
// ─────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACTIVITY CARD
// ─────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final ActivityEntry activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: activity.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child:
                    Text(activity.icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElderLinkTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(activity.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: ElderLinkTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(activity.timeAgo,
              style: const TextStyle(
                  fontSize: 10, color: ElderLinkTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOOD HISTORY SHEET
// ─────────────────────────────────────────────
class _MoodHistorySheet extends StatelessWidget {
  const _MoodHistorySheet();

  static const List<Map<String, dynamic>> _history = [
    {
      'week': 'This week',
      'moods': ['😊', '😴', '😊', '😐', '😊', '—', '—']
    },
    {
      'week': 'Last week',
      'moods': ['😔', '😊', '😊', '😊', '😴', '😊', '😐']
    },
    {
      'week': '2 weeks ago',
      'moods': ['😊', '😊', '😔', '😊', '😊', '😊', '😴']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Mood History',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ElderLinkTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Sunita\'s mood over the past weeks',
              style:
                  TextStyle(fontSize: 13, color: ElderLinkTheme.textSecondary)),
          const SizedBox(height: 20),
          ..._history.map((h) {
            final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            final moods = h['moods'] as List<String>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h['week'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final logged = moods[i] != '—';
                      return Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: logged
                                  ? const Color(0xFFFFF5F2)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                moods[i],
                                style: TextStyle(
                                    fontSize: logged ? 18 : 14,
                                    color:
                                        logged ? null : Colors.grey.shade400),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(days[i],
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: ElderLinkTheme.textSecondary)),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sunita seems happiest on weekdays. Consider scheduling social calls on weekends.',
                    style: TextStyle(
                        fontSize: 12,
                        color: ElderLinkTheme.purple,
                        height: 1.5),
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

// ─────────────────────────────────────────────
//  SEND NOTE SHEET
// ─────────────────────────────────────────────
class _SendNoteSheet extends StatefulWidget {
  final ValueChanged<String> onSend;

  const _SendNoteSheet({required this.onSend});

  @override
  State<_SendNoteSheet> createState() => _SendNoteSheetState();
}

class _SendNoteSheetState extends State<_SendNoteSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _quickNotes = [
    '❤️ Thinking of you!',
    '📞 I\'ll call you tonight.',
    '🍱 Eat your lunch!',
    '💊 Don\'t forget medicines.',
    '😊 Hope you\'re doing well!',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Send a note to Mum',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ElderLinkTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('She\'ll see it as a notification on her phone',
                style: TextStyle(
                    fontSize: 13, color: ElderLinkTheme.textSecondary)),
            const SizedBox(height: 16),

            // Quick notes
            const Text('Quick messages',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickNotes.map((n) {
                return GestureDetector(
                  onTap: () => setState(() => _ctrl.text = n),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(n,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ElderLinkTheme.purple)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Custom message
            const Text('Or type a custom message',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(
                  fontSize: 14, color: ElderLinkTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write something kind...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: ElderLinkTheme.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF8F9FC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: ElderLinkTheme.purple, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_ctrl.text.trim().isNotEmpty) {
                    widget.onSend(_ctrl.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElderLinkTheme.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Send Note 💜',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
