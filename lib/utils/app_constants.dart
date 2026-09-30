class AppConstants {
  // App info
  static const String appName = 'GS Citizen Manager';
  static const String appVersion = '1.0.0';

  // Shared preferences keys
  static const String keyLanguage = 'language';
  static const String keyDarkMode = 'dark_mode';

  // Language codes
  static const String langEnglish = 'en';
  static const String langTamil = 'ta';

  // Column types
  static const String colTypeText = 'text';
  static const String colTypeNumber = 'number';
  static const String colTypeDate = 'date';
  static const String colTypeYesNo = 'yesno';

  // Gender options
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';
  static const String genderOther = 'Other';

  // File paths (relative to app documents dir)
  static const String photoDir = 'GS_App/citizen_photos';
  static const String pdfDir = 'GS_App/pdf_reports';
  static const String backupDir = 'GS_App/backups';
  static const String dbDir = 'GS_App/database';

  // Database
  static const String dbName = 'gs_citizens.db';
  static const int dbVersion = 2;

  // Tables
  static const String tableCitizens = 'citizens';
  static const String tableColumns = 'custom_columns';
  static const String tableColumnValues = 'custom_column_values';
  static const String tableProfile = 'gs_profile';
  static const String tableFamilyMembers = 'family_members';
}
