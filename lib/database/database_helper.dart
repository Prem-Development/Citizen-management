import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/citizen.dart';
import '../models/custom_column.dart';
import '../models/family_member.dart';
import '../models/gs_profile.dart';
import '../utils/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCitizens} (
        nic TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT DEFAULT '',
        village TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        gender TEXT DEFAULT '',
        dob TEXT DEFAULT '',
        family TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        photo TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableFamilyMembers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizen_nic TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT DEFAULT '',
        dob TEXT DEFAULT '',
        gender TEXT DEFAULT '',
        education TEXT DEFAULT '',
        marital_status TEXT DEFAULT '',
        occupation TEXT DEFAULT '',
        nic TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        FOREIGN KEY (citizen_nic) REFERENCES ${AppConstants.tableCitizens}(nic) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_family_citizen ON ${AppConstants.tableFamilyMembers}(citizen_nic)');

    await db.execute('CREATE INDEX idx_citizen_name ON ${AppConstants.tableCitizens}(name)');
    await db.execute('CREATE INDEX idx_citizen_village ON ${AppConstants.tableCitizens}(village)');
    await db.execute('CREATE INDEX idx_citizen_gender ON ${AppConstants.tableCitizens}(gender)');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableColumns} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        column_name TEXT NOT NULL,
        column_type TEXT NOT NULL DEFAULT 'text',
        display_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableColumnValues} (
        citizen_nic TEXT NOT NULL,
        column_id INTEGER NOT NULL,
        value TEXT DEFAULT '',
        PRIMARY KEY (citizen_nic, column_id),
        FOREIGN KEY (citizen_nic) REFERENCES ${AppConstants.tableCitizens}(nic) ON DELETE CASCADE,
        FOREIGN KEY (column_id) REFERENCES ${AppConstants.tableColumns}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableProfile} (
        id INTEGER PRIMARY KEY DEFAULT 1,
        name TEXT DEFAULT '',
        division TEXT DEFAULT '',
        contact TEXT DEFAULT '',
        photo TEXT,
        language TEXT DEFAULT 'en'
      )
    ''');

    // Insert default empty profile
    await db.insert(AppConstants.tableProfile, {
      'id': 1,
      'name': '',
      'division': '',
      'contact': '',
      'language': 'en',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 → v2: add family_members table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.tableFamilyMembers} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          citizen_nic TEXT NOT NULL,
          name TEXT NOT NULL,
          relationship TEXT DEFAULT '',
          dob TEXT DEFAULT '',
          gender TEXT DEFAULT '',
          education TEXT DEFAULT '',
          marital_status TEXT DEFAULT '',
          occupation TEXT DEFAULT '',
          nic TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          FOREIGN KEY (citizen_nic) REFERENCES ${AppConstants.tableCitizens}(nic) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_family_citizen ON ${AppConstants.tableFamilyMembers}(citizen_nic)');
    }
  }

  // ─────────────────────────────────────────────
  // CITIZENS
  // ─────────────────────────────────────────────

  Future<int> insertCitizen(Citizen citizen) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableCitizens,
      citizen.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateCitizen(Citizen citizen) async {
    final db = await database;
    return await db.update(
      AppConstants.tableCitizens,
      citizen.toMap(),
      where: 'nic = ?',
      whereArgs: [citizen.nic],
    );
  }

  Future<int> deleteCitizen(String nic) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableCitizens,
      where: 'nic = ?',
      whereArgs: [nic],
    );
  }

  Future<int> deleteMultipleCitizens(List<String> nics) async {
    final db = await database;
    final placeholders = List.filled(nics.length, '?').join(',');
    return await db.delete(
      AppConstants.tableCitizens,
      where: 'nic IN ($placeholders)',
      whereArgs: nics,
    );
  }

  Future<Citizen?> getCitizenByNic(String nic) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCitizens,
      where: 'nic = ?',
      whereArgs: [nic],
    );
    if (maps.isEmpty) return null;
    final citizen = Citizen.fromMap(maps.first);
    final values = await getColumnValues(nic);
    return citizen.copyWith(customValues: values);
  }

  Future<List<Citizen>> getAllCitizens() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCitizens,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Citizen.fromMap(m)).toList();
  }

  Future<List<Citizen>> searchByNic(String query) async {
    if (query.isEmpty) return getAllCitizens();
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCitizens,
      where: 'nic LIKE ? OR name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Citizen.fromMap(m)).toList();
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
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (village != null && village.isNotEmpty) {
      whereClauses.add('village LIKE ?');
      whereArgs.add('%$village%');
    }
    if (gender != null && gender.isNotEmpty) {
      whereClauses.add('gender = ?');
      whereArgs.add(gender);
    }
    if (dobFrom != null && dobFrom.isNotEmpty) {
      whereClauses.add('dob >= ?');
      whereArgs.add(dobFrom);
    }
    if (dobTo != null && dobTo.isNotEmpty) {
      whereClauses.add('dob <= ?');
      whereArgs.add(dobTo);
    }

    final String whereStr = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';
    final maps = await db.query(
      AppConstants.tableCitizens,
      where: whereStr.isEmpty ? null : whereStr,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    var citizens = maps.map((m) => Citizen.fromMap(m)).toList();

    // Age filter (post-query since age is computed)
    if (ageFrom != null || ageTo != null) {
      citizens = citizens.where((c) {
        final age = c.age;
        if (age == null) return false;
        if (ageFrom != null && age < ageFrom) return false;
        if (ageTo != null && age > ageTo) return false;
        return true;
      }).toList();
    }

    // Custom column filters
    if (customFilters != null && customFilters.isNotEmpty) {
      final filteredNics = <String>[];
      for (final c in citizens) {
        bool matches = true;
        for (final entry in customFilters.entries) {
          final val = await getColumnValue(c.nic, entry.key);
          if (val == null || !val.toLowerCase().contains(entry.value.toLowerCase())) {
            matches = false;
            break;
          }
        }
        if (matches) filteredNics.add(c.nic);
      }
      citizens = citizens.where((c) => filteredNics.contains(c.nic)).toList();
    }

    return citizens;
  }

  Future<bool> nicExists(String nic) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableCitizens,
      columns: ['nic'],
      where: 'nic = ?',
      whereArgs: [nic],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> getTotalCitizens() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppConstants.tableCitizens}');
    return result.first['cnt'] as int? ?? 0;
  }

  Future<List<String>> getDistinctVillages() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT village FROM ${AppConstants.tableCitizens} WHERE village != "" ORDER BY village ASC',
    );
    return result.map((r) => r['village'] as String).toList();
  }

  // ─────────────────────────────────────────────
  // CUSTOM COLUMNS
  // ─────────────────────────────────────────────

  Future<int> insertColumn(CustomColumn column) async {
    final db = await database;
    final maxOrder = await db.rawQuery('SELECT MAX(display_order) as mo FROM ${AppConstants.tableColumns}');
    final nextOrder = ((maxOrder.first['mo'] as int?) ?? -1) + 1;
    return await db.insert(
      AppConstants.tableColumns,
      {...column.toMap(), 'display_order': nextOrder},
    );
  }

  Future<int> updateColumn(CustomColumn column) async {
    final db = await database;
    return await db.update(
      AppConstants.tableColumns,
      column.toMap(),
      where: 'id = ?',
      whereArgs: [column.id],
    );
  }

  Future<int> deleteColumn(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableColumns,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CustomColumn>> getAllColumns() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableColumns,
      orderBy: 'display_order ASC',
    );
    return maps.map((m) => CustomColumn.fromMap(m)).toList();
  }

  Future<void> reorderColumns(List<CustomColumn> columns) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < columns.length; i++) {
      batch.update(
        AppConstants.tableColumns,
        {'display_order': i},
        where: 'id = ?',
        whereArgs: [columns[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────
  // CUSTOM COLUMN VALUES
  // ─────────────────────────────────────────────

  Future<void> upsertColumnValue(String nic, int columnId, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.tableColumnValues,
      {'citizen_nic': nic, 'column_id': columnId, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllColumnValues(String nic, Map<int, String> values) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in values.entries) {
      batch.insert(
        AppConstants.tableColumnValues,
        {'citizen_nic': nic, 'column_id': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Map<int, String>> getColumnValues(String nic) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableColumnValues,
      where: 'citizen_nic = ?',
      whereArgs: [nic],
    );
    return {for (final m in maps) m['column_id'] as int: m['value'] as String? ?? ''};
  }

  Future<String?> getColumnValue(String nic, int columnId) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableColumnValues,
      columns: ['value'],
      where: 'citizen_nic = ? AND column_id = ?',
      whereArgs: [nic, columnId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // ─────────────────────────────────────────────
  // GS PROFILE
  // ─────────────────────────────────────────────

  Future<GSProfile> getProfile() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableProfile, where: 'id = 1');
    if (maps.isEmpty) return const GSProfile();
    return GSProfile.fromMap(maps.first);
  }

  Future<void> upsertProfile(GSProfile profile) async {
    final db = await database;
    await db.insert(
      AppConstants.tableProfile,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, AppConstants.dbName);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ─────────────────────────────────────────────
  // FAMILY MEMBERS
  // ─────────────────────────────────────────────

  Future<int> insertFamilyMember(FamilyMember member) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableFamilyMembers,
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateFamilyMember(FamilyMember member) async {
    final db = await database;
    return await db.update(
      AppConstants.tableFamilyMembers,
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableFamilyMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FamilyMember>> getFamilyMembers(String citizenNic) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableFamilyMembers,
      where: 'citizen_nic = ?',
      whereArgs: [citizenNic],
      orderBy: 'id ASC',
    );
    return maps.map((m) => FamilyMember.fromMap(m)).toList();
  }

  Future<int> getFamilyMemberCount(String citizenNic) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableFamilyMembers} WHERE citizen_nic = ?',
      [citizenNic],
    );
    return result.first['cnt'] as int? ?? 0;
  }
}
