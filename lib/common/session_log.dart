import 'dart:io';
import 'package:path/path.dart';

class SessionLog {
  static SessionLog? _instance;
  File? _logFile;

  SessionLog._();

  factory SessionLog() {
    _instance ??= SessionLog._();
    return _instance!;
  }

  /// Initialize session log - clears previous session and creates new log file
  Future<void> init() async {
    try {
      if (Platform.isWindows) {
        final appDataPath = Platform.environment['APPDATA'];
        if (appDataPath != null) {
          final logDir = Directory(join(appDataPath, 'Flowvy'));
          if (!await logDir.exists()) {
            await logDir.create(recursive: true);
          }
          _logFile = File(join(logDir.path, 'session_log.txt'));

          // Clear previous session log
          if (await _logFile!.exists()) {
            await _logFile!.delete();
          }
          await _logFile!.create();

          write('Session started');
        }
      }
    } catch (e) {
      // Silently fail - logging is not critical
    }
  }

  /// Write message to session log with timestamp
  void write(String message) {
    try {
      if (_logFile != null) {
        final timestamp = DateTime.now().toIso8601String();
        _logFile!.writeAsStringSync(
          '[$timestamp] $message\n',
          mode: FileMode.append,
        );
      }
    } catch (e) {
      // Silently fail - logging is not critical
    }
  }
}

final sessionLog = SessionLog();
