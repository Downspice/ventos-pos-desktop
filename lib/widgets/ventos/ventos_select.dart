import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_shell.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

class VentosSelectEntry<T> {
  const VentosSelectEntry({required this.value, required this.label});

  final T value;
  final String label;
}

/// Align UI `Select` (Radix trigger + content), not Material [DropdownMenu].
class VentosSelect<T> extends StatefulWidget {
  const VentosSelect({
    super.key,
    required this.entries,
    this.label,
    this.value,
    this.hint,
    this.onChanged,
    this.enabled = true,
    this.width,
    this.triggerHeight = 36,
  });

  final List<VentosSelectEntry<T>> entries;
  final String? label;
  final T? value;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final double? width;
  final double triggerHeight;

  @override
  State<VentosSelect<T>> createState() => _VentosSelectState<T>();
}

class _VentosSelectState<T> extends State<VentosSelect<T>> {
  final MenuController _menuController = MenuController();

  String? get _selectedLabel {
    for (final e in widget.entries) {
      if (e.value == widget.value) return e.label;
    }
    return null;
  }

  void _toggleMenu() {
    if (!widget.enabled) return;
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _selectedLabel ?? widget.hint ?? 'Select…';
    final isPlaceholder = _selectedLabel == null;

    final anchor = MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(VentosColors.cardOpaque),
        elevation: WidgetStateProperty.all(12),
        shadowColor: WidgetStateProperty.all(VentosColors.shadowSm),
        padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: VentosColors.strokeSoft),
          ),
        ),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      ),
      builder: (context, controller, child) {
        return _VentosSelectTrigger(
          height: widget.triggerHeight,
          enabled: widget.enabled,
          isOpen: controller.isOpen,
          text: display,
          isPlaceholder: isPlaceholder,
          onTap: _toggleMenu,
          onFocusChange: (_) => setState(() {}),
        );
      },
      menuChildren: [
        for (final entry in widget.entries)
          _VentosSelectMenuItem(
            label: entry.label,
            selected: entry.value == widget.value,
            onPressed: widget.enabled
                ? () {
                    widget.onChanged?.call(entry.value);
                    _menuController.close();
                  }
                : null,
          ),
      ],
    );

    final field = SizedBox(width: widget.width ?? double.infinity, child: anchor);

    return Column(
      crossAxisAlignment:
          widget.width != null ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) VentosFieldLabel(widget.label!),
        field,
      ],
    );
  }
}

class _VentosSelectTrigger extends StatefulWidget {
  const _VentosSelectTrigger({
    required this.height,
    required this.enabled,
    required this.isOpen,
    required this.text,
    required this.isPlaceholder,
    required this.onTap,
    required this.onFocusChange,
  });

  final double height;
  final bool enabled;
  final bool isOpen;
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocusChange;

  @override
  State<_VentosSelectTrigger> createState() => _VentosSelectTriggerState();
}

class _VentosSelectTriggerState extends State<_VentosSelectTrigger> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => widget.onFocusChange(_focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: VentosInputShell(
        focusNode: _focusNode,
        height: widget.height,
        enabled: widget.enabled,
        forceFocused: widget.isOpen,
        padding: ventosSingleLineShellPadding(height: widget.height),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            child: SizedBox(
              width: double.infinity,
              child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: ventosSingleLineTextBlockHeight(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w400,
                          color: widget.isPlaceholder
                              ? VentosColors.textSoft
                              : VentosColors.textStrong,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: widget.isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    LucideIcons.chevron_down,
                    size: 20,
                    color: VentosColors.textSoft,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VentosSelectMenuItem extends StatefulWidget {
  const _VentosSelectMenuItem({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  State<_VentosSelectMenuItem> createState() => _VentosSelectMenuItemState();
}

class _VentosSelectMenuItemState extends State<_VentosSelectMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected || _hovered ? VentosColors.muted : Colors.transparent;
    final fg = widget.selected ? VentosColors.textStrong : VentosColors.textSub;

    return MenuItemButton(
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(double.infinity, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: bg,
      ),
      onPressed: widget.onPressed,
      onHover: (hover) => setState(() => _hovered = hover),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(fontSize: 14, height: 1.3, color: fg),
            ),
          ),
          SizedBox(
            width: 20,
            child: widget.selected
                ? Icon(LucideIcons.check, size: 16, color: VentosColors.textStrong)
                : null,
          ),
        ],
      ),
    );
  }
}
