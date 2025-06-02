import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:arkiva/services/encryption_service.dart';
import 'package:arkiva/services/logging_service.dart';

class BackupService {
  static const String _backupDirName = 'backups';
  static const int _maxBackups = 5;
  final EncryptionService _encryptionService;
  final LoggingService _loggingService;

  BackupService(this._encryptionService, this._loggingService);

  Future<String> createBackup({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'backup_$timestamp.json';
      final backupFile = File(path.join(backupDir.path, backupFileName));

      // Préparer les données de sauvegarde
      final backupData = {
        'timestamp': timestamp,
        'version': '1.0.0',
        'data': data,
      };

      // Chiffrer les données
      final encryptedData = await _encryptionService.encryptFile(
        utf8.encode(jsonEncode(backupData)) as Uint8List,
      );

      // Sauvegarder le fichier
      await backupFile.writeAsBytes(encryptedData);

      // Journaliser la sauvegarde
      await _loggingService.log(
        action: 'backup_created',
        userId: userId,
        level: LogLevel.info,
        details: 'Sauvegarde créée: $backupFileName',
        metadata: {
          'backup_file': backupFileName,
          'data_size': data.toString().length,
        },
      );

      // Nettoyer les anciennes sauvegardes
      await _cleanupOldBackups();

      return backupFileName;
    } catch (e) {
      await _loggingService.log(
        action: 'backup_failed',
        userId: userId,
        level: LogLevel.error,
        details: 'Erreur lors de la création de la sauvegarde: $e',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreBackup({
    required String userId,
    required String backupFileName,
  }) async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File(path.join(backupDir.path, backupFileName));

      if (!await backupFile.exists()) {
        throw Exception('Fichier de sauvegarde introuvable');
      }

      // Lire et déchiffrer les données
      final encryptedData = await backupFile.readAsBytes();
      final decryptedData = await _encryptionService.decryptFile(encryptedData);
      final backupData = jsonDecode(utf8.decode(decryptedData));

      // Journaliser la restauration
      await _loggingService.log(
        action: 'backup_restored',
        userId: userId,
        level: LogLevel.info,
        details: 'Sauvegarde restaurée: $backupFileName',
        metadata: {
          'backup_file': backupFileName,
          'backup_version': backupData['version'],
        },
      );

      return backupData['data'];
    } catch (e) {
      await _loggingService.log(
        action: 'restore_failed',
        userId: userId,
        level: LogLevel.error,
        details: 'Erreur lors de la restauration de la sauvegarde: $e',
        metadata: {
          'backup_file': backupFileName,
        },
      );
      rethrow;
    }
  }

  Future<List<String>> listBackups() async {
    final backupDir = await _getBackupDirectory();
    final files = await backupDir.list().toList();
    return files
        .whereType<File>()
        .map((file) => path.basename(file.path))
        .where((name) => name.startsWith('backup_'))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Trier par ordre décroissant
  }

  Future<void> _cleanupOldBackups() async {
    final backups = await listBackups();
    if (backups.length <= _maxBackups) return;

    final backupDir = await _getBackupDirectory();
    for (var i = _maxBackups; i < backups.length; i++) {
      final file = File(path.join(backupDir.path, backups[i]));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, _backupDirName));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }
} 