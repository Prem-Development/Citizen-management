import '../utils/app_constants.dart';

enum ColumnType { text, number, date, yesno }

extension ColumnTypeExtension on ColumnType {
  String get key {
    switch (this) {
      case ColumnType.text: return AppConstants.colTypeText;
      case ColumnType.number: return AppConstants.colTypeNumber;
      case ColumnType.date: return AppConstants.colTypeDate;
      case ColumnType.yesno: return AppConstants.colTypeYesNo;
    }
  }

  static ColumnType fromKey(String key) {
    switch (key) {
      case AppConstants.colTypeNumber: return ColumnType.number;
      case AppConstants.colTypeDate: return ColumnType.date;
      case AppConstants.colTypeYesNo: return ColumnType.yesno;
      default: return ColumnType.text;
    }
  }
}

class CustomColumn {
  final int? id;
  final String columnName;
  final ColumnType columnType;
  final int displayOrder;

  const CustomColumn({
    this.id,
    required this.columnName,
    required this.columnType,
    this.displayOrder = 0,
  });

  CustomColumn copyWith({
    int? id,
    String? columnName,
    ColumnType? columnType,
    int? displayOrder,
  }) {
    return CustomColumn(
      id: id ?? this.id,
      columnName: columnName ?? this.columnName,
      columnType: columnType ?? this.columnType,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'column_name': columnName,
      'column_type': columnType.key,
      'display_order': displayOrder,
    };
  }

  factory CustomColumn.fromMap(Map<String, dynamic> map) {
    return CustomColumn(
      id: map['id'] as int?,
      columnName: map['column_name'] as String? ?? '',
      columnType: ColumnTypeExtension.fromKey(map['column_type'] as String? ?? 'text'),
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomColumn && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomColumn(id: $id, name: $columnName, type: ${columnType.key})';
}
