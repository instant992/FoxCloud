import 'package:flowvy/enum/enum.dart';
import 'package:flutter/material.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ChipType type;
  final Widget? avatar;

  const CommonChip({
    super.key,
    required this.label,
    this.onPressed,
    this.avatar,
    this.type = ChipType.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color textColor = colorScheme.onSurface;
    final Color iconColor = colorScheme.onSurface;
    final Color defaultBgColor = colorScheme.outline;
    final Color defaultBorderColor = colorScheme.outline;
    final Color hoverBgColor = colorScheme.secondaryContainer;

    final labelStyle = textTheme.bodyMedium?.copyWith(color: textColor);
    final iconTheme = IconThemeData(color: iconColor, size: 18);

    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) {
            return hoverBgColor;
          }
          return defaultBgColor;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: defaultBorderColor, width: 1),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[
            IconTheme(
              data: iconTheme,
              child: avatar!,
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}