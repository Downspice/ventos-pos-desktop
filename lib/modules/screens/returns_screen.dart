import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/pos/process_return_drawer.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  static const _pageSize = 12;
  int _page = 1;

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query ReturnsSales {
        sales(status: "FINALIZED") {
          id total createdAt
          lines { lineType productId name quantity unitPrice lineTotal }
        }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> _processReturn(Map<String, dynamic> sale, VoidCallback onSaved) async {
    final ok = await showProcessReturnDrawer(context: context, app: widget.app, sale: sale);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return processed.')));
      onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<List<Map<String, dynamic>>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, sales, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Returns & refunds',
                description: 'Process returns against finalized sales.',
              ),
              VentosSimpleTable(
                columns: const ['Date', 'Sale', 'Items', 'Total', ''],
                rows: [
                  for (final s in paginateSlice(sales, _page, _pageSize))
                    [
                      Text(moduleFormatDateTime(s['createdAt'] as String)),
                      Text(moduleShortId(s['id'] as String), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      Text('${(s['lines'] as List?)?.length ?? 0}', textAlign: TextAlign.end),
                      Text(moduleFormatMoney((s['total'] as num).toDouble()), textAlign: TextAlign.end),
                      Align(
                        alignment: Alignment.centerRight,
                        child: VentosButton(
                          onPressed: () => _processReturn(s, reload),
                          child: const Text('Return'),
                        ),
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(sales.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}
