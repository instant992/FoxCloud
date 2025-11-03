import 'package:flowvy/models/models.dart';
import 'package:flowvy/state.dart';
import 'package:flutter/cupertino.dart';
import 'session_log.dart';

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  log(String? text) {
    final payload = "[Flowvy] $text";
    debugPrint(payload);

    // Write all logs to session log file
    sessionLog.write(payload);

    if (!globalState.isInit) {
      return;
    }
    globalState.appController.addLog(
      Log.app(payload),
    );
  }
}

final commonPrint = CommonPrint();
