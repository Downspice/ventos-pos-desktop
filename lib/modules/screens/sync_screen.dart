import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query SyncPending {
        syncQueuePending { id entityType entityId operation }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['syncQueuePending'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<List<Map<String, dynamic>>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, pending, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Offline sync',
                description: 'Server-side sync queue (desktop offline outbox coming later).',
              ),
              VentosSimpleTable(
                columns: const ['Entity', 'ID', 'Operation'],
                rows: [
                  for (final p in pending)
                    [
                      Text(p['entityType'] as String? ?? ''),
                      Text(p['entityId'] as String? ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      Text(p['operation'] as String? ?? ''),
                    ],
                ],
                emptyMessage: 'No pending sync items on the server.',
              ),
            ],
          ),
        );
      },
    );
  }
}
