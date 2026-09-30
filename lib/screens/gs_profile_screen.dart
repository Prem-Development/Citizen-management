import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../services/photo_service.dart';
import '../widgets/photo_picker_widget.dart';

class GSProfileScreen extends StatefulWidget {
  const GSProfileScreen({super.key});

  @override
  State<GSProfileScreen> createState() => _GSProfileScreenState();
}

class _GSProfileScreenState extends State<GSProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _divisionCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final p = context.read<ProfileProvider>().profile;
    _nameCtrl.text = p.name;
    _divisionCtrl.text = p.division;
    _contactCtrl.text = p.contact;
    _photoPath = p.photo;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _divisionCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final t = provider.t;
    final updated = provider.profile.copyWith(
      name: _nameCtrl.text.trim(),
      division: _divisionCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      photo: _photoPath,
    );
    await provider.saveProfile(updated);
    if (mounted) {
      setState(() { _isSaving = false; _isEditing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('profile_saved')), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final t = pp.t;
    final profile = pp.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('gs_profile_title')),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => setState(() => _isEditing = true))
          else
            TextButton(
              onPressed: () => setState(() { _isEditing = false; _loadProfile(); }),
              child: Text(t('cancel'), style: const TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D2137), AppColors.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  PhotoPickerWidget(
                    photoPath: _photoPath,
                    size: 110,
                    onCamera: _isEditing ? () async {
                      final p = await PhotoService.instance.pickFromCamera('gs_profile');
                      if (p != null && mounted) setState(() => _photoPath = p);
                    } : () {},
                    onGallery: _isEditing ? () async {
                      final p = await PhotoService.instance.pickFromGallery('gs_profile');
                      if (p != null && mounted) setState(() => _photoPath = p);
                    } : () {},
                    onRemove: (_isEditing && _photoPath != null) ? () => setState(() => _photoPath = null) : null,
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 14),
                    Text(
                      profile.name.isNotEmpty ? profile.name : 'GS Officer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (profile.division.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(profile.division, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                    ],
                    if (profile.contact.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(profile.contact, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      _label(t('edit_profile')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: t('gs_name'),
                          prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? t('required_field') : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _divisionCtrl,
                        decoration: InputDecoration(
                          labelText: t('gs_division'),
                          prefixIcon: const Icon(Icons.account_balance_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? t('required_field') : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: t('gs_contact'),
                          prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                          label: Text(t('save')),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _label('Settings'),
                    const SizedBox(height: 12),

                    // Language switcher
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      title: t('language'),
                      subtitle: pp.isTamil ? t('tamil') : t('english'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LangChip(label: 'EN', isActive: !pp.isTamil, onTap: () => pp.setLanguage(AppConstants.langEnglish)),
                          const SizedBox(width: 8),
                          _LangChip(label: 'த', isActive: pp.isTamil, onTap: () => pp.setLanguage(AppConstants.langTamil)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_rounded, size: 28, color: AppColors.primary),
                          const SizedBox(height: 6),
                          const Text('GS Citizen Manager', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text('v${AppConstants.appVersion} • Offline', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Row(
    children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SettingsRow({required this.icon, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
