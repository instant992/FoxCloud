// ignore_for_file: invalid_annotation_target
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flowvy/clash/core.dart';
import 'package:flowvy/common/common.dart';
import 'package:flowvy/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'clash_config.dart';

part 'generated/profile.freezed.dart';
part 'generated/profile.g.dart';

typedef SelectedMap = Map<String, String>;

@freezed
class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    @Default(0) int upload,
    @Default(0) int download,
    @Default(0) int total,
    @Default(0) int expire,
    String? expiryNotificationTitle,
    String? expiryNotificationTitleExpired,
    String? expiryNotificationBody,
    String? renewUrl,
  }) = _SubscriptionInfo;

  factory SubscriptionInfo.fromJson(Map<String, Object?> json) =>
      _$SubscriptionInfoFromJson(json);

  factory SubscriptionInfo.formHString(
    String? info, {
    String? expiryNotificationTitle,
    String? expiryNotificationTitleExpired,
    String? expiryNotificationBody,
    String? renewUrl,
  }) {
    if (info == null) return const SubscriptionInfo();
    final list = info.split(";");
    Map<String, int?> map = {};
    for (final i in list) {
      final keyValue = i.trim().split("=");
      map[keyValue[0]] = int.tryParse(keyValue[1]);
    }
    return SubscriptionInfo(
      upload: map["upload"] ?? 0,
      download: map["download"] ?? 0,
      total: map["total"] ?? 0,
      expire: map["expire"] ?? 0,
      expiryNotificationTitle: expiryNotificationTitle,
      expiryNotificationTitleExpired: expiryNotificationTitleExpired,
      expiryNotificationBody: expiryNotificationBody,
      renewUrl: renewUrl,
    );
  }
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? label,
    String? currentGroupName,
    @Default("") String url,
    DateTime? lastUpdateDate,
    required Duration autoUpdateDuration,
    SubscriptionInfo? subscriptionInfo,
    String? supportUrl,
    int? subscriptionRefillDate,
    @Default(true) bool autoUpdate,
    @Default({}) SelectedMap selectedMap,
    @Default({}) Set<String> unfoldSet,
    @Default(OverrideData()) OverrideData overrideData,
    String? announce,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false)
    bool isUpdating,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);

  factory Profile.normal({
    String? label,
    String url = '',
  }) {
    return Profile(
      label: label,
      url: url,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      autoUpdateDuration: defaultUpdateDuration,
    );
  }
}

@freezed
class OverrideData with _$OverrideData {
  const factory OverrideData({
    @Default(false) bool enable,
    @Default(OverrideRule()) OverrideRule rule,
    ClashConfig? savedConfig,
  }) = _OverrideData;

  factory OverrideData.fromJson(Map<String, Object?> json) =>
      _$OverrideDataFromJson(json);
}

extension OverrideDataExt on OverrideData {
  List<String> get runningRule {
    if (!enable) {
      return [];
    }
    return rule.rules.map((item) => item.value).toList();
  }
}

@freezed
class OverrideRule with _$OverrideRule {
  const factory OverrideRule({
    @Default(OverrideRuleType.added) OverrideRuleType type,
    @Default([]) List<Rule> overrideRules,
    @Default([]) List<Rule> addedRules,
  }) = _OverrideRule;

  factory OverrideRule.fromJson(Map<String, Object?> json) =>
      _$OverrideRuleFromJson(json);
}

extension OverrideRuleExt on OverrideRule {
  List<Rule> get rules => switch (type == OverrideRuleType.override) {
        true => overrideRules,
        false => addedRules,
      };

  OverrideRule updateRules(List<Rule> Function(List<Rule> rules) builder) {
    if (type == OverrideRuleType.added) {
      return copyWith(addedRules: builder(addedRules));
    }
    return copyWith(overrideRules: builder(overrideRules));
  }
}

extension ProfilesExt on List<Profile> {
  Profile? getProfile(String? profileId) {
    final index = indexWhere((profile) => profile.id == profileId);
    return index == -1 ? null : this[index];
  }
}

extension ProfileExtension on Profile {
  ProfileType get type =>
      url.isEmpty == true ? ProfileType.file : ProfileType.url;

  bool get realAutoUpdate => url.isEmpty == true ? false : autoUpdate;

  /// Checks if profile should be automatically updated
  /// Returns true if:
  /// - Profile has autoUpdate enabled
  /// - Profile has URL (not local file)
  /// - Enough time has passed since last update (>= autoUpdateDuration)
  bool shouldAutoUpdate() {
    if (!realAutoUpdate) {
      return false;
    }

    if (lastUpdateDate == null) {
      return true;
    }

    final timeSinceUpdate = DateTime.now().difference(lastUpdateDate!);
    return timeSinceUpdate >= autoUpdateDuration;
  }

  Future<void> checkAndUpdate() async {
    final isExists = await check();
    if (!isExists) {
      if (url.isNotEmpty) {
        await update();
      }
    }
  }

  Future<bool> check() async {
    final profilePath = await appPath.getProfilePath(id);
    return await File(profilePath).exists();
  }

  Future<File> getFile() async {
    final path = await appPath.getProfilePath(id);
    final file = File(path);
    final isExists = await file.exists();
    if (!isExists) {
      await file.create(recursive: true);
    }
    return file;
  }

  Future<int> get profileLastModified async {
    final file = await getFile();
    return (await file.lastModified()).microsecondsSinceEpoch;
  }

