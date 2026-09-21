import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/products/product_with_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const _pageSize = 12;
  int _page = 1;

  Future<_InventoryData> _load() async {
    const document = r'''
      query InventoryView {
        products { id name barcode price imageUrl }
        stockLevels { id productId locationId quantity }
        locations { id name isDefault }
      }
    ''';
    final data = await widget.app.query(document);
    return _InventoryData(
      products: (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      levels: (data['stockLevels'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      locations: (data['locations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    );
  }

  double _qtyForProduct(_InventoryData data, String productId) {
    return data.levels
        .where((l) => l['productId'] == productId)
        .fold<double>(0, (s, l) => s + (l['quantity'] as num).toDouble());
  }

  Future<void> _openAdjustDrawer(_InventoryData data, {String? initialProductId, required VoidCallback onSaved}) async {
    final applied = await showVentosEndSheet<bool>(
      context: context,
      width: 448,
      child: _AdjustStockDrawer(
        app: widget.app,
        data: data,
        initialProductId: initialProductId,
      ),
    );
    if (applied == true) onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<_InventoryData>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Inventory',
                description: 'Stock levels and adjustments.',
                actions: VentosNewButton(
                  label: 'Adjust stock',
                  onPressed: () => _openAdjustDrawer(data, onSaved: reload),
                ),
              ),
              VentosSimpleTable(
                columns: const ['Product', 'Barcode', 'On hand', 'Price', ''],
                rows: [
                  for (final p in paginateSlice(data.products, _page, _pageSize))
                    [
                      ProductWithImage(
                        name: p['name'] as String? ?? '',
                        imageUrl: p['imageUrl'] as String?,
                      ),
                      Text(p['barcode'] as String? ?? '—'),
                      Text('${_qtyForProduct(data, p['id'] as String)}'),
                      Text(moduleFormatMoney((p['price'] as num?)?.toDouble() ?? 0)),
                      Tooltip(
                        message: 'Adjust stock',
                        child: VentosButton.icon(
                          onPressed: () => _openAdjustDrawer(
                            data,
                            initialProductId: p['id'] as String,
                            onSaved: reload,
                          ),
                          variant: VentosButtonVariant.outline,
                          size: VentosButtonSize.iconSm,
                          icon: LucideIcons.sliders_horizontal,
                        ),
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(data.products.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdjustStockDrawer extends StatefulWidget {
  const _AdjustStockDrawer({
    required this.app,
    required this.data,
    this.initialProductId,
  });

  final AppRepository app;
  final _InventoryData data;
  final String? initialProductId;

  @override
  State<_AdjustStockDrawer> createState() => _AdjustStockDrawerState();
}

class _AdjustStockDrawerState extends State<_AdjustStockDrawer> {
  late String? _productId;
  late String? _locationId;
  final _delta = TextEditingController(text: '1');
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _productId = widget.initialProductId ??
        (widget.data.products.isNotEmpty ? widget.data.products.first['id'] as String : null);
    final defaultLoc = widget.data.locations.cast<Map<String, dynamic>?>().firstWhere(
          (l) => l?['isDefault'] == true,
          orElse: () => widget.data.locations.isNotEmpty ? widget.data.locations.first : null,
        );
    _locationId = defaultLoc?['id'] as String?;
  }

  Map<String, dynamic>? get _selectedProduct {
    final id = _productId;
    if (id == null) return null;
    for (final p in widget.data.products) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  @override
  void dispose() {
    _delta.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final productId = _productId;
    final locationId = _locationId;
    final parsed = double.tryParse(_delta.text.trim());
    if (productId == null || locationId == null) {
      setState(() => _error = 'Select a product and location.');
      return;
    }
    if (parsed == null) {
      setState(() => _error = 'Enter a valid quantity change.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.app.mutate(r'''
        mutation Adjust($productId: ID!, $locationId: ID!, $quantityDelta: Float!) {
          adjustStock(productId: $productId, locationId: $locationId, quantityDelta: $quantityDelta) { id }
        }
      ''', {
        'productId': productId,
        'locationId': locationId,
        'quantityDelta': parsed,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adjust stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Increase or decrease on-hand quantity at a location.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(LucideIcons.x, size: 20),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedProduct case final p?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductWithImage(
                      name: p['name'] as String? ?? 'Product',
                      imageUrl: p['imageUrl'] as String?,
                    ),
                  ),
                VentosSelect<String>(
                  label: 'Product',
                  value: _productId,
                  hint: 'Select product',
                  entries: [
                    for (final p in widget.data.products)
                      VentosSelectEntry(value: p['id'] as String, label: p['name'] as String? ?? ''),
                  ],
                  onChanged: (v) => setState(() => _productId = v),
                ),
                const SizedBox(height: 16),
                VentosSelect<String>(
                  label: 'Location',
                  value: _locationId,
                  hint: 'Select location',
                  entries: [
                    for (final l in widget.data.locations)
                      VentosSelectEntry(value: l['id'] as String, label: l['name'] as String? ?? ''),
                  ],
                  onChanged: (v) => setState(() => _locationId = v),
                ),
                const SizedBox(height: 16),
                VentosTextField(
                  controller: _delta,
                  label: 'Quantity change',
                  hintText: 'Use negative values to reduce stock',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
                const SizedBox(height: 6),
                Text(
                  'Positive adds stock; negative removes it.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: VentosColors.destructive, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VentosButton(
                variant: VentosButtonVariant.outline,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              VentosButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Apply adjustment'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryData {
  _InventoryData({required this.products, required this.levels, required this.locations});

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> levels;
  final List<Map<String, dynamic>> locations;
}
