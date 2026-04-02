import 'package:flutter/foundation.dart';

import '../data/mock/mock_store.dart';
import '../main.dart';
import '../models/help_request.dart';
import 'chat_repository.dart';
import '../services/mock_auth_service.dart';

class RequestTimelineEvent {
  final String id;
  final String elderId;
  final String requestId;
  final RequestStatus status;
  final String title;
  final String subtitle;
  final DateTime createdAt;

  const RequestTimelineEvent({
    required this.id,
    required this.elderId,
    required this.requestId,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.createdAt,
  });

  RequestTimelineEvent copyWith({
    String? id,
    String? elderId,
    String? requestId,
    RequestStatus? status,
    String? title,
    String? subtitle,
    DateTime? createdAt,
  }) {
    return RequestTimelineEvent(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VolunteerRatingStats {
  final double averageRating;
  final int totalRatings;
  final int completedTasksCount;

  const VolunteerRatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.completedTasksCount,
  });
}

class RequestRepository extends ChangeNotifier {
  RequestRepository._();

  static final RequestRepository instance = RequestRepository._();

  final MockStore _store = MockStore.instance;
  final MockAuthService _auth = MockAuthService.instance;
  final ChatRepository _chat = ChatRepository.instance;
  DateTime _lastUpdatedAt = DateTime.now();
  final List<RequestTimelineEvent> _timelineEvents = [];
  bool _timelineSeeded = false;

  DateTime get lastUpdatedAt => _lastUpdatedAt;

  List<HelpRequest> getElderRequestsSnapshot(String elderId) {
    final items = _store.requests
        .where((request) => request.elderId == elderId && !request.isDeleted)
        .map((request) => request.copyWith())
        .toList();
    items.sort(_compareRequestsByPriority);
    return items;
  }

  List<RequestTimelineEvent> getTimelineEventsSnapshot(String elderId) {
    _ensureTimelineSeeded();
    final items = _timelineEvents
        .where((event) => event.elderId == elderId)
        .map((event) => event.copyWith())
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  VolunteerRatingStats getVolunteerRatingStats(String volunteerId) {
    final completedTasksCount = _store.requests
        .where(
          (request) =>
              !request.isDeleted &&
              request.volunteerId == volunteerId &&
              request.status == RequestStatus.completed,
        )
        .length;
    final ratings = _store.requests
        .where(
          (request) =>
              !request.isDeleted &&
              request.ratedVolunteerId == volunteerId &&
              request.isRated &&
              request.rating != null,
        )
        .map((request) => request.rating!)
        .toList();
    final totalRatings = ratings.length;
    final averageRating = totalRatings == 0
        ? 0.0
        : ratings.reduce((a, b) => a + b) / totalRatings;
    return VolunteerRatingStats(
      averageRating: averageRating,
      totalRatings: totalRatings,
      completedTasksCount: completedTasksCount,
    );
  }

  List<HelpRequest> getVolunteerFeedSnapshot() {
    final items = _store.requests
        .where(
          (request) =>
              !request.isDeleted &&
              request.status == RequestStatus.pending &&
              request.volunteerId == null,
        )
        .map((request) => request.copyWith())
        .toList();
    items.sort((a, b) {
      final priorityCompare = _compareRequestsByPriority(a, b);
      if (priorityCompare != 0) return priorityCompare;
      return a.distanceKm.compareTo(b.distanceKm);
    });
    return items;
  }

  List<HelpRequest> getVolunteerAssignedRequestsSnapshot(String volunteerId) {
    final items = _store.requests
        .where(
          (request) =>
              !request.isDeleted && request.volunteerId == volunteerId,
        )
        .map((request) => request.copyWith())
        .toList();
    items.sort(_compareRequestsByPriority);
    return items;
  }

  Future<List<HelpRequest>> fetchElderRequests(String elderId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return getElderRequestsSnapshot(elderId);
  }

  Future<List<HelpRequest>> fetchVolunteerFeed() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return getVolunteerFeedSnapshot();
  }

  Future<List<HelpRequest>> fetchVolunteerAssignedRequests(
    String volunteerId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return getVolunteerAssignedRequestsSnapshot(volunteerId);
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
    _ensureTimelineSeeded();
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
      isEmergency: false,
      isDeleted: false,
      hasAudio: hasAudio,
      audioLocalPath: audioLocalPath,
      createdAt: DateTime.now(),
    );
    _store.requests.insert(0, request);
    _recordTimelineEvent(request, createdAt: request.createdAt);
    _markUpdated();
    return request.copyWith();
  }

  Future<HelpRequest?> triggerSos({
    String? locationLabel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 260));
    _ensureTimelineSeeded();

