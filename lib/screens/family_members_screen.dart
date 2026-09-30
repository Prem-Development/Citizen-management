import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/family_member.dart';
import '../providers/family_member_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/app_colors.dart';

class FamilyMembersScreen extends StatefulWidget {
  final String citizenNic;
  final String citizenName;

  const FamilyMembersScreen({
    super.key,
    required this.citizenNic,
    required this.citizenName,
  });

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyMemberProvider>().loadMembers(widget.citizenNic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final provider = context.watch<FamilyMemberProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('family_members'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              widget.citizenName,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMemberForm(context, t, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(t('add_family_member'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.members.isEmpty
              ? _buildEmptyState(t)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: provider.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = provider.members[index];
                    return _MemberCard(
                      member: member,
                      t: t,
                      onEdit: () => _showMemberForm(context, t, member),
                      onDelete: () => _confirmDelete(context, t, member),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            t('no_family_members'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            t('add_family_member'),
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _showMemberForm(BuildContext context, String Function(String) t, FamilyMember? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyMemberFormSheet(
        citizenNic: widget.citizenNic,
        existing: existing,
        t: t,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String Function(String) t, FamilyMember member) async {
    final provider = context.read<FamilyMemberProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t('delete_member'), style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${t('delete_member_confirm')}\n\n"${member.name}"',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await provider.deleteMember(member.id!, member.citizenNic);
      if (success) {
        messenger.showSnackBar(
          SnackBar(content: Text(t('family_member_deleted')), backgroundColor: AppColors.success),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// Member Card Widget
// ─────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final String Function(String) t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ageText = member.age != null ? '${member.age} ${t('years')}' : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withAlpha(25),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (member.relationship.isNotEmpty) _badge(member.relationship, AppColors.primary),
                          if (member.gender.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _badge(
                              member.gender,
                              member.gender.toLowerCase() == 'male'
                                  ? AppColors.info
                                  : member.gender.toLowerCase() == 'female'
                                      ? const Color(0xFFEC407A)
                                      : AppColors.textSecondary,
                            ),
                          ],
                          if (ageText != null) ...[
                            const SizedBox(width: 6),
                            _badge(ageText, AppColors.success),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(t('edit')),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(t('delete'), style: const TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          // Detail rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                if (member.education.isNotEmpty) _detailRow(Icons.school_rounded, t('education'), member.education),
                if (member.maritalStatus.isNotEmpty) _detailRow(Icons.favorite_rounded, t('marital_status'), member.maritalStatus),
                if (member.occupation.isNotEmpty) _detailRow(Icons.work_rounded, t('occupation'), member.occupation),
                if (member.nic.isNotEmpty) _detailRow(Icons.credit_card_rounded, t('nic_number'), member.nic),
                if (member.dob.isNotEmpty)
                  _detailRow(Icons.cake_rounded, t('date_of_birth'),
                      member.age != null ? '${member.dob}  (${member.age} ${t('years')})' : member.dob),
                if (member.notes.isNotEmpty) _detailRow(Icons.notes_rounded, t('additional_notes'), member.notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add / Edit Form Bottom Sheet
// ─────────────────────────────────────────────

class FamilyMemberFormSheet extends StatefulWidget {
  final String citizenNic;
  final FamilyMember? existing;
  final String Function(String) t;

  const FamilyMemberFormSheet({
    super.key,
    required this.citizenNic,
    required this.existing,
    required this.t,
  });

  @override
  State<FamilyMemberFormSheet> createState() => _FamilyMemberFormSheetState();
}

class _FamilyMemberFormSheetState extends State<FamilyMemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _relationship;
  String? _gender;
  String? _education;
  String? _maritalStatus;
  String? _dob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _nicCtrl.text = e.nic;
      _occupationCtrl.text = e.occupation;
      _notesCtrl.text = e.notes;
      _relationship = e.relationship.isNotEmpty ? e.relationship : null;
      _gender = e.gender.isNotEmpty ? e.gender : null;
      _education = e.education.isNotEmpty ? e.education : null;
      _maritalStatus = e.maritalStatus.isNotEmpty ? e.maritalStatus : null;
      _dob = e.dob.isNotEmpty ? e.dob : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicCtrl.dispose();
    _occupationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final t = widget.t;
    final provider = context.read<FamilyMemberProvider>();

    final member = FamilyMember(
      id: widget.existing?.id,
      citizenNic: widget.citizenNic,
      name: _nameCtrl.text.trim(),
      relationship: _relationship ?? '',
      dob: _dob ?? '',
      gender: _gender ?? '',
      education: _education ?? '',
      maritalStatus: _maritalStatus ?? '',
      occupation: _occupationCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    final bool ok;
    if (widget.existing == null) {
      ok = await provider.addMember(member);
    } else {
      ok = await provider.updateMember(member);
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing == null ? t('family_member_added') : t('family_member_updated')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('error_occurred')), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isEdit = widget.existing != null;

    final relationships = [
      ('rel_spouse', t('rel_spouse')),
      ('rel_son', t('rel_son')),
      ('rel_daughter', t('rel_daughter')),
      ('rel_father', t('rel_father')),
      ('rel_mother', t('rel_mother')),
      ('rel_brother', t('rel_brother')),
      ('rel_sister', t('rel_sister')),
      ('rel_grandfather', t('rel_grandfather')),
      ('rel_grandmother', t('rel_grandmother')),
      ('rel_uncle', t('rel_uncle')),
      ('rel_aunt', t('rel_aunt')),
      ('rel_other', t('rel_other')),
    ];

    final educationOptions = [
      t('edu_none'),
      t('edu_primary'),
      t('edu_secondary'),
      t('edu_ol'),
      t('edu_al'),
      t('edu_diploma'),
      t('edu_degree'),
      t('edu_postgrad'),
      t('edu_other'),
    ];

    final maritalOptions = [
      t('mar_single'),
      t('mar_married'),
      t('mar_divorced'),
      t('mar_widowed'),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? t('edit_family_member') : t('add_family_member'),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: AppColors.cardBorder),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: t('member_name'),
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? t('name_required') : null,
                    ),
                    const SizedBox(height: 14),

                    // Relationship
                    DropdownButtonFormField<String>(
                      initialValue: _relationship,
                      decoration: InputDecoration(
                        labelText: t('relationship'),
                        prefixIcon: const Icon(Icons.people_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: relationships
                          .map((r) => DropdownMenuItem(value: r.$2, child: Text(r.$2)))
                          .toList(),
                      onChanged: (v) => setState(() => _relationship = v),
                    ),
                    const SizedBox(height: 14),

                    // Gender
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: t('gender'),
                        prefixIcon: const Icon(Icons.wc_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: [
                        DropdownMenuItem(value: t('male'), child: Text(t('male'))),
                        DropdownMenuItem(value: t('female'), child: Text(t('female'))),
                        DropdownMenuItem(value: t('other'), child: Text(t('other'))),
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

                    // Education
                    DropdownButtonFormField<String>(
                      initialValue: _education,
                      decoration: InputDecoration(
                        labelText: t('education'),
                        prefixIcon: const Icon(Icons.school_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: educationOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _education = v),
                    ),
                    const SizedBox(height: 14),

                    // Marital Status
                    DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
                      decoration: InputDecoration(
                        labelText: t('marital_status'),
                        prefixIcon: const Icon(Icons.favorite_rounded, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: maritalOptions
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _maritalStatus = v),
                    ),
                    const SizedBox(height: 14),

                    // Occupation
                    TextFormField(
                      controller: _occupationCtrl,
                      decoration: InputDecoration(
                        labelText: t('occupation'),
                        prefixIcon: const Icon(Icons.work_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // NIC
                    TextFormField(
                      controller: _nicCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: t('member_nic'),
                        prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes (extra options)
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: t('additional_notes'),
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        hintText: '...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
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
                            : Icon(isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                        label: Text(isEdit ? t('update') : t('save')),
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
}
