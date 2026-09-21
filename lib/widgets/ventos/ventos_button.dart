import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

enum VentosButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

enum VentosButtonSize { xs, sm, md, lg, xl, icon, iconSm, iconXs }

/// Align UI `Button` — single entry for actions (replaces ad hoc Material buttons).
class VentosButton extends StatelessWidget {
  const VentosButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = VentosButtonVariant.primary,
    this.size = VentosButtonSize.md,
    this.icon,
    this.destructive = false,
  });

  const VentosButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.variant = VentosButtonVariant.outline,
    this.size = VentosButtonSize.icon,
    this.destructive = false,
  }) : child = null;

  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final VentosButtonVariant variant;
  final VentosButtonSize size;
  /// Red icon on outline button (web table delete action).
  final bool destructive;

  bool get _isIcon => icon != null;

  @override
  Widget build(BuildContext context) {
    if (_isIcon &&
        (variant == VentosButtonVariant.outline || variant == VentosButtonVariant.secondary)) {
      return VentosOutlineIconButton(
        key: key,
        onPressed: onPressed,
        icon: icon!,
        size: size,
        destructive: destructive,
      );
    }

    final style = _styleFor(variant, size);
    final content = _isIcon
        ? Icon(icon, size: _iconSize(size))
        : DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: _fontSize(size),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            child: IconTheme.merge(
              data: IconThemeData(size: _iconSize(size)),
              child: child!,
            ),
          );

    if (variant == VentosButtonVariant.link) {
      return TextButton(
        onPressed: onPressed,
        style: style,
        child: content,
      );
    }

    if (variant == VentosButtonVariant.ghost) {
      return TextButton(
        onPressed: onPressed,
        style: style,
        child: content,
      );
    }

    if (variant == VentosButtonVariant.primary || variant == VentosButtonVariant.destructive) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: content,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: content,
    );
  }

  static double _fontSize(VentosButtonSize size) {
    switch (size) {
      case VentosButtonSize.xs:
        return 12;
      case VentosButtonSize.sm:
      case VentosButtonSize.md:
      case VentosButtonSize.icon:
      case VentosButtonSize.iconSm:
        return 14;
      case VentosButtonSize.lg:
        return 14;
      case VentosButtonSize.xl:
        return 16;
      case VentosButtonSize.iconXs:
        return 12;
    }
  }

  static double _iconSize(VentosButtonSize size) {
    switch (size) {
      case VentosButtonSize.iconXs:
        return 16;
      case VentosButtonSize.iconSm:
        return 16;
      case VentosButtonSize.icon:
        return 16;
      default:
        return 18;
    }
  }

  static Size _minimumSize(VentosButtonSize size) {
    switch (size) {
      case VentosButtonSize.xs:
        return const Size(0, 28);
      case VentosButtonSize.sm:
        return const Size(0, 32);
      case VentosButtonSize.md:
        return const Size(0, 36);
      case VentosButtonSize.lg:
        return const Size(0, 40);
      case VentosButtonSize.xl:
        return const Size(0, 48);
      case VentosButtonSize.icon:
        return const Size(36, 36);
      case VentosButtonSize.iconSm:
        return const Size(32, 32); // web size-8
      case VentosButtonSize.iconXs:
        return const Size(28, 28);
    }
  }

  static EdgeInsets _padding(VentosButtonSize size, bool icon) {
    if (icon) return EdgeInsets.zero;
    switch (size) {
      case VentosButtonSize.xs:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      case VentosButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case VentosButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case VentosButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      case VentosButtonSize.xl:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      default:
        return EdgeInsets.zero;
    }
  }

  static double _radius(VentosButtonSize size) {
    if (size == VentosButtonSize.xs) return 8;
    return VentosRadii.button;
  }

  static ButtonStyle _styleFor(VentosButtonVariant variant, VentosButtonSize size) {
    final icon = size == VentosButtonSize.icon ||
        size == VentosButtonSize.iconSm ||
        size == VentosButtonSize.iconXs;

    final base = ButtonStyle(
      minimumSize: WidgetStateProperty.all(_minimumSize(size)),
      padding: WidgetStateProperty.all(_padding(size, icon)),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(VentosColors.shadowXs),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius(size))),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.black.withValues(alpha: 0.04);
        }
        return null;
      }),
    );

    switch (variant) {
      case VentosButtonVariant.primary:
        return base.merge(FilledButton.styleFrom(
          backgroundColor: VentosColors.primary,
          foregroundColor: VentosColors.onPrimary,
          disabledBackgroundColor: VentosColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: VentosColors.onPrimary.withValues(alpha: 0.8),
        ));
      case VentosButtonVariant.destructive:
        return base.merge(FilledButton.styleFrom(
          backgroundColor: VentosColors.destructive,
          foregroundColor: VentosColors.onPrimary,
          disabledBackgroundColor: VentosColors.destructive.withValues(alpha: 0.4),
        ));
      case VentosButtonVariant.secondary:
      case VentosButtonVariant.outline:
        return base.merge(OutlinedButton.styleFrom(
          backgroundColor: VentosColors.cardOpaque,
          foregroundColor: VentosColors.textStrong,
          disabledForegroundColor: VentosColors.textSoft,
          side: const BorderSide(color: VentosColors.strokeSoft),
        ));
      case VentosButtonVariant.ghost:
        return base.merge(TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: VentosColors.textSub,
          disabledForegroundColor: VentosColors.textSoft,
        ));
      case VentosButtonVariant.link:
        return base.merge(TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: VentosColors.textSub,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
    }
  }
}

