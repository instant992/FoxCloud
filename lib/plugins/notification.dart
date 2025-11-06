import 'dart:io';
import 'package:flutter/services.dart';

class FlowvyNotification {
  static const MethodChannel _channel = MethodChannel('flowvy_notification');

  static bool get isSupported => Platform.isWindows;

  static Future<void> showProgress({
    required String tag,
    required String title,
    required String status,
    required double progress,
  }) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod('showProgress', {
        'tag': tag,
        'title': title,
        'status': status,
        'progress': progress,
      });
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> showTrafficLimit({
    required String tag,
    required String title,
    required int percentage,
    String? status,
  }) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod('showTrafficLimit', {
        'tag': tag,
        'title': title,
        'percentage': percentage,
        'status': status ?? '',
      });
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> showSubscriptionExpiry({
    required String tag,
    required String title,
    required String body,
    String? buttonText,
    String? buttonUrl,
  }) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod('showSubscriptionExpiry', {
        'tag': tag,
        'title': title,
        'body': body,
        'buttonText': buttonText ?? '',
        'buttonUrl': buttonUrl ?? '',
      });
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> cancel(String tag) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod('cancel', {
        'tag': tag,
      });
    } catch (e) {
      // Silently fail
    }
  }
}
