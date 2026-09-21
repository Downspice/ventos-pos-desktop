import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';

/// Outer ring + shadow for Align UI `Input` / `Select` triggers.
class VentosInputShell extends StatefulWidget {
  const VentosInputShell({
    super.key,
    required this.child,
    this.focusNode,
    this.height,
    this.minHeight,
    this.enabled = true,
    this.hasError = false,
    this.forceFocused = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final FocusNode? focusNode;
  final double? height;
  final double? minHeight;
  final bool enabled;
  final bool hasError;
  final bool forceFocused;
  final EdgeInsets padding;

  @override
  State<VentosInputShell> createState() => _VentosInputShellState();
}

class _VentosInputShellState extends State<VentosInputShell> {
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(VentosInputShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  Color get _borderColor {
    if (!widget.enabled) return VentosColors.strokeSoft.withValues(alpha: 0.6);
    if (widget.hasError) return VentosColors.destructive;
    if (_focused || widget.forceFocused) return VentosColors.textStrong;
    if (_hovered) return VentosColors.strokeSub;
    return VentosColors.strokeSoft;
  }

  double get _borderWidth {
    if (!widget.enabled) return 1;
    if (widget.hasError || _focused || widget.forceFocused) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height,
      constraints: widget.minHeight != null
          ? BoxConstraints(minHeight: widget.minHeight!)
          : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.enabled ? VentosColors.cardOpaque : VentosColors.muted.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(VentosRadii.input),
        border: Border.all(color: _borderColor, width: _borderWidth),
        boxShadow: ventosInputShadow,
      ),
      child: SizedBox(width: double.infinity, child: widget.child),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: MouseRegion(
        onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
        child: box,
      ),
    );
  }
}
