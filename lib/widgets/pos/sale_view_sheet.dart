import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ventos_pos/models/pos_sale.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart' show VentosColors;
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Desktop equivalent of web `SaleViewDrawer`.
class SaleViewSheet extends StatefulWidget {
  const SaleViewSheet({
    super.key,
    required this.pos,
    required this.saleId,
    required this.formatMoney,
    this.initialCustomerNames = const {},
    this.initialEmployeeNames = const {},
  });

  final PosRepository pos;
  final String saleId;
  final String Function(double) formatMoney;
  final Map<String, String> initialCustomerNames;
  final Map<String, String> initialEmployeeNames;

  static Future<void> open({
    required BuildContext context,
    required PosRepository pos,
    required String saleId,
    required String Function(double) formatMoney,
    Map<String, String> initialCustomerNames = const {},
    Map<String, String> initialEmployeeNames = const {},
  }) {
    return showVentosEndSheet<void>(
      context: context,
      child: SaleViewSheet(
        pos: pos,
        saleId: saleId,
        formatMoney: formatMoney,
        initialCustomerNames: initialCustomerNames,
        initialEmployeeNames: initialEmployeeNames,
      ),
    );
  }

  @override
  State<SaleViewSheet> createState() => _SaleViewSheetState();
}

class _SaleViewSheetState extends State<SaleViewSheet> {
  PosSaleViewContext? _ctx;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ctx = await widget.pos.fetchSaleViewContext(
        widget.saleId,
        fallbackCustomerNames: widget.initialCustomerNames,
        fallbackEmployeeNames: widget.initialEmployeeNames,
      );
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _loading = false;
        _error = ctx == null ? 'Sale not found.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this sale.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = _ctx?.sale;
    final shortId = sale != null && sale.id.length > 8
        ? sale.id.substring(sale.id.length - 8)
        : widget.saleId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Sale details', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              if (sale != null)
                Text(
                  '${DateFormat.yMMMd().add_jm().format(sale.createdAt.toLocal())} · $shortId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: VentosColors.destructive)))
                  : sale == null
                      ? const Center(child: Text('Sale not found.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MetaGrid(
                                status: sale.status,
                                customer: _ctx!.customerLabel,
                                showRegister: sale.registerSessionId != null,
                                register: _ctx!.registerLabel ?? 'Unknown register',
                                showSoldBy: sale.employeeId != null,
                                soldBy: _ctx!.employeeLabel ?? 'Unknown employee',
                              ),
                              const SizedBox(height: 24),
                              Text('Line items', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8),
                              _LineItemsTable(
                                lines: sale.lines,
                                formatMoney: widget.formatMoney,
                                imageUrlForLine: _ctx!.imageUrlForLine,
                              ),
                              const SizedBox(height: 24),
                              _TotalsBlock(
                                subtotal: sale.subtotal,
                                discountTotal: sale.discountTotal,
                                taxTotal: sale.taxTotal,
                                total: sale.total,
                                formatMoney: widget.formatMoney,
                              ),
                            ],
                          ),
                        ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: VentosButton(
              onPressed: () => Navigator.pop(context),
              variant: VentosButtonVariant.outline,
              child: const Text('Close'),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({
    required this.status,
    required this.customer,
    required this.showRegister,
    required this.register,
    required this.showSoldBy,
    required this.soldBy,
  });

  final String status;
  final String customer;
  final bool showRegister;
  final String register;
  final bool showSoldBy;
  final String soldBy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _MetaCell(
          label: 'Status',
          child: VentosBadge(label: status, variant: VentosBadgeVariant.gray, dense: true),
        ),
        _MetaCell(label: 'Customer', value: customer),
        if (showRegister) _MetaCell(label: 'Register', value: register),
        if (showSoldBy) _MetaCell(label: 'Sold by', value: soldBy),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, this.value, this.child})
      : assert(value != null || child != null);

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          child ??
              Text(
                value!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
        ],
      ),
    );
  }
}

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({
    required this.lines,
    required this.formatMoney,
    required this.imageUrlForLine,
  });

  final List<PosSaleLine> lines;
  final String Function(double) formatMoney;
  final String? Function(PosSaleLine line) imageUrlForLine;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: VentosColors.muted.withValues(alpha: 0.5)),
          children: [
            _headCell('Item'),
            _headCell('Qty', align: TextAlign.right),
            _headCell('Unit', align: TextAlign.right),
            _headCell('Discount', align: TextAlign.right),
            _headCell('Total', align: TextAlign.right),
          ],
        ),
        ...lines.map((line) {
          final imageUrl = imageUrlForLine(line);
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  children: [
                    EntityImage(imageUrl: imageUrl, alt: line.name),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          VentosBadge(label: line.lineType, variant: VentosBadgeVariant.gray, dense: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _cell('${line.quantity % 1 == 0 ? line.quantity.toInt() : line.quantity}', align: TextAlign.right),
              _cell(formatMoney(line.unitPrice), align: TextAlign.right),
              _cell(
                line.discountAmount > 0 ? formatMoney(line.discountAmount) : '—',
                align: TextAlign.right,
              ),
              _cell(formatMoney(line.lineTotal), align: TextAlign.right, bold: true),
            ],
          );
        }),
      ],
    );
  }

  Widget _headCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: VentosColors.mutedForeground),
      ),
    );
  }

  Widget _cell(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.formatMoney,
  });

  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        _totalRow('Subtotal', formatMoney(subtotal)),
        if (discountTotal > 0) _totalRow('Discounts', '−${formatMoney(discountTotal)}'),
        if (taxTotal > 0) _totalRow('Tax', formatMoney(taxTotal)),
        const SizedBox(height: 8),
        _totalRow('Total', formatMoney(total), emphasized: true),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              color: emphasized ? VentosColors.textStrong : VentosColors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
