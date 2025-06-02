import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum LogLevel {
  info,
  warning,
  error,
  security,
}

class LoggingService {
  static const String _logFileName = 'arkiva_logs.json';
  late final File _logFile;
  final List<Map<String, dynamic>> _logBuffer = [];
  static const int _maxBufferSize = 100;

  LoggingService() {
    _initializeLogging();
  }

  Future<void> _initializeLogging() async {
    final appDir = await getApplicationDocumentsDirectory();
    _logFile = File(path.join(appDir.path, _logFileName));
    
    if (!await _logFile.exists()) {
      await _logFile.writeAsString('[]');
    }
  }

  Future<void> log({
    required String action,
    required String userId,
    required LogLevel level,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'userId': userId,
      'level': level.toString(),
      'details': details,
      'metadata': metadata,
    };

    _logBuffer.add(logEntry);

    if (_logBuffer.length >= _maxBufferSize) {
      await _flushLogs();
    }
  }

  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty) return;

    try {
      final existingLogs = await _readLogs();
      existingLogs.addAll(_logBuffer);
      
      // Limiter la taille du fichier de logs (garder les 1000 dernières entrées)
      if (existingLogs.length > 1000) {
        existingLogs.removeRange(0, existingLogs.length - 1000);
      }

      await _logFile.writeAsString(jsonEncode(existingLogs));
      _logBuffer.clear();
    } catch (e) {
      print('Erreur lors de l\'écriture des logs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _readLogs() async {
    try {
      final content = await _logFile.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur lors de la lecture des logs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    String? userId,
  }) async {
    final logs = await _readLogs();
    
    return logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      
      if (startDate != null && timestamp.isBefore(startDate)) {
        return false;
      }
      
      if (endDate != null && timestamp.isAfter(endDate)) {
        return false;
      }
      
      if (level != null && log['level'] != level.toString()) {
        return false;
      }
      
      if (userId != null && log['userId'] != userId) {
        return false;
      }
      
      return true;
    }).toList();
  }

  Future<void> clearLogs() async {
    await _logFile.writeAsString('[]');
    _logBuffer.clear();
  }

  Future<void> dispose() async {
    await _flushLogs();
  }
} 