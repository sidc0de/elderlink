import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/mock_auth_service.dart';
import 'elder/elder_home_screen.dart';
import 'family/family_home_screen.dart';
import 'splash_screen.dart';
import 'volunteer/volunteer_home_screen.dart';
import 'signup_elder_screen.dart';
import 'signup_volunteer_screen.dart';
import 'signup_family_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text =
        MockAuthService.instance.demoEmailForRole(widget.role);
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel {
    final l10n = AppLocalizations.of(context);
    switch (widget.role) {
      case UserRole.elder:
        return l10n.t('roleElder');
      case UserRole.volunteer:
        return l10n.t('roleCaregiver');
      case UserRole.family:
        return l10n.t('roleFamilyShort');
    }
  }

  String _withoutDemoText(String value) {
    return value
        .replaceAll(RegExp(r'\bdemo\b\s*', caseSensitive: false), '')
        .replaceAll('डेमो ', '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = await MockAuthService.instance.signInWithCredentials(
      role: widget.role,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _withoutDemoText(context.l10n.t('invalidDemoCredentials')),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.format('loggedInAs', {'name': user.name}),
        ),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _dashboardForRole(widget.role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      appBar: AppBar(
        backgroundColor: ElderLinkTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _accentGradientForRole(widget.role),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _accentGradientForRole(widget.role).first
                              .withOpacity(0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.format('loginAsRole', {'role': _roleLabel}),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: ElderLinkTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.t('email'),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.t('enterYourEmail');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l10n.t('password'),
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.t('enterYourPassword');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(l10n.t('login')),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${l10n.t('dontHaveAccount')} ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ElderLinkTheme.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            _signupScreenForRole(widget.role),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    l10n.t('signUp'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ElderLinkTheme.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _signupScreenForRole(UserRole role) {
  switch (role) {
    case UserRole.elder:
      return const SignupElderScreen();
    case UserRole.volunteer:
      return const SignupVolunteerScreen();
    case UserRole.family:
      return const SignupFamilyScreen();
  }
}

Widget _dashboardForRole(UserRole role) {
  switch (role) {
    case UserRole.elder:
      return const ElderHomeScreen();
    case UserRole.volunteer:
      return const VolunteerHomeScreen();
    case UserRole.family:
      return const FamilyHomeScreen();
  }
}

List<Color> _accentGradientForRole(UserRole role) {
  switch (role) {
    case UserRole.elder:
      return const [ElderLinkTheme.orange, ElderLinkTheme.orangeLight];
    case UserRole.volunteer:
      return const [ElderLinkTheme.purple, ElderLinkTheme.purpleLight];
    case UserRole.family:
      return const [ElderLinkTheme.darkNavy, ElderLinkTheme.deepBlue];
  }
}

Future<void> performMockLogout(BuildContext context) async {
  await MockAuthService.instance.signOut();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.t('loggedOutSuccessfully'))),
  );
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (route) => false,
  );
}
