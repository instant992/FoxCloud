import 'package:flutter/material.dart';

class CustomTheme extends ThemeExtension<CustomTheme> {
  final Color? connectButtonBackground;
  final Color? connectButtonForeground;
  final Color? connectButtonIcon;

  final Color? navRailIndicator;

  final Color? proxyCardBackground;
  final Color? proxyCardBorder;
  final Color? proxyCardBackgroundHover;
  final Color? proxyCardBorderHover;
  final Color? proxyCardBackgroundSelected;
  final Color? proxyCardBorderSelected;
  final Color? proxyPingColor;

  final Color? switcherBackground;
  final Color? switcherBorder;
  final Color? switcherThumbBackground;
  final Color? switcherSelectedText;
  final Color? switcherUnselectedText;

  final Color? profileCardBackground;
  final Color? profileCardBorder;
  final Color? profileCardBackgroundHover;
  final Color? profileCardBorderHover;
  final Color? profileCardBackgroundSelected;
  final Color? profileCardBorderSelected;
  final Color? profileCardProgressTrack;
  final Color? trafficChartDownloadColor;


  const CustomTheme({
    required this.connectButtonBackground,
    required this.connectButtonForeground,
    required this.connectButtonIcon,
    required this.navRailIndicator,
    required this.proxyCardBackground,
    required this.proxyCardBorder,
    required this.proxyCardBackgroundHover,
    required this.proxyCardBorderHover,
    required this.proxyCardBackgroundSelected,
    required this.proxyCardBorderSelected,
    required this.proxyPingColor,
    required this.switcherBackground,
    required this.switcherBorder,
    required this.switcherThumbBackground,
    required this.switcherSelectedText,
    required this.switcherUnselectedText,
    required this.profileCardBackground,
    required this.profileCardBorder,
    required this.profileCardBackgroundHover,
    required this.profileCardBorderHover,
    required this.profileCardBackgroundSelected,
    required this.profileCardBorderSelected,
    required this.profileCardProgressTrack,
    required this.trafficChartDownloadColor,
  });

  @override
  ThemeExtension<CustomTheme> lerp(
    covariant ThemeExtension<CustomTheme>? other,
    double t,
  ) {
    if (other is! CustomTheme) {
      return this;
    }
    return CustomTheme(
      connectButtonBackground: Color.lerp(connectButtonBackground, other.connectButtonBackground, t),
      connectButtonForeground: Color.lerp(connectButtonForeground, other.connectButtonForeground, t),
      connectButtonIcon: Color.lerp(connectButtonIcon, other.connectButtonIcon, t),
      navRailIndicator: Color.lerp(navRailIndicator, other.navRailIndicator, t),
      proxyCardBackground: Color.lerp(proxyCardBackground, other.proxyCardBackground, t),
      proxyCardBorder: Color.lerp(proxyCardBorder, other.proxyCardBorder, t),
      proxyCardBackgroundHover: Color.lerp(proxyCardBackgroundHover, other.proxyCardBackgroundHover, t),
      proxyCardBorderHover: Color.lerp(proxyCardBorderHover, other.proxyCardBorderHover, t),
      proxyCardBackgroundSelected: Color.lerp(proxyCardBackgroundSelected, other.proxyCardBackgroundSelected, t),
      proxyCardBorderSelected: Color.lerp(proxyCardBorderSelected, other.proxyCardBorderSelected, t),
      proxyPingColor: Color.lerp(proxyPingColor, other.proxyPingColor, t),
      switcherBackground: Color.lerp(switcherBackground, other.switcherBackground, t),
      switcherBorder: Color.lerp(switcherBorder, other.switcherBorder, t),
      switcherThumbBackground: Color.lerp(switcherThumbBackground, other.switcherThumbBackground, t),
      switcherSelectedText: Color.lerp(switcherSelectedText, other.switcherSelectedText, t),
      switcherUnselectedText: Color.lerp(switcherUnselectedText, other.switcherUnselectedText, t),
      profileCardBackground: Color.lerp(profileCardBackground, other.profileCardBackground, t),
      profileCardBorder: Color.lerp(profileCardBorder, other.profileCardBorder, t),
      profileCardBackgroundHover: Color.lerp(profileCardBackgroundHover, other.profileCardBackgroundHover, t),
      profileCardBorderHover: Color.lerp(profileCardBorderHover, other.profileCardBorderHover, t),
      profileCardBackgroundSelected: Color.lerp(profileCardBackgroundSelected, other.profileCardBackgroundSelected, t),
      profileCardBorderSelected: Color.lerp(profileCardBorderSelected, other.profileCardBorderSelected, t),
      profileCardProgressTrack: Color.lerp(profileCardProgressTrack, other.profileCardProgressTrack, t),
      trafficChartDownloadColor: Color.lerp(trafficChartDownloadColor, other.trafficChartDownloadColor, t),
    );
  }

