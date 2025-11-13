import 'dart:io';

import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBackScope(
      child: Consumer(
        builder: (_, ref, child) {
          final state = ref.watch(homeStateProvider);
          final viewMode = state.viewMode;
          final navigationItems = state.navigationItems;
          final pageLabel = state.pageLabel;
          final index = navigationItems.lastIndexWhere(
            (element) => element.label == pageLabel,
          );
          final currentIndex = index == -1 ? 0 : index;
          final navigationBar = CommonNavigationBar(
            viewMode: viewMode,
            navigationItems: navigationItems,
            currentIndex: currentIndex,
          );
          final bottomNavigationBar =
              viewMode == ViewMode.mobile ? navigationBar : null;
          final sideNavigationBar =
              viewMode != ViewMode.mobile ? navigationBar : null;
          return CommonScaffold(
            key: globalState.homeScaffoldKey,
            title: Intl.message(
              pageLabel.name,
            ),
            sideNavigationBar: sideNavigationBar,
            body: child!,
            bottomNavigationBar: bottomNavigationBar,
          );
        },
        child: const _HomePageView(),
      ),
    );
  }
}

class _HomePageView extends ConsumerStatefulWidget {
  const _HomePageView();

  @override
  ConsumerState createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<_HomePageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _pageIndex,
      keepPage: true,
    );
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
    ref.listenManual(currentNavigationsStateProvider, (prev, next) {
      if (prev?.value.length != next.value.length) {
        _updatePageController();
      }
    });
  }

  int get _pageIndex {
    final navigationItems = ref.read(currentNavigationsStateProvider).value;
    return navigationItems.indexWhere(
      (item) => item.label == globalState.appState.pageLabel,
    );
  }

  _toPage(PageLabel pageLabel, [bool ignoreAnimateTo = false]) async {
    if (!mounted) {
      return;
    }
    final navigationItems = ref.read(currentNavigationsStateProvider).value;
    final index = navigationItems.indexWhere((item) => item.label == pageLabel);
    if (index == -1) {
      return;
    }
    final isAnimateToPage = ref.read(appSettingProvider).isAnimateToPage;
    final isMobile = ref.read(isMobileViewProvider);
    if (isAnimateToPage && isMobile && !ignoreAnimateTo) {
      await _pageController.animateToPage(
        index,
        duration: kTabScrollDuration,
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  _updatePageController() {
    final pageLabel = globalState.appState.pageLabel;
    _toPage(pageLabel, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = ref.watch(currentNavigationsStateProvider).value;
    final announce = ref.watch(
      currentProfileProvider.select((value) => value?.announce),
    );
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: navigationItems.length,
      itemBuilder: (_, index) {
        final navigationItem = navigationItems[index];
        final pageWidget = KeepScope(
          keep: navigationItem.keep,
          key: Key(navigationItem.label.name),
          child: navigationItem.view,
        );

        if (navigationItem.label == PageLabel.dashboard &&
            announce != null &&
            announce.isNotEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: CommonCard(
                    info: null,
                    onPressed: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              announce,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: pageWidget,
              ),
            ],
          );
        }

        return pageWidget;
      },
    );
  }
}

class CommonNavigationBar extends ConsumerStatefulWidget {
  final ViewMode viewMode;
  final List<NavigationItem> navigationItems;
  final int currentIndex;

  const CommonNavigationBar({
    super.key,
    required this.viewMode,
    required this.navigationItems,
    required this.currentIndex,
  });

  @override
  ConsumerState<CommonNavigationBar> createState() => _CommonNavigationBarState();
}

class _CommonNavigationBarState extends ConsumerState<CommonNavigationBar> {
  // Cache for navigation destinations to avoid rebuilding on every frame
  List<NavigationDestination>? _cachedMobileDestinations;
  List<NavigationRailDestination>? _cachedRailDestinations;
  List<NavigationItem>? _cachedNavigationItems;

  @override
  void didUpdateWidget(CommonNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache if navigation items changed
    if (oldWidget.navigationItems != widget.navigationItems) {
      _cachedMobileDestinations = null;
      _cachedRailDestinations = null;
      _cachedNavigationItems = null;
    }
  }

  List<NavigationDestination> _getMobileDestinations() {
    if (_cachedMobileDestinations == null || _cachedNavigationItems != widget.navigationItems) {
      _cachedNavigationItems = widget.navigationItems;
      _cachedMobileDestinations = widget.navigationItems
          .map(
            (e) => NavigationDestination(
              icon: e.mobileIcon ?? e.icon,
              label: Intl.message((e.mobileLabel ?? e.label).name),
              tooltip: '',
            ),
          )
          .toList();
    }
    return _cachedMobileDestinations!;
  }

