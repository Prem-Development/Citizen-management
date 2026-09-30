import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/app_constants.dart';

class BackupInfo {
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;

  const BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final _dateFormat = DateFormat('yyyyMMdd_HHmmss');
  final _displayFormat = DateFormat('dd MMM yyyy, HH:mm');

  Future<Directory> get _backupDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, AppConstants.backupDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _photoDir async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, AppConstants.photoDir));
  }

  // ─────────────────────────────────────────────
  // CREATE BACKUP
  // ─────────────────────────────────────────────
  Future<BackupInfo?> createBackup() async {
    try {
      final backupDir = await _backupDir;
      final timestamp = _dateFormat.format(DateTime.now());
      final zipPath = path.join(backupDir.path, 'gs_backup_$timestamp.zip');

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // Add SQLite database file
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        encoder.addFile(dbFile, 'database/${path.basename(dbPath)}');
      }

      // Add citizen photos
      final photoDir = await _photoDir;
      if (await photoDir.exists()) {
        final photos = photoDir.listSync().whereType<File>().toList();
        for (final photo in photos) {
          encoder.addFile(photo, 'citizen_photos/${path.basename(photo.path)}');
        }
      }

      encoder.close();

      final zipFile = File(zipPath);
      final stat = zipFile.statSync();
      return BackupInfo(
        filePath: zipPath,
        fileName: path.basename(zipPath),
        sizeBytes: stat.size,
        createdAt: stat.modified,
      );
    } catch (e) {
      debugPrint('BackupService create error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // RESTORE BACKUP
  // ─────────────────────────────────────────────
  Future<bool> restoreBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) return false;

      final appDir = await getApplicationDocumentsDirectory();
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Close DB before replacing
      await DatabaseHelper.instance.close();

      for (final file in archive) {
        final filePath = path.join(appDir.path, 'GS_App', file.name);
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // Copy restored DB to sqflite location
      final restoredDbPath = path.join(
        appDir.path, 'GS_App', 'database', AppConstants.dbName);
      final restoredDb = File(restoredDbPath);
      if (await restoredDb.exists()) {
        final dbPath = await DatabaseHelper.instance.getDatabasePath();
        await restoredDb.copy(dbPath);
      }

      return true;
    } catch (e) {
      debugPrint('BackupService restore error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LIST BACKUPS
  // ─────────────────────────────────────────────
  Future<List<BackupInfo>> listBackups() async {
    try {
      final dir = await _backupDir;
      if (!await dir.exists()) return [];

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      return files.map((f) {
        final stat = f.statSync();
        return BackupInfo(
          filePath: f.path,
          fileName: path.basename(f.path),
          sizeBytes: stat.size,
          createdAt: stat.modified,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Pick a backup ZIP from device storage
  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return result?.files.single.path;
  }

  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  String formatDate(DateTime dt) => _displayFormat.format(dt);
}
