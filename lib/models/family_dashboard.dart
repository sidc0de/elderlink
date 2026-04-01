import 'package:flutter/material.dart';

import 'app_user.dart';

enum ActivityType { taskCompleted, taskAccepted, sos, moodLogged, chat }

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

  MoodEntry copyWith({
    String? day,
    String? emoji,
    String? label,
    bool? logged,
  }) {
    return MoodEntry(
      day: day ?? this.day,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      logged: logged ?? this.logged,
    );
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      day: map['day'] as String,
      emoji: map['emoji'] as String,
      label: map['label'] as String,
      logged: map['logged'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'emoji': emoji,
      'label': label,
      'logged': logged,
    };
  }
}

class ActivityEntry {
  final String icon;
  final int iconBgValue;
  final String title;
  final String subtitle;
  final String timeAgo;
  final ActivityType type;

  const ActivityEntry({
    required this.icon,
    required this.iconBgValue,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
  });

  Color get iconBg => Color(iconBgValue);

  ActivityEntry copyWith({
    String? icon,
    int? iconBgValue,
    String? title,
    String? subtitle,
    String? timeAgo,
    ActivityType? type,
  }) {
    return ActivityEntry(
      icon: icon ?? this.icon,
      iconBgValue: iconBgValue ?? this.iconBgValue,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timeAgo: timeAgo ?? this.timeAgo,
      type: type ?? this.type,
    );
  }

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      icon: map['icon'] as String,
      iconBgValue: map['iconBgValue'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      timeAgo: map['timeAgo'] as String,
      type: ActivityType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ActivityType.chat,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'iconBgValue': iconBgValue,
      'title': title,
      'subtitle': subtitle,
      'timeAgo': timeAgo,
      'type': type.name,
    };
  }
}

class LinkedElder {
  final AppUser user;
  final int activeRequests;
  final int completedTotal;

  const LinkedElder({
    required this.user,
    required this.activeRequests,
    required this.completedTotal,
  });

  String get name => user.name;
  String get initials => user.initials;
  Color get color => user.color;
  String get location => user.location;
  String get lastActive => user.lastActive;
  bool get isOnline => user.isOnline;

  LinkedElder copyWith({
    AppUser? user,
    int? activeRequests,
    int? completedTotal,
  }) {
    return LinkedElder(
      user: user ?? this.user,
      activeRequests: activeRequests ?? this.activeRequests,
      completedTotal: completedTotal ?? this.completedTotal,
    );
  }

  factory LinkedElder.fromMap(Map<String, dynamic> map) {
    return LinkedElder(
      user: AppUser.fromMap(map['user'] as Map<String, dynamic>),
      activeRequests: map['activeRequests'] as int,
      completedTotal: map['completedTotal'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'activeRequests': activeRequests,
      'completedTotal': completedTotal,
    };
  }
}

class FamilyDashboard {
  final DateTime syncedAt;
  final LinkedElder elder;
  final List<MoodEntry> moods;
  final List<ActivityEntry> activities;

  const FamilyDashboard({
    required this.syncedAt,
    required this.elder,
    required this.moods,
    required this.activities,
  });

  FamilyDashboard copyWith({
    DateTime? syncedAt,
    LinkedElder? elder,
    List<MoodEntry>? moods,
    List<ActivityEntry>? activities,
  }) {
    return FamilyDashboard(
      syncedAt: syncedAt ?? this.syncedAt,
      elder: elder ?? this.elder,
      moods: moods ?? this.moods,
      activities: activities ?? this.activities,
    );
  }

  factory FamilyDashboard.fromMap(Map<String, dynamic> map) {
    return FamilyDashboard(
      syncedAt: DateTime.parse(map['syncedAt'] as String),
      elder: LinkedElder.fromMap(map['elder'] as Map<String, dynamic>),
      moods: (map['moods'] as List)
          .cast<Map<String, dynamic>>()
          .map(MoodEntry.fromMap)
          .toList(),
      activities: (map['activities'] as List)
          .cast<Map<String, dynamic>>()
          .map(ActivityEntry.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'syncedAt': syncedAt.toIso8601String(),
      'elder': elder.toMap(),
      'moods': moods.map((item) => item.toMap()).toList(),
      'activities': activities.map((item) => item.toMap()).toList(),
    };
  }
}
