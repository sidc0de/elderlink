import '../data/mock/mock_store.dart';
import '../main.dart';
import '../models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();

  final MockStore _store = MockStore.instance;

  UserRole _activeRole = UserRole.elder;
  AppUser? _signedInUser;

  UserRole get activeRole => _activeRole;

  AppUser get currentUser => _signedInUser ?? _store.usersByRole[_activeRole]!;
  bool get isSignedIn => _signedInUser != null;

  AppUser userForRole(UserRole role) => _store.usersByRole[role]!;

  String demoEmailForRole(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'elder@demo.com';
      case UserRole.volunteer:
        return 'caregiver@demo.com';
      case UserRole.family:
        return 'family@demo.com';
    }
  }

  Future<AppUser> signInAs(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _activeRole = role;
    _signedInUser = _store.usersByRole[role]!;
    return currentUser;
  }

  Future<AppUser?> signInWithCredentials({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final normalizedEmail = email.trim().toLowerCase();
    final expectedEmail = demoEmailForRole(role);
    final acceptedEmails = <String>{
      expectedEmail,
      if (role == UserRole.volunteer) 'volunteer@demo.com',
    };
    if (!acceptedEmails.contains(normalizedEmail) || password != '123456') {
      return null;
    }
    return signInAs(role);
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _signedInUser = null;
  }

  Future<AppUser> updateCurrentUser({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final current = currentUser;
    final updated = current.copyWith(
      name: name.trim(),
      initials: _initialsForName(name),
      email: email.trim(),
      phone: phone.trim(),
      address: address.trim(),
      location: address.trim(),
      emergencyContactName: emergencyContactName?.trim().isEmpty ?? true
          ? null
          : emergencyContactName!.trim(),
      emergencyContactPhone: emergencyContactPhone?.trim().isEmpty ?? true
          ? null
          : emergencyContactPhone!.trim(),
    );
    _store.usersByRole[_activeRole] = updated;
    if (updated.role == UserRole.volunteer) {
      _store.volunteerUsersById[updated.id] = updated;
    }
    _signedInUser = updated;
    return updated;
  }

  String _initialsForName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return currentUser.initials;
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
