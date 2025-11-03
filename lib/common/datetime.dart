// datetime.dart

import 'package:flowvy/common/app_localizations.dart';

extension IntPluralExtension on int {
  /// Returns correct plural form for number (one, two, five).
  String plural(String one, String two, String five) {
    int n = abs();
    n %= 100;
    if (n >= 11 && n <= 19) {
      return five;
    }
    n %= 10;
    if (n == 1) {
      return one;
    }
    if (n >= 2 && n <= 4) {
      return two;
    }
    return five;
  }
}


extension DateTimeExtension on DateTime {
  bool get isBeforeNow {
    return isBefore(DateTime.now());
  }

  bool isBeforeSecure(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    return true;
  }

  String get ddMMyyyy {
    String pad(int n) => n.toString().padLeft(2, '0');
    return "${pad(day)}.${pad(month)}.$year";
  }

  String get lastUpdateTimeDesc {
    final difference = DateTime.now().difference(this);
    final ago = appLocalizations.ago.trim();

    if (difference.inMinutes.abs() < 1) {
      return appLocalizations.just;
    }
    if (difference.inHours.abs() < 1) {
      final minutes = difference.inMinutes;
      final unit = minutes.plural(appLocalizations.minuteOne,
          appLocalizations.minuteTwo, appLocalizations.minutes);
      return "$minutes $unit $ago";
    }
    if (difference.inDays.abs() < 1) {
      final hours = difference.inHours;
      final unit = hours.plural(appLocalizations.hourOne,
          appLocalizations.hourTwo, appLocalizations.hours);
      return "$hours $unit $ago";
    }
    if (difference.inDays.abs() < 30) {
      final days = difference.inDays;
      final unit = days.plural(
          appLocalizations.dayOne, appLocalizations.dayTwo, appLocalizations.days);
      return "$days $unit $ago";
    }
    if (difference.inDays.abs() < 365) {
      final months = (difference.inDays.abs() / 30).floor();
      final unit = months.plural(appLocalizations.monthOne,
          appLocalizations.monthTwo, appLocalizations.months);
      return "$months $unit $ago";
    }

    final years = (difference.inDays.abs() / 365).floor();
    final unit = years.plural(appLocalizations.yearOne,
        appLocalizations.yearTwo, appLocalizations.years);
    return "$years $unit $ago";
  }

  String get show {
    return toIso8601String().substring(0, 10);
  }
}