  @override
  CustomTheme copyWith({
    Color? connectButtonBackground,
    Color? connectButtonForeground,
    Color? connectButtonIcon,
    Color? navRailIndicator,
    Color? proxyCardBackground,
    Color? proxyCardBorder,
    Color? proxyCardBackgroundHover,
    Color? proxyCardBorderHover,
    Color? proxyCardBackgroundSelected,
    Color? proxyCardBorderSelected,
    Color? proxyPingColor,
    Color? switcherBackground,
    Color? switcherBorder,
    Color? switcherThumbBackground,
    Color? switcherSelectedText,
    Color? switcherUnselectedText,
    Color? profileCardBackground,
    Color? profileCardBorder,
    Color? profileCardBackgroundHover,
    Color? profileCardBorderHover,
    Color? profileCardBackgroundSelected,
    Color? profileCardBorderSelected,
    Color? profileCardProgressTrack,
    Color? trafficChartDownloadColor,
  }) {
    return CustomTheme(
      connectButtonBackground: connectButtonBackground ?? this.connectButtonBackground,
      connectButtonForeground: connectButtonForeground ?? this.connectButtonForeground,
      connectButtonIcon: connectButtonIcon ?? this.connectButtonIcon,
      navRailIndicator: navRailIndicator ?? this.navRailIndicator,
      proxyCardBackground: proxyCardBackground ?? this.proxyCardBackground,
      proxyCardBorder: proxyCardBorder ?? this.proxyCardBorder,
      proxyCardBackgroundHover: proxyCardBackgroundHover ?? this.proxyCardBackgroundHover,
      proxyCardBorderHover: proxyCardBorderHover ?? this.proxyCardBorderHover,
      proxyCardBackgroundSelected: proxyCardBackgroundSelected ?? this.proxyCardBackgroundSelected,
      proxyCardBorderSelected: proxyCardBorderSelected ?? this.proxyCardBorderSelected,
      proxyPingColor: proxyPingColor ?? this.proxyPingColor,
      switcherBackground: switcherBackground ?? this.switcherBackground,
      switcherBorder: switcherBorder ?? this.switcherBorder,
      switcherThumbBackground: switcherThumbBackground ?? this.switcherThumbBackground,
      switcherSelectedText: switcherSelectedText ?? this.switcherSelectedText,
      switcherUnselectedText: switcherUnselectedText ?? this.switcherUnselectedText,
      profileCardBackground: profileCardBackground ?? this.profileCardBackground,
      profileCardBorder: profileCardBorder ?? this.profileCardBorder,
      profileCardBackgroundHover: profileCardBackgroundHover ?? this.profileCardBackgroundHover,
      profileCardBorderHover: profileCardBorderHover ?? this.profileCardBorderHover,
      profileCardBackgroundSelected: profileCardBackgroundSelected ?? this.profileCardBackgroundSelected,
      profileCardBorderSelected: profileCardBorderSelected ?? this.profileCardBorderSelected,
      profileCardProgressTrack: profileCardProgressTrack ?? this.profileCardProgressTrack,
      trafficChartDownloadColor: trafficChartDownloadColor ?? this.trafficChartDownloadColor,
    );
  }
}