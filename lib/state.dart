import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Pointer;

import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flowvy/clash/clash.dart';
import 'package:flowvy/common/theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/l10n/l10n.dart';
import 'package:flowvy/plugins/service.dart';
import 'package:flowvy/widgets/dialog.dart';
import 'package:flowvy/widgets/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:material_color_utilities/palettes/core_palette.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common/common.dart';
import 'controller.dart';
import 'models/models.dart';

typedef UpdateTasks = List<FutureOr Function()>;

class GlobalState {
  static GlobalState? _instance;
  Map<CacheTag, double> cacheScrollPosition = {};
  Map<CacheTag, FixedMap<String, double>> cacheHeightMap = {};
  bool isService = false;
  Timer? timer;
  Timer? groupsUpdateTimer;
  late Config config;
  late AppState appState;
  bool isPre = true;
  String? coreSHA256;
  late PackageInfo packageInfo;
  Function? updateCurrentDelayDebounce;
  late Measure measure;
  late CommonTheme theme;
  late Color accentColor;
  CorePalette? corePalette;
  DateTime? startTime;
  UpdateTasks tasks = [];
  final navigatorKey = GlobalKey<NavigatorState>();
  AppController? _appController;
  GlobalKey<CommonScaffoldState> homeScaffoldKey = GlobalKey();
  bool isInit = false;

  bool get isStart => startTime != null && startTime!.isBeforeNow;

  AppController get appController => _appController!;

  set appController(AppController appController) {
    _appController = appController;
    isInit = true;
  }

  GlobalState._internal();

  factory GlobalState() {
    _instance ??= GlobalState._internal();
    return _instance!;
  }

