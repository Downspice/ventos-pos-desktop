import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Preset return reasons; last entry is custom (user types their own).
const kReturnReasonPresets = <String>[
  'Defective or damaged',
  'Wrong item',
  'Customer changed mind',
  'Expired or spoiled',
  'Not as described',
  '__custom__',
];

const _customReasonKey = '__custom__';

class _LineDraft {
  _LineDraft({
    required this.key,
    required this.productId,
    required this.name,
    required this.maxQty,
    required this.unitPrice,
    required this.lineTotal,
  })  : selected = false,
        returnQty = 1,
        refundAmount = _defaultRefund(unitPrice, 1, lineTotal, maxQty);

  final String key;
  final String productId;
  final String name;
  final double maxQty;
  final double unitPrice;
  final double lineTotal;
  bool selected;
  double returnQty;
  double refundAmount;
}

double _defaultRefund(double unitPrice, double qty, double lineTotal, double soldQty) {
  final perUnit = soldQty > 0 ? lineTotal / soldQty : unitPrice;
  return ((perUnit * qty * 100).round()) / 100;
}

String _lineKey(String productId, int index) => '$productId-$index';

Future<bool> showProcessReturnDrawer({
  required BuildContext context,
  required AppRepository app,
  required Map<String, dynamic> sale,
}) async {
  final result = await showVentosEndSheet<bool>(
    context: context,
    width: 520,
    child: _ProcessReturnDrawer(app: app, sale: sale),
  );
  return result == true;
}

class _ProcessReturnDrawer extends StatefulWidget {
  const _ProcessReturnDrawer({required this.app, required this.sale});

  final AppRepository app;
  final Map<String, dynamic> sale;

  @override
  State<_ProcessReturnDrawer> createState() => _ProcessReturnDrawerState();
}

