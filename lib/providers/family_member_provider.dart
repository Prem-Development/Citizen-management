import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/family_member.dart';

class FamilyMemberProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<FamilyMember> _members = [];
  bool _isLoading = false;
  String? _currentNic;

  List<FamilyMember> get members => _members;
  bool get isLoading => _isLoading;
  int get memberCount => _members.length;

  Future<void> loadMembers(String citizenNic) async {
    _currentNic = citizenNic;
    _isLoading = true;
    notifyListeners();
    try {
      _members = await _db.getFamilyMembers(citizenNic);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMember(FamilyMember member) async {
    try {
      await _db.insertFamilyMember(member);
      if (_currentNic == member.citizenNic) {
        _members = await _db.getFamilyMembers(member.citizenNic);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('FamilyMemberProvider.addMember error: $e');
      return false;
    }
  }

  Future<bool> updateMember(FamilyMember member) async {
    try {
      await _db.updateFamilyMember(member);
      if (_currentNic == member.citizenNic) {
        _members = await _db.getFamilyMembers(member.citizenNic);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('FamilyMemberProvider.updateMember error: $e');
      return false;
    }
  }

  Future<bool> deleteMember(int id, String citizenNic) async {
    try {
      await _db.deleteFamilyMember(id);
      if (_currentNic == citizenNic) {
        _members = await _db.getFamilyMembers(citizenNic);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('FamilyMemberProvider.deleteMember error: $e');
      return false;
    }
  }

  Future<int> getMemberCount(String citizenNic) async {
    return await _db.getFamilyMemberCount(citizenNic);
  }

  void clear() {
    _members = [];
    _currentNic = null;
    notifyListeners();
  }
}
