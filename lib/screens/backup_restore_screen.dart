import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/backup_service.dart';
import '../utils/app_colors.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  List<BackupInfo> _backups = [];
  bool _isCreating = false;
  bool _isRestoring = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    _backups = await BackupService.instance.listBackups();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    final t = context.read<ProfileProvider>().t;
    setState(() => _isCreating = true);
    final info = await BackupService.instance.createBackup();
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (info != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('backup_created')), backgroundColor: AppColors.success),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('error_occurred')), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _restoreFromFile() async {
    final t = context.read<ProfileProvider>().t;
    final path = await BackupService.instance.pickBackupFile();
    if (path == null) return;
    await _restoreBackup(path, t);
  }

  Future<void> _restoreBackup(String zipPath, String Function(String) t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('restore_backup')),
        content: Text(t('restore_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isRestoring = true);
    final success = await BackupService.instance.restoreBackup(zipPath);
    if (!mounted) return;
    setState(() => _isRestoring = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? t('restore_success') : t('error_occurred')),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
    if (success) _loadBackups();
  }

  Future<void> _deleteBackup(BackupInfo info, String Function(String) t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete')),
        content: Text('Delete backup "${info.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await BackupService.instance.deleteBackup(info.filePath);
      _loadBackups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<ProfileProvider>().t;

    return Scaffold(
      appBar: AppBar(title: Text(t('backup_restore'))),
      body: Column(
        children: [
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              children: [
                // Create backup
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating || _isRestoring ? null : _createBackup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                    ),
                    icon: _isCreating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isCreating ? t('creating_backup') : t('create_backup')),
                  ),
                ),
                const SizedBox(height: 10),
                // Restore from file
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isCreating || _isRestoring ? null : _restoreFromFile,
                    icon: _isRestoring
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                        : const Icon(Icons.folder_open_rounded),
                    label: Text(_isRestoring ? t('restoring_backup') : t('select_backup_file')),
                  ),
                ),
              ],
            ),
          ),

          // Backups list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Backup History',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                  onPressed: _loadBackups,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _backups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 60, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(t('no_backups'), style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _backups.length,
                        itemBuilder: (ctx, i) {
                          final backup = _backups[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.folder_zip_rounded, color: AppColors.primary, size: 22),
                              ),
                              title: Text(
                                backup.fileName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${backup.sizeFormatted} • ${BackupService.instance.formatDate(backup.createdAt)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore_rounded, color: AppColors.success, size: 20),
                                    onPressed: () => _restoreBackup(backup.filePath, t),
                                    tooltip: t('restore_backup_btn'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                                    onPressed: () => _deleteBackup(backup, t),
                                    tooltip: t('delete'),
                                  ),
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
