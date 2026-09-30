import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/custom_column.dart';

class ColumnProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CustomColumn> _columns = [];
  bool _isLoading = false;

  List<CustomColumn> get columns => _columns;
  bool get isLoading => _isLoading;
  bool get hasColumns => _columns.isNotEmpty;

  Future<void> loadColumns() async {
    _isLoading = true;
    notifyListeners();
    try {
      _columns = await _db.getAllColumns();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addColumn(String name, ColumnType type) async {
    try {
      final column = CustomColumn(columnName: name, columnType: type);
      final id = await _db.insertColumn(column);
      _columns.add(column.copyWith(id: id, displayOrder: _columns.length));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateColumn(CustomColumn column) async {
    try {
      await _db.updateColumn(column);
      final idx = _columns.indexWhere((c) => c.id == column.id);
      if (idx >= 0) {
        _columns[idx] = column;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteColumn(int id) async {
    try {
      await _db.deleteColumn(id);
      _columns.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reorderColumns(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final item = _columns.removeAt(oldIndex);
    _columns.insert(newIndex, item);
    notifyListeners();
    await _db.reorderColumns(_columns);
  }

  CustomColumn? getColumnById(int id) {
    try {
      return _columns.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
