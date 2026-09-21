import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ventos_pos/navigation/desktop_destinations.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

class VentosDock extends StatelessWidget {
  const VentosDock({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DesktopDestination> destinations;
  final String selectedId;
  final ValueChanged<DesktopDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: VentosColors.strokeSoft.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final dest in destinations) ...[
                          _DockItem(
                            destination: dest,
                            selected: dest.id == selectedId,
                            onTap: () => onSelected(dest),
                          ),
                          if (dest != destinations.last) const SizedBox(width: 2),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DesktopDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.selected ? 1.12 : (_hovered ? 1.08 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? VentosColors.primary.withValues(alpha: 0.14)
                        : (_hovered
                            ? VentosColors.muted.withValues(alpha: 0.55)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: widget.selected
                        ? Border.all(color: VentosColors.primary.withValues(alpha: 0.35))
                        : null,
                  ),
                  child: Icon(
                    widget.destination.icon,
                    size: 24,
                    color: widget.selected ? VentosColors.primary : VentosColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.destination.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                        color: widget.selected ? VentosColors.primary : VentosColors.mutedForeground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
