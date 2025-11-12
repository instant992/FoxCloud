import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/widgets/fade_box.dart';
import 'package:flutter/material.dart';

import 'text.dart';

class Info {
  final String label;
  final IconData? iconData;

  const Info({
    required this.label,
    this.iconData,
  });
}

class InfoHeader extends StatelessWidget {
  final Info info;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;

  const InfoHeader({
    super.key,
    required this.info,
    this.padding,
    List<Widget>? actions,
  }) : actions = actions ?? const [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? baseInfoEdgeInsets,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (info.iconData != null) ...[
                  Icon(
                    info.iconData,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
                Flexible(
                  flex: 1,
                  child: TooltipText(
                    text: Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ...actions,
            ],
          ),
        ],
      ),
    );
  }
}
class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    bool? isSelected,
    this.type = CommonCardType.plain,
    this.onPressed,
    this.selectWidget,
    this.radius = 16,
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.actions,
    this.headerPadding,
  }) : isSelected = isSelected ?? false;

  final bool enterAnimated;
  final bool isSelected;
  final void Function()? onPressed;
  final Widget? selectWidget;
  final Widget child;
  final EdgeInsets? padding;
  final Info? info;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? headerPadding;
  final CommonCardType type;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    
    var childWidget = child;

    if (info != null) {
      childWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoHeader(
            padding: headerPadding ?? baseInfoEdgeInsets.copyWith(
              bottom: 0,
            ),
            info: info!,
            actions: actions,
          ),
          Flexible(
            flex: 1,
            child: child,
          ),
        ],
      );
    }

    if (selectWidget != null && isSelected) {
      final List<Widget> children = [];
      children.add(childWidget);
      children.add(
        Positioned.fill(
          child: selectWidget!,
        ),
      );
      childWidget = Stack(
        children: children,
      );
    }

    final card = OutlinedButton(
      onLongPress: null,
      clipBehavior: Clip.antiAlias,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
           if (isSelected) return customTheme.proxyCardBackgroundSelected!;
          if (states.contains(WidgetState.hovered)) return customTheme.proxyCardBackgroundHover!;
          return customTheme.proxyCardBackground!;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
           if (isSelected || states.contains(WidgetState.hovered)) return BorderSide(color: customTheme.proxyCardBorderHover!, width: 1);
          return BorderSide(color: customTheme.proxyCardBorder!, width: 1);
        }),
      ),
      onPressed: onPressed,
      child: childWidget,
    );

    return switch (enterAnimated) {
      true => FadeScaleEnterBox(
          child: card,
        ),
      false => card,
    };
  }
}

class SelectIcon extends StatelessWidget {
  const SelectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.inversePrimary,
      shape: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.check_rounded,
          size: 16,
        ),
      ),
    );
  }
}

class SettingsBlock extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  const SettingsBlock({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          InfoHeader(
            info: Info(
              label: title,
            ),
          ),
          Card(
            color: context.colorScheme.surfaceContainer,
            child: Column(
              children: settings,
            ),
          ),
        ],
      ),
    );
  }
}