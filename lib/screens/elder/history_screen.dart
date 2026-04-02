import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/help_request.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;

  const HistoryScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final RequestRepository _repository;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _repository = RequestRepository.instance;
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

  String get _currentElderId =>
      MockAuthService.instance.userForRole(UserRole.elder).id;

  List<HelpRequest> _snapshotRequests() {
    final requests = _repository.getElderRequestsSnapshot(_currentElderId);
    switch (_selectedTab) {
      case 1:
        return requests
            .where((request) => request.status == RequestStatus.completed)
            .toList();
      default:
        return requests;
    }
  }

  Future<void> _showRatingSheet(HelpRequest request) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RateVolunteerSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _repository,
            builder: (context, _) {
              final allRequests =
                  _repository.getElderRequestsSnapshot(_currentElderId);
              final requests = _snapshotRequests();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppScreenHeader(
                            title: l10n.t('history'),
                            subtitle: l10n.t('historyRecordSubtitle'),
                          ),
                          const SizedBox(height: 16),
                          AppSummaryCard(
                            icon: Icons.history_rounded,
                            iconColor: ElderLinkTheme.statusCompletedText,
                            iconBackground: ElderLinkTheme.statusCompleted,
                            title: l10n.format('totalRequestsCount',
                                {'count': '${allRequests.length}'}),
                            subtitle: l10n.t('newestRequestsFirstAllStatuses'),
                          ),
                          const SizedBox(height: 12),
                          _HistoryTabs(
                            selectedTab: _selectedTab,
                            onChanged: (index) =>
                                setState(() => _selectedTab = index),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (requests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        emoji: '📚',
                        title: l10n.t('noHistoryYetTitle'),
                        subtitle: l10n.t('noHistoryYetSubtitle'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == requests.length - 1 ? 0 : 12,
                            ),
                            child: _HistoryRequestCard(
                              request: requests[index],
                              onRate: () => _showRatingSheet(requests[index]),
                            ),
                          );
                        },
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

class _HistoryTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _HistoryTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [l10n.t('all'), l10n.t('completed')];

    return Row(
      children: [
        Expanded(
          child: AppSectionLabel(title: l10n.t('activity')),
        ),
        ...List.generate(
          tabs.length,
          (index) => Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: selectedTab == index,
              onSelected: (_) => onChanged(index),
              selectedColor: ElderLinkTheme.orange,
              labelStyle: TextStyle(
                color: selectedTab == index
                    ? Colors.white
                    : ElderLinkTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selectedTab == index
                    ? ElderLinkTheme.orange
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

class _HistoryRequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onRate;

  const _HistoryRequestCard({
    required this.request,
    required this.onRate,
  });

  ({String title, String subtitle, Color color, Color backgroundColor})
      _statusBanner(BuildContext context) {
    final l10n = context.l10n;
    switch (request.status) {
      case RequestStatus.pending:
        return (
          title: l10n.t('pendingStatusTitle'),
          subtitle: l10n.t('pendingStatusSubtitle'),
          color: ElderLinkTheme.statusPendingText,
          backgroundColor: ElderLinkTheme.statusPending,
        );
      case RequestStatus.accepted:
        return (
          title: l10n.t('acceptedStatusTitle'),
          subtitle: l10n.t('acceptedStatusSubtitle'),
          color: ElderLinkTheme.statusAcceptedText,
          backgroundColor: ElderLinkTheme.statusAccepted,
        );
      case RequestStatus.inProgress:
        return (
          title: l10n.t('inProgressStatusTitle'),
          subtitle: l10n.t('inProgressStatusSubtitle'),
          color: ElderLinkTheme.statusCompletedText,
          backgroundColor: ElderLinkTheme.statusCompleted,
        );
      case RequestStatus.completed:
        return (
          title: l10n.t('completedStatusTitle'),
          subtitle: l10n.t('completedStatusSubtitle'),
          color: ElderLinkTheme.statusCompletedText,
          backgroundColor: ElderLinkTheme.statusCompleted,
        );
      case RequestStatus.cancelled:
        return (
          title: l10n.t('cancelledStatusTitle'),
          subtitle: l10n.t('cancelledStatusSubtitle'),
          color: ElderLinkTheme.danger,
          backgroundColor: const Color(0xFFFCEBEB),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final volunteerName = request.volunteerName;
    final volunteerInitials = request.volunteerInitials;
    final volunteerColor = request.volunteerColor;
    final banner = _statusBanner(context);
    final volunteerPillLabel = request.isRated && request.rating != null
        ? l10n.format('ratedStars', {'rating': '${request.rating}'})
        : banner.title;
    final volunteerPillTextColor = request.isRated && request.rating != null
        ? ElderLinkTheme.orange
        : banner.color;
    final volunteerPillBackgroundColor =
        request.isRated && request.rating != null
            ? const Color(0xFFFFF5F2)
            : banner.backgroundColor;

    return AppSurfaceCard(
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
            AppEmergencyBadge(label: l10n.t('urgent')),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              AppCategoryChip(category: request.category),
              const Spacer(),
              AppRequestStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            request.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (request.isRated && request.rating != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                AppPill(
                  label: l10n.format('ratedStars', {'rating': '${request.rating}'}),
                  textColor: ElderLinkTheme.orange,
                  backgroundColor: const Color(0xFFFFF5F2),
                ),
                if (request.feedback != null && request.feedback!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.feedback!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ] else if (request.status == RequestStatus.completed &&
              volunteerName != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onRate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: const BorderSide(color: ElderLinkTheme.orange, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.t('rateVolunteer')),
              ),
            ),
          ],
          if (volunteerName != null &&
              volunteerInitials != null &&
              volunteerColor != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                AppAvatar(
                  initials: volunteerInitials,
                  color: volunteerColor,
                  radius: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    volunteerName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                AppPill(
                  label: request.isRated && request.rating != null
                      ? l10n.format('ratedStars', {'rating': '${request.rating}'})
                      : volunteerPillLabel,
                  textColor: volunteerPillTextColor,
                  backgroundColor: volunteerPillBackgroundColor,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            AppInlineBanner(
              icon: Icons.schedule_rounded,
              title: banner.title,
              subtitle: banner.subtitle,
              color: banner.color,
              backgroundColor: banner.backgroundColor,
            ),
          ],
        ],
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    star <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
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
