import 'package:flutter/material.dart';

import '../main.dart';

class FakeBackend {
  static Future<Map<String, dynamic>> fetchElderDashboard() async {
    await Future.delayed(const Duration(milliseconds: 900));

    return {
      'syncedAt': DateTime.now().subtract(const Duration(minutes: 2)),
      'requests': [
        {
          'id': '1',
          'title': 'Collect medicines from Apollo',
          'subtitle': 'Baner Road, Pune · Today 11 AM',
          'category': RequestCategory.medicine,
          'status': RequestStatus.accepted,
          'volunteerName': 'Rohit K.',
          'volunteerInitials': 'RK',
          'volunteerColor': ElderLinkTheme.orange,
        },
        {
          'id': '2',
          'title': 'Evening walk & conversation',
          'subtitle': 'Society Garden · Today 5 PM',
          'category': RequestCategory.companionship,
          'status': RequestStatus.pending,
        },
        {
          'id': '3',
          'title': 'Buy vegetables from market',
          'subtitle': 'Local market · Yesterday',
          'category': RequestCategory.grocery,
          'status': RequestStatus.completed,
          'volunteerName': 'Ananya P.',
          'volunteerInitials': 'AP',
          'volunteerColor': ElderLinkTheme.purple,
        },
        {
          'id': '4',
          'title': 'Doctor visit at Ruby Hall',
          'subtitle': 'Ruby Hall Clinic · 2 days ago',
          'category': RequestCategory.doctorVisit,
          'status': RequestStatus.completed,
          'volunteerName': 'Meera S.',
          'volunteerInitials': 'MS',
          'volunteerColor': const Color(0xFF1565C0),
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> fetchFamilyDashboard() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    return {
      'syncedAt': DateTime.now().subtract(const Duration(minutes: 4)),
      'elder': {
        'name': 'Sunita Deshpande',
        'initials': 'SD',
        'color': ElderLinkTheme.orange,
        'location': 'Baner, Pune',
        'lastActive': '10 min ago',
        'isOnline': true,
        'activeRequests': 2,
        'completedTotal': 14,
      },
      'moods': [
        {'day': 'Mon', 'emoji': '😊', 'label': 'Happy', 'logged': true},
        {'day': 'Tue', 'emoji': '😴', 'label': 'Tired', 'logged': true},
        {'day': 'Wed', 'emoji': '😊', 'label': 'Happy', 'logged': true},
        {'day': 'Thu', 'emoji': '😐', 'label': 'Okay', 'logged': true},
        {'day': 'Fri', 'emoji': '😊', 'label': 'Happy', 'logged': true},
        {'day': 'Sat', 'emoji': '—', 'label': 'Not logged', 'logged': false},
        {'day': 'Sun', 'emoji': '—', 'label': 'Not logged', 'logged': false},
      ],
      'activities': [
        {
          'icon': '✅',
          'iconBg': const Color(0xFFEDFAF3),
          'title': 'Medicine pickup completed',
          'subtitle': 'Rohit Kumar · Apollo Pharmacy, Baner',
          'timeAgo': '2 hours ago',
          'type': 'taskCompleted',
        },
        {
          'icon': '🙋',
          'iconBg': const Color(0xFFF3EEFF),
          'title': 'Volunteer accepted request',
          'subtitle': 'Ananya P. will bring vegetables today',
          'timeAgo': 'This morning',
          'type': 'taskAccepted',
        },
        {
          'icon': '😊',
          'iconBg': const Color(0xFFFFF5F2),
          'title': 'Mood check-in logged',
          'subtitle': 'Feeling happy today',
          'timeAgo': 'Today, 9:15 AM',
          'type': 'moodLogged',
        },
        {
          'icon': '💬',
          'iconBg': const Color(0xFFF0F4FF),
          'title': 'Chat with volunteer',
          'subtitle': 'Rohit Kumar · 12 messages',
          'timeAgo': '3 days ago',
          'type': 'chat',
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> fetchVolunteerDashboard() async {
    await Future.delayed(const Duration(milliseconds: 950));

    return {
      'syncedAt': DateTime.now().subtract(const Duration(minutes: 3)),
      'tasks': [
        {
          'id': '1',
          'elderName': 'Sunita Deshpande',
          'elderInitials': 'SD',
          'elderColor': const Color(0xFFFF6B35),
          'elderRating': 4.8,
          'elderTotalRequests': 12,
          'category': RequestCategory.companionship,
          'title': 'Evening walk & conversation',
          'description':
              'Looking for a friendly companion for a 45-min walk at the society garden. I enjoy talking about books and gardening.',
          'timeLabel': 'Today, 5:00 PM',
          'distanceKm': 0.8,
          'isUrgent': false,
        },
        {
          'id': '2',
          'elderName': 'Ramesh Joshi',
          'elderInitials': 'RJ',
          'elderColor': const Color(0xFF7C5CBF),
          'elderRating': 4.6,
          'elderTotalRequests': 8,
          'category': RequestCategory.grocery,
          'title': 'Buy vegetables from market',
          'description':
              'Need 1kg tomatoes, onions, and green chillies from the local sabzi mandi. Money will be given at delivery.',
          'timeLabel': 'Today, 10:00 AM',
          'distanceKm': 1.2,
          'isUrgent': true,
        },
        {
          'id': '3',
          'elderName': 'Meera Kulkarni',
          'elderInitials': 'MK',
          'elderColor': const Color(0xFF1565C0),
          'elderRating': 5.0,
          'elderTotalRequests': 20,
          'category': RequestCategory.transport,
          'title': 'Doctor appointment drop & pick',
          'description':
              'Need a ride to Ruby Hall Clinic and back. Appointment at 3 PM. I can manage the stairs myself, just need transport.',
          'timeLabel': 'Today, 2:30 PM',
          'distanceKm': 2.1,
          'isUrgent': false,
        },
        {
          'id': '4',
          'elderName': 'Prakash Nair',
          'elderInitials': 'PN',
          'elderColor': const Color(0xFF2ECC71),
          'elderRating': 4.5,
          'elderTotalRequests': 5,
          'category': RequestCategory.medicine,
          'title': 'Collect BP medicines from Apollo',
          'description':
              'Prescription is ready. Please collect from Apollo Pharmacy, Baner Road. Cost will be reimbursed immediately.',
          'timeLabel': 'Today, 11:00 AM',
          'distanceKm': 0.5,
          'isUrgent': true,
        },
      ],
    };
  }

  static Future<void> acceptVolunteerTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }
}
