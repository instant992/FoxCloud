import 'dart:async';

import 'package:flowvy/common/common.dart';
import 'package:flowvy/providers/config.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
  });
}

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  bool _isChecking = false;

  Future<void> _checkUpdate(BuildContext context) async {
    setState(() {
      _isChecking = true;
    });

    try {
      final data = await request.checkForUpdate();
      
      if (mounted) {
        globalState.appController.checkUpdateResultHandle(
          data: data,
          handleError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;

    return generateSection(
      separated: false,
      title: appLocalizations.more,
      items: [
        ListItem(
          title: Text(appLocalizations.project),
          onTap: () {
            globalState.openUrl(
              'https://github.com/$repository',
            );
          },
          trailing: Icon(Icons.insert_link_rounded, color: iconColor),
        ),
        ListItem(
          title: Text(appLocalizations.core),
          onTap: () {
            globalState.openUrl(
              'https://github.com/chen08209/Clash.Meta/tree/FlClash',
            );
          },
          trailing: Icon(Icons.insert_link_rounded, color: iconColor),
        ),
      ],
    );
  }

  List<Widget> _buildCreditsSections(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;

    const authors = [
      Contributor(
        avatar: 'assets/images/avatars/x_kit_.jpg',
        name: 'x_kit_',
        link: 'https://github.com/this-xkit',
      ),
    ];

    const specialThanks = [
      Contributor(
        avatar: 'assets/images/avatars/pluralplay.jpg',
        name: 'pluralplay',
        link: 'https://github.com/pluralplay',
      ),
    ];

    return [
      ...generateSection(
        separated: false,
        title: appLocalizations.Contributors,
        items: [
          ListItem(
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 24,
                children: [
                  for (final contributor in authors)
                    Avatar(contributor: contributor),
                ],
              ),
            ),
          )
        ],
      ),
      const SizedBox(height: 12),
      ...generateSection(
        separated: false,
        title: appLocalizations.specialThanks,
        items: [
          for (final contributor in specialThanks)
            ListItem(
              title: Text(contributor.name),
              onTap: () => globalState.openUrl(contributor.link),
              trailing: Icon(Icons.explore_rounded, color: iconColor),
            )
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scrollableItems = [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(builder: (_, ref, ___) {
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              final String iconAsset = isDarkMode
                  ? 'assets/images/icon.png'
                  : 'assets/images/icon_black.png';

              return _DeveloperModeDetector(
                child: Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        iconAsset,
                        width: 64,
                        height: 64,
                        cacheWidth: 192, // 64 * 3 for higher DPI displays
                        cacheHeight: 192,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appLocalizations.clientVersion}: ${globalState.packageInfo.version}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${appLocalizations.coreVersion}: $coreVersion',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  ],
                ),
                onEnterDeveloperMode: () {
                  ref.read(appSettingProvider.notifier).updateState(
                        (state) => state.copyWith(developerMode: true),
                      );
                  context.showNotifier(appLocalizations.developerModeEnableTip);
                },
              );
            }),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                appLocalizations.desc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._buildCreditsSections(context),
      ..._buildMoreSection(context),
    ];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: kMaterialListPadding.copyWith(
              top: 16,
              bottom: 16,
            ),
            child: generateListView(scrollableItems),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: FilledButton.icon(
              onPressed: _isChecking ? null : () => _checkUpdate(context),
              icon: _isChecking
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : const Icon(Icons.update_rounded),
              label: Text(
                _isChecking 
                    ? appLocalizations.checking
                    : appLocalizations.checkUpdate
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({
    super.key,
    required this.contributor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        globalState.openUrl(contributor.link);
      },
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipOval(
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                contributor.avatar,
                fit: BoxFit.cover,
                cacheWidth: 108, // 36 * 3 for higher DPI displays
                cacheHeight: 108,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            contributor.name,
            style: context.textTheme.bodySmall,
          )
        ],
      ),
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.child,
    );
  }
}