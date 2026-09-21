import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class ProductMetadataFieldDef {
  ProductMetadataFieldDef({
    required this.key,
    required this.label,
    required this.valueType,
    this.unit,
    this.options = const [],
    this.productTypeId,
    this.active = true,
  });

  factory ProductMetadataFieldDef.fromJson(Map<String, dynamic> json) {
    return ProductMetadataFieldDef(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      valueType: json['valueType'] as String? ?? 'TEXT',
      unit: json['unit'] as String?,
      options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
      productTypeId: json['productTypeId'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  final String key;
  final String label;
  final String valueType;
  final String? unit;
  final List<String> options;
  final String? productTypeId;
  final bool active;
}

class ProductMetadataEditor extends StatefulWidget {
  const ProductMetadataEditor({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
  });

  final List<ProductMetadataFieldDef> fields;
  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<ProductMetadataEditor> createState() => _ProductMetadataEditorState();
}

class _ProductMetadataEditorState extends State<ProductMetadataEditor> {
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: widget.values[key] ?? ''),
    );
  }

  void _setKey(String key, String value) {
    final next = Map<String, String>.from(widget.values);
    if (value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return Text(
        'No active metadata fields for this product type. Add fields under Metadata in the dock.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.mutedForeground),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in widget.fields) ...[
          if (field.valueType == 'SELECT' && field.options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VentosSelect<String>(
                label: field.unit != null ? '${field.label} (${field.unit})' : field.label,
                value: widget.values[field.key],
                hint: 'Select…',
                entries: [
                  for (final opt in field.options) VentosSelectEntry(value: opt, label: opt),
                ],
                onChanged: (v) => _setKey(field.key, v ?? ''),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VentosTextField(
                controller: _controllerFor(field.key),
                label: field.unit != null ? '${field.label} (${field.unit})' : field.label,
                keyboardType: field.valueType == 'NUMBER' ? TextInputType.number : TextInputType.text,
                onChanged: (v) => _setKey(field.key, v),
              ),
            ),
        ],
      ],
    );
  }
}
