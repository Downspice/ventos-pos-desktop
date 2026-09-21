import 'package:flutter/material.dart';
import 'package:ventos_pos/widgets/common/ventos_table.dart';

/// Module list tables — same layout as web `Table` + `TableHeader` / `TableBody`.
class VentosSimpleTable extends StatelessWidget {
  const VentosSimpleTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No records yet.',
    this.columnSpecs,
    this.minWidth = 720,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final String emptyMessage;
  final List<VentosTableColumn>? columnSpecs;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final specs = columnSpecs ??
        [for (final c in columns) VentosTable.columnFromHeader(c)];

    return VentosTable(
      columns: specs,
      rows: rows,
      emptyMessage: emptyMessage,
      minWidth: minWidth,
    );
  }
}
