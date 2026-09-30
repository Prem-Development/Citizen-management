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

class AddCitizenScreen extends StatefulWidget {
  const AddCitizenScreen({super.key});

  @override
  State<AddCitizenScreen> createState() => _AddCitizenScreenState();
}

class _AddCitizenScreenState extends State<AddCitizenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicCtrl = TextEditingController();
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
  final Map<int, String> _customValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColumnProvider>().loadColumns();
    });
  }

  @override
  void dispose() {
    _nicCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _phoneCtrl.dispose();
    _familyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final t = context.read<ProfileProvider>().t;
    final provider = context.read<CitizenProvider>();

    final citizen = Citizen(
      nic: _nicCtrl.text.trim(),
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

    final ok = await provider.addCitizen(citizen, _customValues);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('citizen_added')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('nic_exists')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final columns = context.watch<ColumnProvider>().columns;

    return Scaffold(
      appBar: AppBar(title: Text(t('add_new_citizen'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker
            PhotoPickerWidget(
              photoPath: _photoPath,
              onCamera: () async {
                final path = await PhotoService.instance.pickFromCamera(
                  _nicCtrl.text.isNotEmpty ? _nicCtrl.text.trim() : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                );
                if (path != null) setState(() => _photoPath = path);
              },
              onGallery: () async {
                final path = await PhotoService.instance.pickFromGallery(
                  _nicCtrl.text.isNotEmpty ? _nicCtrl.text.trim() : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                );
                if (path != null) setState(() => _photoPath = path);
              },
              onRemove: _photoPath != null ? () => setState(() => _photoPath = null) : null,
            ),
            const SizedBox(height: 24),

            _sectionHeader(t('personal_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nicCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t('nic_number'),
                prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('nic_required') : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: t('full_name'),
                prefixIcon: const Icon(Icons.person_rounded, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('name_required') : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('address'),
                prefixIcon: const Icon(Icons.home_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _villageCtrl,
              decoration: InputDecoration(
                labelText: t('village'),
                prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            _sectionHeader(t('contact_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: t('phone_number'),
                prefixIcon: const Icon(Icons.phone_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: t('gender'),
                prefixIcon: const Icon(Icons.wc_rounded, size: 20),
              ),
              dropdownColor: AppColors.surface,
              items: [
                DropdownMenuItem(value: 'Male', child: Text(t('male'))),
                DropdownMenuItem(value: 'Female', child: Text(t('female'))),
                DropdownMenuItem(value: 'Other', child: Text(t('other'))),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),

            // DOB
            GestureDetector(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: TextFormField(
                  key: ValueKey(_dob),
                  initialValue: _dob ?? '',
                  decoration: InputDecoration(
                    labelText: t('date_of_birth'),
                    prefixIcon: const Icon(Icons.cake_rounded, size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _sectionHeader(t('additional_info')),
            const SizedBox(height: 12),

            TextFormField(
              controller: _familyCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t('family_details'),
                prefixIcon: const Icon(Icons.family_restroom_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t('notes'),
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              ),
            ),

            // Custom columns
            if (columns.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader(t('custom_fields')),
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
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(t('save')),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }
}
