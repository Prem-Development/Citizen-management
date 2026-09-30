import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/citizen_provider.dart';
import '../providers/column_provider.dart';
import '../providers/profile_provider.dart';
import '../models/citizen.dart';
import '../utils/app_colors.dart';
import '../widgets/photo_picker_widget.dart';
import '../widgets/custom_field_widget.dart';
import '../services/photo_service.dart';

class EditCitizenScreen extends StatefulWidget {
  final String nic;

  const EditCitizenScreen({super.key, required this.nic});

  @override
  State<EditCitizenScreen> createState() => _EditCitizenScreenState();
}

class _EditCitizenScreenState extends State<EditCitizenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _gender;
  String? _dob;
  String? _photoPath;
  bool _isSaving = false;
  bool _isLoading = true;
  Citizen? _original;
  final Map<int, String> _customValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCitizen());
  }

  Future<void> _loadCitizen() async {
    final c = await context.read<CitizenProvider>().getCitizenByNic(widget.nic);
    if (c != null && mounted) {
      _original = c;
      _nameCtrl.text = c.name;
      _addressCtrl.text = c.address;
      _villageCtrl.text = c.village;
      _phoneCtrl.text = c.phone;
      _familyCtrl.text = c.family;
      _notesCtrl.text = c.notes;
      _gender = c.gender.isNotEmpty ? c.gender : null;
      _dob = c.dob.isNotEmpty ? c.dob : null;
      _photoPath = c.photo;
      _customValues.addAll(c.customValues);
    }
    await context.read<ColumnProvider>().loadColumns();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDob() async {
    DateTime initial = DateTime(1990);
    if (_dob != null && _dob!.isNotEmpty) {
      try {
        final parts = _dob!.split('-');
        initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _original == null) return;
    setState(() => _isSaving = true);
    final t = context.read<ProfileProvider>().t;
    final provider = context.read<CitizenProvider>();

    final updated = _original!.copyWith(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _gender ?? '',
      dob: _dob ?? '',
      family: _familyCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      photo: _photoPath,
    );

    final ok = await provider.updateCitizen(updated, _customValues);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('changes_saved')), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('error_occurred')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _phoneCtrl.dispose();
    _familyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final columns = context.watch<ColumnProvider>().columns;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('edit_citizen')),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(t('save'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            PhotoPickerWidget(
              photoPath: _photoPath,
              onCamera: () async {
                final path = await PhotoService.instance.pickFromCamera(widget.nic);
                if (path != null) setState(() => _photoPath = path);
              },
              onGallery: () async {
                final path = await PhotoService.instance.pickFromGallery(widget.nic);
                if (path != null) setState(() => _photoPath = path);
              },
              onRemove: _photoPath != null ? () {
                setState(() => _photoPath = null);
                PhotoService.instance.deletePhoto(widget.nic);
              } : null,
            ),
            const SizedBox(height: 24),

            // NIC (read-only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card_rounded, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('nic_number'), style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      Text(widget.nic, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.textHint),
                ],
              ),
            ),
            const SizedBox(height: 14),

            _sectionLabel(t('personal_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: t('full_name'), prefixIcon: const Icon(Icons.person_rounded, size: 20)),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('name_required') : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: t('address'), prefixIcon: const Icon(Icons.home_rounded, size: 20)),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _villageCtrl,
              decoration: InputDecoration(labelText: t('village'), prefixIcon: const Icon(Icons.location_on_rounded, size: 20)),
            ),
            const SizedBox(height: 14),

            _sectionLabel(t('contact_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t('phone_number'), prefixIcon: const Icon(Icons.phone_rounded, size: 20)),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(labelText: t('gender'), prefixIcon: const Icon(Icons.wc_rounded, size: 20)),
              dropdownColor: AppColors.surface,
              items: [
                DropdownMenuItem(value: 'Male', child: Text(t('male'))),
                DropdownMenuItem(value: 'Female', child: Text(t('female'))),
                DropdownMenuItem(value: 'Other', child: Text(t('other'))),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(text: _dob ?? ''),
                  decoration: InputDecoration(
                    labelText: t('date_of_birth'),
                    prefixIcon: const Icon(Icons.cake_rounded, size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _sectionLabel(t('additional_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _familyCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: t('family_details'), prefixIcon: const Icon(Icons.family_restroom_rounded, size: 20)),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: t('notes'), prefixIcon: const Icon(Icons.notes_rounded, size: 20)),
            ),

            if (columns.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel(t('custom_fields')),
              const SizedBox(height: 12),
              ...columns.map((col) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CustomFieldWidget(
                      column: col,
                      value: _customValues[col.id],
                      onChanged: (v) => setState(() => _customValues[col.id!] = v),
                    ),
                  )),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(t('update')),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }
}
