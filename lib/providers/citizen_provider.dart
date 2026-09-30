import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/citizen.dart';

class CitizenProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Citizen> _citizens = [];
  List<Citizen> _filteredCitizens = [];
  List<Citizen> _searchResults = [];
  Set<String> _selectedNics = {};
  bool _isMultiSelect = false;
  bool _isLoading = false;
  String _searchQuery = '';
  int _totalCount = 0;

  List<Citizen> get citizens => _citizens;
  List<Citizen> get filteredCitizens => _filteredCitizens;
  List<Citizen> get searchResults => _searchResults;
  Set<String> get selectedNics => _selectedNics;
  bool get isMultiSelect => _isMultiSelect;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get totalCount => _totalCount;
  bool get hasSelection => _selectedNics.isNotEmpty;
  int get selectionCount => _selectedNics.length;

  Future<void> loadCitizens() async {
    _isLoading = true;
    notifyListeners();
    try {
      _citizens = await _db.getAllCitizens();
      _filteredCitizens = List.from(_citizens);
      _totalCount = await _db.getTotalCitizens();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Citizen>> searchByNic(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = List.from(_citizens);
    } else {
      _searchResults = await _db.searchByNic(query);
    }
    notifyListeners();
    return _searchResults;
  }

  Future<List<Citizen>> getAllCitizens() async {
    return await _db.getAllCitizens();
  }

  Future<List<Citizen>> filterCitizens({
    String? village,
    String? gender,
    int? ageFrom,
    int? ageTo,
    String? dobFrom,
    String? dobTo,
    Map<int, String>? customFilters,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await _db.filterCitizens(
        village: village,
        gender: gender,
        ageFrom: ageFrom,
        ageTo: ageTo,
        dobFrom: dobFrom,
        dobTo: dobTo,
        customFilters: customFilters,
      );
      _filteredCitizens = results;
      return results;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCitizen(Citizen citizen, Map<int, String> customValues) async {
    try {
      final exists = await _db.nicExists(citizen.nic);
      if (exists) return false;
      await _db.insertCitizen(citizen);
      if (customValues.isNotEmpty) {
        await _db.upsertAllColumnValues(citizen.nic, customValues);
      }
      await loadCitizens();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCitizen(Citizen citizen, Map<int, String> customValues) async {
    try {
      await _db.updateCitizen(citizen);
      await _db.upsertAllColumnValues(citizen.nic, customValues);
      await loadCitizens();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCitizen(String nic) async {
    try {
      await _db.deleteCitizen(nic);
      await loadCitizens();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSelected() async {
    if (_selectedNics.isEmpty) return false;
    try {
      await _db.deleteMultipleCitizens(_selectedNics.toList());
      _selectedNics.clear();
      _isMultiSelect = false;
      await loadCitizens();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Citizen?> getCitizenByNic(String nic) async {
    return await _db.getCitizenByNic(nic);
  }

  Future<List<String>> getDistinctVillages() async {
    return await _db.getDistinctVillages();
  }

  // Multi-select
  void toggleMultiSelect() {
    _isMultiSelect = !_isMultiSelect;
    if (!_isMultiSelect) _selectedNics.clear();
    notifyListeners();
  }

  void toggleSelection(String nic) {
    if (_selectedNics.contains(nic)) {
      _selectedNics.remove(nic);
    } else {
      _selectedNics.add(nic);
    }
    if (_selectedNics.isEmpty) _isMultiSelect = false;
    notifyListeners();
  }

  void selectAll() {
    _selectedNics = _citizens.map((c) => c.nic).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedNics.clear();
    _isMultiSelect = false;
    notifyListeners();
  }

  bool isSelected(String nic) => _selectedNics.contains(nic);
}
