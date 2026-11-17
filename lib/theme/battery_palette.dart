import 'package:flutter/material.dart';

enum BatteryStatus { idle, normal, bad, overheat }

@immutable
class BatteryPalette {
  const BatteryPalette({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.modeLabel,
    required this.mainValue,
    required this.divider,
    required this.illustrationCircle,
    required this.batteryShell,
    required this.batteryInner,
    required this.batteryFill,
    required this.batteryHighlight,
    required this.batteryGlyph,
    required this.buttonSelectedBackground,
    required this.buttonSelectedForeground,
    required this.buttonBackground,
    required this.buttonForeground,
    required this.card,
    required this.cardDivider,
  });

  final Color background;

  final Color primaryText;

  final Color secondaryText;

  final Color modeLabel;

  final Color mainValue;

  final Color divider;

  final Color illustrationCircle;

  final Color batteryShell;

  final Color batteryInner;

  final Color batteryFill;

  final Color batteryHighlight;

  final Color batteryGlyph;

  final Color buttonSelectedBackground;
  final Color buttonSelectedForeground;
  final Color buttonBackground;
  final Color buttonForeground;

  final Color card;

  final Color cardDivider;

  static const BatteryPalette normal = BatteryPalette(
    background: Color(0xFFF6F9F5),
    primaryText: Color(0xFF213F30),
    secondaryText: Color(0xFF6A796D),
    modeLabel: Color(0xFF71816F),
    mainValue: Color(0xFF213F30),
    divider: Color(0xFFE1E9DF),
    illustrationCircle: Color(0xFFEAF2E4),
    batteryShell: Color(0xFF284C36),
    batteryInner: Color(0xFFF0F6E9),
    batteryFill: Color(0xFFB6E880),
    batteryHighlight: Color(0xFFD5F3B5),
    batteryGlyph: Color(0xFF284C36),
    buttonSelectedBackground: Color(0xFF284C36),
    buttonSelectedForeground: Color(0xFFD0F4A5),
    buttonBackground: Color(0xFFE7EEDF),
    buttonForeground: Color(0xFF496044),
    card: Color(0xFFFFFFFF),
    cardDivider: Color(0xFFE8EEE5),
  );

  static const BatteryPalette idle = BatteryPalette(
    background: Color(0xFFF6F9F5),
    primaryText: Color(0xFF213F30),
    secondaryText: Color(0xFF6A796D),
    modeLabel: Color(0xFF71816F),
    mainValue: Color(0xFF213F30),
    divider: Color(0xFFE1E9DF),
    illustrationCircle: Color(0xFFEAF2E4),
    batteryShell: Color(0xFF849180),
    batteryInner: Color(0xFFFFFFFF),
    batteryFill: Color(0xFFB6E880),
    batteryHighlight: Color(0xFFD5F3B5),
    batteryGlyph: Color(0xFF849180),
    buttonSelectedBackground: Color(0xFF284C36),
    buttonSelectedForeground: Color(0xFFD0F4A5),
    buttonBackground: Color(0xFFE7EEDF),
    buttonForeground: Color(0xFF496044),
    card: Color(0xFFFFFFFF),
    cardDivider: Color(0xFFE8EEE5),
  );

  static const BatteryPalette bad = BatteryPalette(
    background: Color(0xFFFFF5CC),
    primaryText: Color(0xFF59420F),
    secondaryText: Color(0xFF80682F),
    modeLabel: Color(0xFF80682F),
    mainValue: Color(0xFF59420F),
    divider: Color(0xFFEAD99D),
    illustrationCircle: Color(0xFFF9E9AB),
    batteryShell: Color(0xFF785815),
    batteryInner: Color(0xFFFFF9E3),
    batteryFill: Color(0xFFF2C644),
    batteryHighlight: Color(0xFFFFE99B),
    batteryGlyph: Color(0xFF785815),
    buttonSelectedBackground: Color(0xFF785815),
    buttonSelectedForeground: Color(0xFFFFF3C4),
    buttonBackground: Color(0xFFF4E7B8),
    buttonForeground: Color(0xFF785E25),
    card: Color(0xFFFFFCF0),
    cardDivider: Color(0xFFEDDFB6),
  );

  static const BatteryPalette overheat = BatteryPalette(
    background: Color(0xFFFFF0E5),
    primaryText: Color(0xFF682F23),
    secondaryText: Color(0xFF94604B),
    modeLabel: Color(0xFF94604B),
    mainValue: Color(0xFFB53C2C),
    divider: Color(0xFFF0CEB8),
    illustrationCircle: Color(0xFFFFE0CB),
    batteryShell: Color(0xFF9C352A),
    batteryInner: Color(0xFFFFEDE4),
    batteryFill: Color(0xFFEF6252),
    batteryHighlight: Color(0xFFFFA393),
    batteryGlyph: Color(0xFFFFF3E9),
    buttonSelectedBackground: Color(0xFF9C352A),
    buttonSelectedForeground: Color(0xFFFFF0E5),
    buttonBackground: Color(0xFFF9DCC7),
    buttonForeground: Color(0xFF8B4B35),
    card: Color(0xFFFFFBF7),
    cardDivider: Color(0xFFF3DAC8),
  );

  static BatteryPalette of(BatteryStatus status) => switch (status) {
    BatteryStatus.idle => idle,
    BatteryStatus.normal => normal,
    BatteryStatus.bad => bad,
    BatteryStatus.overheat => overheat,
  };
}
