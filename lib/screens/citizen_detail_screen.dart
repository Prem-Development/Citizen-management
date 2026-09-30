import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../providers/citizen_provider.dart';
import '../providers/column_provider.dart';
import '../providers/family_member_provider.dart';
import '../providers/profile_provider.dart';
import '../models/citizen.dart';
import '../models/family_member.dart';
import '../database/database_helper.dart';
import '../utils/app_colors.dart';
import '../services/pdf_service.dart';
import 'edit_citizen_screen.dart';
import 'family_members_screen.dart';

class CitizenDetailScreen extends StatefulWidget {
  final String nic;

  const CitizenDetailScreen({super.key, required this.nic});

  @override
  State<CitizenDetailScreen> createState() => _CitizenDetailScreenState();
}

class _CitizenDetailScreenState extends State<CitizenDetailScreen> {
  Citizen? _citizen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCitizen();
  }

  Future<void> _loadCitizen() async {
    setState(() => _isLoading = true);
    final c = await context.read<CitizenProvider>().getCitizenByNic(widget.nic);
    if (mounted) setState(() { _citizen = c; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final columns = context.watch<ColumnProvider>().columns;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_citizen == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(t('no_data'))));
    }

    final c = _citizen!;
    final hasPhoto = c.photo != null && File(c.photo!).existsSync();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Photo SliverAppBar with Hero
          SliverAppBar(
            expandedHeight: hasPhoto ? 280 : 120,
            pinned: true,
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditCitizenScreen(nic: c.nic)),
                ).then((_) => _loadCitizen()),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                onPressed: () => _confirmDelete(context, t),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                c.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              background: hasPhoto
                  ? GestureDetector(
                      onTap: () => _openFullPhoto(context, c.photo!),
                      child: Hero(
                        tag: 'citizen_photo_${c.nic}',
                        child: Image.file(
                          File(c.photo!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D2137), AppColors.surface],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceLight,
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NIC badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.credit_card_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(c.nic, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (c.gender.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _GenderBadge(gender: c.gender),
                      ],
                      if (hasPhoto) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openFullPhoto(context, c.photo!),
                          icon: const Icon(Icons.zoom_in_rounded, size: 16),
                          label: Text(t('tap_to_zoom'), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info sections
                  _sectionCard(t('personal_info'), [
                    _infoRow(Icons.person_rounded, t('full_name'), c.name),
                    if (c.dob.isNotEmpty) _infoRow(Icons.cake_rounded, t('date_of_birth'),
                        c.age != null ? '${c.dob}  (${c.age} ${t('years')})' : c.dob),
                  ]),
                  const SizedBox(height: 12),

                  _sectionCard(t('contact_info'), [
                    if (c.address.isNotEmpty) _infoRow(Icons.home_rounded, t('address'), c.address),
                    if (c.village.isNotEmpty) _infoRow(Icons.location_on_rounded, t('village'), c.village),
                    if (c.phone.isNotEmpty) _infoRow(Icons.phone_rounded, t('phone_number'), c.phone),
                  ]),
                  const SizedBox(height: 12),

                  if (c.family.isNotEmpty || c.notes.isNotEmpty)
                    _sectionCard(t('additional_info'), [
                      if (c.family.isNotEmpty) _infoRow(Icons.family_restroom_rounded, t('family_details'), c.family),
                      if (c.notes.isNotEmpty) _infoRow(Icons.notes_rounded, t('notes'), c.notes),
                    ]),

                  const SizedBox(height: 12),
                  // Family Members Card
                  _FamilyMembersCard(citizenNic: c.nic, citizenName: c.name),

                  // Custom columns
                  if (columns.isNotEmpty && c.customValues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionCard(
                      t('custom_fields'),
                      columns
                          .where((col) => c.customValues.containsKey(col.id) && (c.customValues[col.id] ?? '').isNotEmpty)
                          .map((col) => _infoRow(Icons.label_rounded, col.columnName, c.customValues[col.id]!))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditCitizenScreen(nic: c.nic)),
                          ).then((_) => _loadCitizen()),
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(t('edit')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generatePdf(context, t),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: Text(t('generate_pdf')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullPhoto(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PhotoView(
          imageProvider: FileImage(File(path)),
          heroAttributes: PhotoViewHeroAttributes(tag: 'citizen_photo_${_citizen!.nic}'),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
        ),
      ),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, String Function(String) t) async {
    final citizenProvider = context.read<CitizenProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_citizen')),
        content: Text(t('delete_confirm')),
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
      await citizenProvider.deleteCitizen(widget.nic);
      navigator.pop();
    }
  }

  Future<void> _generatePdf(BuildContext context, String Function(String) t) async {
    if (_citizen == null) return;
    final columns = context.read<ColumnProvider>().columns;
    final profile = context.read<ProfileProvider>().profile;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(width: 16),
          Text(t('generating_pdf')),
        ]),
      ),
    );

    final file = await PdfService.instance.generateCitizenPdf(_citizen!, columns, profile);
    navigator.pop(); // close dialog

    if (file != null) {
      await PdfService.instance.sharePdf(file);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(t('error_occurred')), backgroundColor: AppColors.error),
      );
    }
  }
}

