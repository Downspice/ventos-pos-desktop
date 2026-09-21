import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/list_search.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/common/ventos_table.dart';
import 'package:ventos_pos/widgets/products/show_product_metadata_field_drawer.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ProductMetadataScreen extends StatefulWidget {
  const ProductMetadataScreen({
    super.key,
    required this.app,
    this.reloadKey = 0,
    this.initialProductTypeId,
    this.onInitialProductTypeIdApplied,
  });

  final AppRepository app;
  final int reloadKey;
  final String? initialProductTypeId;
  final VoidCallback? onInitialProductTypeIdApplied;

  @override
  State<ProductMetadataScreen> createState() => _ProductMetadataScreenState();
}

class _ProductMetadataScreenState extends State<ProductMetadataScreen> {
  static const _allProductTypesFilter = '';
  static const _pageSize = 12;
  int _page = 1;
  String? _productTypeId;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _productTypeId = widget.initialProductTypeId;
    if (widget.initialProductTypeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialProductTypeIdApplied?.call();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<({List<Map<String, dynamic>> types, List<Map<String, dynamic>> fields})> _load() async {
    const document = r'''
      query ProductMetadataPage($productTypeId: ID) {
        productTypes(includeInactive: true) { id name }
        productMetadataFields(includeInactive: true, productTypeId: $productTypeId) {
          id productTypeId key label valueType unit options sortOrder active
        }
      }
    ''';
    final data = await widget.app.query(document, {
      if (_productTypeId != null) 'productTypeId': _productTypeId,
    });
    final types = (data['productTypes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final fields =
        (data['productMetadataFields'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return (types: types, fields: fields);
  }

  Future<void> _seed(VoidCallback reload) async {
    await widget.app.mutate(r'''
      mutation SeedProductMetadataFields {
        seedProductMetadataFields
      }
    ''', {});
    reload();
  }

  Future<void> _openFieldForm({
    required String productTypeId,
    Map<String, dynamic>? existing,
    required VoidCallback reload,
  }) async {
    final saved = await showProductMetadataFieldDrawer(
      context: context,
      app: widget.app,
      productTypeId: productTypeId,
      existing: existing,
    );
    if (saved == true) {
      setState(() => _page = 1);
      reload();
    }
  }

  Future<void> _viewField(Map<String, dynamic> row) async {
    await showVentosFormDrawer(
      context: context,
      title: 'Metadata field',
      readOnly: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Label: ${row['label']}'),
          const SizedBox(height: 8),
          Text('Key: ${row['key']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          const SizedBox(height: 8),
          Text('Field type: ${row['valueType']}'),
          const SizedBox(height: 8),
          Text('Unit: ${row['unit'] ?? '—'}'),
          const SizedBox(height: 8),
          Text('Options: ${(row['options'] as List<dynamic>? ?? []).join(', ')}'),
          const SizedBox(height: 8),
          Text('Sort order: ${row['sortOrder']}'),
          const SizedBox(height: 8),
          Text('Active: ${(row['active'] as bool? ?? true) ? 'Yes' : 'No'}'),
        ],
      ),
      onSubmit: () async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<({List<Map<String, dynamic>> types, List<Map<String, dynamic>> fields})>(
      key: ValueKey('${_productTypeId ?? ''}-${widget.reloadKey}'),
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        final types = data.types;
        final fields = data.fields;
        final typeNameById = {
          for (final t in types) t['id'] as String: t['name'] as String? ?? '',
        };
        final filtered = fields.where((f) {
          final opts = (f['options'] as List<dynamic>? ?? []).join(', ');
          final typeName = typeNameById[f['productTypeId'] as String?];
          return matchesListSearch(_search, [
            f['label'] as String?,
            f['key'] as String?,
            f['valueType'] as String?,
            f['unit'] as String?,
            opts,
            typeName,
          ]);
        }).toList();
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Metadata fields',
                description: 'Attributes per product type, shown when creating products.',
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (types.isNotEmpty)
                      SizedBox(
                        width: 180,
                        child: VentosSelect<String>(
                          value: _productTypeId ?? _allProductTypesFilter,
                          hint: 'Product type',
                          entries: [
                            const VentosSelectEntry(
                              value: _allProductTypesFilter,
                              label: 'All types',
                            ),
                            for (final t in types)
                              VentosSelectEntry(
                                value: t['id'] as String,
                                label: t['name'] as String? ?? '',
                              ),
                          ],
                          onChanged: (id) => setState(() {
                            _productTypeId =
                                id == null || id == _allProductTypesFilter ? null : id;
                            _page = 1;
                          }),
                        ),
                      ),
                    if (types.isNotEmpty) const SizedBox(width: 8),
                    VentosButton(
                      variant: VentosButtonVariant.outline,
                      onPressed: () => _seed(reload),
                      child: const Text('Suggested types & fields'),
                    ),
                    const SizedBox(width: 8),
                    if (_productTypeId != null)
                      VentosNewButton(
                        label: 'New field',
                        onPressed: () => _openFieldForm(
                          productTypeId: _productTypeId!,
                          reload: reload,
                        ),
                      )
                    else
                      VentosButton(
                        onPressed: null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 18),
                            SizedBox(width: 6),
                            Text('New field'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              VentosTableToolbar(
                child: VentosTextField(
                  controller: _searchController,
                  hintText: 'Search label, key, field type, unit…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  }),
                ),
              ),
              VentosSimpleTable(
                columns: const [
                  'Label',
                  'Key',
                  'Product type',
                  'Field type',
                  'Unit',
                  'Active',
                  '',
                ],
                rows: [
                  for (final f in paginateSlice(filtered, _page, _pageSize))
                    [
                      Text(f['label'] as String? ?? ''),
                      Text(
                        f['key'] as String? ?? '',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      Text(
                        typeNameById[f['productTypeId'] as String?] ?? '—',
                      ),
                      Text(f['valueType'] as String? ?? ''),
                      Text(f['unit'] as String? ?? '—'),
                      VentosBadge(label: (f['active'] as bool? ?? true) ? 'Yes' : 'No'),
                      TableRowActions(
                        onView: () => _viewField(f),
                        onEdit: () {
                          final typeId = f['productTypeId'] as String?;
                          if (typeId == null) return;
                          _openFieldForm(
                            productTypeId: typeId,
                            existing: f,
                            reload: reload,
                          );
                        },
                        deleteTitle: 'Delete metadata field',
                        itemName: f['label'] as String? ?? 'Field',
                        onDelete: () => widget.app.mutate(
                          r'mutation DeleteProductMetadataField($id: ID!) { deleteProductMetadataField(id: $id) }',
                          {'id': f['id']},
                        ),
                        onDeleted: reload,
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
