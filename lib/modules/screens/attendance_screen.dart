import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _pageSize = 10;
  int _page = 1;

  Future<Map<String, dynamic>> _load() async {
    const document = r'''
      query AttendancePage {
        attendanceRecords { id employeeId clockInAt clockOutAt }
        shifts { id employeeId startAt endAt }
        performanceMetrics { id employeeId salesTotal appointmentCount periodStart periodEnd }
      }
    ''';
    return widget.app.query(document);
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<Map<String, dynamic>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        final records = (data['attendanceRecords'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final metrics = (data['performanceMetrics'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Attendance',
                description: 'Clock in/out and team performance.',
                actions: Wrap(
                  spacing: 8,
                  children: [
                    VentosButton(
                      onPressed: () => widget.app.mutate(r'mutation { clockIn { id } }').then((_) => reload()),
                      child: const Text('Clock in'),
                    ),
                    VentosButton(
                      variant: VentosButtonVariant.outline,
                      onPressed: () => widget.app.mutate(r'mutation { clockOut { id } }').then((_) => reload()),
                      child: const Text('Clock out'),
                    ),
                  ],
                ),
              ),
              Text('Recent attendance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              VentosSimpleTable(
                columns: const ['Employee', 'Clock in', 'Clock out'],
                rows: [
                  for (final r in paginateSlice(records, _page, _pageSize))
                    [
                      Text(moduleShortId(r['employeeId'] as String)),
                      Text(moduleFormatDateTime(r['clockInAt'] as String)),
                      Text(r['clockOutAt'] != null ? moduleFormatDateTime(r['clockOutAt'] as String) : 'Open'),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(records.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
              const SizedBox(height: 24),
              Text('Performance metrics', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              VentosSimpleTable(
                columns: const ['Employee', 'Sales', 'Appointments', 'Period'],
                rows: [
                  for (final m in metrics)
                    [
                      Text(moduleShortId(m['employeeId'] as String)),
                      Text(moduleFormatMoney((m['salesTotal'] as num?)?.toDouble() ?? 0)),
                      Text('${m['appointmentCount'] ?? 0}'),
                      Text('${m['periodStart']} – ${m['periodEnd']}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                ],
                emptyMessage: 'No metrics yet.',
              ),
            ],
          ),
        );
      },
    );
  }
}
