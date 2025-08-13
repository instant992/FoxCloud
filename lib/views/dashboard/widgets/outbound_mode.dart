import 'package:flowvy/common/common.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/providers/config.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OutboundMode extends StatelessWidget {
  const OutboundMode({super.key});

  @override
  Widget build(BuildContext context) {
    final height = getWidgetHeight(2);
    return SizedBox(
      height: height,
      child: Consumer(
        builder: (_, ref, __) {
          final mode = ref.watch(
            patchClashConfigProvider.select(
              (state) => state.mode,
            ),
          );
          return Theme(
              data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent),
              child: CommonCard(
                onPressed: () {},
                info: Info(
                  label: appLocalizations.outboundMode,
                  iconData: Icons.call_split_rounded,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final item in Mode.values)
                        Flexible(
                          fit: FlexFit.tight,
                          child: ListItem.radio(
                            dense: true,
                            horizontalTitleGap: 4,
                            padding: EdgeInsets.only(
                              left: 12.ap,
                              right: 16.ap,
                            ),
                            delegate: RadioDelegate(
                              value: item,
                              groupValue: mode,
                              onChanged: (value) async {
                                if (value == null) {
                                  return;
                                }
                                globalState.appController.changeMode(value);
                              },
                            ),
                            title: Text(
                              Intl.message(item.name),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }
}

class OutboundModeV2 extends StatelessWidget {
  const OutboundModeV2({super.key});

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    final height = getWidgetHeight(0.72);

    return SizedBox(
      height: height,
      child: Consumer(
        builder: (_, ref, __) {
          final mode = ref.watch(
            patchClashConfigProvider.select(
              (state) => state.mode,
            ),
          );

          return CommonTabBar<Mode>(
              children: Map.fromEntries(
                Mode.values.map(
                  (item) => MapEntry(
                    item,
                    Container(
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(),
                      height: height - 16,
                      child: Text(
                        Intl.message(item.name),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: item == mode 
                                  ? customTheme.switcherSelectedText 
                                  : customTheme.switcherUnselectedText,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(4),
              groupValue: mode,
              onValueChanged: (value) {
                if (value == null) return;
                globalState.appController.changeMode(value);
              },
              thumbColor: customTheme.switcherThumbBackground!,
            );
        },
      ),
    );
  }
}