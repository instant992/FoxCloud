import 'package:flowvy/common/common.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogLevelItem extends ConsumerWidget {
  const LogLevelItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final logLevel =
        ref.watch(patchClashConfigProvider.select((state) => state.logLevel));
    return ListItem<LogLevel>.options(
      leading: const Icon(Icons.info_rounded),
      title: Text(appLocalizations.logLevel),
      subtitle: Text(logLevel.name),
      delegate: OptionsDelegate<LogLevel>(
        title: appLocalizations.logLevel,
        options: LogLevel.values,
        onChanged: (LogLevel? value) async {
          if (value == null) {
            return;
          }

          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  logLevel: value,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
        textBuilder: (logLevel) => logLevel.name,
        value: logLevel,
      ),
    );
  }
}

class KeepAliveIntervalItem extends ConsumerWidget {
  const KeepAliveIntervalItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final keepAliveInterval = ref.watch(
        patchClashConfigProvider.select((state) => state.keepAliveInterval));
    return ListItem.input(
      leading: const Icon(Icons.timer_rounded),
      title: Text(appLocalizations.keepAliveIntervalDesc),
      subtitle: Text("$keepAliveInterval ${appLocalizations.seconds}"),
      delegate: InputDelegate(
        title: appLocalizations.keepAliveIntervalDesc,
        suffixText: appLocalizations.seconds,
        resetValue: "$defaultKeepAliveInterval",
        value: "$keepAliveInterval",
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.interval);
          }
          final intValue = int.tryParse(value);
          if (intValue == null) {
            return appLocalizations.numberTip(appLocalizations.interval);
          }
          return null;
        },
        onChanged: (String? value) async {
          if (value == null) {
            return;
          }

          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          final intValue = int.parse(value);
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  keepAliveInterval: intValue,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class TestUrlItem extends ConsumerWidget {
  const TestUrlItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final testUrl =
        ref.watch(appSettingProvider.select((state) => state.testUrl));
    return ListItem.input(
      leading: const Icon(Icons.timeline_rounded),
      title: Text(appLocalizations.testUrl),
      subtitle: Text(testUrl),
      delegate: InputDelegate(
        resetValue: defaultTestUrl,
        title: appLocalizations.testUrl,
        value: testUrl,
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.testUrl);
          }
          if (!value.isUrl) {
            return appLocalizations.urlTip(appLocalizations.testUrl);
          }
          return null;
        },
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          ref.read(appSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  testUrl: value,
                ),
              );
        },
      ),
    );
  }
}

class PortItem extends ConsumerWidget {
  const PortItem({super.key});

  handleShowPortDialog() async {
    await globalState.showCommonDialog(
      child: _PortDialog(),
    );
    // inputDelegate.onChanged(value);
  }

  @override
  Widget build(BuildContext context, ref) {
    final mixedPort =
        ref.watch(patchClashConfigProvider.select((state) => state.mixedPort));
    return ListItem(
      leading: const Icon(Icons.adjust_rounded),
      title: Text(appLocalizations.port),
      subtitle: Text("$mixedPort"),
      onTap: () {
        handleShowPortDialog();
      },
      // delegate: InputDelegate(
      //   title: appLocalizations.port,
      //   value: "$mixedPort",
      //   validator: (String? value) {
      //     if (value == null || value.isEmpty) {
      //       return appLocalizations.emptyTip(appLocalizations.proxyPort);
      //     }
      //     final mixedPort = int.tryParse(value);
      //     if (mixedPort == null) {
      //       return appLocalizations.numberTip(appLocalizations.proxyPort);
      //     }
      //     if (mixedPort < 1024 || mixedPort > 49151) {
      //       return appLocalizations.proxyPortTip;
      //     }
      //     return null;
      //   },
      //   onChanged: (String? value) {
      //     if (value == null) {
      //       return;
      //     }
      //     final mixedPort = int.parse(value);
      //     ref.read(patchClashConfigProvider.notifier).updateState(
      //           (state) => state.copyWith(
      //             mixedPort: mixedPort,
      //           ),
      //         );
      //   },
      //   resetValue: "$defaultMixedPort",
      // ),
    );
  }
}

