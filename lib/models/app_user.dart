import 'package:flutter/material.dart';

import '../main.dart';

class AppUser {
  final String id;
  final String name;
  final String initials;
  final UserRole role;
  final int colorValue;
  final String? email;
  final String? phone;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String location;
  final String lastActive;
  final bool isOnline;

  const AppUser({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.colorValue,
    this.email,
    this.phone,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
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
    String? email,
    String? phone,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
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
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
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
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
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
      'email': email,
      'phone': phone,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'location': location,
      'lastActive': lastActive,
      'isOnline': isOnline,
    };
  }
}
