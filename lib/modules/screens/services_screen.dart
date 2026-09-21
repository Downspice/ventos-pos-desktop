import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/common/entity_image_field.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({
    super.key,
    required this.app,
    this.reloadKey = 0,
    this.permissions = const {},
  });

  final AppRepository app;
  final int reloadKey;
  final Set<String> permissions;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _pageSize = 12;
  int _page = 1;

  bool get _canReadMedia => widget.permissions.contains('media.read');
  bool get _canManageMedia => widget.permissions.contains('media.manage');

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query ServicesPage {
        services {
          id name description durationMinutes price isActive imageUrl
        }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['services'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _serviceInput({
    required String name,
    required String description,
    required String duration,
    required String price,
    required String imageUrl,
  }) {
    final input = <String, dynamic>{
      'name': name.trim(),
      'durationMinutes': int.tryParse(duration.trim()) ?? 0,
      'price': double.tryParse(price.trim()) ?? 0,
    };
    final desc = description.trim();
    if (desc.isNotEmpty) input['description'] = desc;
    final img = imageUrl.trim();
    if (img.isNotEmpty) input['imageUrl'] = img;
    return input;
  }

  Future<void> _showView(Map<String, dynamic> row) async {
    await showVentosFormDrawer(
      context: context,
      title: 'Service',
      readOnly: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _readOnlyField('Name', row['name'] as String? ?? ''),
          const SizedBox(height: 12),
          _readOnlyField('Description', row['description'] as String? ?? '—'),
          const SizedBox(height: 12),
          _readOnlyField('Duration', '${row['durationMinutes'] ?? 0} min'),
          const SizedBox(height: 12),
          _readOnlyField('Price', moduleFormatMoney((row['price'] as num?)?.toDouble() ?? 0)),
          const SizedBox(height: 12),
          _readOnlyField('Status', (row['isActive'] as bool? ?? true) ? 'Active' : 'Inactive'),
        ],
      ),
      onSubmit: () async {},
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: VentosColors.mutedForeground)),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  Future<void> _openForm({
    Map<String, dynamic>? existing,
    required VoidCallback onSaved,
  }) async {
    final name = TextEditingController(text: existing?['name'] as String? ?? '');
    final description = TextEditingController(text: existing?['description'] as String? ?? '');
    final duration = TextEditingController(text: '${existing?['durationMinutes'] ?? 60}');
    final price = TextEditingController(text: '${existing?['price'] ?? 0}');
    var imageUrl = existing?['imageUrl'] as String? ?? '';

    final saved = await showVentosFormDrawer(
      context: context,
      title: existing == null ? 'New service' : 'Edit service',
      description: existing == null
          ? 'Add a bookable service to your catalog.'
          : 'Update service details and image.',
      submitLabel: existing == null ? 'Create service' : 'Save changes',
      body: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EntityImageField(
                app: widget.app,
                value: imageUrl,
                onChanged: (url) {
                  imageUrl = url;
                  setLocal(() {});
                },
                libraryEntityType: 'SERVICE',
                canReadLibrary: _canReadMedia,
                canUploadLibrary: _canManageMedia,
              ),
              const SizedBox(height: 16),
              VentosTextField(controller: name, label: 'Name'),
              const SizedBox(height: 16),
              VentosTextField(
                controller: description,
                label: 'Description',
                hintText: 'Optional',
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              VentosTextField(
                controller: duration,
                label: 'Duration (minutes)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              VentosTextField(
                controller: price,
                label: 'Price',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        if (name.text.trim().isEmpty) {
          throw StateError('Name is required');
        }
        final input = _serviceInput(
          name: name.text,
          description: description.text,
          duration: duration.text,
          price: price.text,
          imageUrl: imageUrl,
        );
        if ((input['durationMinutes'] as int) < 1) {
          throw StateError('Duration must be at least 1 minute');
        }
        if (existing == null) {
          await widget.app.mutate(
            r'mutation CreateService($input: ServiceInput!) { createService(input: $input) { id } }',
            {'input': input},
          );
        } else {
          await widget.app.mutate(
            r'mutation UpdateService($id: ID!, $input: ServiceInput!) { updateService(id: $id, input: $input) { id } }',
            {'id': existing['id'], 'input': input},
          );
        }
      },
    );

    if (saved == true) {
      setState(() => _page = 1);
      onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<List<Map<String, dynamic>>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, services, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Services',
                description: 'Bookable services, duration, and pricing.',
                actions: VentosNewButton(
                  label: 'New service',
                  onPressed: () => _openForm(onSaved: reload),
                ),
              ),
              VentosSimpleTable(
                columns: const ['Name', 'Duration', 'Price', 'Status', ''],
                rows: [
                  for (final s in paginateSlice(services, _page, _pageSize))
                    [
                      Text(s['name'] as String? ?? ''),
                      Text('${s['durationMinutes']} min'),
                      Text(moduleFormatMoney((s['price'] as num?)?.toDouble() ?? 0)),
                      VentosBadge(
                        label: (s['isActive'] as bool? ?? true) ? 'Active' : 'Inactive',
                        variant: VentosBadgeVariant.gray,
                        dense: true,
                      ),
                      TableRowActions(
                        onView: () => _showView(s),
                        onEdit: () => _openForm(existing: s, onSaved: reload),
                        deleteTitle: 'Delete service',
                        itemName: s['name'] as String? ?? 'Service',
                        onDelete: () => widget.app.mutate(
                          r'mutation DeleteService($id: ID!) { deleteService(id: $id) }',
                          {'id': s['id']},
                        ),
                        onDeleted: reload,
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(services.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}
