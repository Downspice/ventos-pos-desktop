import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

Future<bool?> showProductMetadataFieldDrawer({
  required BuildContext context,
  required AppRepository app,
  required String productTypeId,
  Map<String, dynamic>? existing,
}) {
  final label = TextEditingController(text: existing?['label'] as String? ?? '');
  final unit = TextEditingController(text: existing?['unit'] as String? ?? '');
  final optionsText = TextEditingController(
    text: ((existing?['options'] as List<dynamic>?) ?? []).join(', '),
  );
  final sortOrder = TextEditingController(text: '${existing?['sortOrder'] ?? 0}');
  var valueType = existing?['valueType'] as String? ?? 'TEXT';
  var active = existing?['active'] as bool? ?? true;

  return showVentosFormDrawer(
    context: context,
    title: existing == null ? 'New metadata field' : 'Edit metadata field',
    description: 'Fields define attributes shown when creating products of this type.',
    submitLabel: existing == null ? 'Create field' : 'Save changes',
    body: StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VentosTextField(controller: label, label: 'Label'),
            const SizedBox(height: 16),
            VentosSelect<String>(
              label: 'Field type',
              value: valueType,
              entries: const [
                VentosSelectEntry(value: 'TEXT', label: 'Text'),
                VentosSelectEntry(value: 'NUMBER', label: 'Number'),
                VentosSelectEntry(value: 'SELECT', label: 'Dropdown'),
              ],
              onChanged: (v) => setLocal(() => valueType = v ?? 'TEXT'),
            ),
            if (valueType == 'NUMBER') ...[
              const SizedBox(height: 16),
              VentosTextField(controller: unit, label: 'Unit (optional)', hintText: 'ml, g…'),
            ],
            if (valueType == 'SELECT') ...[
              const SizedBox(height: 16),
              VentosTextField(
                controller: optionsText,
                label: 'Options (comma-separated)',
                hintText: 'Bottle, Can, Box',
              ),
            ],
            const SizedBox(height: 16),
            VentosTextField(
              controller: sortOrder,
              label: 'Sort order',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: active,
              onChanged: (v) => setLocal(() => active = v),
            ),
            if (existing != null)
              Text(
                'Storage key: ${existing['key']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    ),
    onSubmit: () async {
      if (label.text.trim().isEmpty) throw Exception('Label is required.');
      final options = valueType == 'SELECT'
          ? optionsText.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : <String>[];
      final sort = int.tryParse(sortOrder.text.trim()) ?? 0;
      if (existing == null) {
        await app.mutate(r'''
          mutation CreateProductMetadataField($input: ProductMetadataFieldInput!) {
            createProductMetadataField(input: $input) { id }
          }
        ''', {
          'input': {
            'productTypeId': productTypeId,
            'label': label.text.trim(),
            'valueType': valueType,
            'unit': unit.text.trim().isEmpty ? null : unit.text.trim(),
            'options': options,
            'sortOrder': sort,
            'active': active,
          },
        });
      } else {
        await app.mutate(r'''
          mutation UpdateProductMetadataField($id: ID!, $input: ProductMetadataFieldUpdateInput!) {
            updateProductMetadataField(id: $id, input: $input) { id }
          }
        ''', {
          'id': existing['id'],
          'input': {
            'label': label.text.trim(),
            'valueType': valueType,
            'unit': unit.text.trim().isEmpty ? null : unit.text.trim(),
            'options': options,
            'sortOrder': sort,
            'active': active,
          },
        });
      }
    },
  ).whenComplete(() {
    label.dispose();
    unit.dispose();
    optionsText.dispose();
    sortOrder.dispose();
  });
}
