import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ventos_pos/models/pos_sale.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';
import 'package:ventos_pos/widgets/pos/sale_view_sheet.dart';

class PosSalesList extends StatefulWidget {
  const PosSalesList({
    super.key,
    required this.pos,
    required this.formatMoney,
    this.refreshKey = 0,
  });

  final PosRepository pos;
  final String Function(double) formatMoney;
  final int refreshKey;

  @override
  State<PosSalesList> createState() => _PosSalesListState();
}

class _PosSalesListState extends State<PosSalesList> {
  static const _pageSize = 10;

  String? _statusFilter;
  PosSalesListData? _data;
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PosSalesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.pos.fetchSales(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _page = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<PosSaleSummary> get _pageItems {
    final sales = _data?.sales ?? [];
    final start = (_page - 1) * _pageSize;
    if (start >= sales.length) return [];
    final end = (start + _pageSize).clamp(0, sales.length);
    return sales.sublist(start, end);
  }

  int get _totalPages {
    final n = _data?.sales.length ?? 0;
    return n == 0 ? 1 : ((n + _pageSize - 1) / _pageSize).ceil();
  }

  Future<void> _openViewSale(String id) async {
    await SaleViewSheet.open(
      context: context,
      pos: widget.pos,
      saleId: id,
      formatMoney: widget.formatMoney,
      initialCustomerNames: _data?.customerNames ?? {},
      initialEmployeeNames: _data?.employeeNames ?? {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return VentosCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recent sales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: VentosSelect<String?>(
              width: 220,
              label: 'Status',
              value: _statusFilter,
              hint: 'All statuses',
              entries: const [
                VentosSelectEntry(value: null, label: 'All statuses'),
                VentosSelectEntry(value: 'FINALIZED', label: 'Finalized'),
                VentosSelectEntry(value: 'DRAFT', label: 'Draft'),
                VentosSelectEntry(value: 'VOID', label: 'Void'),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: VentosColors.destructive))
          else if ((_data?.sales ?? []).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No sales yet. Complete an order to see it here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PosSalesTableHeader(
                  headerStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: VentosColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pageItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: VentosColors.strokeSoft),
                  itemBuilder: (context, index) {
                    final s = _pageItems[index];
                    final customer = s.customerId != null
                        ? _data!.customerNames[s.customerId] ?? '—'
                        : 'Walk-in';
                    final seller = s.employeeId != null
                        ? _data!.employeeNames[s.employeeId] ?? '—'
                        : '—';
                    return _PosSalesTableRow(
                      dateLabel: DateFormat.yMMMd().add_jm().format(s.createdAt.toLocal()),
                      saleLabel: s.id.length > 8 ? s.id.substring(s.id.length - 8) : s.id,
                      customerLabel: customer,
                      sellerLabel: seller,
                      status: s.status,
                      totalLabel: widget.formatMoney(s.total),
                      onView: () => _openViewSale(s.id),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_data!.sales.length} sale(s)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _page > 1 ? () => setState(() => _page--) : null,
                          icon: const Icon(LucideIcons.chevron_left),
                        ),
                        Text('Page $_page of $_totalPages'),
                        IconButton(
                          onPressed: _page < _totalPages ? () => setState(() => _page++) : null,
                          icon: const Icon(LucideIcons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PosSalesTableHeader extends StatelessWidget {
  const _PosSalesTableHeader({required this.headerStyle});

  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Date', style: headerStyle)),
          Expanded(flex: 2, child: Text('Sale', style: headerStyle)),
          Expanded(flex: 3, child: Text('Customer', style: headerStyle)),
          Expanded(flex: 3, child: Text('Sold by', style: headerStyle)),
          Expanded(flex: 2, child: Text('Status', style: headerStyle)),
          Expanded(
            flex: 2,
            child: Text('Total', style: headerStyle, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _PosSalesTableRow extends StatelessWidget {
  const _PosSalesTableRow({
    required this.dateLabel,
    required this.saleLabel,
    required this.customerLabel,
    required this.sellerLabel,
    required this.status,
    required this.totalLabel,
    required this.onView,
  });

  final String dateLabel;
  final String saleLabel;
  final String customerLabel;
  final String sellerLabel;
  final String status;
  final String totalLabel;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(dateLabel, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(
              saleLabel,
              style: bodyStyle?.copyWith(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(customerLabel, style: bodyStyle, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: Text(sellerLabel, style: bodyStyle, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: VentosBadge(label: status, variant: VentosBadgeVariant.gray, dense: true),
          ),
          Expanded(
            flex: 2,
            child: Text(
              totalLabel,
              style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'View sale',
                child: VentosOutlineIconButton(
                  onPressed: onView,
                  icon: LucideIcons.eye,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
