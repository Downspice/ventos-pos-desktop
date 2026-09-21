import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _pageSize = 8;
  int _page = 1;

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query NotificationsPage {
        notifications { id title body readAt createdAt }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['notifications'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<List<Map<String, dynamic>>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, items, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Notifications',
                description: 'Alerts for stock, fraud, and system events.',
              ),
              for (final n in paginateSlice(items, _page, _pageSize))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VentosCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: n['readAt'] != null ? 0.65 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(n['body'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 6),
                                Text(moduleFormatDateTime(n['createdAt'] as String), style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ),
                        if (n['readAt'] == null)
                          VentosButton(
                            variant: VentosButtonVariant.outline,
                            onPressed: () async {
                              await widget.app.mutate(r'''
                                mutation MarkRead($id: ID!) { markNotificationRead(id: $id) { id } }
                              ''', {'id': n['id']});
                              reload();
                            },
                            child: const Text('Mark read'),
                          ),
                      ],
                    ),
                  ),
                ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(items.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}
