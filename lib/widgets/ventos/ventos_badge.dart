import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

enum VentosBadgeVariant { outline, gray, primary }

class VentosBadge extends StatelessWidget {
  const VentosBadge({
    super.key,
    required this.label,
    this.variant = VentosBadgeVariant.outline,
    this.dense = false,
  });

  final String label;
  final VentosBadgeVariant variant;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    Color bg;
    Color fg;
    BoxBorder? border;

    switch (variant) {
      case VentosBadgeVariant.outline:
        bg = VentosColors.cardOpaque;
        fg = VentosColors.textSub;
        border = Border.all(color: VentosColors.strokeSoft);
      case VentosBadgeVariant.gray:
        bg = VentosColors.secondary;
        fg = VentosColors.textSub;
      case VentosBadgeVariant.primary:
        bg = VentosColors.primary;
        fg = VentosColors.onPrimary;
    }

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: VentosFont.family,
            fontSize: dense ? 10 : 12,
            fontWeight: FontWeight.w500,
            height: 1,
            color: fg,
          ),
        ),
      ),
    );
  }
}