    final elder = _auth.userForRole(UserRole.elder);
    final volunteer = _store.volunteerUsersById['volunteer_001'] ??
        _auth.userForRole(UserRole.volunteer);
    final createdAt = DateTime.now();
    final effectiveLocation = (locationLabel == null || locationLabel.trim().isEmpty)
        ? 'Current location shared'
        : locationLabel.trim();

    final request = HelpRequest(
      id: 'req_sos_${createdAt.millisecondsSinceEpoch}',
      elderId: elder.id,
      elderName: elder.name,
      elderInitials: elder.initials,
      elderColorValue: elder.colorValue,
      elderRating: 4.8,
      elderTotalRequests: _store.requests
              .where((item) => item.elderId == elder.id && !item.isDeleted)
              .length +
          1,
      title: 'SOS emergency assistance',
      description:
          'Emergency help requested. Please reach the elder immediately and confirm safety.',
      location: effectiveLocation,
      timeLabel: 'Immediate assistance',
      subtitle: '$effectiveLocation - Immediate response needed',
      category: RequestCategory.doctorVisit,
      status: RequestStatus.pending,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      volunteerInitials: volunteer.initials,
      volunteerColorValue: volunteer.colorValue,
      distanceKm: 0.2,
      isUrgent: true,
      isEmergency: true,
      isDeleted: false,
      hasAudio: false,
      audioLocalPath: null,
      emergencyCreatedAt: createdAt,
      createdAt: createdAt,
    );

    _store.requests.insert(0, request);
    _insertTimelineEvent(
      request: request,
      status: RequestStatus.pending,
      title: 'SOS triggered',
      subtitle: 'Emergency alert sent from $effectiveLocation',
      createdAt: createdAt,
    );

    final acceptedAt = createdAt.add(const Duration(seconds: 1));
    _store.requests[0] = _store.requests[0].copyWith(status: RequestStatus.accepted);
    _insertTimelineEvent(
      request: _store.requests[0],
      status: RequestStatus.accepted,
      title: 'Volunteer assigned',
      subtitle: '${volunteer.name} is responding right away',
      createdAt: acceptedAt,
    );

    final inProgressAt = acceptedAt.add(const Duration(seconds: 1));
    _store.requests[0] =
        _store.requests[0].copyWith(status: RequestStatus.inProgress);
    _insertTimelineEvent(
      request: _store.requests[0],
      status: RequestStatus.inProgress,
      title: 'Emergency help in progress',
      subtitle: 'Volunteer is on the way. Location shared with volunteer.',
      createdAt: inProgressAt,
    );

    final thread = _chat.getOrCreateThreadForRequest(
      requestId: _store.requests[0].id,
      elderId: elder.id,
      volunteerId: volunteer.id,
    );
    if (thread != null) {
      _chat.addSeededMessage(
        threadId: thread.id,
        senderId: elder.id,
        senderRole: UserRole.elder,
        text: 'I need urgent help. My location has been shared.',
        timestamp: createdAt,
      );
      _chat.addSeededMessage(
        threadId: thread.id,
        senderId: volunteer.id,
        senderRole: UserRole.volunteer,
        text: 'I received your SOS alert and I am on the way now.',
        timestamp: acceptedAt,
      );
    }

