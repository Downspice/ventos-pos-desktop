import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/products/product_metadata_editor.dart';
import 'package:ventos_pos/utils/macos_image_pick_pending.dart';
import 'package:ventos_pos/widgets/common/entity_image_field.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

const _stepLabels = ['General', 'Attributes', 'Expiry & discounts'];

Future<bool?> showProductFormDrawer({
  required BuildContext context,
  required AppRepository app,
  required Map<String, dynamic> catalog,
  Map<String, dynamic>? existing,
  Set<String>? permissions,
}) {
  return showVentosEndSheet<bool>(
    context: context,
    width: 480,
    child: _ProductFormDrawer(
      key: ValueKey('product-form-v3-${existing?['id'] ?? 'new'}'),
      app: app,
      catalog: catalog,
      existing: existing,
      permissions: permissions,
    ),
  );
}

Future<void> showProductViewSheet({
  required BuildContext context,
  required Map<String, dynamic> product,
  required List<ProductMetadataFieldDef> allMetadataFields,
  required Map<String, String> typeNames,
  required String Function(double) formatMoney,
}) {
  final typeId = product['productTypeId'] as String?;
  final typeName = typeId != null ? (typeNames[typeId] ?? '—') : '—';
  final meta = (product['metadata'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ) ??
      {};
  final fieldsForProduct = allMetadataFields
      .where((f) => typeId == null || f.productTypeId == typeId)
      .toList();
  final attrTags = <String>[];
  for (final f in fieldsForProduct) {
    final v = meta[f.key]?.trim();
    if (v == null || v.isEmpty) continue;
    final unit = f.unit?.trim();
    attrTags.add(unit != null && unit.isNotEmpty ? '$v $unit' : v);
  }

  return showVentosEndSheet<void>(
    context: context,
    width: 440,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                product['name'] as String? ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: VentosColors.mutedForeground),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: EntityImage(
                  imageUrl: product['imageUrl'] as String?,
                  alt: product['name'] as String? ?? 'Product',
                  width: 96,
                  height: 96,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(height: 16),
              _viewRow('Product type', typeName),
              _viewRow('SKU', product['sku'] as String? ?? '—'),
              _viewRow('Barcode', product['barcode'] as String? ?? '—'),
              _viewRow('Price', formatMoney((product['price'] as num?)?.toDouble() ?? 0)),
              _viewRow('Cost', formatMoney((product['cost'] as num?)?.toDouble() ?? 0)),
              _viewRow('Track inventory', (product['trackInventory'] as bool? ?? true) ? 'Yes' : 'No'),
              if (attrTags.isEmpty)
                _viewRow('Attributes', '—')
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attributes',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: VentosColors.mutedForeground,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final tag in attrTags)
                            VentosBadge(label: tag, variant: VentosBadgeVariant.gray, dense: true),
                        ],
                      ),
                    ],
                  ),
                ),
              _viewRow('Expiry', product['expiryDate'] as String? ?? '—'),
              _viewRow('Discount', _discountLabel(product, formatMoney)),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: VentosButton(
              variant: VentosButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _viewRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: VentosColors.mutedForeground)),
        const SizedBox(height: 2),
        Text(value),
      ],
    ),
  );
}

String _discountLabel(Map<String, dynamic> product, String Function(double) formatMoney) {
  final type = product['discountType'] as String? ?? 'NONE';
  final value = (product['discountValue'] as num?)?.toDouble() ?? 0;
  if (type == 'NONE' || value == 0) return '—';
  if (type == 'PERCENT') return '$value% off';
  return '${formatMoney(value)} off';
}

class _ProductFormDrawer extends StatefulWidget {
  const _ProductFormDrawer({
    super.key,
    required this.app,
    required this.catalog,
    this.existing,
    this.permissions,
  });

  final AppRepository app;
  final Map<String, dynamic> catalog;
  final Map<String, dynamic>? existing;
  final Set<String>? permissions;

  Set<String> get _permissions => permissions ?? const {};

  @override
  State<_ProductFormDrawer> createState() => _ProductFormDrawerState();
}

class _ProductFormDrawerState extends State<_ProductFormDrawer> {
  int _step = 0;
  bool _submitting = false;
  String? _error;

  late final TextEditingController _barcode;
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _expiryDate;
  String _productImageUrl = '';
  late final TextEditingController _discountValue;

  String? _productTypeId;
  String? _categoryId;
  bool _trackInventory = true;
  String _discountType = 'NONE';
  Map<String, String> _metadata = {};

