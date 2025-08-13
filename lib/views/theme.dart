import 'package:flowvy/common/common.dart';
import 'package:flowvy/providers/config.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeItemData {
  final ThemeMode themeMode;
  final IconData iconData;
  final String label;

  const ThemeModeItemData({
    required this.themeMode,
    required this.iconData,
    required this.label,
  });
}

class ThemeView extends StatelessWidget {
  const ThemeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        spacing: 24,
        children: [
          _ThemeModeItem(),
          SizedBox(
            height: 64,
          ),
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Widget child;
  final Info info;
  final List<Widget> actions;

  const ItemCard({
    super.key,
    required this.info,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 16,
      children: [
        InfoHeader(
          info: info,
          actions: actions,
        ),
        child,
      ],
    );
  }
}


class _ThemeModeItem extends ConsumerWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeSettingProvider.select((state) => state.themeMode));
    
    final List<ThemeModeItemData> themeModeItems = [
      ThemeModeItemData(
        iconData: Icons.auto_mode_rounded,
        label: appLocalizations.auto,
        themeMode: ThemeMode.system,
      ),
      ThemeModeItemData(
        iconData: Icons.light_mode_rounded,
        label: appLocalizations.light,
        themeMode: ThemeMode.light,
      ),
      ThemeModeItemData(
        iconData: Icons.dark_mode_rounded,
        label: appLocalizations.dark,
        themeMode: ThemeMode.dark,
      ),
    ];

    return ItemCard(
      info: Info(
        label: appLocalizations.themeMode,
        iconData: Icons.brightness_high_rounded,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: themeModeItems.length,
          itemBuilder: (_, index) {
            final themeModeItem = themeModeItems[index];
            return SettingInfoCard(
              Info(
                label: themeModeItem.label,
                iconData: themeModeItem.iconData,
              ),
              isSelected: themeModeItem.themeMode == themeMode,
              onPressed: () {
                ref.read(themeSettingProvider.notifier).updateState(
                      (state) => state.copyWith(
                        themeMode: themeModeItem.themeMode,
                      ),
                    );
              },
            );
          },
          separatorBuilder: (_, __) {
            return const SizedBox(
              width: 16,
            );
          },
        ),
      ),
    );
  }
}