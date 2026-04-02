import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';

class EditProfileScreen extends StatefulWidget {
  final UserRole role;

  const EditProfileScreen({
    super.key,
    required this.role,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  bool _isSaving = false;

  AppUser get _user => MockAuthService.instance.userForRole(widget.role);

  bool get _showsEmergencyFields => widget.role == UserRole.elder;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email ?? '');
    _phoneController = TextEditingController(text: _user.phone ?? '');
    _addressController = TextEditingController(
      text: _user.address ?? _user.location,
    );
    _emergencyNameController = TextEditingController(
      text: _user.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: _user.emergencyContactPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    await MockAuthService.instance.updateCurrentUser(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      emergencyContactName:
          _showsEmergencyFields ? _emergencyNameController.text : null,
      emergencyContactPhone:
          _showsEmergencyFields ? _emergencyPhoneController.text : null,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('profileSaved'))),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      appBar: AppBar(
        backgroundColor: ElderLinkTheme.background,
        elevation: 0,
        title: Text(l10n.t('editProfile')),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: AppSurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.t('fullName'),
                    icon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.t('pleaseEnterName');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: l10n.t('email'),
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.t('pleaseEnterEmail');
                      }
                      if (!value.contains('@')) {
                        return l10n.t('enterValidEmail');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: l10n.t('phoneNumber'),
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.t('pleaseEnterPhoneNumber');
                      }
                      if (value.trim().length < 10) {
                        return l10n.t('enterValidPhone');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: l10n.t('address'),
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.t('pleaseEnterAddress');
                      }
                      return null;
                    },
                  ),
                  if (_showsEmergencyFields) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: l10n.t('emergencyContactName'),
                      icon: Icons.contact_phone_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.t('pleaseEnterEmergencyContactName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: l10n.t('emergencyContactPhone'),
                      icon: Icons.phone_forwarded_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.t('pleaseEnterEmergencyContactPhone');
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.t('save')),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.t('confirmLogoutTitle')),
        content: Text(l10n.t('confirmLogoutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.t('logout')),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
