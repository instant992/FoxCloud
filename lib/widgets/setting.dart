import 'package:flowvy/common/custom_theme.dart';
import 'package:flutter/material.dart';

import 'card.dart';

class _StyledSettingCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;
  final Widget child;

  const _StyledSettingCard({
    required this.isSelected,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    
    return OutlinedButton(
      onPressed: onPressed,
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
          if (isSelected || states.contains(WidgetState.hovered)) {
             return BorderSide(color: customTheme.proxyCardBorderSelected!, width: 1);
          }
          return BorderSide(color: customTheme.proxyCardBorder!, width: 1);
        }),
      ),
      child: child,
    );
  }
}


class SettingInfoCard extends StatelessWidget {
  final Info info;
  final bool? isSelected;
  final VoidCallback onPressed;

  const SettingInfoCard(
      this.info, {
        super.key,
        this.isSelected,
        required this.onPressed,
      });

  @override
  Widget build(BuildContext context) {
    return _StyledSettingCard(
      isSelected: isSelected ?? false,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Icon(info.iconData, color: Theme.of(context).iconTheme.color),
            ),
            const SizedBox(
              width: 8,
            ),
            Flexible(
              child: Text(
                info.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingTextCard extends StatelessWidget {
  final String text;
  final bool? isSelected;
  final VoidCallback onPressed;

  const SettingTextCard(
      this.text, {
        super.key,
        this.isSelected,
        required this.onPressed,
      });

  @override
  Widget build(BuildContext context) {
    return _StyledSettingCard(
      onPressed: onPressed,
      isSelected: isSelected ?? false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface
          ),
        ),
      ),
    );
  }
}