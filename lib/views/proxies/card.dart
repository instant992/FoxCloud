// lib/views/proxies/card.dart - ФИНАЛЬНАЯ ВЕРСИЯ

import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/views/proxies/common.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProxyCard extends StatelessWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  Measure get measure => globalState.measure;

  _handleTestCurrentDelay() {
    proxyDelayTest(
      proxy,
      testUrl,
    );
  }

  Widget _buildDelayText(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    // Используем цвет пинга из кастомной темы
    final pingColor = customTheme.proxyPingColor;

    return SizedBox(
      height: measure.labelSmallHeight,
      child: Consumer(
        builder: (context, ref, __) {
          final delay = ref.watch(getDelayProvider(
            proxyName: proxy.name,
            testUrl: testUrl,
          ));
          
          if (delay == null) {
            return SizedBox(
              height: measure.labelSmallHeight,
              width: measure.labelSmallHeight,
              child: IconButton(
                icon: Icon(Icons.bolt_outlined, color: pingColor),
                iconSize: globalState.measure.labelSmallHeight,
                padding: EdgeInsets.zero,
                onPressed: _handleTestCurrentDelay,
              ),
            );
          }
          if (delay == 0) {
              return SizedBox(
              height: measure.labelSmallHeight,
              width: measure.labelSmallHeight,
              child: CircularProgressIndicator(strokeWidth: 2, color: pingColor),
            );
          }
          return GestureDetector(
            onTap: _handleTestCurrentDelay,
            child: Text(
              delay > 0 ? '$delay ms' : "Timeout",
              style: context.textTheme.labelSmall?.copyWith(
                overflow: TextOverflow.ellipsis,
                color: delay > 0 ? pingColor : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProxyNameText(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
    ); 

    if (type == ProxyCardType.min) {
      return SizedBox(
        height: measure.bodyMediumHeight * 1,
        child: EmojiText(
          proxy.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      );
    } else {
      return SizedBox(
        height: measure.bodyMediumHeight * 2,
        child: EmojiText(
          proxy.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      );
    }
  }

  _changeProxy(WidgetRef ref) async {
    final isComputedSelected = groupType.isComputedSelected;
    final isSelector = groupType == GroupType.Selector;
    if (isComputedSelected || isSelector) {
      final currentProxyName = ref.read(getProxyNameProvider(groupName));
      final nextProxyName = switch (isComputedSelected) {
        true => currentProxyName == proxy.name ? "" : proxy.name,
        false => proxy.name,
      };
      final appController = globalState.appController;
      appController.updateCurrentSelectedMap(
        groupName,
        nextProxyName,
      );
      await appController.changeProxyDebounce(groupName, nextProxyName);
      return;
    }
    globalState.showNotifier(
      appLocalizations.notSelectedTip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measure = globalState.measure;
    final delayText = _buildDelayText(context);
    final proxyNameText = _buildProxyNameText(context);
    final customTheme = theme.extension<CustomTheme>()!;
    
    // Стиль для подзаголовка ("Vless", "Fallback")
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final cardContent = Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          proxyNameText,
          const SizedBox(height: 8),
          if (type == ProxyCardType.expand) ...[
            SizedBox(
              height: measure.bodySmallHeight,
              child: _ProxyDesc(proxy: proxy),
            ),
            const SizedBox(height: 6),
            delayText,
          ] else
            SizedBox(
              height: measure.bodySmallHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: TooltipText(
                      text: Text(
                        proxy.type,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  delayText,
                ],
              ),
            ),
        ],
      ),
    );

    return Stack(
      children: [
        Consumer(
          builder: (_, ref, child) {
            final selectedProxyName =
                ref.watch(getSelectedProxyNameProvider(groupName));
            final isSelected = selectedProxyName == proxy.name;

            return OutlinedButton(
              onPressed: () => _changeProxy(ref),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (isSelected) {
                    return customTheme.proxyCardBackgroundSelected!;
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return customTheme.proxyCardBackgroundHover!;
                  }
                  return customTheme.proxyCardBackground!;
                }),
                side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                  if (isSelected) {
                      return BorderSide(color: customTheme.proxyCardBorderSelected!, width: 1);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return BorderSide(color: customTheme.proxyCardBorderHover!, width: 1);
                  }
                  return BorderSide(color: customTheme.proxyCardBorder!, width: 1);
                }),
              ),
              child: child!,
            );
          },
          child: cardContent,
        ),
        if (groupType.isComputedSelected)
          Positioned(
            top: 0,
            right: 0,
            child: _ProxyComputedMark(
              groupName: groupName,
              proxy: proxy,
            ),
          )
      ],
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({
    required this.proxy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(
      getProxyDescProvider(proxy),
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: subtitleStyle,
    );
  }
}

class _ProxyComputedMark extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;

  const _ProxyComputedMark({
    required this.groupName,
    required this.proxy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref.watch(
      getProxyNameProvider(groupName),
    );
    if (proxyName != proxy.name) {
      return const SizedBox();
    }
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const SelectIcon(),
      ),
    );
  }
}