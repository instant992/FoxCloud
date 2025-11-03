import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flowvy/clash/clash.dart';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/l10n/l10n.dart';
import 'package:flowvy/manager/hotkey_manager.dart';
import 'package:flowvy/manager/manager.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/plugins/app.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart' as tray;

import 'controller.dart';
import 'pages/pages.dart';

const pageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: CommonPageTransitionsBuilder(),
    TargetPlatform.windows: CommonPageTransitionsBuilder(),
    TargetPlatform.linux: CommonPageTransitionsBuilder(),
    TargetPlatform.macOS: CommonPageTransitionsBuilder(),
  },
);

const darkThemeExtension = CustomTheme(
  connectButtonBackground: Color(0xFFFFFFFF),
  trafficChartDownloadColor: Color(0x1FFFFFFF),
  connectButtonForeground: Color(0xFF171717),
  connectButtonIcon: Color(0xE0171717),
  navRailIndicator: Color(0x0FFFFFFF),
  proxyCardBackground: Color(0xFF1C1C1C),
  proxyCardBorder: Color(0x0FFFFFFF),
  proxyCardBackgroundHover: Color(0x0A49DD93),
  proxyCardBorderHover: Color(0x5949DD93),
  proxyCardBackgroundSelected: Color(0x2449DD93),
  proxyCardBorderSelected: Color(0x5949DD93),
  proxyPingColor: Color(0xFF49DD93),
  switcherBackground: Color(0xFF1C1C1C),
  switcherBorder: Color(0x0FFFFFFF),
  switcherThumbBackground: Color(0x2449DD93),
  switcherSelectedText: Color(0xFFFFFFFF),
  switcherUnselectedText: Color(0xA3FFFFFF),
  profileCardBackground: Color(0xFF1C1C1C),
  profileCardBorder: Color(0x0FFFFFFF),
  profileCardBackgroundHover: Color(0x0A49DD93),
  profileCardBorderHover: Color(0x5949DD93),
  profileCardBackgroundSelected: Color(0x2449DD93),
  profileCardBorderSelected: Color(0x5949DD93),
  profileCardProgressTrack: Color(0x1FFFFFFF),
);

const lightThemeExtension = CustomTheme(
  connectButtonBackground: Color(0xFF171717),
  trafficChartDownloadColor: Color(0x1F171717),
  connectButtonForeground: Color(0xFFFFFFFF),
  connectButtonIcon: Color(0xE0FFFFFF),
  navRailIndicator: Color(0x14171717),
  proxyCardBackground: Color(0x0A171717),
  proxyCardBorder: Color(0x14171717),
  proxyCardBackgroundHover: Color(0x1749DD93),
  proxyCardBorderHover: Color(0x5949DD93),
  proxyCardBackgroundSelected: Color(0x2449DD93),
  proxyCardBorderSelected: Color(0x5949DD93),
  proxyPingColor: Color(0xFF49DD93),
  switcherBackground: Color(0x0A171717),
  switcherBorder: Color(0x14171717),
  switcherThumbBackground: Color(0x2449DD93),
  switcherSelectedText: Color(0xFF171717),
  switcherUnselectedText: Color(0xA3171717),
  profileCardBackground: Color(0x0A171717),
  profileCardBorder: Color(0x14171717),
  profileCardBackgroundHover: Color(0x1749DD93),
  profileCardBorderHover: Color(0x5949DD93),
  profileCardBackgroundSelected: Color(0x2449DD93),
  profileCardBorderSelected: Color(0x5949DD93),
  profileCardProgressTrack: Color(0x1F171717),
);


