import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/gs_profile.dart';
import '../l10n/app_en.dart';
import '../l10n/app_ta.dart';
import '../utils/app_constants.dart';

class ProfileProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  GSProfile _profile = const GSProfile();
  bool _isLoading = false;

  GSProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String get language => _profile.language;
  bool get isTamil => _profile.language == AppConstants.langTamil;

  /// Translate a string key to active language
  String t(String key) {
    final map = isTamil ? taStrings : enStrings;
    return map[key] ?? key;
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _db.getProfile();
      // Sync language from shared_preferences if needed
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(AppConstants.keyLanguage);
      if (savedLang != null && savedLang != _profile.language) {
        _profile = _profile.copyWith(language: savedLang);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(GSProfile profile) async {
    await _db.upsertProfile(profile);
    _profile = profile;
    // Persist language to shared_preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, profile.language);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _profile = _profile.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, lang);
    await _db.upsertProfile(_profile);
    notifyListeners();
  }

  Future<void> updatePhoto(String? photoPath) async {
    _profile = _profile.copyWith(photo: photoPath);
    await _db.upsertProfile(_profile);
    notifyListeners();
  }
}
