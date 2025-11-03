import 'dart:ui';
import 'dart:async';
import 'dart:math';

import 'package:flowvy/common/common.dart';
import 'package:flowvy/common/custom_theme.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:flowvy/models/models.dart';
import 'package:flowvy/providers/providers.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/views/profiles/edit_profile.dart';
import 'package:flowvy/views/profiles/override_profile.dart';
import 'package:flowvy/views/profiles/scripts.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_profile.dart';

class TimeAgoWidget extends StatefulWidget {
  final DateTime date;

  const TimeAgoWidget({super.key, required this.date});

  @override
  State<TimeAgoWidget> createState() => _TimeAgoWidgetState();
}

class _TimeAgoWidgetState extends State<TimeAgoWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconTheme = Theme.of(context).iconTheme;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.sync_rounded, size: 16, color: iconTheme.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: textTheme.bodySmall?.copyWith(color: subtitleColor),
              children: [
                TextSpan(text: '${appLocalizations.updated} '),
                TextSpan(
                  text: widget.date.lastUpdateTimeDesc,
                  style: TextStyle(fontWeight: FontWeight.w500, color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


String _formatBytes(BigInt bytes, int decimals) {
  if (bytes <= BigInt.zero) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (bytes.bitLength - 1) ~/ 10;
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes.toDouble() / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> with PageMixin {
  Function? applyConfigDebounce;

  _handleShowAddExtendPage() {
    showExtend(
      globalState.navigatorKey.currentState!.context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: AddProfileView(
            context: globalState.navigatorKey.currentState!.context,
          ),
          title: appLocalizations.addProfileTitle,
        );
      },
    );
  }

  _updateProfiles() async {
    final profiles = globalState.config.profiles;
    final messages = [];
    final updateProfiles = profiles.map<Future>(
      (profile) async {
        if (profile.type == ProfileType.file) return;
        globalState.appController.setProfile(
          profile.copyWith(isUpdating: true),
        );
        try {
          await globalState.appController.updateProfile(profile, isManualUpdate: true);
        } catch (e) {
          messages.add("${profile.label ?? profile.id}: $e \n");
          globalState.appController.setProfile(
            profile.copyWith(
              isUpdating: false,
            ),
          );
        }
      },
    );
    final titleMedium = context.textTheme.titleMedium;
    await Future.wait(updateProfiles);
    if (messages.isNotEmpty) {
      globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(
          children: [
            for (final message in messages)
              TextSpan(text: message, style: titleMedium)
          ],
        ),
      );
    }
  }

  @override
  List<Widget> get actions => [
        IconButton(
          onPressed: () {
            _updateProfiles();
          },
          icon: const Icon(Icons.sync_rounded),
          tooltip: appLocalizations.update,
        ),
        IconButton(
          onPressed: () {
            showExtend(
              context,
              builder: (_, type) {
                return ScriptsView();
              },
            );
          },
          icon: Consumer(
            builder: (context, ref, __) {
              final isScriptMode = ref.watch(
                  scriptStateProvider.select((state) => state.realId != null));
              return Icon(
                Icons.functions_rounded,
                color: isScriptMode ? context.colorScheme.primary : null,
              );
            },
          ),
          tooltip: appLocalizations.script,
        ),
        IconButton(
          onPressed: () {
            final profiles = globalState.config.profiles;
            showSheet(
              context: context,
              builder: (_, type) {
                return ReorderableProfilesSheet(
                  type: type,
                  profiles: profiles,
                );
              },
            );
          },
          icon: const Icon(Icons.sort_rounded),
          tooltip: appLocalizations.sort,
          iconSize: 26,
        ),
      ];

  @override
  Widget? get floatingActionButton {

    return FloatingActionButton(
      heroTag: null,
      onPressed: _handleShowAddExtendPage,
      child: const Icon(Icons.add_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        ref.listenManual(
          isCurrentPageProvider(PageLabel.profiles),
          (prev, next) {
            if (prev != next && next == true) {
              initPageState();
            }
          },
          fireImmediately: true,
        );
        final profilesSelectorState = ref.watch(profilesSelectorStateProvider);
        if (profilesSelectorState.profiles.isEmpty) {
          return NullStatus(
            label: appLocalizations.nullProfileDesc,
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 88,
            ),
            child: Grid(
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              crossAxisCount: profilesSelectorState.columns,
              children: [
                for (int i = 0; i < profilesSelectorState.profiles.length; i++)
                  GridItem(
                    child: ProfileItem(
                      key: Key(profilesSelectorState.profiles[i].id),
                      profile: profilesSelectorState.profiles[i],
                      groupValue: profilesSelectorState.currentProfileId,
                      onChanged: (profileId) {
                        ref.read(currentProfileIdProvider.notifier).value =
                            profileId;
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileItem extends StatelessWidget {
  final Profile profile;
  final String? groupValue;
  final void Function(String? value) onChanged;

  const ProfileItem({
    super.key,
    required this.profile,
    required this.groupValue,
    required this.onChanged,
  });

  _handleDeleteProfile(BuildContext context) async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip,
      ),
    );
    if (res != true) {
      return;
    }
    await globalState.appController.deleteProfile(profile.id);
  }

  Future updateProfile() async {
    final appController = globalState.appController;
    if (profile.type == ProfileType.file) return;
    await globalState.safeRun(silence: false, () async {
      try {
        appController.setProfile(
          profile.copyWith(
            isUpdating: true,
          ),
        );
        await appController.updateProfile(profile, isManualUpdate: true);
      } catch (e) {
        appController.setProfile(
          profile.copyWith(
            isUpdating: false,
          ),
        );
        rethrow;
      }
    });
  }

  _handleShowEditExtendPage(BuildContext context) {
    showExtend(
      context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: EditProfileView(
            profile: profile,
            context: context,
          ),
          title: appLocalizations.editProfileTitle,
        );
      },
    );
  }

  _handlePushGenProfilePage(BuildContext context, String id) {
    final overrideProfileView = OverrideProfileView(
      profileId: id,
    );
    BaseNavigator.modal(
      context,
      overrideProfileView,
    );
  }

  _handleExportFile(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    final res = await commonScaffoldState?.loadingRun<bool>(() async {
      final file = await profile.getFile();
      // Добавляем расширение .yaml к имени файла
      final fileName = '${profile.label ?? profile.id}.yaml';
      final value = await picker.saveFile(
        fileName,
        file.readAsBytesSync(),
      );
      if (value == null) return false;
      return true;
    },
      title: appLocalizations.tip,
    );
    if (res == true && context.mounted) {
      context.showNotifier(appLocalizations.exportSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconTheme = Theme.of(context).iconTheme;

    final subscriptionInfo = profile.subscriptionInfo;
    final isUrlProfile =
        profile.type == ProfileType.url && subscriptionInfo != null;
    final isSelected = profile.id == groupValue;
    final subtitleStyle = textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    final cardContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  profile.label ?? profile.id,
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 24,
                width: 24,
                child: FadeThroughBox(
                  child: profile.isUpdating
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : CommonPopupBox(
                          popup: CommonPopupMenu(
                            items: [
                              PopupMenuItemData(
                                icon: Icons.edit_rounded,
                                label: appLocalizations.edit,
                                onPressed: () =>
                                    _handleShowEditExtendPage(context),
                              ),
                              if (profile.type == ProfileType.url)
                                PopupMenuItemData(
                                  icon: Icons.sync_alt_rounded,
                                  label: appLocalizations.sync,
                                  onPressed: updateProfile,
                                ),
                              if (profile.supportUrl != null &&
                                  profile.supportUrl!.isNotEmpty)
                                PopupMenuItemData(
                                  icon: isTelegramUrl(profile.supportUrl!)
                                      ? Icons.telegram_rounded
                                      : Icons.support_agent_rounded,
                                  label: appLocalizations.support,
                                  onPressed: () {
                                    globalState.openUrl(profile.supportUrl!);
                                  },
                                ),
                              PopupMenuItemData(
                                icon: Icons.extension_rounded,
                                label: appLocalizations.override,
                                onPressed: () => _handlePushGenProfilePage(
                                    context, profile.id),
                              ),
                              PopupMenuItemData(
                                icon: Icons.file_copy_rounded,
                                label: appLocalizations.exportFile,
                                onPressed: () => _handleExportFile(context),
                              ),
                              PopupMenuItemData(
                                icon: Icons.delete_rounded,
                                label: appLocalizations.delete,
                                onPressed: () => _handleDeleteProfile(context),
                              ),
                            ],
                          ),
                          targetBuilder: (open) {
                            return IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: open,
                              icon: Icon(Icons.more_vert_rounded, size: 20, color: iconTheme.color),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isUrlProfile)
            Builder(builder: (context) {
              final BigInt totalTraffic =
                  BigInt.from(subscriptionInfo.total);
              final BigInt download =
                  BigInt.from(subscriptionInfo.download);
              final BigInt upload =
                  BigInt.from(subscriptionInfo.upload);
              final BigInt usedTraffic = download + upload;

              final isUnlimitedTraffic = totalTraffic <= BigInt.zero;

              double progress = 0.0;
              if (!isUnlimitedTraffic) {
                progress = usedTraffic.toDouble() / totalTraffic.toDouble();
                if (progress.isNaN) progress = 0.0;
                if (progress < 0) progress = 0.0;
                if (progress > 1) progress = 1.0;
              }

              final hasExpireDate = subscriptionInfo.expire > 0;
              final expireDate = hasExpireDate
                  ? DateTime.fromMillisecondsSinceEpoch(subscriptionInfo.expire * 1000)
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.data_usage_rounded, size: 16, color: iconTheme.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isUnlimitedTraffic
                            ? Text(
                                appLocalizations.trafficUnlimited,
                                style: subtitleStyle?.copyWith(fontWeight: FontWeight.w500),
                              )
                            : Text.rich(
                                TextSpan(
                                  style: subtitleStyle,
                                  children: [
                                    TextSpan(text: '${appLocalizations.traffic} '),
                                    TextSpan(
                                      text:
                                          '${_formatBytes(usedTraffic, 2)} / ${_formatBytes(totalTraffic, 2)}',
                                      style:
                                          TextStyle(fontWeight: FontWeight.w500, color: subtitleStyle?.color),
                                    ),
                                  ],
                                ),
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
                          color: colorScheme.primary,
                          backgroundColor: customTheme.profileCardProgressTrack,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 16, color: iconTheme.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: hasExpireDate && expireDate != null
                            ? Text.rich(
                                TextSpan(
                                  style: subtitleStyle,
                                  children: [
                                    TextSpan(
                                        text:
                                            '${appLocalizations.subscriptionExpires} '),
                                    TextSpan(
                                      text: expireDate.ddMMyyyy,
                                      style:
                                          TextStyle(fontWeight: FontWeight.w500, color: subtitleStyle?.color),
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
              );
            }),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (profile.lastUpdateDate != null)
            TimeAgoWidget(date: profile.lastUpdateDate!),
        ],
      ),
    );

    return OutlinedButton(
      onPressed: () => onChanged(profile.id),
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (isSelected) return customTheme.profileCardBackgroundSelected!;
          if (states.contains(WidgetState.hovered)) return customTheme.profileCardBackgroundHover!;
          return customTheme.profileCardBackground!;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
          if (isSelected) return BorderSide(color: customTheme.profileCardBorderSelected!, width: 1);
          if (states.contains(WidgetState.hovered)) return BorderSide(color: customTheme.profileCardBorderHover!, width: 1);
          return BorderSide(color: customTheme.profileCardBorder!, width: 1);
        }),
      ),
      child: cardContent,
    );
  }
}

class ReorderableProfilesSheet extends StatefulWidget {
  final List<Profile> profiles;
  final SheetType type;

  const ReorderableProfilesSheet({
    super.key,
    required this.profiles,
    required this.type,
  });

  @override
  State<ReorderableProfilesSheet> createState() =>
      _ReorderableProfilesSheetState();
}

class _ReorderableProfilesSheetState extends State<ReorderableProfilesSheet> {
  late List<Profile> profiles;

  @override
  void initState() {
    super.initState();
    profiles = List.from(widget.profiles);
  }

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final profile = profiles[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (_, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = lerpDouble(1, 1.02, animValue)!;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        key: Key(profile.id),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: CommonCard(
          type: CommonCardType.filled,
          child: ListTile(
            contentPadding: const EdgeInsets.only(
              right: 44,
              left: 16,
            ),
            title: Text(profile.label ?? profile.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetScaffold(
      type: widget.type,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            globalState.appController.setProfiles(profiles);
          },
          icon: const Icon(
            Icons.save_rounded,
          ),
        )
      ],
      body: Padding(
        padding: const EdgeInsets.only(
          bottom: 32,
          top: 16,
        ),
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          proxyDecorator: proxyDecorator,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final profile = profiles.removeAt(oldIndex);
              profiles.insert(newIndex, profile);
            });
          },
          itemBuilder: (_, index) {
            final profile = profiles[index];
            return Container(
              key: Key(profile.id),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CommonCard(
                type: CommonCardType.filled,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(
                    right: 16,
                    left: 16,
                  ),
                  title: Text(profile.label ?? profile.id),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ),
            );
          },
          itemCount: profiles.length,
        ),
      ),
      title: appLocalizations.profilesSort,
    );
  }
}