class Application extends ConsumerStatefulWidget {
  const Application({
    super.key,
  });

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application> {
  Timer? _autoUpdateGroupTaskTimer;
  Timer? _autoUpdateProfilesTaskTimer;

  Future<void> _updateTrayIconForSystemBrightness(Brightness brightness) async {
    if (!Platform.isAndroid) {
       final iconPath = utils.getTrayIconPath(brightness: brightness);
       await tray.trayManager.setIcon(iconPath);
    }
  }

  @override
  void initState() {
    super.initState();

    if (!Platform.isAndroid) {
      final dispatcher = PlatformDispatcher.instance;
      _updateTrayIconForSystemBrightness(dispatcher.platformBrightness);
      
      dispatcher.onPlatformBrightnessChanged = () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           _updateTrayIconForSystemBrightness(dispatcher.platformBrightness);
        });
      };
    }
    
    _autoUpdateGroupTask();
    _autoUpdateProfilesTask();
    globalState.appController = AppController(context, ref);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final currentContext = globalState.navigatorKey.currentContext;
      if (currentContext != null) {
        globalState.appController = AppController(currentContext, ref);
      }
      await globalState.appController.init();
      globalState.appController.initLink();
      app?.initShortcuts();
    });
  }

  _autoUpdateGroupTask() {
    _autoUpdateGroupTaskTimer = Timer(const Duration(milliseconds: 20000), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalState.appController.updateGroupsDebounce();
        _autoUpdateGroupTask();
      });
    });
  }

  _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer(const Duration(minutes: 5), () async {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final profiles = ref.read(profilesProvider);

        for (final profile in profiles) {
          if (!profile.shouldAutoUpdate()) {
            continue;
          }

          try {
            await globalState.appController.updateProfile(profile);
          } catch (e) {
            commonPrint.log("Failed to auto-update profile ${profile.label}: $e");
          }
        }

        _autoUpdateProfilesTask();
      });
    });
  }

  _buildPlatformState(Widget child) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(
            child: ProxyManager(
              child: child,
            ),
          ),
        ),
      );
    }
    return AndroidManager(
      child: TileManager(
        child: child,
      ),
    );
  }

  _buildState(Widget child) {
    return AppStateManager(
      child: ClashManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            if (!results.contains(ConnectivityResult.vpn)) {
              await clashCore.closeConnections();
            }
            globalState.appController.updateLocalIp();
            globalState.appController.addCheckIpNumDebounce();
          },
          child: child,
        ),
      ),
    );
  }

  _buildPlatformApp(Widget child) {
    if (system.isDesktop) {
      return WindowHeaderContainer(
        child: child,
      );
    }
    return VpnManager(
      child: child,
    );
  }

  _buildApp(Widget child) {
    return MessageManager(
      child: ThemeManager(
        child: child,
      ),
    );
  }

  final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    pageTransitionsTheme: pageTransitionsTheme,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF49DD93),
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFE6E6E6),
      surfaceContainer: Color(0xFFF2F2F2),
      onSurface: Color(0xFF171717),
      onSurfaceVariant: Color(0xA3171717),
      outline: Color(0x14171717),
      secondary: Color(0xFF49DD93),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0x1F171717),
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(fontWeight: FontWeight.w500),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFF171717)),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x1F171717); // #171717 12%
          }
          return const Color(0x14171717); // #171717 8%
        }),
        elevation: const WidgetStatePropertyAll(0),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF171717),
      foregroundColor: const Color(0xE0FFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        return const Color(0xA3171717);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF49DD93);
        }
        return const Color(0x1F171717);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return const Color(0x59171717);
      }),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      actionsIconTheme: IconThemeData(color: Color(0xE0171717)),
      iconTheme: IconThemeData(color: Color(0xE0171717)),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xE0171717),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x14171717),
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFF2F2F2),
      modalBackgroundColor: Color(0xFFF2F2F2),
      elevation: 0,
      modalElevation: 0,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      lightThemeExtension,
    ],
  );

  @override
  Widget build(context) {
    return _buildPlatformState(
      _buildState(
        Consumer(
          builder: (_, ref, child) {
            final locale = ref.watch(appSettingProvider.select((state) => state.locale));
            final themeProps = ref.watch(themeSettingProvider);
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: globalState.navigatorKey,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate
              ],
              builder: (_, child) {
                return AppEnvManager(
                  child: _buildPlatformApp(
                    _buildApp(child!),
                  ),
                );
              },
              scrollBehavior: BaseScrollBehavior(),
              title: appName,
              locale: utils.getLocaleForString(locale),
              supportedLocales: AppLocalizations.delegate.supportedLocales,
              themeMode: themeProps.themeMode,
              theme: lightTheme,
              darkTheme: darkTheme,
              home: child,
            );
          },
          child: const HomePage(),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (!Platform.isAndroid) {
      PlatformDispatcher.instance.onPlatformBrightnessChanged = null;
    }

    linkManager.destroy();
    _autoUpdateGroupTaskTimer?.cancel();
    _autoUpdateProfilesTaskTimer?.cancel();
    await clashCore.destroy();
    await globalState.appController.savePreferences();
    await globalState.appController.handleExit();
    super.dispose();
  }
}

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  pageTransitionsTheme: pageTransitionsTheme,
  scaffoldBackgroundColor: const Color(0xFF171717),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF49DD93),
    onPrimary: Color(0xFF171717),
    surface: Color(0xFF292929),
    surfaceContainer: Color(0xFF212121),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xA3FFFFFF),
    outline: Color(0x0FFFFFFF),
    secondary: Color(0xFF49DD93),
    onSecondary: Color(0xFF171717),
    secondaryContainer: Color(0x1FFFFFFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  ),
  textTheme: const TextTheme(
    titleMedium: TextStyle(fontWeight: FontWeight.w500),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0x1FFFFFFF); // #FFFFFF 12%
        }
        return const Color(0x0FFFFFFF); // #FFFFFF 6%
      }),
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFFFFFFFF),
    foregroundColor: const Color(0xE0171717),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFFFFFF);
      return const Color(0xA3FFFFFF);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF49DD93);
      return const Color(0x1FFFFFFF);
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.transparent;
      return const Color(0x59FFFFFF);
    }),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    actionsIconTheme: IconThemeData(color: Color(0xE0FFFFFF)),
    iconTheme: IconThemeData(color: Color(0xE0FFFFFF)),
  ),
  iconTheme: const IconThemeData(
    color: Color(0xE0FFFFFF),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0x0FFFFFFF),
    thickness: 1,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF212121),
    modalBackgroundColor: Color(0xFF212121),
    elevation: 0,
    modalElevation: 0,
  ),
  extensions: const <ThemeExtension<dynamic>>[
    darkThemeExtension,
  ],
);