import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/list_search.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/common/ventos_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ProductTypesScreen extends StatefulWidget {
  const ProductTypesScreen({
    super.key,
    required this.app,
    this.reloadKey = 0,
    this.onOpenMetadataFields,
  });

  final AppRepository app;
  final int reloadKey;
  final void Function(String productTypeId)? onOpenMetadataFields;

  @override
  State<ProductTypesScreen> createState() => _ProductTypesScreenState();
}

class _ProductTypesScreenState extends State<ProductTypesScreen> {
  static const _pageSize = 12;
  int _page = 1;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query ProductTypesPage {
        productTypes(includeInactive: true) {
          id name description sortOrder active
        }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['productTypes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> _seed(VoidCallback reload) async {
    await widget.app.mutate(r'''
      mutation SeedProductMetadataFields {
        seedProductMetadataFields
      }
    ''', {});
    reload();
  }

  Future<void> _showView(Map<String, dynamic> row) async {
    await showVentosFormDrawer(
      context: context,
      title: 'Product type',
      readOnly: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _readOnlyField('Name', row['name'] as String? ?? ''),
          const SizedBox(height: 12),
          _readOnlyField('Description', row['description'] as String? ?? '—'),
          const SizedBox(height: 12),
          _readOnlyField('Sort order', '${row['sortOrder'] ?? 0}'),
          const SizedBox(height: 12),
          _readOnlyField('Active', (row['active'] as bool? ?? true) ? 'Yes' : 'No'),
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
    final sortOrder = TextEditingController(text: '${existing?['sortOrder'] ?? 0}');
    var active = existing?['active'] as bool? ?? true;

    final saved = await showVentosFormDrawer(
      context: context,
      title: existing == null ? 'New product type' : 'Edit product type',
      description: 'Types group products and define which metadata fields apply.',
      submitLabel: existing == null ? 'Create type' : 'Save changes',
      body: StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VentosTextField(controller: name, label: 'Name'),
              const SizedBox(height: 16),
              VentosTextField(controller: description, label: 'Description'),
              const SizedBox(height: 16),
              VentosTextField(
                controller: sortOrder,
                label: 'Sort order',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: active,
                onChanged: (v) => setLocal(() => active = v),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        if (name.text.trim().isEmpty) throw Exception('Name is required.');
        final input = {
          'name': name.text.trim(),
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
          'sortOrder': int.tryParse(sortOrder.text.trim()) ?? 0,
          'active': active,
        };
        if (existing == null) {
          await widget.app.mutate(r'''
            mutation CreateProductType($input: ProductTypeInput!) {
              createProductType(input: $input) { id }
            }
          ''', {'input': input});
        } else {
          await widget.app.mutate(r'''
            mutation UpdateProductType($id: ID!, $input: ProductTypeUpdateInput!) {
              updateProductType(id: $id, input: $input) { id }
            }
          ''', {'id': existing['id'], 'input': input});
        }
      },
    );

    name.dispose();
    description.dispose();
    sortOrder.dispose();

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
      builder: (context, types, reload) {
        final filtered = types
            .where(
              (t) => matchesListSearch(_search, [
                t['name'] as String?,
                t['description'] as String?,
                '${t['sortOrder']}',
              ]),
            )
            .toList();
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Product types',
                description: 'Beverage, food, cosmetic, etc. Metadata fields attach to each type.',
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VentosButton(
                      variant: VentosButtonVariant.outline,
                      onPressed: () => _seed(reload),
                      child: const Text('Suggested types & fields'),
                    ),
                    const SizedBox(width: 8),
                    VentosNewButton(
                      label: 'New type',
                      onPressed: () => _openForm(onSaved: reload),
                    ),
                  ],
                ),
              ),
              VentosTableToolbar(
                child: VentosTextField(
                  controller: _searchController,
                  hintText: 'Search type name or description…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  }),
                ),
              ),
              VentosSimpleTable(
                columns: const ['Name', 'Description', 'Order', 'Active', ''],
                columnSpecs: const [
                  VentosTableColumn(label: 'Name', flex: 1),
                  VentosTableColumn(label: 'Description', flex: 1.2),
                  VentosTableColumn(label: 'Order', fixedWidth: 64),
                  VentosTableColumn(label: 'Active', fixedWidth: 72),
                  VentosTableColumn(
                    label: '',
                    fixedWidth: 220,
                    isActions: true,
                    textAlign: TextAlign.right,
                  ),
                ],
                minWidth: 820,
                rows: [
                  for (final t in paginateSlice(filtered, _page, _pageSize))
                    [
                      Text(t['name'] as String? ?? ''),
                      Text(t['description'] as String? ?? '—'),
                      Text('${t['sortOrder'] ?? 0}'),
                      VentosBadge(label: (t['active'] as bool? ?? true) ? 'Yes' : 'No'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.onOpenMetadataFields != null)
                            VentosButton(
                              variant: VentosButtonVariant.outline,
                              size: VentosButtonSize.sm,
                              onPressed: () => widget.onOpenMetadataFields!(
                                t['id'] as String,
                              ),
                              child: const Text('Fields'),
                            ),
                          if (widget.onOpenMetadataFields != null) const SizedBox(width: 4),
                          TableRowActions(
                            onView: () => _showView(t),
                            onEdit: () => _openForm(existing: t, onSaved: reload),
                            deleteTitle: 'Delete product type',
                            deleteDescription:
                                'Cannot delete if products still use this type. Metadata fields for this type are removed.',
                            itemName: t['name'] as String? ?? 'Type',
                            onDelete: () => widget.app.mutate(
                              r'mutation DeleteProductType($id: ID!) { deleteProductType(id: $id) }',
                              {'id': t['id']},
                            ),
                            onDeleted: reload,
                          ),
                        ],
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(filtered.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}