  List<NavigationRailDestination> _getRailDestinations() {
    if (_cachedRailDestinations == null || _cachedNavigationItems != widget.navigationItems) {
      _cachedNavigationItems = widget.navigationItems;
      _cachedRailDestinations = widget.navigationItems
          .map(
            (e) => NavigationRailDestination(
              icon: e.icon,
              label: Text(
                Intl.message(e.label.name),
              ),
            ),
          )
          .toList();
    }
    return _cachedRailDestinations!;
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;

    if (widget.viewMode == ViewMode.mobile) {
      return NavigationBarTheme(
        data: _NavigationBarDefaultsM3(context),
        child: NavigationBar(
          destinations: _getMobileDestinations(),
          onDestinationSelected: (index) {
            globalState.appController.toPage(widget.navigationItems[index].label);
          },
          selectedIndex: widget.currentIndex,
        ),
      );
    }
    final showLabel = ref.watch(appSettingProvider).showLabel;
    return Material(
      color: context.colorScheme.surfaceContainer,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const AppIconOnly(),
          const SizedBox(height: 16),
          Expanded(
            child: ScrollConfiguration(
              behavior: HiddenBarScrollBehavior(),
              child: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: NavigationRailTheme(
                    data: NavigationRailThemeData(
                      backgroundColor: context.colorScheme.surfaceContainer,
                      indicatorColor: customTheme.navRailIndicator,
                      selectedIconTheme: IconThemeData(
                        color: Theme.of(context).iconTheme.color,
                      ),
                      unselectedIconTheme: IconThemeData(
                        color: Theme.of(context).iconTheme.color,
                      ),
                      selectedLabelTextStyle:
                          context.textTheme.labelLarge!.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                      unselectedLabelTextStyle:
                          context.textTheme.labelLarge!.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                              : const Color(0xFF171717).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          return NavigationRail(
                            destinations: _getRailDestinations(),
                            onDestinationSelected: (index) {
                              globalState.appController
                                  .toPage(widget.navigationItems[index].label);
                            },
                            extended: false,
                            selectedIndex: widget.currentIndex,
                            labelType: showLabel
                                ? NavigationRailLabelType.all
                                : NavigationRailLabelType.none,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          IconButton(
            onPressed: () {
              ref.read(appSettingProvider.notifier).updateState(
                    (state) => state.copyWith(
                      showLabel: !state.showLabel,
                    ),
                  );
            },
            icon: const Icon(Icons.menu_rounded),
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(56, 32)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: WidgetStateProperty.all(
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
                    : const Color(0xFF171717).withValues(alpha: 0.08),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}

class _NavigationBarDefaultsM3 extends NavigationBarThemeData {
  _NavigationBarDefaultsM3(this.context)
      : super(
          height: 80.0,
          elevation: 3.0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;
  late final CustomTheme _customTheme = Theme.of(context).extension<CustomTheme>()!;

  @override
  Color? get backgroundColor => _colors.surfaceContainer;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  WidgetStateProperty<IconThemeData?>? get iconTheme {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      final color = Theme.of(context).iconTheme.color;
      return IconThemeData(
        size: 24.0,
        color: states.contains(WidgetState.disabled)
            ? color?.withValues(alpha: 0.38)
            : color,
      );
    });
  }

  @override
  Color? get indicatorColor => _customTheme.navRailIndicator;

  @override
  ShapeBorder? get indicatorShape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  @override
  WidgetStateProperty<TextStyle?>? get labelTextStyle {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      final TextStyle style = _textTheme.labelLarge!;
      final Color color = _colors.onSurface;

      return style.apply(
        overflow: TextOverflow.ellipsis,
        color: states.contains(WidgetState.disabled)
            ? color.withValues(alpha: 0.38)
            : color,
      );
    });
  }
}

class HomeBackScope extends StatelessWidget {
  final Widget child;

  const HomeBackScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return CommonPopScope(
        onPop: () async {
          final canPop = Navigator.canPop(context);
          if (canPop) {
            Navigator.pop(context);
          } else {
            await globalState.appController.handleBackOrExit();
          }
          return false;
        },
        child: child,
      );
    }
    return child;
  }
}

class AppIconOnly extends StatelessWidget {
  const AppIconOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String iconAsset = isDarkMode
        ? "assets/images/icon.png"
        : "assets/images/icon_black.png";

    return SizedBox(
      width: 32,
      height: 32,
      child: Image.asset(
        iconAsset,
        fit: BoxFit.contain,
        cacheWidth: 96, // 32 * 3 for higher DPI displays
        cacheHeight: 96,
      ),
    );
  }
}