import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import 'login_screen.dart';
import 'signup_elder_screen.dart';
import 'signup_volunteer_screen.dart';
import 'signup_family_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateTo(UserRole role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LoginOrSignupSheet(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElderLinkTheme.darkNavy,
              ElderLinkTheme.midNavy,
              ElderLinkTheme.deepBlue,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: ElderLinkTheme.orange,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: ElderLinkTheme.orange.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🤝', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        l10n.t('appTitle'),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.t('splashTagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.t('splashRolePrompt'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      emoji: '🧓',
                      title: l10n.t('roleElder'),
                      subtitle: l10n.t('roleElderSubtitle'),
                      iconBg: const Color(0xFFFF6B35),
                      onTap: () => _navigateTo(UserRole.elder),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      emoji: '🙋',
                      title: l10n.t('roleVolunteer'),
                      subtitle: l10n.t('roleVolunteerSubtitle'),
                      iconBg: const Color(0xFF7C5CBF),
                      onTap: () => _navigateTo(UserRole.volunteer),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      emoji: '👨‍👩‍👧',
                      title: l10n.t('roleFamily'),
                      subtitle: l10n.t('roleFamilySubtitle'),
                      iconBg: const Color(0xFF0F3460),
                      onTap: () => _navigateTo(UserRole.family),
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        l10n.t('splashFooter'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginOrSignupSheet extends StatelessWidget {
  final UserRole role;

  const _LoginOrSignupSheet({required this.role});

  String _getRoleLabel() {
    switch (role) {
      case UserRole.elder:
        return 'Elder';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.family:
        return 'Family Member';
    }
  }

  Widget _signupScreenForRole() {
    switch (role) {
      case UserRole.elder:
        return const SignupElderScreen();
      case UserRole.volunteer:
        return const SignupVolunteerScreen();
      case UserRole.family:
        return const SignupFamilyScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: ElderLinkTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            'Continue as ${_getRoleLabel()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to proceed',
            style: TextStyle(
              fontSize: 13,
              color: ElderLinkTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(role: role),
                  ),
                );
              },
              child: const Text('Login to Existing Account'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _signupScreenForRole(),
                  ),
                );
              },
              child: const Text('Create New Account'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
