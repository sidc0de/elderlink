import 'package:flutter/material.dart';

import '../main.dart';

class HelpRequest {
  final String id;
  final String elderId;
  final String elderName;
  final String elderInitials;
  final int elderColorValue;
  final double elderRating;
  final int elderTotalRequests;
  final String title;
  final String description;
  final String location;
  final String timeLabel;
  final String subtitle;
  final RequestCategory category;
  final RequestStatus status;
  final String? volunteerId;
  final String? volunteerName;
  final String? volunteerInitials;
  final int? volunteerColorValue;
  final double distanceKm;
  final bool isUrgent;
  final bool isEmergency;
  final bool isDeleted;
  final bool hasAudio;
  final String? audioLocalPath;
  final bool isRated;
  final int? rating;
  final String? feedback;
  final DateTime? ratedAt;
  final String? ratedVolunteerId;
  final DateTime? emergencyCreatedAt;
  final DateTime createdAt;

  const HelpRequest({
    required this.id,
    required this.elderId,
    required this.elderName,
    required this.elderInitials,
    required this.elderColorValue,
    required this.elderRating,
    required this.elderTotalRequests,
    required this.title,
    required this.description,
    required this.location,
    required this.timeLabel,
    required this.subtitle,
    required this.category,
    required this.status,
    this.volunteerId,
    this.volunteerName,
    this.volunteerInitials,
    this.volunteerColorValue,
    required this.distanceKm,
    required this.isUrgent,
    this.isEmergency = false,
    required this.isDeleted,
    required this.hasAudio,
    this.audioLocalPath,
    this.isRated = false,
    this.rating,
    this.feedback,
    this.ratedAt,
    this.ratedVolunteerId,
    this.emergencyCreatedAt,
    required this.createdAt,
  });

  Color get elderColor => Color(elderColorValue);
  Color? get volunteerColor =>
      volunteerColorValue == null ? null : Color(volunteerColorValue!);

  HelpRequest copyWith({
    String? id,
    String? elderId,
    String? elderName,
    String? elderInitials,
    int? elderColorValue,
    double? elderRating,
    int? elderTotalRequests,
    String? title,
    String? description,
    String? location,
    String? timeLabel,
    String? subtitle,
    RequestCategory? category,
    RequestStatus? status,
    String? volunteerId,
    String? volunteerName,
    String? volunteerInitials,
    int? volunteerColorValue,
    double? distanceKm,
    bool? isUrgent,
    bool? isEmergency,
    bool? isDeleted,
    bool? hasAudio,
    String? audioLocalPath,
    bool? isRated,
    int? rating,
    String? feedback,
    DateTime? ratedAt,
    String? ratedVolunteerId,
    DateTime? emergencyCreatedAt,
    DateTime? createdAt,
  }) {
    return HelpRequest(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      elderName: elderName ?? this.elderName,
      elderInitials: elderInitials ?? this.elderInitials,
      elderColorValue: elderColorValue ?? this.elderColorValue,
      elderRating: elderRating ?? this.elderRating,
      elderTotalRequests: elderTotalRequests ?? this.elderTotalRequests,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      timeLabel: timeLabel ?? this.timeLabel,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      status: status ?? this.status,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerInitials: volunteerInitials ?? this.volunteerInitials,
      volunteerColorValue: volunteerColorValue ?? this.volunteerColorValue,
      distanceKm: distanceKm ?? this.distanceKm,
      isUrgent: isUrgent ?? this.isUrgent,
      isEmergency: isEmergency ?? this.isEmergency,
      isDeleted: isDeleted ?? this.isDeleted,
      hasAudio: hasAudio ?? this.hasAudio,
      audioLocalPath: audioLocalPath ?? this.audioLocalPath,
      isRated: isRated ?? this.isRated,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      ratedAt: ratedAt ?? this.ratedAt,
      ratedVolunteerId: ratedVolunteerId ?? this.ratedVolunteerId,
      emergencyCreatedAt: emergencyCreatedAt ?? this.emergencyCreatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HelpRequest.fromMap(Map<String, dynamic> map) {
    return HelpRequest(
      id: map['id'] as String,
      elderId: map['elderId'] as String,
      elderName: map['elderName'] as String,
      elderInitials: map['elderInitials'] as String,
      elderColorValue: map['elderColorValue'] as int,
      elderRating: (map['elderRating'] as num).toDouble(),
      elderTotalRequests: map['elderTotalRequests'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      timeLabel: map['timeLabel'] as String,
      subtitle: map['subtitle'] as String,
      category: RequestCategory.values.firstWhere(
        (value) => value.name == map['category'],
      ),
      status: RequestStatus.values.firstWhere(
        (value) => value.name == map['status'],
      ),
      volunteerId: map['volunteerId'] as String?,
      volunteerName: map['volunteerName'] as String?,
      volunteerInitials: map['volunteerInitials'] as String?,
      volunteerColorValue: map['volunteerColorValue'] as int?,
      distanceKm: (map['distanceKm'] as num).toDouble(),
      isUrgent: map['isUrgent'] as bool? ?? false,
      isEmergency: map['isEmergency'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      hasAudio: map['hasAudio'] as bool? ?? false,
      audioLocalPath: map['audioLocalPath'] as String?,
      isRated: map['isRated'] as bool? ?? false,
      rating: map['rating'] as int?,
      feedback: map['feedback'] as String?,
      ratedAt: map['ratedAt'] == null
          ? null
          : DateTime.parse(map['ratedAt'] as String),
      ratedVolunteerId: map['ratedVolunteerId'] as String?,
      emergencyCreatedAt: map['emergencyCreatedAt'] == null
          ? null
          : DateTime.parse(map['emergencyCreatedAt'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'elderId': elderId,
      'elderName': elderName,
      'elderInitials': elderInitials,
      'elderColorValue': elderColorValue,
      'elderRating': elderRating,
      'elderTotalRequests': elderTotalRequests,
      'title': title,
      'description': description,
      'location': location,
      'timeLabel': timeLabel,
      'subtitle': subtitle,
      'category': category.name,
      'status': status.name,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'volunteerInitials': volunteerInitials,
      'volunteerColorValue': volunteerColorValue,
      'distanceKm': distanceKm,
      'isUrgent': isUrgent,
      'isEmergency': isEmergency,
      'isDeleted': isDeleted,
      'hasAudio': hasAudio,
      'audioLocalPath': audioLocalPath,
      'isRated': isRated,
      'rating': rating,
      'feedback': feedback,
      'ratedAt': ratedAt?.toIso8601String(),
      'ratedVolunteerId': ratedVolunteerId,
      'emergencyCreatedAt': emergencyCreatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
