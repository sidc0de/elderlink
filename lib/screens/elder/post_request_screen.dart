import 'package:flutter/material.dart';

import '../../main.dart';
import '../../repositories/request_repository.dart';
import '../../services/mock_auth_service.dart';
import '../../ui/app_ui.dart';

// ─────────────────────────────────────────────
//  POST REQUEST SCREEN
// ─────────────────────────────────────────────
class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen>
    with SingleTickerProviderStateMixin {
  // Form state
  RequestCategory? _selectedCategory;
  int _selectedWhen = 0; // 0=Today 1=Tomorrow 2=This week
  TimeOfDay _selectedTime = const TimeOfDay(hour: 11, minute: 0);
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isVoiceActive = false;
  bool _isSubmitting = false;
  bool _isUrgent = false;
  bool _usedVoiceInput = false;

  // Step progress (1–3 for visual stepper)
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _whenOptions = ['Today', 'Tomorrow', 'This Week'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Computed step based on form fill ──
  int get _filledStep {
    if (_selectedCategory == null) return 0;
    if (_descController.text.trim().isEmpty) return 1;
    return 2;
  }

  bool get _canSubmit =>
      _selectedCategory != null &&
      _descController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty;

  // ── Time picker ──
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ElderLinkTheme.orange,
            onSurface: ElderLinkTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Voice mock ──
  void _toggleVoice() {
    setState(() => _isVoiceActive = !_isVoiceActive);
    if (_isVoiceActive) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isVoiceActive = false;
          _usedVoiceInput = true;
          _descController.text =
              'Please collect my BP medicines from Apollo Pharmacy, Baner Road. The prescription is ready.';
        });
      });
    }
  }

  // ── Submit ──
  Future<void> _submit() async {
    if (!_canSubmit) {
      _showError('Please fill in all required fields.');
      return;
    }
    setState(() => _isSubmitting = true);
    await MockAuthService.instance.signInAs(UserRole.elder);
    final whenLabel = _whenOptions[_selectedWhen];
    final timeLabel = '$whenLabel, ${_selectedTime.format(context)}';
    final location = _locationController.text.trim();
    await RequestRepository.instance.createRequest(
      title: _buildRequestTitle(),
      description: _descController.text.trim(),
      location: location,
      timeLabel: timeLabel,
      subtitle: '$location · $timeLabel',
      category: _selectedCategory!,
      isUrgent: _isUrgent,
      hasAudio: _usedVoiceInput,
      audioLocalPath: _usedVoiceInput
          ? 'mock_recordings/request_${DateTime.now().millisecondsSinceEpoch}.aac'
          : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSuccessSheet();
  }

  String _buildRequestTitle() {
    final description = _descController.text.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
    if (description.isEmpty) {
      return _selectedCategory?.label ?? 'New request';
    }
    if (description.length <= 42) return description;
    return '${description.substring(0, 42).trim()}...';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFA32D2D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        category: _selectedCategory!,
        onDone: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // back to home
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderLinkTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(),
              _buildStepper(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        step: 1,
                        title: 'What kind of help do you need?',
                        child: _buildCategoryGrid(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        step: 2,
                        title: 'Describe your request',
                        child: _buildDescriptionField(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        step: 3,
                        title: 'When & where?',
                        child: _buildWhenWhere(),
                      ),
                      const SizedBox(height: 28),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      color: ElderLinkTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: ElderLinkTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'New Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ElderLinkTheme.textPrimary,
                  ),
                ),
              ),
              const AppPill(
                label: 'Step 1 of 3',
                textColor: ElderLinkTheme.orange,
                backgroundColor: Color(0xFFFFF5F2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress stepper ──
  Widget _buildStepper() {
    return Container(
      color: ElderLinkTheme.background,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _filledStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? ElderLinkTheme.orange
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Section wrapper ──
  Widget _buildSection(
      {required int step, required String title, required Widget child}) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: step <= _filledStep + 1
                      ? ElderLinkTheme.orange
                      : ElderLinkTheme.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: step <= _filledStep + 1
                          ? Colors.white
                          : ElderLinkTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ElderLinkTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Category grid ──
  Widget _buildCategoryGrid() {
    final categories = RequestCategory.values;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? cat.bgColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cat.color : const Color(0xFFEEEEEE),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected ? [] : AppConstants.cardShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cat.color : ElderLinkTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Description field ──
  Widget _buildDescriptionField() {
    return Column(
      children: [
        // Voice button
        GestureDetector(
          onTap: _toggleVoice,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _isVoiceActive ? const Color(0xFFFFF0EB) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isVoiceActive
                    ? ElderLinkTheme.orange
                    : const Color(0xFFE8E8E8),
                width: _isVoiceActive ? 2 : 1.5,
                style: _isVoiceActive ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isVoiceActive
                      ? _PulsingMic(key: const ValueKey('active'))
                      : const Icon(Icons.mic_none_rounded,
                          color: ElderLinkTheme.orange,
                          size: 22,
                          key: ValueKey('idle')),
                ),
                const SizedBox(width: 8),
                Text(
                  _isVoiceActive
                      ? 'Listening... tap to stop'
                      : '🎤  Tap to speak your request',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isVoiceActive
                        ? ElderLinkTheme.orange
                        : ElderLinkTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Or divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or type below',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
          ],
        ),

        const SizedBox(height: 10),

        // Text area
        TextField(
          controller: _descController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          style:
              const TextStyle(fontSize: 14, color: ElderLinkTheme.textPrimary),
          decoration: InputDecoration(
            hintText: _selectedCategory != null
                ? _hintFor(_selectedCategory!)
                : 'Describe what you need help with...',
            hintStyle: const TextStyle(
                fontSize: 13, color: ElderLinkTheme.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: ElderLinkTheme.orange, width: 1.5),
            ),
          ),
        ),

        // Character count
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_descController.text.length} / 300',
              style: const TextStyle(
                  fontSize: 11, color: ElderLinkTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  String _hintFor(RequestCategory cat) {
    switch (cat) {
      case RequestCategory.medicine:
        return 'e.g. Please collect my BP medicines from Apollo Pharmacy, Baner Road...';
      case RequestCategory.grocery:
        return 'e.g. Need 1kg tomatoes, onions and green chillies from the local market...';
      case RequestCategory.transport:
        return 'e.g. Need a ride to Ruby Hall Clinic for my 3 PM appointment...';
      case RequestCategory.companionship:
        return 'e.g. Looking for someone to chat with or take a short evening walk...';
      case RequestCategory.doctorVisit:
        return 'e.g. Doctor appointment at Jehangir Hospital at 10 AM, need assistance...';
      case RequestCategory.errand:
        return 'e.g. Please pay my electricity bill at the MSEDCL office nearby...';
    }
  }

  // ── When & Where ──
  Widget _buildWhenWhere() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // When chips
        const Text('When?',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ElderLinkTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            _whenOptions.length,
            (i) => GestureDetector(
              onTap: () => setState(() => _selectedWhen = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color:
                      _selectedWhen == i ? ElderLinkTheme.orange : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedWhen == i
                        ? ElderLinkTheme.orange
                        : const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _whenOptions[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedWhen == i
                        ? Colors.white
                        : ElderLinkTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Time picker
        const Text('Preferred time',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ElderLinkTheme.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
              boxShadow: AppConstants.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: ElderLinkTheme.orange, size: 20),
                const SizedBox(width: 10),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ElderLinkTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text('Tap to change',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Location
        const Text('Your location',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ElderLinkTheme.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          onChanged: (_) => setState(() {}),
          style:
              const TextStyle(fontSize: 14, color: ElderLinkTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: ElderLinkTheme.orange, size: 20),
            hintText: 'e.g. Baner Road, Pune',
            hintStyle: const TextStyle(
                fontSize: 13, color: ElderLinkTheme.textSecondary),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: ElderLinkTheme.orange, width: 1.5),
            ),
            suffixIcon: TextButton(
              onPressed: () {
                setState(() => _locationController.text = 'Baner Road, Pune');
              },
              child: const Text('Use GPS',
                  style: TextStyle(
                      fontSize: 12,
                      color: ElderLinkTheme.orange,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Urgency toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD5C8), width: 1),
          ),
          child: Row(
            children: [
              const Text('🚨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mark as urgent',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ElderLinkTheme.textPrimary)),
                    Text('Notifies more volunteers immediately',
                        style: TextStyle(
                            fontSize: 11, color: ElderLinkTheme.textSecondary)),
                  ],
                ),
              ),
              _UrgencyToggle(
                value: _isUrgent,
                onChanged: (value) => setState(() => _isUrgent = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Submit button ──
  Widget _buildSubmitButton() {
    return AnimatedOpacity(
      opacity: _canSubmit ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: ElderLinkTheme.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Post Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Footer note ──
  Widget _buildFooterNote() {
    return const AppInlineBanner(
      icon: Icons.lock_outline_rounded,
      title: 'Private by default',
      subtitle: 'Your address is only shared with accepted volunteers.',
      color: ElderLinkTheme.orange,
      backgroundColor: Color(0xFFFFF5F2),
    );
  }
}

// ─────────────────────────────────────────────
//  PULSING MIC WIDGET
// ─────────────────────────────────────────────
class _PulsingMic extends StatefulWidget {
  const _PulsingMic({super.key});

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child:
          const Icon(Icons.mic_rounded, color: ElderLinkTheme.orange, size: 22),
    );
  }
}

// ─────────────────────────────────────────────
//  URGENCY TOGGLE
// ─────────────────────────────────────────────
class _UrgencyToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _UrgencyToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_UrgencyToggle> createState() => _UrgencyToggleState();
}

class _UrgencyToggleState extends State<_UrgencyToggle> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: widget.value,
      activeColor: ElderLinkTheme.orange,
      onChanged: widget.onChanged,
    );
  }
}

// ─────────────────────────────────────────────
//  SUCCESS BOTTOM SHEET
// ─────────────────────────────────────────────
class _SuccessSheet extends StatefulWidget {
  final RequestCategory category;
  final VoidCallback onDone;

  const _SuccessSheet({required this.category, required this.onDone});

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 28),

          // Animated success icon
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 42))),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Request Posted!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ElderLinkTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'We\'re finding a volunteer near you.\nYou\'ll be notified as soon as someone accepts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.category.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.category.emoji}  ${widget.category.label} request',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.category.color,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Info row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ElderLinkTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _InfoChip(icon: '📍', label: 'Searching 2.5km'),
                const SizedBox(width: 8),
                _InfoChip(icon: '👥', label: '12 volunteers online'),
                const SizedBox(width: 8),
                _InfoChip(icon: '⏱', label: '~10 min'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onDone,
              child: const Text('Back to Home',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ElderLinkTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
