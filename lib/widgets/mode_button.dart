import 'package:flutter/material.dart';

import '../theme/battery_palette.dart';

class ModeButton extends StatelessWidget {
  const ModeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.palette,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final BatteryPalette palette;

  final bool selected;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed ?? () {},
          tooltip: label,
          isSelected: selected,
          icon: Icon(icon, weight: 600),
          iconSize: 28,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(64),
            padding: EdgeInsets.zero,
            backgroundColor: selected
                ? palette.buttonSelectedBackground
                : palette.buttonBackground,
            foregroundColor: selected
                ? palette.buttonSelectedForeground
                : palette.buttonForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 98),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? palette.primaryText : palette.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