class _GenderBadge extends StatelessWidget {
  final String gender;
  const _GenderBadge({required this.gender});

  @override
  Widget build(BuildContext context) {
    final color = gender.toLowerCase() == 'male'
        ? AppColors.info
        : gender.toLowerCase() == 'female'
            ? const Color(0xFFEC407A)
            : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(gender, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────
// Family Members Card (shown in citizen detail)
// ─────────────────────────────────────────────

class _FamilyMembersCard extends StatefulWidget {
  final String citizenNic;
  final String citizenName;

  const _FamilyMembersCard({required this.citizenNic, required this.citizenName});

  @override
  State<_FamilyMembersCard> createState() => _FamilyMembersCardState();
}

class _FamilyMembersCardState extends State<_FamilyMembersCard> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  Future<void> _showAddForm(BuildContext context, String Function(String) t) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyMemberFormSheet(
        citizenNic: widget.citizenNic,
        existing: null,
        t: t,
      ),
    );
    _refresh();
  }

  Future<void> _showEditForm(BuildContext context, String Function(String) t, FamilyMember member) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyMemberFormSheet(
        citizenNic: widget.citizenNic,
        existing: member,
        t: t,
      ),
    );
    _refresh();
  }

  Future<void> _deleteMember(BuildContext context, String Function(String) t, FamilyMember member) async {
    final provider = context.read<FamilyMemberProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t('delete_member'), style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${t('delete_member_confirm')}\n\n"${member.name}"',
            style: const TextStyle(color: AppColors.textSecondary)),
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
      await provider.deleteMember(member.id!, member.citizenNic);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;

    return FutureBuilder<List<FamilyMember>>(
      key: ValueKey(_refreshKey),
      future: DatabaseHelper.instance.getFamilyMembers(widget.citizenNic),
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      t('family_members'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (members.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Text(
                          '${members.length} ${t('members_count')}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // ── Member List ──────────────────────────
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Text(t('no_family_members'),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...members.map((member) => _InlineMemberTile(
                      member: member,
                      t: t,
                      onEdit: () => _showEditForm(context, t, member),
                      onDelete: () => _deleteMember(context, t, member),
                    )),

              // ── Add Family Member Button ─────────────
              const Divider(height: 1, color: AppColors.cardBorder),
              InkWell(
                onTap: () => _showAddForm(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.person_add_rounded, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t('add_family_member'),
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Manage All Button ────────────────────
              if (members.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.cardBorder),
                InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyMembersScreen(
                        citizenNic: widget.citizenNic,
                        citizenName: widget.citizenName,
                      ),
                    ),
                  ).then((_) => _refresh()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          t('manage_family'),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Inline Member Tile
// ─────────────────────────────────────────────

class _InlineMemberTile extends StatelessWidget {
  final FamilyMember member;
  final String Function(String) t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InlineMemberTile({
    required this.member,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ageText = member.age != null ? '${member.age} ${t('years')}' : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (member.relationship.isNotEmpty)
                          _chip(member.relationship, AppColors.primary),
                        if (member.gender.isNotEmpty)
                          _chip(
                            member.gender,
                            member.gender.toLowerCase() == 'male'
                                ? AppColors.info
                                : member.gender.toLowerCase() == 'female'
                                    ? const Color(0xFFEC407A)
                                    : AppColors.textSecondary,
                          ),
                        if (ageText != null) _chip(ageText, AppColors.success),
                        if (member.maritalStatus.isNotEmpty)
                          _chip(member.maritalStatus, AppColors.textSecondary),
                        if (member.education.isNotEmpty)
                          _chip(member.education, const Color(0xFF7C4DFF)),
                        if (member.occupation.isNotEmpty)
                          _chip(member.occupation, AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                color: AppColors.surface,
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(t('edit')),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(t('delete'), style: const TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.cardBorder),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

