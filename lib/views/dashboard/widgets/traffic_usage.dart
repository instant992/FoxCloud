import 'dart:math';

import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/providers/app.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrafficUsage extends StatelessWidget {
  const TrafficUsage({super.key});

  Widget _buildTrafficDataItem(
    BuildContext context,
    Icon icon,
    TrafficValue trafficValue,
  ) {
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              icon,
              const SizedBox(
                width: 8,
              ),
              Flexible(
                flex: 1,
                child: Text(
                  trafficValue.showValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        Text(
          trafficValue.showUnit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor.withAlpha(204)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customTheme = theme.extension<CustomTheme>()!;

    final primaryColor = colorScheme.primary;
    final subtitleColor = colorScheme.onSurfaceVariant;
    
    final downloadColor = customTheme.trafficChartDownloadColor!;

    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        info: Info(
          label: appLocalizations.trafficUsage,
          iconData: Icons.data_saver_off_rounded,
        ),
        onPressed: () {},
        child: Consumer(
          builder: (_, ref, __) {
            final totalTraffic = ref.watch(totalTrafficProvider);
            final upTotalTrafficValue = totalTraffic.up;
            final downTotalTrafficValue = totalTraffic.down;
            return Padding(
              padding: baseInfoEdgeInsets.copyWith(
                top: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: DonutChart(
                              data: [
                                DonutChartData(
                                  value: upTotalTrafficValue.value.toDouble(),
                                  color: primaryColor,
                                ),
                                DonutChartData(
                                  value: downTotalTrafficValue.value.toDouble(),
                                  color: downloadColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Flexible(
                            child: LayoutBuilder(
                              builder: (_, container) {
                                final textStyle = theme.textTheme.bodySmall?.copyWith(color: subtitleColor);
                                final uploadText = Text(
                                  maxLines: 1,
                                  appLocalizations.upload,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyle,
                                );
                                final downloadText = Text(
                                  maxLines: 1,
                                  appLocalizations.download,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyle,
                                );
                                final uploadTextSize = globalState.measure
                                    .computeTextSize(uploadText);
                                final downloadTextSize = globalState.measure
                                    .computeTextSize(downloadText);
                                final maxTextWidth = max(uploadTextSize.width,
                                    downloadTextSize.width);
                                if (maxTextWidth + 24 > container.maxWidth) {
                                  return Container();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: primaryColor,
                                            shape: RoundedSuperellipseBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          maxLines: 1,
                                          appLocalizations.upload,
                                          overflow: TextOverflow.ellipsis,
                                          style: textStyle,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 8,
                                          decoration: ShapeDecoration(
                                            color: downloadColor,
                                            shape: RoundedSuperellipseBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          maxLines: 1,
                                          appLocalizations.download,
                                          overflow: TextOverflow.ellipsis,
                                          style: textStyle,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildTrafficDataItem(
                    context,
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: primaryColor,
                      size: 14,
                    ),
                    upTotalTrafficValue,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildTrafficDataItem(
                    context,
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: downloadColor,
                      size: 14,
                    ),
                    downTotalTrafficValue,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}