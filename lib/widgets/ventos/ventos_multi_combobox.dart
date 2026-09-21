import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_combobox.dart';
import 'package:ventos_pos/widgets/ventos/ventos_command_search.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_decorations.dart';
import 'package:ventos_pos/widgets/ventos/ventos_input_shell.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

/// Multi-select combobox — same trigger/panel pattern as [VentosCombobox].
class VentosMultiCombobox<T> extends StatefulWidget {
  const VentosMultiCombobox({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    this.label,
    this.placeholder = 'All…',
    this.searchPlaceholder = 'Search…',
    this.emptyText = 'No results found.',
    this.enabled = true,
    this.triggerHeight = 36,
  });

  final List<VentosComboboxItem<T>> items;
  final Set<T> values;
  final ValueChanged<Set<T>> onChanged;
  final String? label;
  final String placeholder;
  final String searchPlaceholder;
  final String emptyText;
  final bool enabled;
  final double triggerHeight;

  @override
  State<VentosMultiCombobox<T>> createState() => _VentosMultiComboboxState<T>();
}

class _VentosMultiComboboxState<T> extends State<VentosMultiCombobox<T>> {
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
            child: _VentosMultiComboboxPanel<T>(
              searchFocus: _searchFocus,
              searchPlaceholder: widget.searchPlaceholder,
              emptyText: widget.emptyText,
              selectedValues: widget.values,
              items: widget.items,
              onSelectionChanged: widget.onChanged,
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
    final count = widget.values.length;
    final displayText = count > 0 ? '$count selected' : widget.placeholder;
    final mutedText = count == 0;

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

class _VentosMultiComboboxPanel<T> extends StatefulWidget {
  const _VentosMultiComboboxPanel({
    required this.searchFocus,
    required this.searchPlaceholder,
    required this.emptyText,
    required this.selectedValues,
    required this.items,
    required this.onSelectionChanged,
  });

  final FocusNode searchFocus;
  final String searchPlaceholder;
  final String emptyText;
  final Set<T> selectedValues;
  final List<VentosComboboxItem<T>> items;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  State<_VentosMultiComboboxPanel<T>> createState() => _VentosMultiComboboxPanelState<T>();
}

class _VentosMultiComboboxPanelState<T> extends State<_VentosMultiComboboxPanel<T>> {
  String _query = '';
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(covariant _VentosMultiComboboxPanel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _selected = Set<T>.from(widget.selectedValues);
    }
  }

  void _toggle(T value) {
    final next = Set<T>.from(_selected);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    setState(() => _selected = next);
    widget.onSelectionChanged(next);
  }

  void _clearAll() {
    if (_selected.isEmpty) return;
    setState(() => _selected = {});
    widget.onSelectionChanged({});
  }

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
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: VentosColors.textSub,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Clear all'),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 288),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                children: [
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
                      _VentosMultiComboboxRow(
                        key: ValueKey(item.value),
                        label: item.label,
                        selected: _selected.contains(item.value),
                        onTap: () => _toggle(item.value),
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

class _VentosMultiComboboxRow extends StatefulWidget {
  const _VentosMultiComboboxRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_VentosMultiComboboxRow> createState() => _VentosMultiComboboxRowState();
}

class _VentosMultiComboboxRowState extends State<_VentosMultiComboboxRow> {
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
