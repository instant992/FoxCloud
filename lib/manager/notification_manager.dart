import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flowvy/common/common.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

class NotificationManager {
  static NotificationManager? _instance;
  late FlutterLocalNotificationsPlugin _notifications;
  WindowsNotification? _winNotification;
  bool _initialized = false;

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
      commonPrint.log('macOS notification manager initialized');
    } else if (Platform.isWindows) {
      commonPrint.log('Initializing Windows notifications...');

      const appId = 'Flowvy.App';

      // Register app in Windows registry for proper notification support
      try {
        await _registerInRegistry(appId);
      } catch (e) {
        commonPrint.log('Warning: Failed to register in registry (non-critical): $e');
      }

      // Update Start Menu shortcut with AppUserModelID
      try {
        await _updateShortcut(appId);
      } catch (e) {
        commonPrint.log('Warning: Failed to update shortcut (non-critical): $e');
      }

      _winNotification = WindowsNotification(
        applicationId: appId,
      );

      commonPrint.log('Windows notification manager initialized with AppID: $appId');
    }

    _initialized = true;
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<void> _registerInRegistry(String appId) async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = exePath.substring(0, exePath.lastIndexOf('\\'));
      final iconPath = '$exeDir\\data\\flutter_assets\\assets\\images\\icon_bg_white.png';

      var result = await Process.run(
        'reg',
        [
          'add',
          'HKCU\\Software\\Classes\\AppUserModelId\\$appId',
          '/f',
        ],
      );
      commonPrint.log('Registry key creation: ${result.stdout} ${result.stderr}');

      result = await Process.run(
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
      commonPrint.log('DisplayName set: ${result.stdout} ${result.stderr}');

      // Use PNG icon from assets instead of exe icon
      result = await Process.run(
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
      commonPrint.log('IconUri set to: $iconPath - ${result.stdout} ${result.stderr}');
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

      // Create/update shortcut with AppUserModelID for notification grouping
      final psScript = '''
\$WshShell = New-Object -ComObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
\$Shortcut.TargetPath = "$exePath"
\$Shortcut.WorkingDirectory = "$workingDir"
\$Shortcut.IconLocation = "$exePath,0"
\$Shortcut.Save()

# Устанавливаем AppUserModelID через PropertyStore
Add-Type -AssemblyName System.Runtime.WindowsRuntime
\$null = [Windows.UI.StartScreen.JumpList, Windows.UI.StartScreen, ContentType = WindowsRuntime]

# Устанавливаем флаг в заголовке .lnk файла
\$bytes = [System.IO.File]::ReadAllBytes("$shortcutPath")
if (\$bytes.Length -gt 21) {
    \$bytes[21] = \$bytes[21] -bor 0x01
}
[System.IO.File]::WriteAllBytes("$shortcutPath", \$bytes)

Write-Output "Shortcut updated with AppUserModelID"
''';

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript],
      );

      commonPrint.log('Shortcut setup: ${result.stdout}');
      if (result.stderr.toString().isNotEmpty) {
        commonPrint.log('Shortcut setup error: ${result.stderr}');
      }
    } catch (e) {
      commonPrint.log('Failed to setup shortcut: $e');
    }
  }

  Future<void> showTrafficLimitNotification({
    required String title,
    required String body,
    int? percentage,
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
        final displayBody = percentage != null ? 'Использовано $percentage%' : body;
        await _notifications.show(
          percentage ?? 100,
          title,
          displayBody,
          details,
        );
      } else if (Platform.isWindows) {
        if (_winNotification == null) {
          commonPrint.log('Windows notification manager is null, skipping notification');
          return;
        }

        commonPrint.log('Showing Windows notification: $title - $body');

        final message = NotificationMessage.fromCustomTemplate(
          'toast${percentage ?? 100}',
          group: 'traffic_notifications',
        );

        final escapedTitle = _escapeXml(title);

        String progressBar = '';
        if (percentage != null) {
          final normalizedValue = (percentage / 100.0).clamp(0.0, 1.0);
          progressBar = '\n      <progress value="$normalizedValue" valueStringOverride="$percentage%" status="Использовано"/>';
        }

        final template = '''
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>$progressBar
    </binding>
  </visual>
  <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
''';

        await _winNotification!.showNotificationCustomTemplate(message, template);
        commonPrint.log('Notification shown successfully: $escapedTitle');
      } else if (Platform.isLinux) {
        const linuxDetails = LinuxNotificationDetails();
        const details = NotificationDetails(linux: linuxDetails);
        final displayBody = percentage != null ? 'Использовано $percentage%' : body;
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
        final displayBody = percentage != null ? 'Использовано $percentage%' : body;
        await _notifications.show(
          percentage ?? 100,
          title,
          displayBody,
          details,
        );
      }

      commonPrint.log('System notification shown: $title - $body');
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
        if (_winNotification == null) {
          commonPrint.log('Windows notification manager is null, skipping notification');
          return;
        }

        commonPrint.log('Showing subscription expiry notification: $title');

        final message = NotificationMessage.fromCustomTemplate(
          'subscription_expiry',
          group: 'subscription_notifications',
        );

        final escapedTitle = _escapeXml(title);
        final escapedBody = _escapeXml(body);

        // Only add button if URL is provided
        String actionsSection = '';
        if (buttonUrl != null && buttonUrl.isNotEmpty && buttonText != null && buttonText.isNotEmpty) {
          final escapedButtonText = _escapeXml(buttonText);
          actionsSection = '''
  <actions>
    <action content="$escapedButtonText" arguments="$buttonUrl" activationType="protocol"/>
  </actions>''';
        }

        final template = '''
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedBody</text>
    </binding>
  </visual>$actionsSection
  <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
''';

        await _winNotification!.showNotificationCustomTemplate(message, template);
        commonPrint.log('Subscription expiry notification shown successfully');
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

      commonPrint.log('Subscription expiry notification shown: $title - $body');
    } catch (e) {
      commonPrint.log('Failed to show subscription expiry notification: $e');
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
