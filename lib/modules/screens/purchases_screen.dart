import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/module_format.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/products/product_with_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  int _tab = 0;

  Future<Map<String, dynamic>> _load() async {
    const document = r'''
      query PurchasesPage {
        suppliers { id name email phone address }
        purchaseOrders { id supplierId status createdAt }
        stockTransfers { id status fromLocationId toLocationId }
        stockMovements(limit: 20) { id movementType quantityDelta productId createdAt }
        products { id name imageUrl }
      }
    ''';
    return widget.app.query(document);
  }

  Future<void> _openSupplierForm({Map<String, dynamic>? existing, required VoidCallback onSaved}) async {
    final name = TextEditingController(text: existing?['name'] as String? ?? '');
    final email = TextEditingController(text: existing?['email'] as String? ?? '');
    final phone = TextEditingController(text: existing?['phone'] as String? ?? '');
    final address = TextEditingController(text: existing?['address'] as String? ?? '');

    final saved = await showVentosFormDrawer(
      context: context,
      title: existing == null ? 'New supplier' : 'Edit supplier',
      description: 'Add a vendor for purchase orders.',
      submitLabel: existing == null ? 'Create supplier' : 'Save changes',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VentosTextField(controller: name, label: 'Supplier name'),
          const SizedBox(height: 16),
          VentosTextField(controller: email, label: 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          VentosTextField(controller: phone, label: 'Phone', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          VentosTextField(controller: address, label: 'Address', maxLines: 3, minLines: 3),
        ],
      ),
      onSubmit: () async {
        if (name.text.trim().isEmpty) throw Exception('Supplier name is required.');
        if (existing == null) {
          await widget.app.mutate(r'''
            mutation CreateSupplier($name: String!, $email: String, $phone: String, $address: String) {
              createSupplier(name: $name, email: $email, phone: $phone, address: $address) { id }
            }
          ''', {
            'name': name.text.trim(),
            'email': email.text.trim().isEmpty ? null : email.text.trim(),
            'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
            'address': address.text.trim().isEmpty ? null : address.text.trim(),
          });
        } else {
          await widget.app.mutate(r'''
            mutation UpdateSupplier($id: ID!, $input: SupplierInput!) {
              updateSupplier(id: $id, input: $input) { id }
            }
          ''', {
            'id': existing['id'],
            'input': {
              'name': name.text.trim(),
              'email': email.text.trim().isEmpty ? null : email.text.trim(),
              'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
              'address': address.text.trim().isEmpty ? null : address.text.trim(),
            },
          });
        }
      },
    );

    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    if (saved == true) onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<Map<String, dynamic>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, data, reload) {
        final suppliers = (data['suppliers'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final orders = (data['purchaseOrders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final transfers = (data['stockTransfers'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final movements = (data['stockMovements'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final products = (data['products'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final productById = {for (final p in products) p['id'] as String: p};

        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Purchasing',
                description: 'Suppliers, purchase orders, transfers, and stock movements.',
                actions: _tab == 0
                    ? VentosNewButton(
                        label: 'New supplier',
                        onPressed: () => _openSupplierForm(onSaved: reload),
                      )
                    : null,
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Suppliers')),
                  ButtonSegment(value: 1, label: Text('POs')),
                  ButtonSegment(value: 2, label: Text('Transfers')),
                  ButtonSegment(value: 3, label: Text('Movements')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 16),
              if (_tab == 0)
                VentosSimpleTable(
                  columns: const ['Name', 'Email', 'Phone', ''],
                  rows: [
                    for (final s in suppliers)
                      [
                        Text(s['name'] as String? ?? ''),
                        Text(s['email'] as String? ?? '—'),
                        Text(s['phone'] as String? ?? '—'),
                        TableRowActions(
                          onEdit: () => _openSupplierForm(existing: s, onSaved: reload),
                          deleteTitle: 'Delete supplier',
                          itemName: s['name'] as String? ?? 'Supplier',
                          itemDescription: s['email'] as String?,
                          onDelete: () => widget.app.mutate(
                            r'mutation DeleteSupplier($id: ID!) { deleteSupplier(id: $id) }',
                            {'id': s['id']},
                          ),
                          onDeleted: reload,
                        ),
                      ],
                  ],
                ),
              if (_tab == 1)
                VentosSimpleTable(
                  columns: const ['Order', 'Supplier', 'Status', 'Created'],
                  rows: [
                    for (final o in orders)
                      [
                        Text(moduleShortId(o['id'] as String)),
                        Text(moduleShortId(o['supplierId'] as String)),
                        VentosBadge(label: o['status'] as String? ?? ''),
                        Text(moduleFormatDateTime(o['createdAt'] as String)),
                      ],
                  ],
                ),
              if (_tab == 2)
                VentosSimpleTable(
                  columns: const ['Transfer', 'Status', 'From', 'To'],
                  rows: [
                    for (final t in transfers)
                      [
                        Text(moduleShortId(t['id'] as String)),
                        VentosBadge(label: t['status'] as String? ?? ''),
                        Text(moduleShortId(t['fromLocationId'] as String)),
                        Text(moduleShortId(t['toLocationId'] as String)),
                      ],
                  ],
                ),
              if (_tab == 3)
                VentosSimpleTable(
                  columns: const ['When', 'Type', 'Product', 'Delta'],
                  rows: [
                    for (final m in movements)
                      [
                        Text(moduleFormatDateTime(m['createdAt'] as String)),
                        Text(m['movementType'] as String? ?? ''),
                        ProductWithImage(
                          name: (productById[m['productId']]?['name'] as String?) ??
                              moduleShortId(m['productId'] as String),
                          imageUrl: productById[m['productId']]?['imageUrl'] as String?,
                        ),
                        Text('${m['quantityDelta']}'),
                      ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
