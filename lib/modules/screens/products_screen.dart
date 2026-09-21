import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/product_list_filters.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/common/ventos_table.dart';
import 'package:ventos_pos/widgets/products/product_metadata_editor.dart';
import 'package:ventos_pos/widgets/products/product_with_image.dart';
import 'package:ventos_pos/widgets/products/show_product_form_drawer.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
    required this.app,
    this.reloadKey = 0,
    this.permissions = const {},
  });

  final AppRepository app;
  final int reloadKey;
  final Set<String> permissions;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const _pageSize = 12;
  int _page = 1;
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String _search = '';
  Set<String> _filterTypeIds = {};
  Set<String> _filterMetadata = {};
  String _minPrice = '';
  String _maxPrice = '';

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _searchController.clear();
      _filterTypeIds = {};
      _filterMetadata = {};
      _minPrice = '';
      _maxPrice = '';
      _minPriceController.clear();
      _maxPriceController.clear();
      _page = 1;
    });
  }

  List<Map<String, dynamic>> _filterProducts(
    List<Map<String, dynamic>> products,
    List<ProductMetadataFieldDef> allFields,
    Map<String, String> typeNames,
  ) {
    return products
        .where(
          (p) => productMatchesListFilters(
            p,
            search: _search,
            typeIds: _filterTypeIds,
            metadataValues: _filterMetadata,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            typeNames: typeNames,
            allFields: allFields,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> _load() async {
    const document = r'''
      query ProductsPage {
        products {
          id name sku barcode price cost isActive imageUrl categoryId productTypeId
          trackInventory metadata expiryDate discountType discountValue
        }
        productCategories { id name }
        productTypes(includeInactive: false) { id name }
        productMetadataFields {
          id productTypeId key label valueType unit options active
        }
      }
    ''';
    return widget.app.query(document);
  }

  List<Map<String, dynamic>> _products(Map<String, dynamic> data) =>
      (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

  List<ProductMetadataFieldDef> _metadataFields(Map<String, dynamic> data) =>
      (data['productMetadataFields'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProductMetadataFieldDef.fromJson)
          .where((f) => f.active)
          .toList();

  Map<String, String> _typeNames(Map<String, dynamic> data) {
    final types = (data['productTypes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return {for (final t in types) t['id'] as String: t['name'] as String? ?? ''};
  }

  List<String> _metadataTags(Map<String, dynamic> product, List<ProductMetadataFieldDef> allFields) {
    final meta = (product['metadata'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    final typeId = product['productTypeId'] as String?;
    final fields = allFields.where((f) => typeId == null || f.productTypeId == typeId);
    final tags = <String>[];
    final knownKeys = fields.map((f) => f.key).toSet();
    for (final f in fields) {
      final v = meta[f.key]?.trim();
      if (v == null || v.isEmpty) continue;
      final unit = f.unit?.trim();
      tags.add(unit != null && unit.isNotEmpty ? '$v $unit' : v);
    }
    for (final entry in meta.entries) {
      if (!knownKeys.contains(entry.key) && entry.value.trim().isNotEmpty) {
        tags.add(entry.value.trim());
      }
    }
    return tags;
  }

  Widget _metadataCell(BuildContext context, Map<String, dynamic> product, List<ProductMetadataFieldDef> allFields) {
    final tags = _metadataTags(product, allFields);
    if (tags.isEmpty) {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in tags)
          VentosBadge(
            label: tag,
            variant: VentosBadgeVariant.gray,
            dense: true,
          ),
      ],
    );
  }

  Future<void> _openForm({
    required Map<String, dynamic> catalog,
    Map<String, dynamic>? existing,
    required VoidCallback reload,
  }) async {
    final saved = await showProductFormDrawer(
      context: context,
      app: widget.app,
      catalog: catalog,
      existing: existing,
      permissions: widget.permissions,
    );
    if (saved == true) {
      setState(() => _page = 1);
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<Map<String, dynamic>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        final products = _products(data);
        final allFields = _metadataFields(data);
        final typeNames = _typeNames(data);
        final filtered = _filterProducts(products, allFields, typeNames);
        final metadataOptions = collectMetadataFilterOptions(products, allFields);
        final typeItems = typeNames.entries
            .map((e) => VentosComboboxItem(value: e.key, label: e.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
        final metadataItems = metadataOptions
            .map((v) => VentosComboboxItem(value: v, label: v))
            .toList();
        final filtersActive = hasActiveProductListFilters(
          search: _search,
          typeIds: _filterTypeIds,
          metadataValues: _filterMetadata,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );

        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Products',
                description: 'Catalog, SKUs, barcodes, and type-specific attributes.',
                actions: VentosNewButton(
                  label: 'New product',
                  onPressed: () => _openForm(catalog: data, reload: reload),
                ),
              ),
              VentosTableToolbar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: 280,
                          child: VentosTextField(
                            controller: _searchController,
                            hintText: 'Search name, SKU, barcode, type, attributes…',
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            onChanged: (v) => setState(() {
                              _search = v;
                              _page = 1;
                            }),
                          ),
                        ),
                        SizedBox(
                          width: 176,
                          child: VentosMultiCombobox<String>(
                            label: 'Type',
                            placeholder: 'All types',
                            items: typeItems,
                            values: _filterTypeIds,
                            enabled: typeItems.isNotEmpty,
                            onChanged: (next) => setState(() {
                              _filterTypeIds = next;
                              _page = 1;
                            }),
                          ),
                        ),
                        SizedBox(
                          width: 192,
                          child: VentosMultiCombobox<String>(
                            label: 'Metadata',
                            placeholder: 'All attributes',
                            items: metadataItems,
                            values: _filterMetadata,
                            enabled: metadataItems.isNotEmpty,
                            onChanged: (next) => setState(() {
                              _filterMetadata = next;
                              _page = 1;
                            }),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: VentosTextField(
                            label: 'Min price',
                            controller: _minPriceController,
                            hintText: 'Any',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() {
                              _minPrice = v;
                              _page = 1;
                            }),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: VentosTextField(
                            label: 'Max price',
                            controller: _maxPriceController,
                            hintText: 'Any',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() {
                              _maxPrice = v;
                              _page = 1;
                            }),
                          ),
                        ),
                        if (filtersActive)
                          VentosButton(
                            variant: VentosButtonVariant.ghost,
                            size: VentosButtonSize.sm,
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                    if (filtersActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${filtered.length} of ${products.length} products',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              VentosSimpleTable(
                columns: const ['Product', 'Barcode', 'Metadata', 'Price', ''],
                rows: [
                  for (final p in paginateSlice(filtered, _page, _pageSize))
                    [
                      ProductWithImage(
                        name: p['name'] as String? ?? '',
                        imageUrl: p['imageUrl'] as String?,
                        subtitle: p['sku'] as String?,
                      ),
                      Text(p['barcode'] as String? ?? '—'),
                      _metadataCell(context, p, allFields),
                      Text(moduleFormatMoney((p['price'] as num?)?.toDouble() ?? 0)),
                      TableRowActions(
                        onView: () => showProductViewSheet(
                          context: context,
                          product: p,
                          allMetadataFields: allFields,
                          typeNames: typeNames,
                          formatMoney: moduleFormatMoney,
                        ),
                        onEdit: () => _openForm(catalog: data, existing: p, reload: reload),
                        deleteTitle: 'Delete product',
                        itemName: p['name'] as String? ?? 'Product',
                        onDelete: () => widget.app.mutate(
                          r'mutation DeleteProduct($id: ID!) { deleteProduct(id: $id) }',
                          {'id': p['id']},
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
