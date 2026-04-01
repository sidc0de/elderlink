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
      activities: _store.activities.map((item) => item.copyWith()).toList(),
    );
  }
}
