import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_shell.dart';

/// Align UI `Input` / `Textarea` — borderless field inside [VentosInputShell].
class VentosTextField extends StatefulWidget {
  const VentosTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
    this.size = VentosInputSize.md,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;
  final VentosInputSize size;
  final FocusNode? focusNode;

  @override
  State<VentosTextField> createState() => _VentosTextFieldState();
}

class _VentosTextFieldState extends State<VentosTextField> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _multiline => (widget.maxLines ?? 1) > 1 || (widget.minLines ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  TextStyle get _singleLineTextStyle {
    return TextStyle(
      fontSize: widget.size.fontSize,
      color: VentosColors.textStrong,
      height: 1,
      leadingDistribution: TextLeadingDistribution.proportional,
      fontWeight: FontWeight.w400,
    );
  }

  InputDecoration _borderlessDecoration() {
    return InputDecoration(
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      hintText: widget.hintText,
      hintStyle: TextStyle(
        fontSize: widget.size.fontSize,
        color: VentosColors.textSoft,
        height: 1,
        leadingDistribution: TextLeadingDistribution.proportional,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _iconSlot(Widget? icon) {
    if (icon == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: const IconThemeData(size: 18, color: VentosColors.mutedForeground),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final textField = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      cursorHeight: _multiline ? null : widget.size.fontSize,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      minLines: widget.minLines ?? (_multiline ? 3 : 1),
      autofillHints: widget.autofillHints,
      textAlignVertical: _multiline ? TextAlignVertical.top : TextAlignVertical.center,
      style: _multiline
          ? TextStyle(
              fontSize: widget.size.fontSize,
              color: VentosColors.textStrong,
              height: 1.25,
              fontWeight: FontWeight.w400,
            )
          : _singleLineTextStyle,
      decoration: _borderlessDecoration(),
    );

    final fieldRow = Row(
      crossAxisAlignment:
          _multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          _iconSlot(widget.prefixIcon),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _multiline
              ? textField
              : SizedBox(
                  height: widget.size.fontSize + 4,
                  child: textField,
                ),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: 8),
          _iconSlot(widget.suffixIcon),
        ],
      ],
    );

    final shell = VentosInputShell(
      focusNode: _focusNode,
      enabled: widget.enabled,
      hasError: hasError,
      height: _multiline ? null : widget.size.height,
      minHeight: _multiline ? 80 : null,
      padding: _multiline
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 12),
      child: fieldRow,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) VentosFieldLabel(widget.label!),
        shell,
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              color: VentosColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact icon control for [VentosTextField.suffixIcon] / prefix slots (avoids 48px [IconButton]).
class VentosInputSuffixButton extends StatelessWidget {
  const VentosInputSuffixButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final control = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Icon(icon, size: 18, color: VentosColors.mutedForeground),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return control;
    return Tooltip(message: tooltip!, preferBelow: false, child: control);
  }
}
