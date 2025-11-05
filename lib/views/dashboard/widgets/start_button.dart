import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartButton extends ConsumerStatefulWidget {
  final bool isMobileStyle;

  const StartButton({
    super.key,
    this.isMobileStyle = false,
  });

  @override
  ConsumerState<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends ConsumerState<StartButton> {
  bool isStart = false;

  @override
  void initState() {
    super.initState();
    isStart = globalState.appState.runTime != null;

    ref.listenManual(
      runTimeProvider.select((state) => state != null),
      (prev, next) {
        if (next != isStart && mounted) {
          setState(() {
            isStart = next;
          });
        }
      },
      fireImmediately: true,
    );
  }

  void handleSwitchStart() async {
    // Проверка лимита только при попытке ВКЛЮЧИТЬ прокси
    if (!isStart) {
      final profile = ref.read(currentProfileProvider);
      final info = profile?.subscriptionInfo;

      // Если есть информация о подписке и установлен лимит трафика
      if (info != null && info.total > 0) {
        final use = info.upload + info.download;
        final total = info.total;

        // Блокируем подключение если лимит превышен
        if (use >= total) {
          final supportUrl = profile?.supportUrl;
          await globalState.showMessage(
            title: appLocalizations.trafficLimitExceeded,
            message: TextSpan(
              text: appLocalizations.trafficLimitExceededMessage,
            ),
            confirmText: supportUrl != null && supportUrl.isNotEmpty
                ? appLocalizations.contactSupport
                : appLocalizations.confirm,
          ).then((result) {
            // Если есть ссылка на поддержку и пользователь нажал кнопку
            if (result == true && supportUrl != null && supportUrl.isNotEmpty) {
              globalState.openUrl(supportUrl);
            }
          });
          return; // НЕ разрешаем подключение
        }
      }
    }

    setState(() {
      isStart = !isStart;
    });
    debouncer.call(
      FunctionTag.updateStatus,
      () {
        globalState.appController.updateStatus(isStart);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(startButtonSelectorStateProvider);
    final customTheme = Theme.of(context).extension<CustomTheme>()!;

    if (!state.isInit || !state.hasProfile) {
      return const SizedBox.shrink();
    }

    final isMobile = widget.isMobileStyle;

    const buttonIcon = Icons.power_settings_new_rounded;

    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: customTheme.connectButtonForeground,
        );

    final connectText = Text(
      appLocalizations.connect,
      style: textStyle,
      softWrap: false,
      overflow: TextOverflow.clip,
    );

    final timerConsumer = Consumer(
      builder: (_, ref, __) {
        final runTime = ref.watch(runTimeProvider);
        final text = utils.getTimeText(runTime);
        return Text(
          text,
          style: textStyle,
          softWrap: false,
          overflow: TextOverflow.clip,
        );
      },
    );

    final connectTextWidth = isMobile
        ? 0.0
        : globalState.measure.computeTextSize(connectText).width;
    final runTime = ref.watch(runTimeProvider);
    final timerTextString = utils.getTimeText(runTime);
    final timerTextWidth = isMobile
        ? 0.0
        : globalState.measure
            .computeTextSize(
              Text(timerTextString, style: textStyle),
            )
            .width;

    final targetWidth = isStart ? timerTextWidth : connectTextWidth;

    final buttonContent = Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          buttonIcon,
          color: customTheme.connectButtonIcon,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2.5),
          child: isMobile
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isStart ? timerConsumer : connectText,
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: targetWidth,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isStart ? timerConsumer : connectText,
                  ),
                ),
        ),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: handleSwitchStart,
            style: TextButton.styleFrom(
              backgroundColor: customTheme.connectButtonBackground,
              foregroundColor: customTheme.connectButtonForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: buttonContent,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: handleSwitchStart,
      backgroundColor: customTheme.connectButtonBackground,
      label: buttonContent,
    );
  }
}