  Future<Profile> update() async {
    final response = await request.getFileResponseForUrl(url);

      // 🔒 Проверяем, что ответ действительно от Remnawave
  final headers = response.headers.map;

  if (!headers.containsKey('subscription-userinfo') &&
      !headers.containsKey('profile-title')) {
    throw Exception('Неверный источник подписки.');
  }

  if (!headers.containsKey('support-link') &&
      !headers.containsKey('support-url')) {
    throw Exception('Подписка не принадлежит нашему провайдеру.');
  }

  // ⚠ Remnawave также всегда выдаёт announce-url
  if (!headers.containsKey('announce-url')) {
    throw Exception('Подписка не от Remnawave.');
  }


    final disposition = response.headers.value("content-disposition");
    final userinfo = response.headers.value('subscription-userinfo');
    final updateIntervalHeader =
        response.headers.value('profile-update-interval');
    final profileTitleHeader = response.headers.value('profile-title');
    final supportUrlHeader = response.headers.value('support-url');
    final refillDateHeader = response.headers.value('subscription-refill-date');
    final expiryNotificationTitleHeader = response.headers.value('expiry-notification-title');
    final expiryNotificationTitleExpiredHeader = response.headers.value('expiry-notification-title-expired');
    final expiryNotificationBodyHeader = response.headers.value('expiry-notification-body');
    final renewUrlHeader = response.headers.value('renew-url');

    Duration newUpdateDuration = const Duration(hours: 12);
    if (updateIntervalHeader != null) {
      final hours = int.tryParse(updateIntervalHeader);
      if (hours != null && hours > 0) {
        newUpdateDuration = Duration(hours: hours);
      }
    }

    String? newLabel;
    if (profileTitleHeader != null) {
      if (profileTitleHeader.startsWith('base64:')) {
        try {
          final encoded = profileTitleHeader.substring(7);
          newLabel = utf8.decode(base64.decode(encoded));
        } catch (e) {
          commonPrint.log(appLocalizations.logProfileTitleDecodeError(e.toString()));
        }
      } else {
        newLabel = profileTitleHeader;
      }
    }

    String? announce;
    final announceHeader = response.headers.value('Announce');
    if (announceHeader != null && announceHeader.startsWith('base64:')) {
      final encoded = announceHeader.substring(7);
      try {
        announce = utf8.decode(base64.decode(encoded));
      } catch (e) {
        commonPrint.log(appLocalizations.logAnnounceDecodeError(e.toString()));
      }
    }

    int? newRefillDate;
    if (refillDateHeader != null) {
      newRefillDate = int.tryParse(refillDateHeader);
    }

    String? decodedExpiryTitle;
    if (expiryNotificationTitleHeader != null && expiryNotificationTitleHeader.startsWith('base64:')) {
      final encoded = expiryNotificationTitleHeader.substring(7);
      try {
        decodedExpiryTitle = utf8.decode(base64.decode(encoded));
      } catch (e) {
        commonPrint.log('Failed to decode expiry notification title: $e');
      }
    }

    String? decodedExpiryTitleExpired;
    if (expiryNotificationTitleExpiredHeader != null && expiryNotificationTitleExpiredHeader.startsWith('base64:')) {
      final encoded = expiryNotificationTitleExpiredHeader.substring(7);
      try {
        decodedExpiryTitleExpired = utf8.decode(base64.decode(encoded));
      } catch (e) {
        commonPrint.log('Failed to decode expiry notification title (expired): $e');
      }
    }

    String? decodedExpiryBody;
    if (expiryNotificationBodyHeader != null && expiryNotificationBodyHeader.startsWith('base64:')) {
      final encoded = expiryNotificationBodyHeader.substring(7);
      try {
        decodedExpiryBody = utf8.decode(base64.decode(encoded));
      } catch (e) {
        commonPrint.log('Failed to decode expiry notification body: $e');
      }
    }

    String? decodedRenewUrl;
    if (renewUrlHeader != null && renewUrlHeader.startsWith('base64:')) {
      final encoded = renewUrlHeader.substring(7);
      try {
        decodedRenewUrl = utf8.decode(base64.decode(encoded));
      } catch (e) {
        commonPrint.log('Failed to decode renew URL: $e');
      }
    }

    return await copyWith(
      label: newLabel ?? utils.getFileNameForDisposition(disposition) ?? label ?? id,
      subscriptionInfo: SubscriptionInfo.formHString(
        userinfo,
        expiryNotificationTitle: decodedExpiryTitle,
        expiryNotificationTitleExpired: decodedExpiryTitleExpired,
        expiryNotificationBody: decodedExpiryBody,
        renewUrl: decodedRenewUrl,
      ),
      announce: announce,
      autoUpdateDuration: newUpdateDuration,
      supportUrl: supportUrlHeader,
      subscriptionRefillDate: newRefillDate,
    ).saveFile(response.data);
  }

  Future<Profile> saveFile(Uint8List bytes) async {
    final message = await clashCore.validateConfig(utf8.decode(bytes));
    if (message.isNotEmpty) {
      throw message;
    }
    final file = await getFile();
    await file.writeAsBytes(bytes);
    return copyWith(lastUpdateDate: DateTime.now());
  }

  Future<Profile> saveFileWithString(String value) async {
    final message = await clashCore.validateConfig(value);
    if (message.isNotEmpty) {
      throw message;
    }
    final file = await getFile();
    await file.writeAsString(value);
    return copyWith(lastUpdateDate: DateTime.now());
  }
}