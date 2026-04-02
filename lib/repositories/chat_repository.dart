import 'package:flutter/foundation.dart';

import '../data/mock/mock_store.dart';
import '../main.dart';
import '../models/chat_thread.dart';
import '../models/help_request.dart';
import '../services/mock_auth_service.dart';

class ChatRepository extends ChangeNotifier {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final MockStore _store = MockStore.instance;
  final MockAuthService _auth = MockAuthService.instance;

  List<ChatThread> getElderThreads(String elderId) {
    final threads = _store.chatThreads
        .where((thread) => thread.elderId == elderId)
        .map((thread) => thread.copyWith())
        .toList();
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads.take(2).toList();
  }

  List<ChatThread> getVolunteerThreads(String volunteerId) {
    final threads = _store.chatThreads
        .where((thread) => thread.volunteerId == volunteerId)
        .map((thread) => thread.copyWith())
        .toList();
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  ChatThread? getThreadById(String threadId) {
    final thread = _store.chatThreads.cast<ChatThread?>().firstWhere(
          (item) => item?.id == threadId,
          orElse: () => null,
        );
    return thread?.copyWith();
  }

  ChatThread? getThreadForRequest(String requestId) {
    final thread = _store.chatThreads.cast<ChatThread?>().firstWhere(
          (item) => item?.requestId == requestId,
          orElse: () => null,
        );
    return thread?.copyWith();
  }

  HelpRequest? getRequestSnapshot(String requestId) {
    final request = _store.requests.cast<HelpRequest?>().firstWhere(
          (item) => item?.id == requestId,
          orElse: () => null,
        );
    return request?.copyWith();
  }

  ChatThread? getOrCreateThreadForRequest({
    required String requestId,
    required String elderId,
    required String volunteerId,
  }) {
    final request = getRequestSnapshot(requestId);
    if (request == null ||
        request.volunteerId == null ||
        request.elderId != elderId ||
        request.volunteerId != volunteerId) {
      return null;
    }

    final existingIndex =
        _store.chatThreads.indexWhere((thread) => thread.requestId == requestId);
    if (existingIndex != -1) {
      return _store.chatThreads[existingIndex].copyWith();
    }

    final thread = ChatThread(
      id: 'thread_$requestId',
      requestId: requestId,
      elderId: elderId,
      volunteerId: volunteerId,
      updatedAt: DateTime.now(),
      messages: const [],
    );
    _store.chatThreads.insert(0, thread);
    notifyListeners();
    return thread.copyWith();
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 120));
    final index = _store.chatThreads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;

    final sender = _auth.currentUser;
    final current = _store.chatThreads[index];
    final message = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      senderId: sender.id,
      senderRole: sender.role,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    _store.chatThreads[index] = current.copyWith(
      messages: [...current.messages, message],
      updatedAt: message.timestamp,
    );
    notifyListeners();
  }

  void addSeededMessage({
    required String threadId,
    required String senderId,
    required UserRole senderRole,
    required String text,
    DateTime? timestamp,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final index = _store.chatThreads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;

    final current = _store.chatThreads[index];
    final createdAt = timestamp ?? DateTime.now();
    final message = ChatMessage(
      id: 'msg_${createdAt.microsecondsSinceEpoch}',
      senderId: senderId,
      senderRole: senderRole,
      text: trimmed,
      timestamp: createdAt,
    );
    _store.chatThreads[index] = current.copyWith(
      messages: [...current.messages, message],
      updatedAt: createdAt,
    );
    notifyListeners();
  }

  String displayNameForThread(ChatThread thread, UserRole viewerRole) {
    if (viewerRole == UserRole.elder) {
      return _volunteerName(thread.volunteerId);
    }
    final request = getRequestSnapshot(thread.requestId);
    return request?.elderName ?? 'Elder';
  }

  String displayInitialsForThread(ChatThread thread, UserRole viewerRole) {
    if (viewerRole == UserRole.elder) {
      return _volunteerInitials(thread.volunteerId);
    }
    final request = getRequestSnapshot(thread.requestId);
    return request?.elderInitials ?? 'EL';
  }

  int displayColorValueForThread(ChatThread thread, UserRole viewerRole) {
    if (viewerRole == UserRole.elder) {
      return _volunteerColorValue(thread.volunteerId);
    }
    final request = getRequestSnapshot(thread.requestId);
    return request?.elderColorValue ?? 0xFFFF6B35;
  }

  bool isParticipant(ChatThread thread, String userId) {
    return thread.elderId == userId || thread.volunteerId == userId;
  }

  String _volunteerName(String volunteerId) {
    return _store.volunteerUsersById[volunteerId]?.name ??
        _auth.userForRole(UserRole.volunteer).name;
  }

  String _volunteerInitials(String volunteerId) {
    return _store.volunteerUsersById[volunteerId]?.initials ?? 'VL';
  }

  int _volunteerColorValue(String volunteerId) {
    return _store.volunteerUsersById[volunteerId]?.colorValue ?? 0xFF7C5CBF;
  }
}
