import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/citizen_provider.dart';
import '../providers/column_provider.dart';
import '../providers/profile_provider.dart';
import '../models/citizen.dart';
import '../utils/app_colors.dart';
import '../services/pdf_service.dart';

class PdfExportScreen extends StatefulWidget {
  final List<Citizen>? filteredCitizens;
  final String? filterDesc;

  const PdfExportScreen({super.key, this.filteredCitizens, this.filterDesc});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  bool _isGenerating = false;
  File? _lastGenerated;
  String _status = '';
  int _selectedOption = 0; // 0=full, 1=filtered (if available)

  Future<void> _generate(int option) async {
    setState(() { _isGenerating = true; _status = ''; _lastGenerated = null; });
    final t = context.read<ProfileProvider>().t;
    final profile = context.read<ProfileProvider>().profile;
    final columns = context.read<ColumnProvider>().columns;
    final citizenProvider = context.read<CitizenProvider>();

    try {
      File? file;
      if (option == 0) {
        // Full database
        final all = await citizenProvider.getAllCitizens();
        // Enrich with custom values
        final enriched = <Citizen>[];
        for (final c in all) {
          final full = await citizenProvider.getCitizenByNic(c.nic);
          if (full != null) enriched.add(full);
        }
        file = await PdfService.instance.generateFullDatabasePdf(enriched, columns, profile);
      } else {
        // Filtered
        final citizens = widget.filteredCitizens ?? [];
        file = await PdfService.instance.generateFilteredPdf(
          citizens, columns, profile, widget.filterDesc ?? '',
        );
      }
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _lastGenerated = file;
          _status = file != null ? t('pdf_ready') : t('error_occurred');
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isGenerating = false; _status = t('error_occurred'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final hasFiltered = widget.filteredCitizens != null && widget.filteredCitizens!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(t('pdf_export'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2635), Color(0xFF0F1923)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, size: 36, color: Color(0xFFFF7043)),
                  ),
                  const SizedBox(height: 14),
                  Text(t('pdf_export'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(t('gs_division_report'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _PdfOptionCard(
              icon: Icons.dataset_rounded,
              title: t('full_database_pdf'),
              subtitle: 'All citizens with full details',
              color: AppColors.primary,
              isSelected: _selectedOption == 0,
              onTap: () => setState(() => _selectedOption = 0),
            ),
            const SizedBox(height: 12),

            if (hasFiltered)
              _PdfOptionCard(
                icon: Icons.filter_alt_rounded,
                title: t('filtered_pdf'),
                subtitle: '${widget.filteredCitizens!.length} ${t('found_citizens')} • ${widget.filterDesc ?? ''}',
                color: AppColors.accent,
                isSelected: _selectedOption == 1,
                onTap: () => setState(() => _selectedOption = 1),
              ),

            const Spacer(),

            // Status
            if (_status.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (_lastGenerated != null ? AppColors.success : AppColors.error).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastGenerated != null ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lastGenerated != null ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _lastGenerated != null ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(_status, style: TextStyle(color: _lastGenerated != null ? AppColors.success : AppColors.error)),
                  ],
                ),
              ),

            // Action buttons
            if (_lastGenerated != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => PdfService.instance.printPdf(_lastGenerated!),
                      icon: const Icon(Icons.print_rounded),
                      label: Text(t('view')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => PdfService.instance.sharePdf(_lastGenerated!),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(t('share')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generate(_selectedOption),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                ),
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(_isGenerating ? t('generating_pdf') : t('generate_pdf')),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PdfOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PdfOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked_rounded, color: color, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
