import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

/// Align UI table column (`TableHead` / `TableCell`).
class VentosTableColumn {
  const VentosTableColumn({
    required this.label,
    this.flex = 1,
    this.fixedWidth,
    this.textAlign = TextAlign.left,
    this.isActions = false,
  });

  final String label;
  final double flex;
  final double? fixedWidth;
  final TextAlign textAlign;
  final bool isActions;

  bool get isActionsColumn => isActions || label.trim().isEmpty;
}

/// Data table matching web `@/components/align-ui/table`.
class VentosTable extends StatelessWidget {
  const VentosTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No records yet.',
    this.minWidth = 720,
  });

  final List<VentosTableColumn> columns;
  final List<List<Widget>> rows;
  final String emptyMessage;
  final double minWidth;

  static VentosTableColumn columnFromHeader(String header) {
    final trimmed = header.trim();
    if (trimmed.isEmpty) {
      return const VentosTableColumn(
        label: '',
        fixedWidth: 118,
        isActions: true,
        textAlign: TextAlign.right,
      );
    }
    final lower = trimmed.toLowerCase();
    final alignRight = lower == 'price' ||
        lower == 'total' ||
        lower.contains('delta') ||
        lower.contains('on hand') ||
        lower.contains('qty');
    return VentosTableColumn(
      label: trimmed,
      flex: lower.contains('metadata') ? 1.6 : 1,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VentosColors.strokeSoft)),
        ),
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.mutedForeground),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, minWidth);
        return Scrollbar(
          thumbVisibility: width > constraints.maxWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VentosTableHeaderRow(columns: columns),
                  for (var r = 0; r < rows.length; r++)
                    _VentosTableDataRow(
                      key: ValueKey('ventos-table-row-$r'),
                      columns: columns,
                      cells: rows[r],
                      isLast: r == rows.length - 1,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VentosTableHeaderRow extends StatelessWidget {
  const _VentosTableHeaderRow({required this.columns});

  final List<VentosTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 1.2,
          letterSpacing: 0.6,
          color: VentosColors.textSoft,
        );

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: VentosColors.bgWeak50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length; i++)
            _VentosTableHeaderCell(
              column: columns[i],
              isFirst: i == 0,
              isLast: i == columns.length - 1,
              style: style,
            ),
        ],
      ),
    );
  }
}

class _VentosTableHeaderCell extends StatelessWidget {
  const _VentosTableHeaderCell({
    required this.column,
    required this.isFirst,
    required this.isLast,
    required this.style,
  });

  final VentosTableColumn column;
  final bool isFirst;
  final bool isLast;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = column.isActionsColumn
        ? ''
        : column.label.toUpperCase();

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: _alignmentFor(column.textAlign),
        child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    if (column.fixedWidth != null) {
      return SizedBox(width: column.fixedWidth, child: child);
    }
    return Expanded(flex: (column.flex * 100).round().clamp(1, 1000), child: child);
  }
}

class _VentosTableDataRow extends StatefulWidget {
  const _VentosTableDataRow({
    super.key,
    required this.columns,
    required this.cells,
    required this.isLast,
  });

  final List<VentosTableColumn> columns;
  final List<Widget> cells;
  final bool isLast;

  @override
  State<_VentosTableDataRow> createState() => _VentosTableDataRowState();
}

class _VentosTableDataRowState extends State<_VentosTableDataRow> {
  @override
  Widget build(BuildContext context) {
    final border = widget.isLast
        ? BorderSide.none
        : const BorderSide(color: VentosColors.strokeSoft);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.columns.length; i++)
            _VentosTableDataCell(
              column: widget.columns[i],
              child: i < widget.cells.length ? widget.cells[i] : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _VentosTableDataCell extends StatelessWidget {
  const _VentosTableDataCell({
    required this.column,
    required this.child,
  });

  final VentosTableColumn column;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Align(
        alignment: _alignmentFor(column.textAlign),
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: VentosColors.textSub,
                height: 1.35,
              ),
          child: child,
        ),
      ),
    );

    if (column.isActionsColumn) {
      return Container(
        width: column.fixedWidth ?? 118,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(left: BorderSide(color: VentosColors.strokeSoft)),
        ),
        child: padded,
      );
    }

    if (column.fixedWidth != null) {
      return SizedBox(width: column.fixedWidth, child: padded);
    }
    return Expanded(flex: (column.flex * 100).round().clamp(1, 1000), child: padded);
  }
}

/// Bordered strip above module tables (web list search card).
class VentosTableToolbar extends StatelessWidget {
  const VentosTableToolbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VentosColors.cardOpaque,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VentosColors.strokeSoft),
        boxShadow: const [
          BoxShadow(color: VentosColors.shadowXs, blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

Alignment _alignmentFor(TextAlign align) {
  switch (align) {
    case TextAlign.right:
    case TextAlign.end:
      return Alignment.centerRight;
    case TextAlign.center:
      return Alignment.center;
    default:
      return Alignment.centerLeft;
  }
}
