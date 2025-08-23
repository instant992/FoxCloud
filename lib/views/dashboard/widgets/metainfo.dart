import 'dart:math';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/views/profiles/add_profile.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowvy/common/custom_theme.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MetainfoWidget extends ConsumerWidget {
  const MetainfoWidget({super.key});

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = ref.watch(profilesProvider);
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final customTheme = theme.extension<CustomTheme>()!;

    Widget child;

    if (allProfiles.isEmpty) {
      child = CommonCard(
        onPressed: () {
          showExtend(
            context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: AddProfileView(
                  context: context,
                ),
                title: appLocalizations.addProfileTitle,
              );
            },
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                appLocalizations.addProfileTitle,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    } else {
      final subscriptionInfo = profile?.subscriptionInfo;

      if (profile == null || subscriptionInfo == null) {
        child = const SizedBox.shrink();
      } else {
        final bool isPerpetual = subscriptionInfo.expire == 0;
        final supportUrl = profile.supportUrl;

        String expireDate = '';
        if (!isPerpetual) {
          final expireDateTime =
              DateTime.fromMillisecondsSinceEpoch(subscriptionInfo.expire * 1000);
          expireDate = expireDateTime.ddMMyyyy;
        }

        child = CommonCard(
          onPressed: () {},
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        profile.label ?? 'Профиль',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (supportUrl != null && supportUrl.isNotEmpty)
                      Tooltip(
                        message: appLocalizations.support,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              supportUrl.toLowerCase().contains('t.me')
                                  ? Icons.telegram_rounded
                                  : Icons.launch_rounded,
                            ),
                            iconSize: 22,
                            color: theme.iconTheme.color,
                            onPressed: () {
                              globalState.openUrl(supportUrl);
                            },
                          ),
                        ),
                      ),
                    Tooltip(
                      message: appLocalizations.sync,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.sync_rounded),
                          iconSize: 22,
                          color: theme.iconTheme.color,
                          onPressed: () {
                            globalState.appController.updateProfile(profile);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(builder: (context) {
                    final total = subscriptionInfo.total;
                    final used =
                        subscriptionInfo.upload + subscriptionInfo.download;
                    final isUnlimited = total == 0;

                    if (isUnlimited) {
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations.trafficUnlimited,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: theme.colorScheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 14, color: subtitleColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        isPerpetual
                                            ? appLocalizations.subscriptionEternal
                                            : '${appLocalizations.expiresOn} $expireDate',
                                        style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ]
                      );
                    }

                    return ScrollConfiguration(
                      behavior: _NoScrollbarBehavior(),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (used / total).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    color: theme.colorScheme.primary,
                                    backgroundColor: customTheme.profileCardProgressTrack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatBytes(used, 0),
                                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5, color: subtitleColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            _formatBytes(total, 0),
                                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5, color: subtitleColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.hourglass_bottom_rounded, size: 15, color: subtitleColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "${appLocalizations.remaining}: ${_formatBytes(total - used, 2)}",
                                        style: theme.textTheme.bodySmall?.copyWith(fontFeatures: [const FontFeature.tabularFigures()], color: subtitleColor),
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                                if (profile.subscriptionRefillDate != null && profile.subscriptionRefillDate! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.restart_alt_rounded, size: 15, color: subtitleColor),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Builder(
                                            builder: (context) {
                                              final refillTimestamp = profile.subscriptionRefillDate!;
                                              final nextResetDate = DateTime.fromMillisecondsSinceEpoch(refillTimestamp * 1000);
                                              final daysUntilReset = nextResetDate.difference(DateTime.now()).inDays.clamp(0, 9999);
                                              final dayUnit = daysUntilReset.plural(appLocalizations.dayOne, appLocalizations.dayTwo, appLocalizations.days);

                                              return Text(
                                                '${appLocalizations.limitResetIn} $daysUntilReset $dayUnit',
                                                style: theme.textTheme.bodySmall?.copyWith(fontFeatures: [const FontFeature.tabularFigures()], color: subtitleColor),
                                                softWrap: true, // ✅ разрешаем перенос
                                                maxLines: 2,      // ✅ максимум 2 строки
                                                overflow: TextOverflow.visible,
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: getWidgetHeight(2),
      child: child,
    );
  }
}