  initApp(int version) async {
    coreSHA256 = const String.fromEnvironment("CORE_SHA256");
    isPre = const String.fromEnvironment("APP_ENV") != 'stable';
    appState = AppState(
      version: version,
      viewSize: Size.zero,
      requests: FixedList(maxLength),
      logs: FixedList(maxLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
    );
    await _initDynamicColor();
    await init();
  }

  _initDynamicColor() async {
    try {
      corePalette = await DynamicColorPlugin.getCorePalette();
      accentColor = await DynamicColorPlugin.getAccentColor() ??
          Color(defaultPrimaryColor);
    } catch (_) {}
  }

init() async {
  packageInfo = await PackageInfo.fromPlatform();
  config = await preferences.getConfig() ??
      Config(
        appSetting: AppSettingProps.safeFromJson(null),
        themeProps: ThemeProps.safeFromJson(null),
      );
  await globalState.migrateOldData(config);
  await AppLocalizations.load(
    utils.getLocaleForString(config.appSetting.locale) ??
        WidgetsBinding.instance.platformDispatcher.locale,
  );
}

  startUpdateTasks([UpdateTasks? tasks]) async {
    if (timer != null && timer!.isActive == true) return;
    if (tasks != null) {
      this.tasks = tasks;
    }
    await executorUpdateTask();
    timer = Timer(const Duration(seconds: 1), () async {
      startUpdateTasks();
    });
  }

  executorUpdateTask() async {
    for (final task in tasks) {
      await task();
    }
    timer = null;
  }

  stopUpdateTasks() {
    if (timer == null || timer?.isActive == false) return;
    timer?.cancel();
    timer = null;
  }

  handleStart([UpdateTasks? tasks]) async {
    startTime ??= DateTime.now();
    await clashCore.startListener();
    await service?.startVpn();
    startUpdateTasks(tasks);
  }

  Future updateStartTime() async {
    startTime = await clashLib?.getRunTime();
  }

  Future handleStop() async {
    startTime = null;
    await clashCore.stopListener();
    await service?.stopVpn();
    stopUpdateTasks();
  }

  Future<bool?> showMessage({
    String? title,
    required InlineSpan message,
    String? confirmText,
    bool cancelable = true,
  }) async {
    return await showCommonDialog<bool>(
      child: Builder(
        builder: (context) {
          return CommonDialog(
            title: title ?? appLocalizations.tip,
            actions: [
              if (cancelable)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(appLocalizations.cancel),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(confirmText ?? appLocalizations.confirm),
              )
            ],
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelLarge,
                    children: [message],
                  ),
                  style: const TextStyle(
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Future<Map<String, dynamic>> getProfileMap(String id) async {
  //   final profilePath = await appPath.getProfilePath(id);
  //   final res = await Isolate.run<Result<dynamic>>(() async {
  //     try {
  //       final file = File(profilePath);
  //       if (!await file.exists()) {
  //         return Result.error("");
  //       }
  //       final value = await file.readAsString();
  //       return Result.success(utils.convertYamlNode(loadYaml(value)));
  //     } catch (e) {
  //       return Result.error(e.toString());
  //     }
  //   });
  //   if (res.isSuccess) {
  //     return res.data as Map<String, dynamic>;
  //   } else {
  //     throw res.message;
  //   }
  // }

  Future<T?> showCommonDialog<T>({
    required Widget child,
    bool dismissible = true,
  }) async {
    return await showModal<T>(
      context: navigatorKey.currentState!.context,
      configuration: FadeScaleTransitionConfiguration(
        barrierColor: Colors.black38,
        barrierDismissible: dismissible,
      ),
      builder: (_) => child,
      filter: commonFilter,
    );
  }

  Future<T?> safeRun<T>(
    FutureOr<T> Function() futureFunction, {
    String? title,
    bool silence = true,
  }) async {
    try {
      final res = await futureFunction();
      return res;
    } catch (e) {
      commonPrint.log("$e");
      if (silence) {
        showNotifier(e.toString());
      } else {
        showMessage(
          title: title ?? appLocalizations.tip,
          message: TextSpan(
            text: e.toString(),
          ),
        );
      }
      return null;
    }
  }

  showNotifier(String text) {
    if (text.isEmpty) {
      return;
    }
    navigatorKey.currentContext?.showNotifier(text);
  }

  openUrl(String url) async {
    final res = await showMessage(
      message: TextSpan(text: url),
      title: appLocalizations.externalLink,
      confirmText: appLocalizations.go,
    );
    if (res != true) {
      return;
    }
    launchUrl(Uri.parse(url));
  }

  Future<void> migrateOldData(Config config) async {
    final clashConfig = await preferences.getClashConfig();
    if (clashConfig != null) {
      config = config.copyWith(
        patchClashConfig: clashConfig,
      );
      preferences.clearClashConfig();
      preferences.saveConfig(config);
    }
  }

  CoreState getCoreState() {
    final currentProfile = config.currentProfile;
    return CoreState(
      vpnProps: config.vpnProps,
      onlyStatisticsProxy: config.appSetting.onlyStatisticsProxy,
      currentProfileName: currentProfile?.label ?? currentProfile?.id ?? "",
      bypassDomain: config.networkProps.bypassDomain,
    );
  }

  Future<SetupParams> getSetupParams({
    required ClashConfig pathConfig,
  }) async {
    final clashConfig = await patchRawConfig(
      patchConfig: pathConfig,
    );
    final params = SetupParams(
      config: clashConfig,
      selectedMap: config.currentProfile?.selectedMap ?? {},
      testUrl: config.appSetting.testUrl,
    );
    return params;
  }

  Future<Map<String, dynamic>> patchRawConfig({
    required ClashConfig patchConfig,
  }) async {
    final profile = config.currentProfile;
    if (profile == null) {
      return {};
    }
    final profileId = profile.id;
    final configMap = await getProfileConfig(profileId);
    final rawConfig = await handleEvaluate(configMap);
    final realPatchConfig = patchConfig.copyWith(
      tun: patchConfig.tun.getRealTun(config.networkProps.routeMode),
    );
    rawConfig["external-controller"] = realPatchConfig.externalController.value;
    rawConfig["external-ui"] = "";
    rawConfig["interface-name"] = "";
    rawConfig["external-ui-url"] = "";
    rawConfig["tcp-concurrent"] = realPatchConfig.tcpConcurrent;
    rawConfig["unified-delay"] = realPatchConfig.unifiedDelay;
    rawConfig["ipv6"] = realPatchConfig.ipv6;
    // LogLevel.app is for Flutter logs only, mihomo doesn't support it
    rawConfig["log-level"] = realPatchConfig.logLevel == LogLevel.app
        ? LogLevel.info.name
        : realPatchConfig.logLevel.name;
    rawConfig["port"] = 0;
    rawConfig["socks-port"] = 0;
    rawConfig["keep-alive-interval"] = realPatchConfig.keepAliveInterval;
    rawConfig["mixed-port"] = realPatchConfig.mixedPort;
    rawConfig["port"] = realPatchConfig.port;
    rawConfig["socks-port"] = realPatchConfig.socksPort;
    rawConfig["redir-port"] = realPatchConfig.redirPort;
    rawConfig["tproxy-port"] = realPatchConfig.tproxyPort;
    rawConfig["find-process-mode"] = realPatchConfig.findProcessMode.name;
    rawConfig["allow-lan"] = realPatchConfig.allowLan;
    rawConfig["mode"] = realPatchConfig.mode.name;
    if (rawConfig["tun"] == null) {
      rawConfig["tun"] = {};
    }
    rawConfig["tun"]["enable"] = realPatchConfig.tun.enable;
    rawConfig["tun"]["device"] = realPatchConfig.tun.device;
    rawConfig["tun"]["dns-hijack"] = realPatchConfig.tun.dnsHijack;
    rawConfig["tun"]["stack"] = realPatchConfig.tun.stack.name;
    rawConfig["tun"]["route-address"] = realPatchConfig.tun.routeAddress;
    rawConfig["tun"]["auto-route"] = realPatchConfig.tun.autoRoute;
    rawConfig["geodata-loader"] = realPatchConfig.geodataLoader.name;
    if (rawConfig["sniffer"]?["sniff"] != null) {
      for (final value in (rawConfig["sniffer"]?["sniff"] as Map).values) {
        if (value["ports"] != null && value["ports"] is List) {
          value["ports"] =
              value["ports"]?.map((item) => item.toString()).toList() ?? [];
        }
      }
    }
    if (rawConfig["profile"] == null) {
      rawConfig["profile"] = {};
    }
    if (rawConfig["proxy-providers"] != null) {
      final proxyProviders = rawConfig["proxy-providers"] as Map;
      for (final key in proxyProviders.keys) {
        final proxyProvider = proxyProviders[key];
        if (proxyProvider["type"] != "http") {
          continue;
        }
        if (proxyProvider["url"] != null) {
          proxyProvider["path"] = await appPath.getProvidersFilePath(
            profile.id,
            "proxies",
            proxyProvider["url"],
          );
        }
      }
    }

    if (rawConfig["rule-providers"] != null) {
      final ruleProviders = rawConfig["rule-providers"] as Map;
      for (final key in ruleProviders.keys) {
        final ruleProvider = ruleProviders[key];
        if (ruleProvider["type"] != "http") {
          continue;
        }
        if (ruleProvider["url"] != null) {
          ruleProvider["path"] = await appPath.getProvidersFilePath(
            profile.id,
            "rules",
            ruleProvider["url"],
          );
        }
      }
    }

    rawConfig["profile"]["store-selected"] = false;
    rawConfig["geox-url"] = realPatchConfig.geoXUrl.toJson();
    rawConfig["global-ua"] = globalState.packageInfo.ua;
    if (rawConfig["hosts"] == null) {
      rawConfig["hosts"] = {};
    }
    for (final host in realPatchConfig.hosts.entries) {
      rawConfig["hosts"][host.key] = host.value.splitByMultipleSeparators;
    }
    if (rawConfig["dns"] == null) {
      rawConfig["dns"] = {};
    }
    final isEnableDns = rawConfig["dns"]["enable"] == true;
    final overrideDns = globalState.config.overrideDns;
    if (overrideDns || !isEnableDns) {
      final dns = switch (!isEnableDns) {
        true => realPatchConfig.dns.copyWith(
            nameserver: [...realPatchConfig.dns.nameserver, "system://"]),
        false => realPatchConfig.dns,
      };
      rawConfig["dns"] = dns.toJson();
      rawConfig["dns"]["nameserver-policy"] = {};
      for (final entry in dns.nameserverPolicy.entries) {
        rawConfig["dns"]["nameserver-policy"][entry.key] =
            entry.value.splitByMultipleSeparators;
      }
    }
    var rules = [];
    if (rawConfig["rules"] != null) {
      rules = rawConfig["rules"];
    }
    rawConfig.remove("rules");

    final overrideData = profile.overrideData;
    if (overrideData.enable && config.scriptProps.currentScript == null) {
      if (overrideData.rule.type == OverrideRuleType.override) {
        rules = overrideData.runningRule;
      } else {
        rules = [...overrideData.runningRule, ...rules];
      }
    }
    rawConfig["rule"] = rules;
    return rawConfig;
  }

  Future<Map<String, dynamic>> getProfileConfig(String profileId) async {
    final configMap = await switch (clashLibHandler != null) {
      true => clashLibHandler!.getConfig(profileId),
      false => clashCore.getConfig(profileId),
    };
    configMap["rules"] = configMap["rule"];
    configMap.remove("rule");
    return configMap;
  }

  /// Applies profile config settings to patchClashConfigProvider
  /// Called on profile load/update
  ///
  /// [force] - if true, ignores savedConfig and applies settings from config
  /// (used on first profile import or server update)
  Future<void> applyConfigOverridesFromProfile(
    Profile? profile, {
    bool force = false,
  }) async {
    if (profile == null) return;

    // Apply settings only for URL profiles
    if (profile.type != ProfileType.url) {
      return;
    }

    // If there are saved settings and not force mode, load them
    // Saved settings have priority when switching between profiles
    if (!force && profile.overrideData.savedConfig != null) {
      commonPrint.log("Loading saved config from profile overrideData");
      await _applySavedConfig(profile.overrideData.savedConfig!);
      return;
    }

    // If no saved settings or force mode - apply from config
    try {
      final configMap = await getProfileConfig(profile.id);

      // Read settings from config
      final mixedPort = configMap["mixed-port"] as int? ?? defaultMixedPort;
      final socksPort = configMap["socks-port"] as int? ?? 0;
      final port = configMap["port"] as int? ?? 0;
      final redirPort = configMap["redir-port"] as int? ?? 0;
      final tproxyPort = configMap["tproxy-port"] as int? ?? 0;
      final allowLan = configMap["allow-lan"] as bool? ?? false;
      final ipv6 = configMap["ipv6"] as bool? ?? false;
      final keepAliveInterval = configMap["keep-alive-interval"] as int? ?? defaultKeepAliveInterval;
      final unifiedDelay = configMap["unified-delay"] as bool? ?? true;
      final tcpConcurrent = configMap["tcp-concurrent"] as bool? ?? true;

      // Parse Log Level
      LogLevel logLevel = LogLevel.error;
      final logLevelStr = configMap["log-level"];
      if (logLevelStr != null) {
        try {
          logLevel = LogLevel.values.firstWhere(
            (e) => e.name == logLevelStr,
            orElse: () => LogLevel.error,
          );
        } catch (_) {}
      }

      // Parse Find Process Mode
      FindProcessMode findProcessMode = FindProcessMode.always;
      final findProcessModeStr = configMap["find-process-mode"];
      if (findProcessModeStr != null) {
        try {
          findProcessMode = FindProcessMode.values.firstWhere(
            (e) => e.name == findProcessModeStr,
            orElse: () => FindProcessMode.always,
          );
        } catch (_) {}
      }

      // Parse Geodata Loader
      GeodataLoader geodataLoader = GeodataLoader.memconservative;
      final geodataLoaderStr = configMap["geodata-loader"];
      if (geodataLoaderStr != null) {
        try {
          geodataLoader = GeodataLoader.values.firstWhere(
            (e) => e.name == geodataLoaderStr,
            orElse: () => GeodataLoader.memconservative,
          );
        } catch (_) {}
      }

      // Parse Hosts
      HostsMap hosts = {};
      if (configMap["hosts"] is Map) {
        final hostsMap = configMap["hosts"] as Map;
        for (final entry in hostsMap.entries) {
          hosts[entry.key.toString()] = entry.value.toString();
        }
      }

      // Parse TUN Stack (only stack, other TUN settings remain default)
      TunStack? tunStack;
      if (configMap["tun"] is Map) {
        try {
          final tunMap = Map<String, dynamic>.from(configMap["tun"] as Map);
          final tunStackStr = tunMap["stack"];
          if (tunStackStr != null) {
            try {
              // Compare in lowercase since config might have "System" while enum has "system"
              final stackLower = tunStackStr.toString().toLowerCase();
              tunStack = TunStack.values.firstWhere(
                (e) => e.name.toLowerCase() == stackLower,
                orElse: () => TunStack.mixed,
              );
            } catch (_) {
              tunStack = TunStack.mixed;
            }
          }
        } catch (e) {
          commonPrint.log("Error parsing tun stack from config: $e");
        }
      }

      // Apply settings through AppController
      if (_appController != null) {
        appController.applyClashConfigOverrides(
          mixedPort: mixedPort,
          socksPort: socksPort,
          port: port,
          redirPort: redirPort,
          tproxyPort: tproxyPort,
          allowLan: allowLan,
          ipv6: ipv6,
          keepAliveInterval: keepAliveInterval,
          unifiedDelay: unifiedDelay,
          tcpConcurrent: tcpConcurrent,
          logLevel: logLevel,
          findProcessMode: findProcessMode,
          geodataLoader: geodataLoader,
          hosts: hosts,
          tunStack: tunStack,
        );

        commonPrint.log("Applied config overrides from profile: ${profile.label ?? profile.id}");
      }
    } catch (e) {
      commonPrint.log("Error applying config overrides from profile: $e");
    }
  }

  /// Applies saved settings from overrideData.savedConfig
  Future<void> _applySavedConfig(ClashConfig savedConfig) async {
    if (_appController == null) return;

    // Extract only stack from TUN (other settings remain default)
    final tunStack = savedConfig.tun.stack;

    // Apply all settings from savedConfig
    appController.applyClashConfigOverrides(
      mixedPort: savedConfig.mixedPort,
      socksPort: savedConfig.socksPort,
      port: savedConfig.port,
      redirPort: savedConfig.redirPort,
      tproxyPort: savedConfig.tproxyPort,
      allowLan: savedConfig.allowLan,
      ipv6: savedConfig.ipv6,
      keepAliveInterval: savedConfig.keepAliveInterval,
      unifiedDelay: savedConfig.unifiedDelay,
      tcpConcurrent: savedConfig.tcpConcurrent,
      logLevel: savedConfig.logLevel,
      findProcessMode: savedConfig.findProcessMode,
      geodataLoader: savedConfig.geodataLoader,
      hosts: savedConfig.hosts,
      tunStack: tunStack,
    );

    commonPrint.log("Applied saved config from profile overrideData");
  }

  /// Saves current settings to profile's overrideData.savedConfig
  Future<void> saveCurrentConfigToProfile(Profile profile, ClashConfig currentConfig) async {
    if (_appController == null) return;

    // Save to profile's overrideData
    final updatedProfile = profile.copyWith(
      overrideData: profile.overrideData.copyWith(
        savedConfig: currentConfig,
      ),
    );

    // Update profile through AppController
    appController.setProfile(updatedProfile);
    appController.savePreferencesDebounce();

    commonPrint.log("Saved current config to profile overrideData");
  }

  Future<Map<String, dynamic>> handleEvaluate(
    Map<String, dynamic> config,
  ) async {
    final currentScript = globalState.config.scriptProps.currentScript;
    if (currentScript == null) {
      return config;
    }
    if (config["proxy-providers"] == null) {
      config["proxy-providers"] = {};
    }
    final configJs = json.encode(config);
    final runtime = getJavascriptRuntime();
    final res = await runtime.evaluateAsync("""
      ${currentScript.content}
      main($configJs)
    """);
    if (res.isError) {
      throw res.stringResult;
    }
    final value = switch (res.rawResult is Pointer) {
      true => runtime.convertValue<Map<String, dynamic>>(res),
      false => Map<String, dynamic>.from(res.rawResult),
    };
    return value ?? config;
  }
}

final globalState = GlobalState();

class DetectionState {
  static DetectionState? _instance;
  bool? _preIsStart;
  Timer? _setTimeoutTimer;
  CancelToken? cancelToken;

  final state = ValueNotifier<NetworkDetectionState>(
    const NetworkDetectionState(
      isTesting: false,
      isLoading: true,
      ipInfo: null,
    ),
  );

  DetectionState._internal();

  factory DetectionState() {
    _instance ??= DetectionState._internal();
    return _instance!;
  }

  startCheck() {
    debouncer.call(
      FunctionTag.checkIp,
      _checkIp,
      duration: Duration(
        milliseconds: 1200,
      ),
    );
  }

  _checkIp() async {
    final appState = globalState.appState;
    final isInit = appState.isInit;
    if (!isInit) return;
    final isStart = appState.runTime != null;
    if (_preIsStart == false &&
        _preIsStart == isStart &&
        state.value.ipInfo != null) {
      return;
    }
    _clearSetTimeoutTimer();
    state.value = state.value.copyWith(
      isLoading: true,
      ipInfo: null,
    );
    _preIsStart = isStart;
    if (cancelToken != null) {
      cancelToken!.cancel();
      cancelToken = null;
    }
    cancelToken = CancelToken();
    state.value = state.value.copyWith(
      isTesting: true,
    );
    final res = await request.checkIp(cancelToken: cancelToken);
    if (res.isError) {
      state.value = state.value.copyWith(
        isLoading: true,
        ipInfo: null,
      );
      return;
    }
    final ipInfo = res.data;
    state.value = state.value.copyWith(
      isTesting: false,
    );
    if (ipInfo != null) {
      state.value = state.value.copyWith(
        isLoading: false,
        ipInfo: ipInfo,
      );
      return;
    }
    _clearSetTimeoutTimer();
    _setTimeoutTimer = Timer(const Duration(milliseconds: 300), () {
      state.value = state.value.copyWith(
        isLoading: false,
        ipInfo: null,
      );
    });
  }

  _clearSetTimeoutTimer() {
    if (_setTimeoutTimer != null) {
      _setTimeoutTimer?.cancel();
      _setTimeoutTimer = null;
    }
  }
}

final detectionState = DetectionState();
