import '../data/mock/mock_store.dart';
import '../main.dart';
import '../models/family_dashboard.dart';
import '../models/help_request.dart';
import '../services/mock_auth_service.dart';
import 'request_repository.dart';

class ElderDashboard {
  final DateTime syncedAt;
  final List<HelpRequest> requests;

  const ElderDashboard({
    required this.syncedAt,
    required this.requests,
  });
}

class VolunteerDashboard {
  final DateTime syncedAt;
  final List<HelpRequest> tasks;

  const VolunteerDashboard({
    required this.syncedAt,
    required this.tasks,
  });
}

class DashboardRepository {
  DashboardRepository._();

  static final DashboardRepository instance = DashboardRepository._();

  final MockStore _store = MockStore.instance;
  final MockAuthService _auth = MockAuthService.instance;
  final RequestRepository _requests = RequestRepository.instance;

  Future<ElderDashboard> fetchElderDashboard() async {
    final elder = _auth.userForRole(UserRole.elder);
    final items = await _requests.fetchElderRequests(elder.id);
    return ElderDashboard(
      syncedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      requests: items,
    );
  }

  Future<VolunteerDashboard> fetchVolunteerDashboard() async {
    final items = await _requests.fetchVolunteerFeed();
    return VolunteerDashboard(
      syncedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      tasks: items,
    );
  }

  Future<FamilyDashboard> fetchFamilyDashboard() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final elder = _auth.userForRole(UserRole.elder);
    final requests = await _requests.fetchElderRequests(elder.id);
    final activeRequests = requests
        .where(
          (request) =>
              request.status == RequestStatus.pending ||
              request.status == RequestStatus.accepted ||
              request.status == RequestStatus.inProgress,
        )
        .length;
    final completedTotal = requests
        .where((request) => request.status == RequestStatus.completed)
        .length;

    return FamilyDashboard(
      syncedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      elder: LinkedElder(
        user: elder,
        activeRequests: activeRequests,
        completedTotal: completedTotal,
      ),
      moods: _store.moods.map((item) => item.copyWith()).toList(),
      activities: _buildFamilyActivities(requests),
    );
  }

  List<ActivityEntry> _buildFamilyActivities(List<HelpRequest> requests) {
    final items = requests.take(6).map((request) {
      if (request.isEmergency) {
        switch (request.status) {
          case RequestStatus.pending:
            return ActivityEntry(
              icon: '🚨',
              iconBgValue: 0xFFFFF0EB,
              title: 'SOS triggered',
              subtitle: 'Emergency alert sent from ${request.location}',
              timeAgo: _timeAgo(request.emergencyCreatedAt ?? request.createdAt),
              type: ActivityType.sos,
            );
          case RequestStatus.accepted:
            return ActivityEntry(
              icon: '🚨',
              iconBgValue: 0xFFFFF0EB,
              title: 'Volunteer assigned to SOS',
              subtitle:
                  '${request.volunteerName ?? 'A volunteer'} is responding now',
              timeAgo: _timeAgo(request.emergencyCreatedAt ?? request.createdAt),
              type: ActivityType.sos,
            );
          case RequestStatus.inProgress:
            return ActivityEntry(
              icon: '🚑',
              iconBgValue: 0xFFFFF0EB,
              title: 'Emergency help in progress',
              subtitle: 'Location shared with volunteer',
              timeAgo: _timeAgo(request.emergencyCreatedAt ?? request.createdAt),
              type: ActivityType.sos,
            );
          case RequestStatus.completed:
            return ActivityEntry(
              icon: '✅',
              iconBgValue: ElderLinkTheme.statusAccepted.value,
              title: 'Emergency support completed',
              subtitle: request.title,
              timeAgo: _timeAgo(request.createdAt),
              type: ActivityType.taskCompleted,
            );
          case RequestStatus.cancelled:
            return ActivityEntry(
              icon: '✖',
              iconBgValue: 0xFFFCEBEB,
              title: 'Emergency request cancelled',
              subtitle: request.title,
              timeAgo: _timeAgo(request.createdAt),
              type: ActivityType.sos,
            );
        }
      }

      switch (request.status) {
        case RequestStatus.pending:
          return ActivityEntry(
            icon: '📝',
            iconBgValue: ElderLinkTheme.statusPending.value,
            title: 'New request posted',
            subtitle: request.title,
            timeAgo: _timeAgo(request.createdAt),
            type: ActivityType.chat,
          );
        case RequestStatus.accepted:
          return ActivityEntry(
            icon: '🙋',
            iconBgValue: 0xFFF3EEFF,
            title: 'Volunteer accepted request',
            subtitle:
                '${request.volunteerName ?? 'A volunteer'} accepted ${request.title}',
            timeAgo: _timeAgo(request.createdAt),
            type: ActivityType.taskAccepted,
          );
        case RequestStatus.inProgress:
          return ActivityEntry(
            icon: '🚶',
            iconBgValue: ElderLinkTheme.statusCompleted.value,
            title: 'Request in progress',
            subtitle: request.title,
            timeAgo: _timeAgo(request.createdAt),
            type: ActivityType.chat,
          );
        case RequestStatus.completed:
          return ActivityEntry(
            icon: '✅',
            iconBgValue: ElderLinkTheme.statusAccepted.value,
            title: 'Request completed',
            subtitle: request.title,
            timeAgo: _timeAgo(request.createdAt),
            type: ActivityType.taskCompleted,
          );
        case RequestStatus.cancelled:
          return ActivityEntry(
            icon: '✖',
            iconBgValue: 0xFFFCEBEB,
            title: 'Request cancelled',
            subtitle: request.title,
            timeAgo: _timeAgo(request.createdAt),
            type: ActivityType.chat,
          );
      }
    }).toList();

    return [
      ...items,
      ..._store.activities.map((item) => item.copyWith()),
    ].take(6).toList();
  }

  String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays} days ago';
  }
}
