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
}