/// Align UI `Button` outline + `icon-sm` — white fill, inset ring, shadow-regular-xs.
class VentosOutlineIconButton extends StatefulWidget {
  const VentosOutlineIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = VentosButtonSize.iconSm,
    this.destructive = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final VentosButtonSize size;
  final bool destructive;

  @override
  State<VentosOutlineIconButton> createState() => _VentosOutlineIconButtonState();
}

class _VentosOutlineIconButtonState extends State<VentosOutlineIconButton> {
  bool _hover = false;
  bool _pressed = false;

  double get _boxSize {
    switch (widget.size) {
      case VentosButtonSize.iconXs:
        return 28;
      case VentosButtonSize.icon:
        return 36;
      case VentosButtonSize.iconSm:
      default:
        return 32;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case VentosButtonSize.iconXs:
        return 14;
      case VentosButtonSize.icon:
        return 18;
      case VentosButtonSize.iconSm:
      default:
        return 16;
    }
  }

  double get _radius {
    switch (widget.size) {
      case VentosButtonSize.iconXs:
        return 8;
      default:
        return VentosRadii.button;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = !_hover && !_pressed
        ? VentosColors.cardOpaque
        : _pressed
            ? const Color(0xFFF5F5F5)
            : VentosColors.bgWeak50;
    final borderColor = _hover || _pressed ? VentosColors.strokeSub : VentosColors.strokeSoft;
    final iconColor = widget.destructive
        ? VentosColors.destructive
        : (enabled ? VentosColors.textStrong : VentosColors.textSoft);

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled ? (_) => setState(() => _hover = false) : null,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _boxSize,
          height: _boxSize,
          decoration: BoxDecoration(
            color: enabled ? bg : VentosColors.cardOpaque.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x080A0D14),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: _iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Full-width primary action (login, add to cart).
class VentosButtonFull extends StatelessWidget {
  const VentosButtonFull({
    super.key,
    required this.onPressed,
    required this.label,
    this.variant = VentosButtonVariant.primary,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final VentosButtonVariant variant;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: VentosButton(
        onPressed: busy ? null : onPressed,
        variant: variant,
        size: VentosButtonSize.md,
        child: busy
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: variant == VentosButtonVariant.primary || variant == VentosButtonVariant.destructive
                      ? VentosColors.onPrimary
                      : VentosColors.textStrong,
                ),
              )
            : Text(label),
      ),
    );
  }
}
