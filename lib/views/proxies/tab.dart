import 'dart:math';

import 'package:flowvy/common/common.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/common.dart';
import 'card.dart';
import 'common.dart';

typedef GroupNameKeyMap = Map<String, GlobalObjectKey<ProxyGroupViewState>>;

class ProxiesTabView extends ConsumerStatefulWidget {
  const ProxiesTabView({super.key});

  @override
  ConsumerState<ProxiesTabView> createState() => ProxiesTabViewState();
}

class ProxiesTabViewState extends ConsumerState<ProxiesTabView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  GroupNameKeyMap _keyMap = {};
  double _dragStartX = 0;
  int _dragStartIndex = 0;

  @override
  void initState() {
    super.initState();
    _handleTabListen();
  }

  @override
  void dispose() {
    _destroyTabController();
    super.dispose();
  }

  scrollToGroupSelected() {
    final currentGroupName = globalState.appController.getCurrentGroupName();
    _keyMap[currentGroupName]?.currentState?.scrollToSelected();
  }

  delayTestCurrentGroup() async {
    final currentGroupName = globalState.appController.getCurrentGroupName();
    final currentState = _keyMap[currentGroupName]?.currentState;
    await delayTest(
      currentState?.proxies ?? [],
      currentState?.testUrl,
    );
  }

  Widget _buildPageIndicator(int count) {
    return Consumer(
      builder: (_, ref, __) {
        final isMobile = ref.watch(isMobileViewProvider);

        // Show indicators only on mobile devices
        if (!isMobile) {
          return const SizedBox.shrink();
        }

        final currentGroupName = ref.watch(
          currentProfileProvider.select((state) => state?.currentGroupName),
        );
        final groupNames = ref.watch(
          proxiesSelectorStateProvider.select((state) => state.groupNames),
        );
        final currentIndex = groupNames.indexWhere(
          (name) => name == currentGroupName,
        );

        return GestureDetector(
          onHorizontalDragStart: (details) {
            _dragStartX = details.globalPosition.dx;
            _dragStartIndex = currentIndex;
          },
          onHorizontalDragUpdate: (details) {
            final deltaX = details.globalPosition.dx - _dragStartX;
            final threshold = 40.0; // Threshold value for switching

            if (deltaX > threshold && _dragStartIndex > 0) {
              // Swipe right - switch to previous group
              final newIndex = _dragStartIndex - 1;
              _tabController?.animateTo(newIndex);
              globalState.appController.updateCurrentGroupName(groupNames[newIndex]);
              _dragStartX = details.globalPosition.dx;
              _dragStartIndex = newIndex;
            } else if (deltaX < -threshold && _dragStartIndex < groupNames.length - 1) {
              // Swipe left - switch to next group
              final newIndex = _dragStartIndex + 1;
              _tabController?.animateTo(newIndex);
              globalState.appController.updateCurrentGroupName(groupNames[newIndex]);
              _dragStartX = details.globalPosition.dx;
              _dragStartIndex = newIndex;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                min(count, 10), // Max 10 dots for large number of groups
                (index) {
                  final isActive = index == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withAlpha(51),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  _tabControllerListener([int? index]) {
    int? groupIndex = index;
    if (groupIndex == -1) {
      return;
    }
    final appController = globalState.appController;
    if (groupIndex == null) {
      final currentIndex = _tabController?.index;
      groupIndex = currentIndex;
    }
    final currentGroups = appController.getCurrentGroups();
    if (groupIndex == null || groupIndex > currentGroups.length) {
      return;
    }
    final currentGroup = currentGroups[groupIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalState.appController.updateCurrentGroupName(
        currentGroup.name,
      );
    });
  }

  _destroyTabController() {
    _tabController?.removeListener(_tabControllerListener);
    _tabController?.dispose();
    _tabController = null;
  }

  _updateTabController(int length, int index) {
    if (length == 0) {
      _destroyTabController();
      return;
    }
    final realIndex = index == -1 ? 0 : index;
    _tabController ??= TabController(
      length: length,
      initialIndex: realIndex,
      vsync: this,
    );
    _tabControllerListener(realIndex);
    _tabController?.addListener(_tabControllerListener);
  }

  _handleTabListen() {
    ref.listenManual(
      proxiesSelectorStateProvider,
      (prev, next) {
        if (prev == next) {
          return;
        }
        if (!stringListEquality.equals(prev?.groupNames, next.groupNames)) {
          _destroyTabController();
          final index = next.groupNames.indexWhere(
            (item) => item == next.currentGroupName,
          );
          _updateTabController(next.groupNames.length, index);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeSettingProvider.select((state) => state.textScale));
    final state = ref.watch(groupNamesStateProvider);
    final groupNames = state.groupNames;
    if (groupNames.isEmpty) {
      return NullStatus(
        label: appLocalizations.emptyStateMessage,
      );
    }
    final GroupNameKeyMap keyMap = {};
    final children = groupNames.map((groupName) {
      keyMap[groupName] = GlobalObjectKey(groupName);
      return KeepScope(
        child: ProxyGroupView(
          key: keyMap[groupName],
          groupName: groupName,
        ),
      );
    }).toList();
    _keyMap = keyMap;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              dividerColor: Colors.transparent,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              overlayColor:
                  const WidgetStatePropertyAll(Colors.transparent),

              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,

              tabs: [
                for (final groupName in groupNames)
                  Tab(
                    text: groupName,
                  ),
              ],
            ),
            if (groupNames.length > 1)
              _buildPageIndicator(groupNames.length),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: children,
          ),
        )
      ],
    );
  }
}

class ProxyGroupView extends ConsumerStatefulWidget {
  final String groupName;

  const ProxyGroupView({
    super.key,
    required this.groupName,
  });

  @override
  ConsumerState<ProxyGroupView> createState() => ProxyGroupViewState();
}

class ProxyGroupViewState extends ConsumerState<ProxyGroupView> {
  final _controller = ScrollController();

  List<Proxy> proxies = [];
  String? testUrl;

  String get groupName => widget.groupName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  scrollToSelected() {
    if (_controller.position.maxScrollExtent == 0) {
      return;
    }
    _controller.animateTo(
      min(
        16 +
            getScrollToSelectedOffset(
              groupName: groupName,
              proxies: proxies,
            ),
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proxyGroupSelectorStateProvider(groupName));
    final proxies = state.proxies;
    final columns = state.columns;
    final proxyCardType = state.proxyCardType;
    final sortedProxies = globalState.appController.getSortProxies(
      proxies,
      state.testUrl,
    );
    this.proxies = sortedProxies;
    testUrl = state.testUrl;

    return Align(
      alignment: Alignment.topCenter,
      child: CommonAutoHiddenScrollBar(
        controller: _controller,
        child: GridView.builder(
          controller: _controller,
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 96,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: getItemHeight(proxyCardType),
          ),
          itemCount: sortedProxies.length,
          itemBuilder: (_, index) {
            final proxy = sortedProxies[index];
            return ProxyCard(
              testUrl: state.testUrl,
              groupType: state.groupType,
              type: proxyCardType,
              key: ValueKey('$groupName.${proxy.name}'),
              proxy: proxy,
              groupName: groupName,
            );
          },
        ),
      ),
    );
  }
}

class DelayTestButton extends StatefulWidget {
  final Future Function() onClick;

  const DelayTestButton({
    super.key,
    required this.onClick,
  });

  @override
  State<DelayTestButton> createState() => _DelayTestButtonState();
}

class _DelayTestButtonState extends State<DelayTestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  _healthcheck() async {
    if (_controller.isAnimating) {
      return;
    }
    _controller.forward();
    await widget.onClick();
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 200,
      ),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (_, child) {
        return SizedBox(
          width: 56,
          height: 56,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        heroTag: null,
        onPressed: _healthcheck,
        child: const Icon(Icons.network_ping_rounded),
      ),
    );
  }
}
