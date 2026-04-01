import 'package:flutter/material.dart';

import '../main.dart';

class AppUser {
  final String id;
  final String name;
  final String initials;
  final UserRole role;
  final int colorValue;
  final String location;
  final String lastActive;
  final bool isOnline;

  const AppUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.colorValue,
    required this.location,
    required this.lastActive,
    required this.isOnline,
  });

  Color get color => Color(colorValue);

  AppUser copyWith({
    String? id,
    String? name,
    String? initials,
    UserRole? role,
    int? colorValue,
    String? location,
    String? lastActive,
    bool? isOnline,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      colorValue: colorValue ?? this.colorValue,
      location: location ?? this.location,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      initials: map['initials'] as String,
      role: UserRole.values.firstWhere(
        (value) => value.name == map['role'],
        orElse: () => UserRole.elder,
      ),
      colorValue: map['colorValue'] as int,
      location: map['location'] as String,
      lastActive: map['lastActive'] as String,
      isOnline: map['isOnline'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'role': role.name,
      'colorValue': colorValue,
      'location': location,
      'lastActive': lastActive,
      'isOnline': isOnline,
    };
  }
}