    _markUpdated();
    return _store.requests[0].copyWith();
  }

  Future<void> acceptRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 450));
    _ensureTimelineSeeded();
    final volunteer = _auth.userForRole(UserRole.volunteer);
    final index =
        _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;
    final current = _store.requests[index];
    if (current.status != RequestStatus.pending) return;
    _store.requests[index] = current.copyWith(
      status: RequestStatus.accepted,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      volunteerInitials: volunteer.initials,
      volunteerColorValue: volunteer.colorValue,
    );
    _recordTimelineEvent(_store.requests[index]);
    _markUpdated();
  }

  Future<void> startRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _updateRequestStatus(
      requestId,
      RequestStatus.inProgress,
      allowedCurrentStatuses: const [RequestStatus.accepted],
    );
  }

  Future<void> completeRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _updateRequestStatus(
      requestId,
      RequestStatus.completed,
      allowedCurrentStatuses: const [RequestStatus.inProgress],
    );
  }

  Future<void> cancelRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _updateRequestStatus(
      requestId,
      RequestStatus.cancelled,
      allowedCurrentStatuses: const [
        RequestStatus.pending,
        RequestStatus.accepted,
        RequestStatus.inProgress,
      ],
    );
  }

  Future<void> submitVolunteerRating({
    required String requestId,
    required int rating,
    String? feedback,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _ensureTimelineSeeded();
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1 to 5');
    }

    final elder = _auth.userForRole(UserRole.elder);
    final index =
        _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;

    final current = _store.requests[index];
    if (current.elderId != elder.id) return;
    if (current.status != RequestStatus.completed) return;
    if (current.isRated) return;
    if (current.volunteerId == null) return;

    final cleanedFeedback = (feedback ?? '').trim();
    final ratedAt = DateTime.now();
    _store.requests[index] = current.copyWith(
      isRated: true,
      rating: rating,
      feedback: cleanedFeedback.isEmpty ? null : cleanedFeedback,
      ratedAt: ratedAt,
      ratedVolunteerId: current.volunteerId,
    );
    _timelineEvents.insert(
      0,
      RequestTimelineEvent(
        id: '${current.id}_rated_${ratedAt.microsecondsSinceEpoch}',
        elderId: current.elderId,
        requestId: current.id,
        status: RequestStatus.completed,
        title: 'Volunteer rated ${rating}★ by elder',
        subtitle: cleanedFeedback.isEmpty
            ? current.title
            : cleanedFeedback,
        createdAt: ratedAt,
      ),
    );
    _markUpdated();
  }

  Future<void> softDeleteRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;
    _store.requests[index] = _store.requests[index].copyWith(isDeleted: true);
    _markUpdated();
  }

  Future<void> _updateRequestStatus(
    String requestId,
    RequestStatus newStatus, {
    required List<RequestStatus> allowedCurrentStatuses,
  }) async {
    _ensureTimelineSeeded();
    final index = _store.requests.indexWhere((request) => request.id == requestId);
    if (index == -1) return;
    final current = _store.requests[index];
    if (!allowedCurrentStatuses.contains(current.status)) return;
    _store.requests[index] = current.copyWith(status: newStatus);
    _recordTimelineEvent(_store.requests[index]);
    _markUpdated();
  }

  void _markUpdated() {
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void _ensureTimelineSeeded() {
    if (_timelineSeeded) return;
    final seededRequests = _store.requests
        .where((request) => !request.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final request in seededRequests.reversed) {
      _recordTimelineEvent(request, createdAt: request.createdAt);
    }
    _timelineSeeded = true;
  }

  void _recordTimelineEvent(
    HelpRequest request, {
    DateTime? createdAt,
  }) {
    final eventTime = createdAt ?? DateTime.now();
    final meta = _timelineMeta(request);
    _insertTimelineEvent(
      request: request,
      status: request.status,
      title: meta.title,
      subtitle: meta.subtitle,
      createdAt: eventTime,
    );
  }

  ({String title, String subtitle}) _timelineMeta(HelpRequest request) {
    if (request.isEmergency) {
      switch (request.status) {
        case RequestStatus.pending:
          return (
            title: 'SOS triggered',
            subtitle: 'Emergency alert shared with nearby volunteer support',
          );
        case RequestStatus.accepted:
          return (
            title: 'Volunteer assigned',
            subtitle:
                '${request.volunteerName ?? 'A volunteer'} accepted the emergency alert',
          );
        case RequestStatus.inProgress:
          return (
            title: 'Emergency help in progress',
            subtitle:
                '${request.volunteerName ?? 'A volunteer'} is heading to ${request.location}',
          );
        case RequestStatus.completed:
          return (
            title: 'Emergency task completed',
            subtitle:
                '${request.volunteerName ?? 'A volunteer'} completed the emergency support',
          );
        case RequestStatus.cancelled:
          return (
            title: 'Emergency request cancelled',
            subtitle: 'The SOS request is no longer active',
          );
      }
    }

    switch (request.status) {
      case RequestStatus.pending:
        return (
          title: 'Request created',
          subtitle: request.title,
        );
      case RequestStatus.accepted:
        return (
          title: 'Request accepted by volunteer',
          subtitle:
              '${request.volunteerName ?? 'A volunteer'} accepted ${request.title}',
        );
      case RequestStatus.inProgress:
        return (
          title: 'Task started',
          subtitle:
              '${request.volunteerName ?? 'A volunteer'} started ${request.title}',
        );
      case RequestStatus.completed:
        return (
          title: 'Task completed',
          subtitle:
              '${request.volunteerName ?? 'A volunteer'} completed ${request.title}',
        );
      case RequestStatus.cancelled:
        return (
          title: 'Request cancelled',
          subtitle: '${request.title} is no longer active',
        );
    }
  }

  void _insertTimelineEvent({
    required HelpRequest request,
    required RequestStatus status,
    required String title,
    required String subtitle,
    required DateTime createdAt,
  }) {
    _timelineEvents.insert(
      0,
      RequestTimelineEvent(
        id: '${request.id}_${status.name}_${createdAt.microsecondsSinceEpoch}',
        elderId: request.elderId,
        requestId: request.id,
        status: status,
        title: title,
        subtitle: subtitle,
        createdAt: createdAt,
      ),
    );
  }

  int _compareRequestsByPriority(HelpRequest a, HelpRequest b) {
    if (a.isEmergency != b.isEmergency) {
      return a.isEmergency ? -1 : 1;
    }
    if (a.isUrgent != b.isUrgent) {
      return a.isUrgent ? -1 : 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  }
}
