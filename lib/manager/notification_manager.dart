import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/plugins/notification.dart';

class NotificationManager {
  static NotificationManager? _instance;
  late FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  DateTime? _lastProgressUpdate;
  int? _lastProgressPercentage;
  static const _progressUpdateThrottle = Duration(milliseconds: 500);

  NotificationManager._internal();

  factory NotificationManager() {
    _instance ??= NotificationManager._internal();
    return _instance!;
  }

  Future<void> init() async {
    if (_initialized) return;

    _notifications = FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher_foreground');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(initSettings);
    } else if (Platform.isLinux) {
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');
      const initSettings = InitializationSettings(linux: linuxSettings);
      await _notifications.initialize(initSettings);
    } else if (Platform.isMacOS) {
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(macOS: darwinSettings);
      await _notifications.initialize(initSettings);
    } else if (Platform.isWindows) {
      const appId = 'Flowvy.App';

      try {
        await _registerInRegistry(appId);
      } catch (e) {
        commonPrint.log('Failed to register in registry: $e');
      }

      try {
        await _updateShortcut(appId);
      } catch (_) {
        // Ignore shortcut update errors
      }
    }

    _initialized = true;
  }

  Future<void> _registerInRegistry(String appId) async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = exePath.substring(0, exePath.lastIndexOf('\\'));
      final iconPath = '$exeDir\\data\\flutter_assets\\assets\\images\\icon_bg_white.png';

      await Process.run(
        'reg',
        [
          'add',
          'HKCU\\Software\\Classes\\AppUserModelId\\$appId',
          '/f',
        ],
      );

      await Process.run(
        'reg',
        [
          'add',
          'HKCU\\Software\\Classes\\AppUserModelId\\$appId',
          '/v',
          'DisplayName',
          '/t',
          'REG_SZ',
          '/d',
          'Flowvy',
          '/f',
        ],
      );

      await Process.run(
        'reg',
        [
          'add',
          'HKCU\\Software\\Classes\\AppUserModelId\\$appId',
          '/v',
          'IconUri',
          '/t',
          'REG_SZ',
          '/d',
          iconPath,
          '/f',
        ],
      );
    } catch (e) {
      commonPrint.log('Failed to register in registry: $e');
    }
  }

  Future<void> _updateShortcut(String appId) async {
    try {
      final startMenuPath = Platform.environment['APPDATA'];
      if (startMenuPath == null) return;

      final shortcutPath = '$startMenuPath\\Microsoft\\Windows\\Start Menu\\Programs\\Flowvy.lnk';
      final exePath = Platform.resolvedExecutable;
      final workingDir = exePath.substring(0, exePath.lastIndexOf('\\'));

      final psScript = '''
\$WshShell = New-Object -ComObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
\$Shortcut.TargetPath = "$exePath"
\$Shortcut.WorkingDirectory = "$workingDir"
\$Shortcut.IconLocation = "$exePath,0"
\$Shortcut.Save()

# Set AppUserModelID via PropertyStore
Add-Type -AssemblyName System.Runtime.WindowsRuntime
\$null = [Windows.UI.StartScreen.JumpList, Windows.UI.StartScreen, ContentType = WindowsRuntime]

# Set flag in .lnk file header
\$bytes = [System.IO.File]::ReadAllBytes("$shortcutPath")
if (\$bytes.Length -gt 21) {
    \$bytes[21] = \$bytes[21] -bor 0x01
}
[System.IO.File]::WriteAllBytes("$shortcutPath", \$bytes)

Write-Output "Shortcut updated"
''';

      await Process.run(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript],
      );
    } catch (e) {
      commonPrint.log('Failed to setup shortcut: $e');
    }
  }

  Future<void> showTrafficLimitNotification({
    required String title,
    required String body,
    int? percentage,
    String? status,
  }) async {
    if (!_initialized) await init();

    try {
      if (Platform.isAndroid) {
        final androidDetails = AndroidNotificationDetails(
          'traffic_limit_channel',
          'Traffic Limit Notifications',
          channelDescription: 'Notifications about traffic limit status',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          showProgress: percentage != null,
          maxProgress: 100,
          progress: percentage ?? 0,
        );
        final details = NotificationDetails(android: androidDetails);
        final displayBody = percentage != null ? '${status ?? ''} $percentage%' : body;
        await _notifications.show(
          percentage ?? 100,
          title,
          displayBody,
          details,
        );
      } else if (Platform.isWindows) {
        if (percentage != null) {
          // Use native plugin for traffic limit with progress bar
          await FlowvyNotification.showTrafficLimit(
            tag: 'traffic_$percentage',
            title: title,
            percentage: percentage,
            status: status,
          );
        } else {
          await FlowvyNotification.showSubscriptionExpiry(
            tag: 'traffic_alert',
            title: title,
            body: body,
          );
        }
      } else if (Platform.isLinux) {
        const linuxDetails = LinuxNotificationDetails();
        const details = NotificationDetails(linux: linuxDetails);
        final displayBody = percentage != null ? '${status ?? ''} $percentage%' : body;
        await _notifications.show(
          percentage ?? 100,
          title,
          displayBody,
          details,
        );
      } else if (Platform.isMacOS) {
        const darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const details = NotificationDetails(macOS: darwinDetails);
        final displayBody = percentage != null ? '${status ?? ''} $percentage%' : body;
        await _notifications.show(
          percentage ?? 100,
          title,
          displayBody,
          details,
        );
      }
    } catch (e) {
      commonPrint.log('Failed to show system notification: $e');
    }
  }

  Future<void> showSubscriptionExpiryNotification({
    required String title,
    required String body,
    String? buttonText,
    String? buttonUrl,
  }) async {
    if (!_initialized) await init();

    try {
      if (Platform.isAndroid) {
        const androidDetails = AndroidNotificationDetails(
          'subscription_expiry_channel',
          'Subscription Notifications',
          channelDescription: 'Notifications about subscription expiry',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );
        const details = NotificationDetails(android: androidDetails);
        await _notifications.show(
          1000,
          title,
          body,
          details,
        );
      } else if (Platform.isWindows) {
        // Use native plugin for subscription expiry
        await FlowvyNotification.showSubscriptionExpiry(
          tag: 'subscription_expiry',
          title: title,
          body: body,
          buttonText: buttonText,
          buttonUrl: buttonUrl,
        );
      } else if (Platform.isLinux) {
        const linuxDetails = LinuxNotificationDetails();
        const details = NotificationDetails(linux: linuxDetails);
        await _notifications.show(
          1000,
          title,
          body,
          details,
        );
      } else if (Platform.isMacOS) {
        final darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: buttonUrl != null && buttonUrl.isNotEmpty ? buttonUrl : null,
        );
        final details = NotificationDetails(macOS: darwinDetails);
        await _notifications.show(
          1000,
          title,
          body,
          details,
        );
      }
    } catch (e) {
      commonPrint.log('Failed to show subscription expiry notification: $e');
    }
  }

  Future<void> showDownloadProgressNotification({
    required String title,
    required int percentage,
    required String status,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();

    if (_lastProgressUpdate != null && percentage != 100) {
      final timeSinceLastUpdate = now.difference(_lastProgressUpdate!);
      final percentageChange = _lastProgressPercentage == null ? 100 : (percentage - _lastProgressPercentage!).abs();

      // Skip intermediate updates if less than 500ms passed and percentage change < 5%
      // Always show 100% (completion)
      if (timeSinceLastUpdate < _progressUpdateThrottle && percentageChange < 5) {
        return;
      }
    }

    _lastProgressUpdate = now;
    _lastProgressPercentage = percentage;

    try {
      if (Platform.isAndroid) {
        final androidDetails = AndroidNotificationDetails(
          'update_download_channel',
          'Update Downloads',
          channelDescription: 'Notifications about app update downloads',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
          showProgress: true,
          maxProgress: 100,
          progress: percentage,
          ongoing: true,
          autoCancel: false,
        );
        final details = NotificationDetails(android: androidDetails);
        await _notifications.show(
          9999,
          title,
          status,
          details,
        );
      } else if (Platform.isWindows) {
        // Use native Toast notification with update support
        await FlowvyNotification.showProgress(
          tag: 'update_download',
          title: title,
          status: status,
          progress: percentage / 100.0,
        );
      } else if (Platform.isLinux) {
        final linuxDetails = LinuxNotificationDetails(
          category: LinuxNotificationCategory.transfer,
        );
        final details = NotificationDetails(linux: linuxDetails);
        await _notifications.show(
          9999,
          title,
          '$status - $percentage%',
          details,
        );
      } else if (Platform.isMacOS) {
        const darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        );
        const details = NotificationDetails(macOS: darwinDetails);
        await _notifications.show(
          9999,
          title,
          '$status - $percentage%',
          details,
        );
      }

      // Don't log every percentage update to avoid spam
    } catch (e) {
      commonPrint.log('Failed to show download progress notification: $e');
    }
  }

  Future<void> cancelDownloadNotification() async {
    if (!_initialized) return;

    _lastProgressUpdate = null;
    _lastProgressPercentage = null;

    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      await _notifications.cancel(9999);
    } else if (Platform.isWindows) {
      await FlowvyNotification.cancel('update_download');
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    if (!Platform.isWindows) {
      await _notifications.cancelAll();
    }
  }
}

final notificationManager = NotificationManager();
