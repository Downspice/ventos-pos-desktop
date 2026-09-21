import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart' show VentosColors, VentosRadii;

/// Matches AlignUI `Card` (rounded-2xl, ring, shadow-regular-sm).
class VentosCard extends StatelessWidget {
  const VentosCard({super.key, required this.child, this.padding, this.clipBehavior = Clip.antiAlias});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VentosColors.cardOpaque,
        borderRadius: BorderRadius.circular(VentosRadii.card),
        border: Border.all(color: VentosColors.strokeSoft),
        boxShadow: const [
          BoxShadow(
            color: VentosColors.shadowSm,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VentosRadii.card),
        clipBehavior: clipBehavior,
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
