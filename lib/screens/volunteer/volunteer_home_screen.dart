import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';
import 'volunteer_badges_screen.dart';
import 'volunteer_my_tasks_screen.dart';
import 'volunteer_profile_screen.dart';

// ─────────────────────────────────────────────
//  VOLUNTEER TASK MODEL
// ─────────────────────────────────────────────
class VolunteerTask {
  final String id;
  final String elderName;
  final String elderInitials;
  final Color elderColor;
  final double elderRating;
  final int elderTotalRequests;
  final RequestCategory category;
  final String title;
  final String description;
  final String timeLabel;
  final double distanceKm;
  final bool isUrgent;

  const VolunteerTask({
    required this.id,
    required this.elderName,
    required this.elderInitials,
    required this.elderColor,
    required this.elderRating,
    required this.elderTotalRequests,
    required this.category,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.distanceKm,
    this.isUrgent = false,
  });
}

// ─────────────────────────────────────────────
//  MOCK TASKS
// ─────────────────────────────────────────────
final List<VolunteerTask> _allTasks = [
  VolunteerTask(
    id: '1',
    elderName: 'Sunita Deshpande',
    elderInitials: 'SD',
    elderColor: const Color(0xFFFF6B35),
    elderRating: 4.8,
    elderTotalRequests: 12,
    category: RequestCategory.companionship,
    title: 'Evening walk & conversation',
    description:
        'Looking for a friendly companion for a 45-min walk at the society garden. I enjoy talking about books and gardening.',
    timeLabel: 'Today, 5:00 PM',
    distanceKm: 0.8,
    isUrgent: false,
  ),
  VolunteerTask(
    id: '2',
    elderName: 'Ramesh Joshi',
    elderInitials: 'RJ',
    elderColor: const Color(0xFF7C5CBF),
    elderRating: 4.6,
    elderTotalRequests: 8,
    category: RequestCategory.grocery,
    title: 'Buy vegetables from market',
    description:
        'Need 1kg tomatoes, onions, and green chillies from the local sabzi mandi. Money will be given at delivery.',
    timeLabel: 'Today, 10:00 AM',
    distanceKm: 1.2,
    isUrgent: true,
  ),
  VolunteerTask(
    id: '3',
    elderName: 'Meera Kulkarni',
    elderInitials: 'MK',
    elderColor: const Color(0xFF1565C0),
    elderRating: 5.0,
    elderTotalRequests: 20,
    category: RequestCategory.transport,
    title: 'Doctor appointment drop & pick',
    description:
        'Need a ride to Ruby Hall Clinic and back. Appointment at 3 PM. I can manage the stairs myself, just need transport.',
    timeLabel: 'Today, 2:30 PM',
    distanceKm: 2.1,
    isUrgent: false,
  ),
  VolunteerTask(
    id: '4',
    elderName: 'Prakash Nair',
    elderInitials: 'PN',
    elderColor: const Color(0xFF2ECC71),
    elderRating: 4.5,
    elderTotalRequests: 5,
    category: RequestCategory.medicine,
    title: 'Collect BP medicines from Apollo',
    description:
        'Prescription is ready. Please collect from Apollo Pharmacy, Baner Road. Cost will be reimbursed immediately.',
    timeLabel: 'Today, 11:00 AM',
    distanceKm: 0.5,
    isUrgent: true,
  ),
  VolunteerTask(
    id: '5',
    elderName: 'Lata Sharma',
    elderInitials: 'LS',
    elderColor: const Color(0xFFD4537E),
    elderRating: 4.9,
    elderTotalRequests: 15,
    category: RequestCategory.errand,
    title: 'Pay electricity bill at MSEDCL',
    description:
        'Need someone to pay the monthly electricity bill at the MSEDCL office on FC Road. Will give cash + extra for help.',
    timeLabel: 'Tomorrow, 10:00 AM',
    distanceKm: 1.8,
  ),
];

