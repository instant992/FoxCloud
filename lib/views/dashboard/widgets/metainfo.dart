import 'dart:math';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/views/profiles/add_profile.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MetainfoWidget extends ConsumerWidget {
  const MetainfoWidget({super.key});

  String _formatBytes(BigInt bytes, int decimals) {
    if (bytes <= BigInt.zero) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes.toDouble() / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = ref.watch(profilesProvider);
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final iconTheme = theme.iconTheme;
    final customTheme = theme.extension<CustomTheme>()!;
    final subtitleStyle = textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    Widget child;

    if (allProfiles.isEmpty) {
      child = CommonCard(
        info: Info(
          label: appLocalizations.addProfileTitle,
          iconData: Icons.manage_accounts_rounded,
        ),
        onPressed: () {
          showExtend(
            context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: AddProfileView(
                  context: context,
                  navigateToProfiles: false,
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
                color: iconTheme.color,
              ),
            ],
          ),
        ),
      );
    } else if (profile == null || profile.subscriptionInfo == null) {
      child = const SizedBox.shrink();
    } else {
      final subscriptionInfo = profile.subscriptionInfo!;
      final BigInt totalTraffic = BigInt.from(subscriptionInfo.total);
      final BigInt download = BigInt.from(subscriptionInfo.download);
      final BigInt upload = BigInt.from(subscriptionInfo.upload);
      final BigInt usedTraffic = download + upload;

      final isUnlimitedTraffic = totalTraffic <= BigInt.zero;
      final isOverLimit = !isUnlimitedTraffic && usedTraffic >= totalTraffic;

      double progress = 0.0;
      if (!isUnlimitedTraffic) {
        progress = usedTraffic.toDouble() / totalTraffic.toDouble();
        if (progress.isNaN) progress = 0.0;
        if (progress < 0) progress = 0.0;
        if (progress > 1) progress = 1.0;
      }
      final isNearLimit = !isUnlimitedTraffic && progress >= 0.8 && !isOverLimit;

      final hasExpireDate = subscriptionInfo.expire > 0;
      final expireDate = hasExpireDate
          ? DateTime.fromMillisecondsSinceEpoch(subscriptionInfo.expire * 1000)
          : null;

      final hasRefillDate = !isUnlimitedTraffic &&
          profile.subscriptionRefillDate != null &&
          profile.subscriptionRefillDate! > 0;

      child = LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 230;

          final menuItems = <PopupMenuEntry<String>>[
            if (profile.supportUrl != null && profile.supportUrl!.isNotEmpty)
              PopupMenuItem<String>(
                value: 'support',
                child: Row(
                  children: [
                    Icon(
                      isTelegramUrl(profile.supportUrl!)
                          ? Icons.telegram_rounded
                          : Icons.open_in_new_rounded,
                      size: 20,
                      color: iconTheme.color,
                    ),
                    const SizedBox(width: 12),
                    Text(appLocalizations.support),
                  ],
                ),
              ),
            PopupMenuItem<String>(
              value: 'sync',
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 20,
                    color: iconTheme.color,
                  ),
                  const SizedBox(width: 12),
                  Text(appLocalizations.sync),
                ],
              ),
            ),
          ];

          final narrowActions = [
            Transform.translate(
              offset: const Offset(8, 0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: iconTheme.color,
                  ),
                  itemBuilder: (context) => menuItems,
                  onSelected: (value) {
                    switch (value) {
                      case 'support':
                        if (profile.supportUrl != null) {
                          globalState.openUrl(profile.supportUrl!);
                        }
                        break;
                      case 'sync':
                        globalState.appController.updateProfile(profile);
                        break;
                    }
                  },
                ),
              ),
            ),
          ];

          final wideActions = [
            if (profile.supportUrl != null && profile.supportUrl!.isNotEmpty) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                icon: Icon(
                  isTelegramUrl(profile.supportUrl!)
                      ? Icons.telegram_rounded
                      : Icons.open_in_new_rounded,
                ),
                color: iconTheme.color,
                tooltip: appLocalizations.support,
                onPressed: () {
                  globalState.openUrl(profile.supportUrl!);
                },
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.sync_rounded),
              color: iconTheme.color,
              tooltip: appLocalizations.sync,
              onPressed: () {
                globalState.appController.updateProfile(profile);
              },
            ),
          ];

          final cardWidget = CommonCard(
            info: Info(
              label: (profile.label != null && profile.label!.isNotEmpty)
                  ? profile.label!
                  : appLocalizations.yourPlan,
              iconData: Icons.manage_accounts_rounded,
            ),
            headerPadding: baseInfoEdgeInsets.copyWith(top: 12.ap, bottom: 0),
            actions: isNarrow ? narrowActions : wideActions,
            onPressed: () {},
            child: Padding(
              padding: baseInfoEdgeInsets.copyWith(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isOverLimit
                            ? Icons.error_rounded
                            : (isNearLimit ? Icons.warning_rounded : Icons.data_usage_rounded),
                        size: 16,
                        color: isOverLimit
                            ? Colors.red
                            : (isNearLimit ? Colors.orange : iconTheme.color),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isUnlimitedTraffic
                            ? Text(
                                appLocalizations.trafficUnlimited,
                                style: subtitleStyle?.copyWith(fontWeight: FontWeight.w500),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate full text width
                                  final fullText = '${appLocalizations.traffic} ${_formatBytes(usedTraffic, 2)} / ${_formatBytes(totalTraffic, 2)}';
                                  final textPainter = TextPainter(
                                    text: TextSpan(
                                      text: fullText,
                                      style: subtitleStyle,
                                    ),
                                    maxLines: 1,
                                    textDirection: TextDirection.ltr,
                                  )..layout(maxWidth: constraints.maxWidth);

                                  // If it fits - show full text
                                  if (textPainter.didExceedMaxLines == false) {
                                    return Text.rich(
                                      TextSpan(
                                        style: subtitleStyle,
                                        children: [
                                          TextSpan(text: '${appLocalizations.traffic} '),
                                          TextSpan(
                                            text: '${_formatBytes(usedTraffic, 2)} / ${_formatBytes(totalTraffic, 2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: subtitleStyle?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // If doesn't fit - show only numbers
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _formatBytes(usedTraffic, 2),
                                          style: subtitleStyle?.copyWith(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          _formatBytes(totalTraffic, 2),
                                          style: subtitleStyle?.copyWith(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  if (!isUnlimitedTraffic) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: isOverLimit
                              ? Colors.red
                              : (isNearLimit ? Colors.orange : colorScheme.primary),
                          backgroundColor: customTheme.profileCardProgressTrack,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  if (hasRefillDate) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: iconTheme.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final refillTimestamp = profile.subscriptionRefillDate!;
                              final refillDate = DateTime.fromMillisecondsSinceEpoch(refillTimestamp * 1000);
                              final daysUntilReset = refillDate.difference(DateTime.now()).inDays.clamp(0, 9999);
                              final dayUnit = daysUntilReset.plural(
                                appLocalizations.dayOne,
                                appLocalizations.dayTwo,
                                appLocalizations.days,
                              );

                              return Text.rich(
                                TextSpan(
                                  style: subtitleStyle,
                                  children: [
                                    TextSpan(text: '${appLocalizations.limitResetIn} '),
                                    TextSpan(
                                      text: '$daysUntilReset $dayUnit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: subtitleStyle?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: iconTheme.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: hasExpireDate && expireDate != null
                            ? Text.rich(
                                TextSpan(
                                  style: subtitleStyle,
                                  children: [
                                    TextSpan(text: '${appLocalizations.subscriptionTo} '),
                                    TextSpan(
                                      text: expireDate.ddMMyyyy,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: subtitleStyle?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                appLocalizations.subscriptionUnlimited,
                                style: subtitleStyle?.copyWith(fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          final bool showCat = isUnlimitedTraffic && !hasExpireDate;

          if (showCat) {
            final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

            final String catAsset = isDarkMode
                ? 'assets/images/xxx/white_cat.svg'
                : 'assets/images/xxx/black_cat.svg';

            return Stack(
              children: [
                cardWidget,
                Positioned(
                  bottom: 8.0,
                  right: 8.0,
                  child: SvgPicture.asset(
                    catAsset,
                    width: 32,
                    height: 32,
                  ),
                ),
              ],
            );
          } else {
            return cardWidget;
          }
        },
      );
    }

    return SizedBox(
      height: getWidgetHeight(2),
      child: child,
    );
  }
}
