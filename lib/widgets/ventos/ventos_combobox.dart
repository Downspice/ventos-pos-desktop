import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';
import 'package:ventos_pos/widgets/ventos/ventos_command_search.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_shell.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

class VentosComboboxItem<T> {
  const VentosComboboxItem({
    required this.value,
    required this.label,
    String? searchValue,
  }) : searchValue = searchValue ?? label;

  final T value;
  final String label;
  final String searchValue;
}

/// Web combobox: outline trigger + popover width match + Command search/list.
class VentosCombobox<T> extends StatefulWidget {
  const VentosCombobox({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.placeholder = 'Select…',
    this.searchPlaceholder = 'Search…',
    this.emptyText = 'No results found.',
    this.nullOptionLabel,
    this.enabled = true,
    this.triggerHeight = 36,
  });

  final List<VentosComboboxItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String placeholder;
  final String searchPlaceholder;
  final String emptyText;
  /// When set, adds a row that calls [onChanged] with `null`.
  final String? nullOptionLabel;
  final bool enabled;
  final double triggerHeight;

  @override
  State<VentosCombobox<T>> createState() => _VentosComboboxState<T>();
}

class _VentosComboboxState<T> extends State<VentosCombobox<T>> {
  final GlobalKey _triggerKey = GlobalKey();
  final FocusNode _triggerFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _detachOverlay();
    _triggerFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  VentosComboboxItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  void _detachOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _removeOverlay() {
    _detachOverlay();
    if (mounted) setState(() {});
  }

  void _openOverlay() {
    if (!widget.enabled || _overlay != null) return;
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final width = box.size.width;
    final top = offset.dy + box.size.height + 4;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: top,
            width: width,
            child: _VentosComboboxPanel<T>(
              searchFocus: _searchFocus,
              searchPlaceholder: widget.searchPlaceholder,
              emptyText: widget.emptyText,
              nullOptionLabel: widget.nullOptionLabel,
              selectedValue: widget.value,
              items: widget.items,
              onPick: (v) {
                widget.onChanged?.call(v);
                _removeOverlay();
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
    setState(() {});
  }

  void _toggleOverlay() {
    if (_overlay != null) {
      _removeOverlay();
    } else {
      _openOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;
    final displayText = widget.value == null && widget.nullOptionLabel != null
        ? widget.nullOptionLabel!
        : (selected?.label ?? widget.placeholder);
    final mutedText = widget.value == null && widget.nullOptionLabel == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) VentosFieldLabel(widget.label!),
        Focus(
          focusNode: _triggerFocus,
          child: VentosInputShell(
            key: _triggerKey,
            focusNode: _triggerFocus,
            height: widget.triggerHeight,
            enabled: widget.enabled,
            forceFocused: _overlay != null,
            padding: ventosSingleLineShellPadding(height: widget.triggerHeight),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? _toggleOverlay : null,
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
                              displayText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                                color: mutedText ? VentosColors.textSoft : VentosColors.textStrong,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevrons_up_down,
                        size: 18,
                        color: VentosColors.mutedForeground.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VentosComboboxPanel<T> extends StatefulWidget {
  const _VentosComboboxPanel({
    required this.searchFocus,
    required this.searchPlaceholder,
    required this.emptyText,
    required this.nullOptionLabel,
    required this.selectedValue,
    required this.items,
    required this.onPick,
  });

  final FocusNode searchFocus;
  final String searchPlaceholder;
  final String emptyText;
  final String? nullOptionLabel;
  final T? selectedValue;
  final List<VentosComboboxItem<T>> items;
  final ValueChanged<T?> onPick;

  @override
  State<_VentosComboboxPanel<T>> createState() => _VentosComboboxPanelState<T>();
}

class _VentosComboboxPanelState<T> extends State<_VentosComboboxPanel<T>> {
  String _query = '';

  List<VentosComboboxItem<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((i) => i.searchValue.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VentosColors.cardOpaque,
      elevation: 12,
      shadowColor: VentosColors.shadowSm,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VentosColors.strokeSoft),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VentosCommandSearchInput(
              focusNode: widget.searchFocus,
              placeholder: widget.searchPlaceholder,
              onChanged: (v) => setState(() => _query = v),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 288),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                children: [
                  if (widget.nullOptionLabel != null)
                    _VentosComboboxRow(
                      label: widget.nullOptionLabel!,
                      selected: widget.selectedValue == null,
                      onTap: () => widget.onPick(null),
                    ),
                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        widget.emptyText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  else
                    for (final item in _filtered)
                      _VentosComboboxRow(
                        label: item.label,
                        selected: item.value == widget.selectedValue,
                        onTap: () => widget.onPick(item.value),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VentosComboboxRow extends StatefulWidget {
  const _VentosComboboxRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_VentosComboboxRow> createState() => _VentosComboboxRowState();
}

class _VentosComboboxRowState extends State<_VentosComboboxRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovered ? VentosColors.muted : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Opacity(
                    opacity: widget.selected ? 1 : 0,
                    child: const Icon(LucideIcons.check, size: 16, color: VentosColors.textStrong),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(fontSize: 14, height: 1.25, color: VentosColors.textSub),
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