  List<Map<String, dynamic>> get _types =>
      (widget.catalog['productTypes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _categories =>
      (widget.catalog['productCategories'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  List<ProductMetadataFieldDef> get _allFields =>
      (widget.catalog['productMetadataFields'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProductMetadataFieldDef.fromJson)
          .where((f) => f.active)
          .toList();

  List<ProductMetadataFieldDef> get _fieldsForType => _allFields
      .where((f) => _productTypeId == null || f.productTypeId == _productTypeId)
      .toList();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _barcode = TextEditingController(text: e?['barcode'] as String? ?? '');
    _name = TextEditingController(text: e?['name'] as String? ?? '');
    _sku = TextEditingController(text: e?['sku'] as String? ?? '');
    _price = TextEditingController(text: e != null ? '${e['price']}' : '0');
    _cost = TextEditingController(text: e != null ? '${e['cost'] ?? 0}' : '0');
    _productImageUrl =
        MacImagePickPending.takeImageUrlForReopenedForm() ?? e?['imageUrl'] as String? ?? '';
    _expiryDate = TextEditingController(text: e?['expiryDate'] as String? ?? '');
    _discountType = e?['discountType'] as String? ?? 'NONE';
    final disc = (e?['discountValue'] as num?)?.toDouble();
    _discountValue = TextEditingController(
      text: _discountType != 'NONE' && disc != null ? '$disc' : '',
    );
    _productTypeId = e?['productTypeId'] as String?;
    _categoryId = e?['categoryId'] as String?;
    _trackInventory = e?['trackInventory'] as bool? ?? true;
    final rawMeta = e?['metadata'];
    if (rawMeta is Map) {
      _metadata = rawMeta.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (_productTypeId == null && _types.isNotEmpty) {
      _productTypeId = _types.first['id'] as String?;
    }
  }

  @override
  void dispose() {
    _barcode.dispose();
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _cost.dispose();
    _expiryDate.dispose();
    _discountValue.dispose();
    super.dispose();
  }

  bool _canAdvance(int step) {
    if (step == 0) {
      final typeOk = _types.isEmpty || (_productTypeId != null && _productTypeId!.isNotEmpty);
      final price = double.tryParse(_price.text.trim()) ?? -1;
      return typeOk && _name.text.trim().isNotEmpty && price >= 0;
    }
    if (step == 1) return true;
    if (_discountType == 'PERCENT') {
      final v = double.tryParse(_discountValue.text.trim());
      if (_discountValue.text.trim().isEmpty) return true;
      return v != null && v >= 0 && v <= 100;
    }
    return true;
  }

  Map<String, dynamic> _toInput() {
    final discountValue = _discountType == 'NONE'
        ? 0
        : (double.tryParse(_discountValue.text.trim()) ?? 0);
    return {
      'name': _name.text.trim(),
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'barcode': _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'cost': double.tryParse(_cost.text.trim()) ?? 0,
      'categoryId': _categoryId,
      'productTypeId': _productTypeId,
      'trackInventory': _trackInventory,
      'imageUrl': _productImageUrl.trim().isEmpty ? null : _productImageUrl.trim(),
      'metadata': _metadata.isEmpty ? null : _metadata,
      'expiryDate': _expiryDate.text.trim().isEmpty ? null : _expiryDate.text.trim(),
      'discountType': _discountType,
      if (_discountType != 'NONE') 'discountValue': discountValue,
    };
  }

  Future<void> _generateBarcode() async {
    final id = widget.existing?['id'] as String?;
    if (id == null) return;
    final data = await widget.app.mutate(r'''
      mutation Barcode($id: ID!) {
        generateProductBarcode(id: $id) { barcode }
      }
    ''', {'id': id});
    final code = data['generateProductBarcode']?['barcode'] as String?;
    if (code != null) setState(() => _barcode.text = code);
  }

  Future<void> _submit() async {
    if (!_canAdvance(2)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final input = _toInput();
      if (widget.existing == null) {
        await widget.app.mutate(r'''
          mutation CreateProduct($input: ProductInput!) {
            createProduct(input: $input) { id }
          }
        ''', {'input': input});
      } else {
        await widget.app.mutate(r'''
          mutation UpdateProduct($id: ID!, $input: ProductInput!) {
            updateProduct(id: $id, input: $input) { id }
          }
        ''', {'id': widget.existing!['id'], 'input': input});
      }
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

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_expiryDate.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      _expiryDate.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step >= _stepLabels.length - 1;
    final title = widget.existing == null ? 'New product' : 'Edit product';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < _stepLabels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: i == _step
                                ? VentosColors.primary
                                : i < _step
                                    ? VentosColors.primary.withValues(alpha: 0.2)
                                    : VentosColors.muted,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: i == _step ? VentosColors.onPrimary : VentosColors.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepLabels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == 0
                ? _buildGeneralStep()
                : _step == 1
                    ? _buildAttributesStep()
                    : _buildExpiryStep(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_error!, style: const TextStyle(color: VentosColors.destructive, fontSize: 13)),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              VentosButton(
                variant: VentosButtonVariant.outline,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 8),
                VentosButton(
                  variant: VentosButtonVariant.outline,
                  onPressed: _submitting ? null : () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              ],
              const Spacer(),
              if (isLast)
                VentosButton(
                  onPressed: _submitting || !_canAdvance(2) ? null : _submit,
                  child: Text(_submitting ? 'Saving…' : (widget.existing == null ? 'Create product' : 'Save changes')),
                )
              else
                VentosButton(
                  onPressed: !_canAdvance(_step) ? null : () => setState(() => _step++),
                  child: const Text('Next'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_types.isNotEmpty) ...[
          VentosSelect<String>(
            label: 'Product type',
            value: _productTypeId,
            entries: [
              for (final t in _types)
                VentosSelectEntry(value: t['id'] as String, label: t['name'] as String? ?? ''),
            ],
            onChanged: (id) => setState(() {
              _productTypeId = id;
              _metadata = {};
            }),
          ),
          const SizedBox(height: 16),
        ],
        VentosTextField(controller: _barcode, label: 'UPC / barcode'),
        if (widget.existing != null && _barcode.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: VentosButton(
              variant: VentosButtonVariant.link,
              onPressed: _generateBarcode,
              child: const Text('Generate barcode'),
            ),
          ),
        const SizedBox(height: 16),
        VentosTextField(controller: _name, label: 'Name'),
        const SizedBox(height: 16),
        VentosTextField(controller: _sku, label: 'SKU'),
        const SizedBox(height: 16),
        EntityImageField(
          app: widget.app,
          value: _productImageUrl,
          onChanged: (url) {
            _productImageUrl = url;
            if (mounted) setState(() {});
          },
          libraryEntityType: 'PRODUCT',
          canReadLibrary: widget._permissions.contains('media.read'),
          canUploadLibrary: widget._permissions.contains('media.manage'),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          VentosSelect<String>(
            label: 'Category',
            value: _categoryId,
            hint: 'None',
            entries: [
              for (final c in _categories)
                VentosSelectEntry(value: c['id'] as String, label: c['name'] as String? ?? ''),
            ],
            onChanged: (id) => setState(() => _categoryId = id),
          ),
        ],
        const SizedBox(height: 16),
        VentosTextField(
          controller: _price,
          label: 'Price',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        VentosTextField(
          controller: _cost,
          label: 'Cost',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Track inventory'),
          value: _trackInventory,
          onChanged: (v) => setState(() => _trackInventory = v),
        ),
      ],
    );
  }

  Widget _buildAttributesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Optional attributes for the selected product type.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.mutedForeground),
        ),
        const SizedBox(height: 16),
        ProductMetadataEditor(
          fields: _fieldsForType,
          values: _metadata,
          onChanged: (m) => setState(() => _metadata = m),
        ),
      ],
    );
  }

  Widget _buildExpiryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VentosTextField(
          controller: _expiryDate,
          label: 'Expiry date (YYYY-MM-DD)',
          hintText: 'Leave empty if none',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: VentosButton(
            variant: VentosButtonVariant.link,
            onPressed: _pickExpiry,
            child: const Text('Pick date'),
          ),
        ),
        const SizedBox(height: 16),
        VentosSelect<String>(
          label: 'Product discount',
          value: _discountType,
          entries: const [
            VentosSelectEntry(value: 'NONE', label: 'No product discount'),
            VentosSelectEntry(value: 'PERCENT', label: 'Percent off price'),
            VentosSelectEntry(value: 'FIXED', label: 'Fixed amount off'),
          ],
          onChanged: (v) => setState(() {
            _discountType = v ?? 'NONE';
            if (_discountType == 'NONE') _discountValue.clear();
          }),
        ),
        if (_discountType == 'PERCENT') ...[
          const SizedBox(height: 16),
          VentosTextField(
            controller: _discountValue,
            label: 'Discount percent',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        if (_discountType == 'FIXED') ...[
          const SizedBox(height: 16),
          VentosTextField(
            controller: _discountValue,
            label: 'Amount off',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }
}
