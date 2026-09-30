import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/column_provider.dart';
import '../providers/profile_provider.dart';
import '../models/custom_column.dart';
import '../utils/app_colors.dart';

class AddColumnScreen extends StatefulWidget {
  const AddColumnScreen({super.key});

  @override
  State<AddColumnScreen> createState() => _AddColumnScreenState();
}

class _AddColumnScreenState extends State<AddColumnScreen> {
  final _nameCtrl = TextEditingController();
  ColumnType _selectedType = ColumnType.text;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColumnProvider>().loadColumns();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addColumn() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    final t = context.read<ProfileProvider>().t;
    final ok = await context.read<ColumnProvider>().addColumn(name, _selectedType);
    setState(() => _isSaving = false);
    if (mounted) {
      _nameCtrl.clear();
      setState(() => _selectedType = ColumnType.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? t('column_added') : t('error_occurred')),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _editColumn(BuildContext context, CustomColumn col, String Function(String) t) async {
    final ctrl = TextEditingController(text: col.columnName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('edit_column')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: t('column_name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('save')),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
      await context.read<ColumnProvider>().updateColumn(col.copyWith(columnName: ctrl.text.trim()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('column_updated')), backgroundColor: AppColors.success),
        );
      }
    }
    ctrl.dispose();
  }

  Future<void> _deleteColumn(BuildContext context, CustomColumn col, String Function(String) t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('delete_column_confirm')),
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
    if (ok == true && mounted) {
      await context.read<ColumnProvider>().deleteColumn(col.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('column_deleted')), backgroundColor: AppColors.success),
        );
      }
    }
  }

  String _typeLabel(ColumnType type, String Function(String) t) {
    switch (type) {
      case ColumnType.text: return t('col_type_text');
      case ColumnType.number: return t('col_type_number');
      case ColumnType.date: return t('col_type_date');
      case ColumnType.yesno: return t('col_type_yesno');
    }
  }

  IconData _typeIcon(ColumnType type) {
    switch (type) {
      case ColumnType.text: return Icons.text_fields_rounded;
      case ColumnType.number: return Icons.numbers_rounded;
      case ColumnType.date: return Icons.calendar_today_rounded;
      case ColumnType.yesno: return Icons.toggle_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;
    final columns = context.watch<ColumnProvider>().columns;

    return Scaffold(
      appBar: AppBar(title: Text(t('manage_columns'))),
      body: Column(
        children: [
          // Add new column form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(t('add_column'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: t('column_name'),
                          prefixIcon: const Icon(Icons.label_rounded, size: 18),
                        ),
                        onSubmitted: (_) => _addColumn(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<ColumnType>(
                        value: _selectedType,
                        decoration: InputDecoration(labelText: t('column_type')),
                        dropdownColor: AppColors.surface,
                        items: ColumnType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_typeIcon(type), size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(_typeLabel(type, t), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedType = v ?? ColumnType.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _addColumn,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_rounded),
                    label: Text(t('add_column')),
                  ),
                ),
              ],
            ),
          ),

          // Column list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(t('drag_to_reorder'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Text('${columns.length} columns', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),

          // Existing columns with drag-to-reorder
          Expanded(
            child: columns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_chart_outlined, size: 60, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(t('no_columns'), style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('Add your first custom column above', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    onReorder: (oldIdx, newIdx) {
                      context.read<ColumnProvider>().reorderColumns(oldIdx, newIdx);
                    },
                    itemCount: columns.length,
                    itemBuilder: (ctx, i) {
                      final col = columns[i];
                      return Container(
                        key: ValueKey(col.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_typeIcon(col.columnType), color: AppColors.primary, size: 18),
                          ),
                          title: Text(col.columnName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _typeLabel(col.columnType, t),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.accent),
                                onPressed: () => _editColumn(context, col, t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                                onPressed: () => _deleteColumn(context, col, t),
                              ),
                              const Icon(Icons.drag_handle_rounded, color: AppColors.textHint, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
