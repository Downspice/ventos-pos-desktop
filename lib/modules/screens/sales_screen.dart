import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/pos/sale_view_sheet.dart' show SaleViewSheet;
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.app, required this.pos, this.reloadKey = 0});

  final AppRepository app;
  final PosRepository pos;
  final int reloadKey;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const _pageSize = 12;
  int _salesPage = 1;
  int _sessionsPage = 1;

  Future<_SalesPageData> _load() async {
    const document = r'''
      query SalesPage {
        sales { id status total customerId createdAt }
        openRegisterSessions { id registerId openingFloat openedAt }
        discountRules { id name type value }
        customers { id firstName lastName }
      }
    ''';
    final data = await widget.app.query(document);
    final customers = <String, String>{};
    for (final c in data['customers'] as List<dynamic>? ?? []) {
      final m = c as Map<String, dynamic>;
      customers[m['id'] as String] = '${m['firstName']} ${m['lastName']}'.trim();
    }
    return _SalesPageData(
      sales: (data['sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      sessions: (data['openRegisterSessions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      rules: (data['discountRules'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      customerNames: customers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<_SalesPageData>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Sales',
                description: 'Sales history, register sessions, and discount rules.',
              ),
              Text('Open register sessions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              VentosSimpleTable(
                columns: const ['Session', 'Register', 'Opened', 'Float'],
                rows: [
                  for (final s in paginateSlice(data.sessions, _sessionsPage, _pageSize))
                    [
                      Text(moduleShortId(s['id'] as String), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      Text(moduleShortId(s['registerId'] as String)),
                      Text(moduleFormatDateTime(s['openedAt'] as String)),
                      Text(moduleFormatMoney((s['openingFloat'] as num).toDouble()), textAlign: TextAlign.end),
                    ],
                ],
                emptyMessage: 'No open register sessions.',
              ),
              VentosPaginationBar(
                page: _sessionsPage,
                totalPages: paginateTotalPages(data.sessions.length, _pageSize),
                onPageChanged: (p) => setState(() => _sessionsPage = p),
              ),
              const SizedBox(height: 24),
              Text('All sales', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              VentosSimpleTable(
                columns: const ['Date', 'Sale', 'Customer', 'Status', 'Total', ''],
                rows: [
                  for (final s in paginateSlice(data.sales, _salesPage, _pageSize))
                    [
                      Text(moduleFormatDateTime(s['createdAt'] as String)),
                      Text(moduleShortId(s['id'] as String), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      Text(data.customerNames[s['customerId']] ?? '—'),
                      VentosBadge(label: s['status'] as String? ?? ''),
                      Text(moduleFormatMoney((s['total'] as num).toDouble()), textAlign: TextAlign.end),
                      TableRowActions(
                        onView: () => SaleViewSheet.open(
                          context: context,
                          pos: widget.pos,
                          saleId: s['id'] as String,
                          formatMoney: moduleFormatMoney,
                          initialCustomerNames: data.customerNames,
                        ),
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _salesPage,
                totalPages: paginateTotalPages(data.sales.length, _pageSize),
                onPageChanged: (p) => setState(() => _salesPage = p),
              ),
              const SizedBox(height: 24),
              Text('Discount rules', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              VentosSimpleTable(
                columns: const ['Name', 'Type', 'Value'],
                rows: [
                  for (final r in data.rules)
                    [
                      Text(r['name'] as String? ?? ''),
                      Text(r['type'] as String? ?? ''),
                      Text('${r['value']}'),
                    ],
                ],
                emptyMessage: 'No discount rules configured.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesPageData {
  _SalesPageData({
    required this.sales,
    required this.sessions,
    required this.rules,
    required this.customerNames,
  });

  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> rules;
  final Map<String, String> customerNames;
}
