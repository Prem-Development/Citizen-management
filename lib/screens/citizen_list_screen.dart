import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/citizen_provider.dart';
import '../providers/profile_provider.dart';
import '../models/citizen.dart';
import '../utils/app_colors.dart';
import '../widgets/citizen_card.dart';
import 'add_citizen_screen.dart';
import 'citizen_detail_screen.dart';
import 'edit_citizen_screen.dart';
import 'filter_search_screen.dart';

class CitizenListScreen extends StatefulWidget {
  final String? initialSearch;
  final List<Citizen>? prefiltered;
  final String? filterDesc;

  const CitizenListScreen({
    super.key,
    this.initialSearch,
    this.prefiltered,
    this.filterDesc,
  });

  @override
  State<CitizenListScreen> createState() => _CitizenListScreenState();
}

class _CitizenListScreenState extends State<CitizenListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Citizen> _displayList = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider = context.read<CitizenProvider>();
    if (widget.prefiltered != null) {
      setState(() => _displayList = widget.prefiltered!);
      return;
    }
    await provider.loadCitizens();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchCtrl.text = widget.initialSearch!;
      await _onSearch(widget.initialSearch!);
    } else {
      setState(() => _displayList = provider.citizens);
    }
    setState(() => _initialized = true);
  }

  Future<void> _onSearch(String query) async {
    final provider = context.read<CitizenProvider>();
    if (query.isEmpty) {
      setState(() => _displayList = provider.citizens);
    } else {
      final results = await provider.searchByNic(query);
      setState(() => _displayList = results);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CitizenProvider>();
    final t = context.read<ProfileProvider>().t;

    return Scaffold(
      appBar: AppBar(
        title: provider.isMultiSelect
            ? Text('${provider.selectionCount} selected')
            : Text(widget.filterDesc != null ? t('search_results') : t('citizen_list')),
        actions: provider.isMultiSelect
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all_rounded),
                  onPressed: provider.selectAll,
                  tooltip: t('select_all'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                  onPressed: () => _confirmDeleteSelected(context, t),
                  tooltip: t('delete_selected'),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: provider.clearSelection,
                ),
              ]
            : [
                if (widget.prefiltered == null)
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FilterSearchScreen()),
                    ),
                    tooltip: t('filter_search'),
                  ),
              ],
      ),
      body: Column(
        children: [
          // Filter description banner
          if (widget.filterDesc != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.accent.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.filterDesc!,
                      style: const TextStyle(color: AppColors.accent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_displayList.length} ${t('found_citizens')}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Search bar (only when not showing prefiltered)
          if (widget.prefiltered == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: t('search_by_nic'),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),

          // List
          Expanded(
            child: provider.isLoading && !_initialized
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _displayList.isEmpty
                    ? _buildEmpty(t)
                    : AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: _displayList.length,
                          itemBuilder: (ctx, i) {
                            final citizen = _displayList[i];
                            return AnimationConfiguration.staggeredList(
                              position: i,
                              duration: const Duration(milliseconds: 350),
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: CitizenCard(
                                    citizen: citizen,
                                    isSelected: provider.isSelected(citizen.nic),
                                    isMultiSelect: provider.isMultiSelect,
                                    onTap: () {
                                      if (provider.isMultiSelect) {
                                        provider.toggleSelection(citizen.nic);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CitizenDetailScreen(nic: citizen.nic),
                                          ),
                                        ).then((_) => _init());
                                      }
                                    },
                                    onLongPress: () {
                                      if (!provider.isMultiSelect) {
                                        provider.toggleMultiSelect();
                                        provider.toggleSelection(citizen.nic);
                                      }
                                    },
                                    onView: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CitizenDetailScreen(nic: citizen.nic),
                                      ),
                                    ).then((_) => _init()),
                                    onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditCitizenScreen(nic: citizen.nic),
                                      ),
                                    ).then((_) => _init()),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.prefiltered == null
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCitizenScreen()),
              ).then((_) => _init()),
              child: const Icon(Icons.person_add_rounded),
            )
          : null,
    );
  }

  Widget _buildEmpty(String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 72, color: AppColors.textHint.withAlpha(120)),
          const SizedBox(height: 16),
          Text(
            t('no_citizens'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            t('long_press_select'),
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context, String Function(String) t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_citizen')),
        content: Text(t('delete_multiple_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<CitizenProvider>().deleteSelected();
      if (success && mounted) {
        await _init();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('delete_success'))),
        );
      }
    }
  }
}