class HostsItem extends StatelessWidget {
  const HostsItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list_rounded),
      title: const Text("Hosts"),
      subtitle: Text(appLocalizations.hostsDesc),
      delegate: OpenDelegate(
        blur: false,
        title: "Hosts",
        widget: Consumer(
          builder: (_, ref, __) {
            final hosts = ref
                .watch(patchClashConfigProvider.select((state) => state.hosts));
            return MapInputPage(
              title: "Hosts",
              map: hosts,
              titleBuilder: (item) => Text(item.key),
              subtitleBuilder: (item) => Text(item.value),
              onChange: (value) async {
                // Check profile auto-update status
                final currentProfile = ref.read(currentProfileProvider);
                if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
                  final res = await globalState.showMessage(
                    title: appLocalizations.tip,
                    message: TextSpan(
                      text: appLocalizations.profileHasUpdate,
                    ),
                  );
                  if (res == true) {
                    // Disable auto-update
                    if (currentProfile != null) {
                      final appController = globalState.appController;
                      appController.setProfile(
                        currentProfile.copyWith(autoUpdate: false),
                      );
                      appController.savePreferencesDebounce();
                    }
                  }
                }

                // Setting is always applied
                ref.read(patchClashConfigProvider.notifier).updateState(
                      (state) => state.copyWith(
                        hosts: value,
                      ),
                    );

                // Save current config to profile
                final updatedProfile = ref.read(currentProfileProvider);
                if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
                  final currentConfig = ref.read(patchClashConfigProvider);
                  await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class Ipv6Item extends ConsumerWidget {
  const Ipv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 =
        ref.watch(patchClashConfigProvider.select((state) => state.ipv6));
    return ListItem.switchItem(
      leading: const Icon(Icons.water_rounded),
      title: const Text("IPv6"),
      subtitle: Text(appLocalizations.ipv6Desc),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  ipv6: value,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class AllowLanItem extends ConsumerWidget {
  const AllowLanItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final allowLan =
        ref.watch(patchClashConfigProvider.select((state) => state.allowLan));
    return ListItem.switchItem(
      leading: const Icon(Icons.device_hub_rounded),
      title: Text(appLocalizations.allowLan),
      subtitle: Text(appLocalizations.allowLanDesc),
      delegate: SwitchDelegate(
        value: allowLan,
        onChanged: (bool value) async {
          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  allowLan: value,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class UnifiedDelayItem extends ConsumerWidget {
  const UnifiedDelayItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final unifiedDelay = ref
        .watch(patchClashConfigProvider.select((state) => state.unifiedDelay));

    return ListItem.switchItem(
      leading: const Icon(Icons.compress_rounded),
      title: Text(appLocalizations.unifiedDelay),
      subtitle: Text(appLocalizations.unifiedDelayDesc),
      delegate: SwitchDelegate(
        value: unifiedDelay,
        onChanged: (bool value) async {
          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  unifiedDelay: value,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class FindProcessItem extends ConsumerWidget {
  const FindProcessItem({super.key});

  String _getFindProcessModeText(FindProcessMode mode) {
    return switch (mode) {
      FindProcessMode.off => appLocalizations.off,
      FindProcessMode.strict => "Strict",
      FindProcessMode.always => "Always",
    };
  }

  @override
  Widget build(BuildContext context, ref) {
    final findProcessMode = ref.watch(patchClashConfigProvider
        .select((state) => state.findProcessMode));

    return ListItem<FindProcessMode>.options(
      leading: const Icon(Icons.polymer_rounded),
      title: Text(appLocalizations.findProcessMode),
      subtitle: Text(_getFindProcessModeText(findProcessMode)),
      delegate: OptionsDelegate<FindProcessMode>(
        title: appLocalizations.findProcessMode,
        options: FindProcessMode.values,
        value: findProcessMode,
        textBuilder: (mode) => _getFindProcessModeText(mode),
        onChanged: (FindProcessMode? value) async {
          if (value == null) {
            return;
          }

          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  findProcessMode: value,
                ),
              );
        },
      ),
    );
  }
}

class TcpConcurrentItem extends ConsumerWidget {
  const TcpConcurrentItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final tcpConcurrent = ref
        .watch(patchClashConfigProvider.select((state) => state.tcpConcurrent));
    return ListItem.switchItem(
      leading: const Icon(Icons.double_arrow_rounded),
      title: Text(appLocalizations.tcpConcurrent),
      subtitle: Text(appLocalizations.tcpConcurrentDesc),
      delegate: SwitchDelegate(
        value: tcpConcurrent,
        onChanged: (value) async {
          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  tcpConcurrent: value,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class GeodataLoaderItem extends ConsumerWidget {
  const GeodataLoaderItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isMemconservative = ref.watch(patchClashConfigProvider.select(
        (state) => state.geodataLoader == GeodataLoader.memconservative));
    return ListItem.switchItem(
      leading: const Icon(Icons.memory_rounded),
      title: Text(appLocalizations.geodataLoader),
      subtitle: Text(appLocalizations.geodataLoaderDesc),
      delegate: SwitchDelegate(
        value: isMemconservative,
        onChanged: (bool value) async {
          // Check profile auto-update status
          final currentProfile = ref.read(currentProfileProvider);
          if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
            final res = await globalState.showMessage(
              title: appLocalizations.tip,
              message: TextSpan(
                text: appLocalizations.profileHasUpdate,
              ),
            );
            if (res == true) {
              // Disable auto-update
              if (currentProfile != null) {
                final appController = globalState.appController;
                appController.setProfile(
                  currentProfile.copyWith(autoUpdate: false),
                );
                appController.savePreferencesDebounce();
              }
            }
          }

          // Setting is always applied
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  geodataLoader: value
                      ? GeodataLoader.memconservative
                      : GeodataLoader.standard,
                ),
              );

          // Save current config to profile
          final updatedProfile = ref.read(currentProfileProvider);
          if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
            final currentConfig = ref.read(patchClashConfigProvider);
            await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
          }
        },
      ),
    );
  }
}

class ExternalControllerItem extends ConsumerWidget {
  const ExternalControllerItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final hasExternalController = ref.watch(patchClashConfigProvider.select(
        (state) => state.externalController == ExternalControllerStatus.open));
    return ListItem.switchItem(
      leading: const Icon(Icons.api_rounded),
      title: Text(appLocalizations.externalController),
      subtitle: Text(appLocalizations.externalControllerDesc),
      delegate: SwitchDelegate(
        value: hasExternalController,
        onChanged: (bool value) async {
          ref.read(patchClashConfigProvider.notifier).updateState(
                (state) => state.copyWith(
                  externalController: value
                      ? ExternalControllerStatus.open
                      : ExternalControllerStatus.close,
                ),
              );
        },
      ),
    );
  }
}

final generalItems = <Widget>[
  LogLevelItem(),
  if (system.isDesktop) KeepAliveIntervalItem(),
  TestUrlItem(),
  PortItem(),
  HostsItem(),
  Ipv6Item(),
  AllowLanItem(),
  UnifiedDelayItem(),
  FindProcessItem(),
  TcpConcurrentItem(),
  GeodataLoaderItem(),
  ExternalControllerItem(),
]
    .separated(
      const Divider(
        height: 0,
      ),
    )
    .toList();

class _PortDialog extends ConsumerStatefulWidget {
  const _PortDialog();

  @override
  ConsumerState<_PortDialog> createState() => _PortDialogState();
}

class _PortDialogState extends ConsumerState<_PortDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isMore = false;

  late TextEditingController _mixedPortController;
  late TextEditingController _portController;
  late TextEditingController _socksPortController;
  late TextEditingController _redirPortController;
  late TextEditingController _tProxyPortController;

  @override
  void initState() {
    super.initState();
    final vm5 = ref.read(patchClashConfigProvider.select((state) {
      return VM5(
        a: state.mixedPort,
        b: state.port,
        c: state.socksPort,
        d: state.redirPort,
        e: state.tproxyPort,
      );
    }));
    _mixedPortController = TextEditingController(
      text: vm5.a.toString(),
    );
    _portController = TextEditingController(
      text: vm5.b.toString(),
    );
    _socksPortController = TextEditingController(
      text: vm5.c.toString(),
    );
    _redirPortController = TextEditingController(
      text: vm5.d.toString(),
    );
    _tProxyPortController = TextEditingController(
      text: vm5.e.toString(),
    );
  }

  _handleReset() async {
    final res = await globalState.showMessage(
      message: TextSpan(
        text: appLocalizations.resetTip,
      ),
    );
    if (res != true) {
      return;
    }
    ref.read(patchClashConfigProvider.notifier).updateState(
          (state) => state.copyWith(
            mixedPort: 7890,
            port: 0,
            socksPort: 0,
            redirPort: 0,
            tproxyPort: 0,
          ),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _handleUpdate() async {
    if (_formKey.currentState?.validate() == false) return;

    // Check profile auto-update status
    final currentProfile = ref.read(currentProfileProvider);
    if (currentProfile?.autoUpdate == true && currentProfile?.type == ProfileType.url) {
      final res = await globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(
          text: appLocalizations.profileHasUpdate,
        ),
      );
      if (res == true) {
        // Disable auto-update
        if (currentProfile != null) {
          final appController = globalState.appController;
          appController.setProfile(
            currentProfile.copyWith(autoUpdate: false),
          );
          appController.savePreferencesDebounce();
        }
      }
    }

    // Setting is always applied
    ref.read(patchClashConfigProvider.notifier).updateState(
          (state) => state.copyWith(
            mixedPort: int.parse(_mixedPortController.text),
            port: int.parse(_portController.text),
            socksPort: int.parse(_socksPortController.text),
            redirPort: int.parse(_redirPortController.text),
            tproxyPort: int.parse(_tProxyPortController.text),
          ),
        );

    // Save current config to profile
    final updatedProfile = ref.read(currentProfileProvider);
    if (updatedProfile != null && updatedProfile.type == ProfileType.url) {
      final currentConfig = ref.read(patchClashConfigProvider);
      await globalState.saveCurrentConfigToProfile(updatedProfile, currentConfig);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _handleMore() {
    setState(() {
      _isMore = !_isMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.port,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              onPressed: _handleMore,
              icon: CommonExpandIcon(
                expand: _isMore,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _handleReset,
                  child: Text(appLocalizations.reset),
                ),
                const SizedBox(
                  width: 4,
                ),
                TextButton(
                  onPressed: _handleUpdate,
                  child: Text(appLocalizations.submit),
                )
              ],
            )
          ],
        )
      ],
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.only(top: 8),
          child: AnimatedSize(
            duration: midDuration,
            curve: Curves.easeOutQuad,
            alignment: Alignment.topCenter,
            child: Column(
              spacing: 24,
              children: [
                TextFormField(
                  keyboardType: TextInputType.url,
                  maxLines: 1,
                  minLines: 1,
                  controller: _mixedPortController,
                  onFieldSubmitted: (_) {
                    _handleUpdate();
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: appLocalizations.mixedPort,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations
                          .emptyTip(appLocalizations.mixedPort);
                    }
                    final port = int.tryParse(value);
                    if (port == null) {
                      return appLocalizations
                          .numberTip(appLocalizations.mixedPort);
                    }
                    if (port < 1024 || port > 49151) {
                      return appLocalizations
                          .portTip(appLocalizations.mixedPort);
                    }
                    final ports = [
                      _portController.text,
                      _socksPortController.text,
                      _tProxyPortController.text,
                      _redirPortController.text
                    ].map((item) => item.trim());
                    if (ports.contains(value.trim())) {
                      return appLocalizations.portConflictTip;
                    }
                    return null;
                  },
                ),
                if (_isMore) ...[
                  TextFormField(
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                    minLines: 1,
                    controller: _portController,
                    onFieldSubmitted: (_) {
                      _handleUpdate();
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocalizations.port,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations.emptyTip(appLocalizations.port);
                      }
                      final port = int.tryParse(value);
                      if (port == null) {
                        return appLocalizations.numberTip(
                          appLocalizations.port,
                        );
                      }
                      if (port == 0) {
                        return null;
                      }
                      if (port < 1024 || port > 49151) {
                        return appLocalizations.portTip(appLocalizations.port);
                      }
                      final ports = [
                        _mixedPortController.text,
                        _socksPortController.text,
                        _tProxyPortController.text,
                        _redirPortController.text
                      ].map((item) => item.trim());
                      if (ports.contains(value.trim())) {
                        return appLocalizations.portConflictTip;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                    minLines: 1,
                    controller: _socksPortController,
                    onFieldSubmitted: (_) {
                      _handleUpdate();
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocalizations.socksPort,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations
                            .emptyTip(appLocalizations.socksPort);
                      }
                      final port = int.tryParse(value);
                      if (port == null) {
                        return appLocalizations
                            .numberTip(appLocalizations.socksPort);
                      }
                      if (port == 0) {
                        return null;
                      }
                      if (port < 1024 || port > 49151) {
                        return appLocalizations
                            .portTip(appLocalizations.socksPort);
                      }
                      final ports = [
                        _portController.text,
                        _mixedPortController.text,
                        _tProxyPortController.text,
                        _redirPortController.text
                      ].map((item) => item.trim());
                      if (ports.contains(value.trim())) {
                        return appLocalizations.portConflictTip;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                    minLines: 1,
                    controller: _redirPortController,
                    onFieldSubmitted: (_) {
                      _handleUpdate();
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocalizations.redirPort,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations
                            .emptyTip(appLocalizations.redirPort);
                      }
                      final port = int.tryParse(value);
                      if (port == null) {
                        return appLocalizations
                            .numberTip(appLocalizations.redirPort);
                      }
                      if (port == 0) {
                        return null;
                      }
                      if (port < 1024 || port > 49151) {
                        return appLocalizations
                            .portTip(appLocalizations.redirPort);
                      }
                      final ports = [
                        _portController.text,
                        _socksPortController.text,
                        _tProxyPortController.text,
                        _mixedPortController.text
                      ].map((item) => item.trim());
                      if (ports.contains(value.trim())) {
                        return appLocalizations.portConflictTip;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                    minLines: 1,
                    controller: _tProxyPortController,
                    onFieldSubmitted: (_) {
                      _handleUpdate();
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: appLocalizations.tproxyPort,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations
                            .emptyTip(appLocalizations.tproxyPort);
                      }
                      final port = int.tryParse(value);
                      if (port == null) {
                        return appLocalizations
                            .numberTip(appLocalizations.tproxyPort);
                      }
                      if (port == 0) {
                        return null;
                      }
                      if (port < 1024 || port > 49151) {
                        return appLocalizations.portTip(
                          appLocalizations.tproxyPort,
                        );
                      }
                      final ports = [
                        _portController.text,
                        _socksPortController.text,
                        _mixedPortController.text,
                        _redirPortController.text
                      ].map((item) => item.trim());
                      if (ports.contains(value.trim())) {
                        return appLocalizations.portConflictTip;
                      }

                      return null;
                    },
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