// ─────────────────────────────────────────────
//  VOLUNTEER HOME SCREEN
// ─────────────────────────────────────────────
class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen>
    with SingleTickerProviderStateMixin {
  RequestCategory? _activeFilter;
  int _bottomNavIndex = 0;
  String _sortBy = 'distance'; // 'distance' | 'time' | 'urgent'
  bool _isLoading = true;
  DateTime? _lastSyncedAt;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  List<VolunteerTask> _remoteTasks = [];

  @override
  void initState() {
    super.initState();
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
    _loadDashboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<VolunteerTask> get _filteredTasks {
    var tasks = _remoteTasks.toList();
    if (_activeFilter != null) {
      tasks = tasks.where((t) => t.category == _activeFilter).toList();
    }
    switch (_sortBy) {
      case 'distance':
        tasks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case 'time':
        tasks.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
        break;
      case 'urgent':
        tasks
            .sort((a, b) => (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0));
        break;
    }
    return tasks;
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await MockAuthService.instance.signInAs(UserRole.volunteer);
    final response = await DashboardRepository.instance.fetchVolunteerDashboard();
    final tasks = response.tasks.map(_taskFromHelpRequest).toList();

    if (!mounted) return;
    setState(() {
      _remoteTasks = tasks;
      _lastSyncedAt = response.syncedAt;
      _isLoading = false;
    });
  }

  VolunteerTask _taskFromHelpRequest(dynamic request) {
    return VolunteerTask(
      id: request.id as String,
      elderName: request.elderName as String,
      elderInitials: request.elderInitials as String,
      elderColor: request.elderColor as Color,
      elderRating: request.elderRating as double,
      elderTotalRequests: request.elderTotalRequests as int,
      category: request.category as RequestCategory,
      title: request.title as String,
      description: request.description as String,
      timeLabel: request.timeLabel as String,
      distanceKm: request.distanceKm as double,
      isUrgent: request.isUrgent as bool,
    );
  }

  String get _syncLabel {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) return 'Syncing nearby requests...';

    final difference = DateTime.now().difference(syncedAt);
    if (difference.inMinutes < 1) return 'Updated just now';
    if (difference.inHours < 1)
      return 'Updated ${difference.inMinutes} min ago';
    return 'Updated ${difference.inHours}h ago';
  }

  Future<void> _confirmAccept(VolunteerTask task) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ElderLinkTheme.deepBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        content: const Text(
          'Reserving task on server...',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
    await RequestRepository.instance.acceptRequest(task.id);
    if (!mounted) return;
    await _loadDashboard();
    _showAcceptSnackbar(task);
  }

  void _onAccept(VolunteerTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcceptSheet(
        task: task,
        onConfirm: () {
          _confirmAccept(task);
        },
      ),
    );
  }

  void _showAcceptSnackbar(VolunteerTask task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ElderLinkTheme.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You accepted: ${task.title}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sortBy,
        onSelect: (val) {
          setState(() => _sortBy = val);
          Navigator.pop(context);
        },
      ),
    );
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
        return const VolunteerMyTasksScreen(embedded: true);
      case 2:
        return const VolunteerBadgesScreen(embedded: true);
      case 3:
        return const VolunteerProfileScreen(embedded: true);
      default:
        return RefreshIndicator(
          color: ElderLinkTheme.purple,
          onRefresh: _loadDashboard,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildFilterRow()),
                  SliverToBoxAdapter(child: _buildSortRow()),
                  if (_filteredTasks.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TaskCard(
                          task: _filteredTasks[i],
                          onAccept: () => _onAccept(_filteredTasks[i]),
                          onTap: () => _showTaskDetail(_filteredTasks[i]),
                        ),
                        childCount: _filteredTasks.length,
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
      color: ElderLinkTheme.purple,
      message: context.l10n.t('findNearbyRequests'),
    );
  }

  // ── Purple gradient hero ──
  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ElderLinkTheme.purple, ElderLinkTheme.purpleLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 2),
                      const Text('Rohit Kumar 🌟',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_syncLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.78))),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
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
                              color: ElderLinkTheme.orange,
                              shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stats row
              Row(
                children: [
                  _StatBox(value: '24', label: 'Tasks done'),
                  const SizedBox(width: 10),
                  _StatBox(value: '4.9 ⭐', label: 'Rating'),
                  const SizedBox(width: 10),
                  _StatBox(value: '🥇', label: 'Top helper'),
                ],
              ),

              const SizedBox(height: 16),

              // Radius indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Showing requests within 2.5 km',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text('Change',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category filter chips ──
  Widget _buildFilterRow() {
    final categories = [null, ...RequestCategory.values];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = _activeFilter == cat;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? (cat == null ? ElderLinkTheme.purple : cat.color)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? (cat == null ? ElderLinkTheme.purple : cat.color)
                      : const Color(0xFFE8E8E8),
                  width: 1.5,
                ),
                boxShadow: isActive ? [] : AppConstants.cardShadow,
              ),
              child: Text(
                cat == null ? 'All' : '${cat.emoji} ${cat.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : ElderLinkTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sort + count row ──
  Widget _buildSortRow() {
    final count = _filteredTasks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Text(
            '$count request${count != 1 ? 's' : ''} near you',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ElderLinkTheme.textPrimary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 16, color: ElderLinkTheme.purple),
                  const SizedBox(width: 6),
                  Text(
                    _sortLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElderLinkTheme.purple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'distance':
        return 'Nearest first';
      case 'time':
        return 'Soonest first';
      case 'urgent':
        return 'Urgent first';
      default:
        return 'Sort';
    }
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      emoji: '🔍',
      title: context.l10n.t('noCategoryRequestsTitle'),
      subtitle: context.l10n.t('noCategoryRequestsSubtitle'),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (i) => setState(() => _bottomNavIndex = i),
      selectedItemColor: ElderLinkTheme.purple,
      unselectedItemColor: ElderLinkTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), label: 'Nearby'),
        BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded), label: 'My Tasks'),
        BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined), label: 'Badges'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
      ],
    );
  }

  void _showTaskDetail(VolunteerTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(
        task: task,
        onAccept: () {
          Navigator.pop(context);
          _onAccept(task);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT BOX (hero)
// ─────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TASK CARD
// ─────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final VolunteerTask task;
  final VoidCallback onAccept;
  final VoidCallback onTap;

  const _TaskCard(
      {required this.task, required this.onAccept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppConstants.cardShadow,
          border: task.isUrgent
              ? Border.all(color: const Color(0xFFFF6B35), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgent banner
            if (task.isUrgent)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5F2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: const Row(
                  children: [
                    Text('🚨', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Text('Urgent request',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ElderLinkTheme.orange)),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Elder info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: task.elderColor.withOpacity(0.15),
                        child: Text(
                          task.elderInitials,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: task.elderColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.elderName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ElderLinkTheme.textPrimary)),
                          Text(
                              '⭐ ${task.elderRating} · ${task.elderTotalRequests} requests',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: ElderLinkTheme.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      _DistanceBadge(km: task.distanceKm),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Category pill
                  _CategoryPill(category: task.category),

                  const SizedBox(height: 8),

                  // Task title
                  Text(task.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textPrimary)),

                  const SizedBox(height: 4),

                  // Description (truncated)
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: ElderLinkTheme.textSecondary,
                        height: 1.5),
                  ),

                  const SizedBox(height: 12),

                  // Footer: time + accept btn
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: ElderLinkTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(task.timeLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color: ElderLinkTheme.textSecondary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onAccept,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: ElderLinkTheme.purple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DISTANCE BADGE
// ─────────────────────────────────────────────
class _DistanceBadge extends StatelessWidget {
  final double km;
  const _DistanceBadge({required this.km});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${km.toStringAsFixed(1)} km',
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ElderLinkTheme.purple),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: category.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${category.emoji} ${category.label}',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: category.color)),
    );
  }
}

// ─────────────────────────────────────────────
//  TASK DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _TaskDetailSheet extends StatelessWidget {
  final VolunteerTask task;
  final VoidCallback onAccept;

  const _TaskDetailSheet({required this.task, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  // Elder profile card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ElderLinkTheme.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: task.elderColor.withOpacity(0.15),
                          child: Text(task.elderInitials,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: task.elderColor)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.elderName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ElderLinkTheme.textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                                '⭐ ${task.elderRating}  ·  ${task.elderTotalRequests} past requests',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: ElderLinkTheme.textSecondary)),
                          ],
                        ),
                        const Spacer(),
                        if (task.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('🚨 Urgent',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ElderLinkTheme.orange)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _CategoryPill(category: task.category),
                  const SizedBox(height: 10),

                  Text(task.title,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: ElderLinkTheme.textPrimary)),

                  const SizedBox(height: 10),
                  Text(task.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: ElderLinkTheme.textSecondary,
                          height: 1.65)),

                  const SizedBox(height: 20),

                  // Info chips
                  Row(
                    children: [
                      _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: task.timeLabel),
                      const SizedBox(width: 10),
                      _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Distance',
                          value:
                              '${task.distanceKm.toStringAsFixed(1)} km away'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Guidelines
                  const Text('Volunteer guidelines',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ...[
                    'Be on time or notify the elder in advance.',
                    'Always be respectful and patient.',
                    'Do not ask for more money than agreed.',
                    'Complete the task and mark it done in the app.',
                  ].map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(
                                    color: ElderLinkTheme.purple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            Expanded(
                              child: Text(g,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: ElderLinkTheme.textSecondary,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // Accept button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ElderLinkTheme.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Accept this request',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INFO TILE
// ─────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ElderLinkTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ElderLinkTheme.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: ElderLinkTheme.textSecondary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ElderLinkTheme.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACCEPT CONFIRMATION SHEET
// ─────────────────────────────────────────────
class _AcceptSheet extends StatefulWidget {
  final VolunteerTask task;
  final VoidCallback onConfirm;

  const _AcceptSheet({required this.task, required this.onConfirm});

  @override
  State<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends State<_AcceptSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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

          const SizedBox(height: 24),

          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.task.category.emoji,
                    style: const TextStyle(fontSize: 38)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Confirm Acceptance',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElderLinkTheme.textPrimary)),

          const SizedBox(height: 8),

          Text(
            'You are committing to help ${widget.task.elderName} with:',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: ElderLinkTheme.textSecondary),
          ),

          const SizedBox(height: 6),

          Text(
            '"${widget.task.title}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ElderLinkTheme.textPrimary),
          ),

          const SizedBox(height: 6),

          Text(
            widget.task.timeLabel,
            style: const TextStyle(fontSize: 13, color: ElderLinkTheme.purple),
          ),

          const SizedBox(height: 24),

          // What happens next
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What happens next:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElderLinkTheme.textSecondary)),
                const SizedBox(height: 8),
                ...[
                  '📲 Elder gets notified immediately',
                  '🗺️ You get their exact address',
                  '💬 Chat opens with the elder',
                  '⭐ Complete & get rated',
                ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 13,
                              color: ElderLinkTheme.textPrimary,
                              height: 1.5)),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: ElderLinkTheme.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Yes, I'll help!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: ElderLinkTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SORT SHEET
// ─────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _SortSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'key': 'distance', 'label': 'Nearest first', 'icon': '📍'},
      {'key': 'time', 'label': 'Soonest first', 'icon': '⏰'},
      {'key': 'urgent', 'label': 'Urgent first', 'icon': '🚨'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          const Text('Sort by',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ElderLinkTheme.textPrimary)),
          const SizedBox(height: 14),
          ...options.map((o) => GestureDetector(
                onTap: () => onSelect(o['key']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: current == o['key']
                        ? const Color(0xFFF3EEFF)
                        : ElderLinkTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: current == o['key']
                          ? ElderLinkTheme.purple
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(o['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(o['label']!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: current == o['key']
                                  ? ElderLinkTheme.purple
                                  : ElderLinkTheme.textPrimary)),
                      const Spacer(),
                      if (current == o['key'])
                        const Icon(Icons.check_circle_rounded,
                            color: ElderLinkTheme.purple, size: 20),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
