import 'package:flutter/material.dart';
import '../models/custom_column.dart';
import '../utils/app_colors.dart';

/// Renders a dynamic form field based on CustomColumn type
class CustomFieldWidget extends StatelessWidget {
  final CustomColumn column;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  const CustomFieldWidget({
    super.key,
    required this.column,
    required this.onChanged,
    this.value,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (column.columnType) {
      case ColumnType.yesno:
        return _YesNoField(column: column, value: value, onChanged: onChanged, readOnly: readOnly);
      case ColumnType.date:
        return _DateField(column: column, value: value, onChanged: onChanged, readOnly: readOnly);
      case ColumnType.number:
        return _NumberField(column: column, value: value, onChanged: onChanged, readOnly: readOnly);
      case ColumnType.text:
        return _TextField(column: column, value: value, onChanged: onChanged, readOnly: readOnly);
    }
  }
}

class _TextField extends StatefulWidget {
  final CustomColumn column;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  const _TextField({required this.column, this.value, required this.onChanged, required this.readOnly});

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.column.columnName,
        prefixIcon: const Icon(Icons.text_fields_rounded, size: 18),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final CustomColumn column;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  const _NumberField({required this.column, this.value, required this.onChanged, required this.readOnly});

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.number,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.column.columnName,
        prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final CustomColumn column;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  const _DateField({required this.column, this.value, required this.onChanged, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () async {
        DateTime initial = DateTime.now();
        if (value != null && value!.isNotEmpty) {
          try {
            final parts = value!.split('-');
            if (parts.length == 3) {
              initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(text: value ?? ''),
          decoration: InputDecoration(
            labelText: column.columnName,
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          ),
        ),
      ),
    );
  }
}

class _YesNoField extends StatelessWidget {
  final CustomColumn column;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  const _YesNoField({required this.column, this.value, required this.onChanged, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final isYes = value?.toLowerCase() == 'yes' || value == '1';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.toggle_on_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              column.columnName,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          if (!readOnly)
            Switch(
              value: isYes,
              onChanged: (v) => onChanged(v ? 'Yes' : 'No'),
            )
          else
            Text(
              isYes ? 'Yes' : 'No',
              style: TextStyle(
                color: isYes ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
