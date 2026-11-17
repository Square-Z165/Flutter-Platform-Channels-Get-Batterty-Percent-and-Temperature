import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/battery_palette.dart';

class BatteryIcon extends StatelessWidget {
  const BatteryIcon({
    super.key,
    required this.status,
    this.level,
    this.width = designWidth,
    this.palette,
    this.glyph,
  });

  static const double designWidth = 136;
  static const double designHeight = 225;

  final BatteryStatus status;

  final double? level;

  final double width;

  final BatteryPalette? palette;

  final IconData? glyph;

  static IconData? _defaultGlyph(BatteryStatus status) => switch (status) {
    BatteryStatus.idle => null,
    BatteryStatus.normal => Symbols.bolt,
    BatteryStatus.bad => Symbols.priority_high,
    BatteryStatus.overheat => Symbols.local_fire_department,
  };

  @override
  Widget build(BuildContext context) {
    final colors = palette ?? BatteryPalette.of(status);
    final icon = glyph ?? _defaultGlyph(status);
    final fillLevel = level?.clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      height: width * designHeight / designWidth,
      child: FittedBox(
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: Stack(
            children: [
              Positioned(
                left: 48,
                top: 0,
                width: 40,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.batteryShell,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 13,
                width: 136,
                height: 212,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.batteryShell,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: _BatteryCell(
                    colors: colors,
                    level: fillLevel,
                    glyph: icon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatteryCell extends StatelessWidget {
  const _BatteryCell({
    required this.colors,
    required this.level,
    required this.glyph,
  });

  static const double _height = 196;

  final BatteryPalette colors;
  final double? level;
  final IconData? glyph;

  @override
  Widget build(BuildContext context) {
    final fillHeight = level == null ? 0.0 : _height * level!;
    final highlightHeight = (fillHeight - 20).clamp(0.0, 91.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: ColoredBox(
        color: colors.batteryInner,
        child: Stack(
          children: [
            if (fillHeight > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: fillHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.batteryFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            if (highlightHeight > 0)
              Positioned(
                left: 12,
                top: _height - fillHeight + 10,
                width: 7,
                height: highlightHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.batteryHighlight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            if (glyph != null)
              Positioned(
                left: 44,
                top: 78,
                width: 32,
                height: 44,
                child: OverflowBox(
                  maxWidth: 48,
                  maxHeight: 48,
                  child: Icon(
                    glyph,
                    size: 44,
                    fill: 1,
                    weight: 500,
                    color: colors.batteryGlyph,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
