import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/citizen_provider.dart';
import '../providers/column_provider.dart';
import '../providers/profile_provider.dart';
import '../models/citizen.dart';
import '../models/custom_column.dart';
import '../utils/app_colors.dart';
import 'citizen_list_screen.dart';
import 'pdf_export_screen.dart';

class FilterSearchScreen extends StatefulWidget {
  const FilterSearchScreen({super.key});

  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  String? _selectedVillage;
  String? _selectedGender;
  final _ageFromCtrl = TextEditingController();
  final _ageToCtrl = TextEditingController();
  String? _dobFrom;
  String? _dobTo;
  final Map<int, TextEditingController> _customCtrls = {};

  List<String> _villages = [];
  List<Citizen> _results = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<CitizenProvider>();
    _villages = await provider.getDistinctVillages();
    await context.read<ColumnProvider>().loadColumns();
    // Init custom column controllers
    final columns = context.read<ColumnProvider>().columns;
    for (final col in columns) {
      if (col.id != null) _customCtrls[col.id!] = TextEditingController();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ageFromCtrl.dispose();
    _ageToCtrl.dispose();
    for (final c in _customCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    setState(() { _isSearching = true; _hasSearched = true; });
    final provider = context.read<CitizenProvider>();
    final columns = context.read<ColumnProvider>().columns;

    final customFilters = <int, String>{};
    for (final col in columns) {
      if (col.id != null) {
        final val = _customCtrls[col.id!]?.text.trim() ?? '';
        if (val.isNotEmpty) customFilters[col.id!] = val;
      }
    }

    final results = await provider.filterCitizens(
      village: _selectedVillage,
      gender: _selectedGender,
      ageFrom: _ageFromCtrl.text.isNotEmpty ? int.tryParse(_ageFromCtrl.text) : null,
      ageTo: _ageToCtrl.text.isNotEmpty ? int.tryParse(_ageToCtrl.text) : null,
      dobFrom: _dobFrom,
      dobTo: _dobTo,
      customFilters: customFilters.isNotEmpty ? customFilters : null,
    );

    if (mounted) setState(() { _results = results; _isSearching = false; });
  }

  void _resetFilters() {
    _ageFromCtrl.clear();
    _ageToCtrl.clear();
    for (final c in _customCtrls.values) c.clear();
    setState(() {
      _selectedVillage = null;
      _selectedGender = null;
      _dobFrom = null;
      _dobTo = null;
      _results = [];
      _hasSearched = false;
    });
  }

  String _buildFilterDesc(String Function(String) t) {
    final parts = <String>[];
    if (_selectedVillage != null) parts.add('${t('village')}: $_selectedVillage');
    if (_selectedGender != null) parts.add('${t('gender')}: $_selectedGender');
    if (_ageFromCtrl.text.isNotEmpty || _ageToCtrl.text.isNotEmpty) {
      parts.add('${t('age')}: ${_ageFromCtrl.text}-${_ageToCtrl.text}');
    }
    if (_dobFrom != null) parts.add('DOB ≥ $_dobFrom');
    if (_dobTo != null) parts.add('DOB ≤ $_dobTo');
    return parts.join(', ');
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => isFrom ? _dobFrom = s : _dobTo = s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final columns = context.watch<ColumnProvider>().columns;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('filter_title')),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(t('reset_filters'), style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter form
          Expanded(
            flex: _hasSearched ? 2 : 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(t('filter_village')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedVillage,
                    decoration: InputDecoration(
                      hintText: t('all_villages'),
                      prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                    ),
                    dropdownColor: AppColors.surface,
                    items: [
                      DropdownMenuItem(value: null, child: Text(t('all_villages'))),
                      ..._villages.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                    ],
                    onChanged: (v) => setState(() => _selectedVillage = v),
                  ),
                  const SizedBox(height: 16),

                  _label(t('filter_gender')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      hintText: t('all_genders'),
                      prefixIcon: const Icon(Icons.wc_rounded, size: 18),
                    ),
                    dropdownColor: AppColors.surface,
                    items: [
                      DropdownMenuItem(value: null, child: Text(t('all_genders'))),
                      DropdownMenuItem(value: 'Male', child: Text(t('male'))),
                      DropdownMenuItem(value: 'Female', child: Text(t('female'))),
                      DropdownMenuItem(value: 'Other', child: Text(t('other'))),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                  const SizedBox(height: 16),

                  _label(t('age')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageFromCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: t('filter_age_from')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ageToCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: t('filter_age_to')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label(t('date_of_birth')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(true),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(text: _dobFrom ?? ''),
                              decoration: InputDecoration(
                                labelText: t('filter_date_from'),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(false),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(text: _dobTo ?? ''),
                              decoration: InputDecoration(
                                labelText: t('filter_date_to'),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Custom column filters
                  if (columns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _label(t('custom_fields')),
                    const SizedBox(height: 8),
                    ...columns
                        .where((c) => c.columnType == ColumnType.text || c.columnType == ColumnType.number)
                        .map((col) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _customCtrls[col.id!],
                                decoration: InputDecoration(
                                  labelText: col.columnName,
                                  hintText: 'contains...',
                                  prefixIcon: const Icon(Icons.label_rounded, size: 18),
                                ),
                              ),
                            )),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _applyFilters,
                      icon: _isSearching
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.filter_alt_rounded),
                      label: Text(t('apply')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results
          if (_hasSearched) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Icon(
                    _results.isEmpty ? Icons.search_off_rounded : Icons.check_circle_rounded,
                    color: _results.isEmpty ? AppColors.error : AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _results.isEmpty ? t('no_results') : '${_results.length} ${t('found_citizens')}',
                    style: TextStyle(
                      color: _results.isEmpty ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_results.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CitizenListScreen(
                            prefiltered: _results,
                            filterDesc: _buildFilterDesc(t),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.list_rounded, size: 16),
                      label: Text(t('view'), style: const TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfExportScreen(
                            filteredCitizens: _results,
                            filterDesc: _buildFilterDesc(t),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(t('export_pdf'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
