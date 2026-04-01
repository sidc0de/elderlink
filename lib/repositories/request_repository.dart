import '../data/mock/mock_store.dart';
import '../main.dart';
import '../models/help_request.dart';
import '../services/mock_auth_service.dart';

class RequestRepository {
  RequestRepository._();

  static final RequestRepository instance = RequestRepository._();

  final MockStore _store = MockStore.instance;
  final MockAuthService _auth = MockAuthService.instance;

  Future<List<HelpRequest>> fetchElderRequests(String elderId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return _store.requests
        .where((request) => request.elderId == elderId && !request.isDeleted)
        .map((request) => request.copyWith())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<HelpRequest>> fetchVolunteerFeed() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return _store.requests
        .where(
          (request) =>
              !request.isDeleted &&
              request.status == RequestStatus.pending &&
              request.volunteerId == null,
        )
        .map((request) => request.copyWith())
        .toList()
      ..sort((a, b) {
        if (a.isUrgent != b.isUrgent) {
          return b.isUrgent ? 1 : -1;
        }
        return a.distanceKm.compareTo(b.distanceKm);
      });
  }

  Future<List<HelpRequest>> fetchVolunteerAssignedRequests(
    String volunteerId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _store.requests
        .where(
          (request) =>
              !request.isDeleted && request.volunteerId == volunteerId,
        )
        .map((request) => request.copyWith())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<HelpRequest> createRequest({
    required String title,
    required String description,
    required String location,
    required String timeLabel,
    required String subtitle,
    required RequestCategory category,
    required bool isUrgent,
    bool hasAudio = false,
    String? audioLocalPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final elder = _auth.userForRole(_auth.activeRole);
    final request = HelpRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      elderId: elder.id,
      elderName: elder.name,
      elderInitials: elder.initials,
      elderColorValue: elder.colorValue,
      elderRating: 4.8,
      elderTotalRequests: _store.requests
              .where((item) => item.elderId == elder.id && !item.isDeleted)
              .length +
          1,
      title: title,
      description: description,
      location: location,
      timeLabel: timeLabel,
      subtitle: subtitle,
      category: category,
      status: RequestStatus.pending,
      distanceKm: isUrgent ? 0.7 : 1.1,
      isUrgent: isUrgent,
      isDeleted: false,
      hasAudio: hasAudio,
      audioLocalPath: audioLocalPath,
      createdAt: DateTime.now(),
    );
    _store.requests.insert(0, request);
    return request.copyWith();
  }

  Future<void> acceptRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final volunteer = _auth.userForRole(UserRole.volunteer);
    final index = _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;
    final current = _store.requests[index];
    _store.requests[index] = current.copyWith(
      status: RequestStatus.accepted,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      volunteerInitials: volunteer.initials,
      volunteerColorValue: volunteer.colorValue,
    );
  }

  Future<void> softDeleteRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;
    _store.requests[index] = _store.requests[index].copyWith(isDeleted: true);
  }
}
