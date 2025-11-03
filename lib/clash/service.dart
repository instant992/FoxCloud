import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flowvy/clash/interface.dart';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/models/core.dart';
import 'package:flowvy/state.dart';

class ClashService extends ClashHandlerInterface {
  static ClashService? _instance;

  Completer<ServerSocket> serverCompleter = Completer();

  Completer<Socket> socketCompleter = Completer();

  bool isStarting = false;

  bool _isShuttingDown = false;

  Process? process;

  factory ClashService() {
    _instance ??= ClashService._internal();
    return _instance!;
  }

  ClashService._internal() {
    _initServer();
    reStart();
  }

  _initServer() async {
    runZonedGuarded(() async {
      final address = !Platform.isWindows
          ? InternetAddress(
              unixSocketPath,
              type: InternetAddressType.unix,
            )
          : InternetAddress(
              localhost,
              type: InternetAddressType.IPv4,
            );
      await _deleteSocketFile();
      final server = await ServerSocket.bind(
        address,
        0,
        shared: true,
      );
      serverCompleter.complete(server);
      await for (final socket in server) {
        await _destroySocket();
        socketCompleter.complete(socket);
        socket
            .transform(uint8ListToListIntConverter)
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen(
          (data) {
            handleResult(
              ActionResult.fromJson(
                json.decode(data.trim()),
              ),
            );
          },
        );
      }
    }, (error, stack) {
      // Don't log socket errors during shutdown (expected behavior)
      if (_isShuttingDown && error is SocketException) {
        return;
      }
      commonPrint.log(appLocalizations.logClashServiceError(error.toString()));
      if (error is SocketException) {
        globalState.showNotifier(error.toString());
      }
    });
  }

  @override
  reStart() async {
    if (isStarting == true) {
      return;
    }
    isStarting = true;
    _isShuttingDown = false;
    socketCompleter = Completer();
    if (process != null) {
      await shutdown();
    }
    final serverSocket = await serverCompleter.future;
    final arg = Platform.isWindows
        ? "${serverSocket.port}"
        : serverSocket.address.address;
    if (Platform.isWindows && await system.checkIsAdmin()) {
      final isSuccess = await request.startCoreByHelper(arg);
      if (isSuccess) {
        return;
      }
    }
    process = await Process.start(
      appPath.corePath,
      [
        arg,
      ],
    );
    process?.stdout.listen((_) {});
    process?.stderr.listen((e) {
      final error = utf8.decode(e);
      if (error.isNotEmpty) {
        commonPrint.log(appLocalizations.logClashCoreStderr(error));
      }
    });
    isStarting = false;
  }

  @override
  destroy() async {
    final server = await serverCompleter.future;
    await server.close();
    await _deleteSocketFile();
    return true;
  }

  @override
  sendMessage(String message) async {
    final socket = await socketCompleter.future;
    socket.writeln(message);
  }

  _deleteSocketFile() async {
    if (!Platform.isWindows) {
      final file = File(unixSocketPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  _destroySocket() async {
    if (socketCompleter.isCompleted) {
      final lastSocket = await socketCompleter.future;
      await lastSocket.close();
      socketCompleter = Completer();
    }
  }

  @override
  shutdown() async {
    _isShuttingDown = true;

    // Kill process first (if still alive)
    process?.kill();

    if (Platform.isWindows) {
      try {
        await request.stopCoreByHelper().timeout(Duration(seconds: 2));
      } catch (_) {
        // Ignore timeout/errors
      }
    }

    // Close socket with timeout (may hang if process already dead)
    try {
      await _destroySocket().timeout(Duration(milliseconds: 500));
    } catch (_) {
      // Ignore timeout - socket will close when process dies
    }

    process = null;
    return true;
  }

  @override
  Future<bool> preload() async {
    await serverCompleter.future;
    return true;
  }
}

final clashService = system.isDesktop ? ClashService() : null;