class _ProcessReturnDrawerState extends State<_ProcessReturnDrawer> {
  late List<_LineDraft> _lines;
  final Map<String, String?> _imageByProductId = {};
  String _reasonPreset = kReturnReasonPresets.first;
  final _customReason = TextEditingController();
  String _kind = 'RETURN';
  String _stockDisposition = 'RESTOCK';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lines = _buildLineDrafts();
    _loadProductImages();
  }

  Future<void> _loadProductImages() async {
    try {
      final data = await widget.app.query(r'''
        query ReturnProductImages { products { id imageUrl } }
      ''');
      final products = (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        for (final p in products) {
          _imageByProductId[p['id'] as String] = p['imageUrl'] as String?;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _customReason.dispose();
    super.dispose();
  }

  List<_LineDraft> _buildLineDrafts() {
    final raw = (widget.sale['lines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final drafts = <_LineDraft>[];
    for (var i = 0; i < raw.length; i++) {
      final line = raw[i];
      if (line['lineType'] != 'PRODUCT') continue;
      final productId = line['productId'] as String?;
      if (productId == null) continue;
      drafts.add(
        _LineDraft(
          key: _lineKey(productId, i),
          productId: productId,
          name: line['name'] as String? ?? 'Product',
          maxQty: (line['quantity'] as num?)?.toDouble() ?? 0,
          unitPrice: (line['unitPrice'] as num?)?.toDouble() ?? 0,
          lineTotal: (line['lineTotal'] as num?)?.toDouble() ?? 0,
        ),
      );
    }
    return drafts;
  }

  List<_LineDraft> get _selected => _lines.where((l) => l.selected).toList();

  double get _totalRefund => _selected.fold<double>(0, (s, l) => s + l.refundAmount);

  String? get _resolvedReason {
    if (_reasonPreset == _customReasonKey) {
      final t = _customReason.text.trim();
      return t.isEmpty ? null : t;
    }
    return _reasonPreset;
  }

  void _updateLine(String key, {bool? selected, double? returnQty, double? refundAmount}) {
    setState(() {
      for (final l in _lines) {
        if (l.key != key) continue;
        if (selected != null) l.selected = selected;
        if (returnQty != null) {
          final qty = returnQty.clamp(1, l.maxQty).toDouble();
          l.returnQty = qty;
          l.refundAmount = _defaultRefund(l.unitPrice, qty, l.lineTotal, l.maxQty);
        }
        if (refundAmount != null) l.refundAmount = refundAmount;
      }
    });
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected.isEmpty) {
      setState(() => _error = 'Select at least one item to return or refund.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.app.mutate(r'''
        mutation ProcessReturn(
          $saleId: ID!
          $lines: [ReturnLineInput!]!
          $reason: String
          $kind: ReturnKind
          $stockDisposition: ReturnStockDisposition
        ) {
          createReturn(
            saleId: $saleId
            lines: $lines
            reason: $reason
            kind: $kind
            stockDisposition: $stockDisposition
          ) {
            id
            totalRefund
          }
        }
      ''', {
        'saleId': widget.sale['id'],
        'reason': _resolvedReason,
        'kind': _kind,
        'stockDisposition': _kind == 'RETURN' ? _stockDisposition : null,
        'lines': [
          for (final l in selected)
            {
              'productId': l.productId,
              'quantity': l.returnQty,
              'refundAmount': l.refundAmount,
            },
        ],
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
    final saleId = widget.sale['id'] as String;
    final createdAt = widget.sale['createdAt'] as String? ?? '';
    final total = (widget.sale['total'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Process return or refund',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sale ${moduleShortId(saleId)} · ${moduleFormatDateTime(createdAt)} · Order ${moduleFormatMoney(total)}',
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
                if (_lines.isEmpty)
                  Text('This sale has no returnable product lines.', style: Theme.of(context).textTheme.bodySmall)
                else
                  for (final line in _lines)
                    _LineCard(
                      line: line,
                      imageUrl: _imageByProductId[line.productId],
                      onUpdate: _updateLine,
                    ),
                const SizedBox(height: 16),
                VentosSelect<String>(
                  label: 'Return reason',
                  value: _reasonPreset,
                  entries: [
                    for (final p in kReturnReasonPresets)
                      VentosSelectEntry(
                        value: p,
                        label: p == _customReasonKey ? 'Other (custom)' : p,
                      ),
                  ],
                  onChanged: (v) => setState(() => _reasonPreset = v ?? kReturnReasonPresets.first),
                ),
                if (_reasonPreset == _customReasonKey) ...[
                  const SizedBox(height: 12),
                  VentosTextField(
                    controller: _customReason,
                    label: 'Custom reason',
                    hintText: 'Describe why items are being returned…',
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 16),
                Text('Type', style: Theme.of(context).textTheme.labelMedium),
                RadioListTile<String>(
                  title: const Text('Return — customer brings items back'),
                  value: 'RETURN',
                  groupValue: _kind,
                  onChanged: _submitting ? null : (v) => setState(() => _kind = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Refund — money back only (no stock change)'),
                  value: 'REFUND',
                  groupValue: _kind,
                  onChanged: _submitting ? null : (v) => setState(() => _kind = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (_kind == 'RETURN') ...[
                  const SizedBox(height: 8),
                  Text('Inventory', style: Theme.of(context).textTheme.labelMedium),
                  RadioListTile<String>(
                    title: const Text('Back to stock'),
                    value: 'RESTOCK',
                    groupValue: _stockDisposition,
                    onChanged: _submitting ? null : (v) => setState(() => _stockDisposition = v!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<String>(
                    title: const Text('Wasted / not restocked'),
                    value: 'WASTE',
                    groupValue: _stockDisposition,
                    onChanged: _submitting ? null : (v) => setState(() => _stockDisposition = v!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: VentosColors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total refund', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        moduleFormatMoney(_totalRefund),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
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
                onPressed: (_submitting || _lines.isEmpty || _selected.isEmpty) ? null : _submit,
                child: Text(_submitting ? 'Processing…' : 'Confirm'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.line,
    required this.onUpdate,
    this.imageUrl,
  });

  final _LineDraft line;
  final String? imageUrl;
  final void Function(String key, {bool? selected, double? returnQty, double? refundAmount}) onUpdate;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _refundCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: _qtyText(widget.line.returnQty));
    _refundCtrl = TextEditingController(text: widget.line.refundAmount.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_LineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.returnQty != widget.line.returnQty) {
      _qtyCtrl.text = _qtyText(widget.line.returnQty);
    }
    if (oldWidget.line.refundAmount != widget.line.refundAmount) {
      _refundCtrl.text = widget.line.refundAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _refundCtrl.dispose();
    super.dispose();
  }

  String _qtyText(double q) {
    return q.truncateToDouble() == q ? '${q.toInt()}' : q.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VentosCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: line.selected,
                  onChanged: (v) => widget.onUpdate(line.key, selected: v ?? false),
                ),
                EntityImage(imageUrl: widget.imageUrl, alt: line.name, width: 40, height: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      Text(
                        'Sold ${_qtyText(line.maxQty)} · ${moduleFormatMoney(line.unitPrice)} each',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (line.selected) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VentosTextField(
                      controller: _qtyCtrl,
                      label: 'Qty returning',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final n = double.tryParse(v.trim());
                        if (n != null) widget.onUpdate(line.key, returnQty: n);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VentosTextField(
                      controller: _refundCtrl,
                      label: 'Refund amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final n = double.tryParse(v.trim());
                        if (n != null) widget.onUpdate(line.key, refundAmount: n);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
