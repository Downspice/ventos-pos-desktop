import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/common/table_row_actions.dart';
import 'package:ventos_pos/widgets/common/ventos_simple_table.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  static const _pageSize = 12;
  int _page = 1;

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query CustomersPage {
        customers { id firstName lastName email phone }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['customers'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> _openForm({Map<String, dynamic>? existing, required VoidCallback onSaved}) async {
    final firstName = TextEditingController(text: existing?['firstName'] as String? ?? '');
    final lastName = TextEditingController(text: existing?['lastName'] as String? ?? '');
    final email = TextEditingController(text: existing?['email'] as String? ?? '');
    final phone = TextEditingController(text: existing?['phone'] as String? ?? '');

    final saved = await showVentosFormDrawer(
      context: context,
      title: existing == null ? 'New customer' : 'Edit customer',
      description: 'Contact details for checkout and purchase history.',
      submitLabel: existing == null ? 'Create customer' : 'Save changes',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VentosTextField(controller: firstName, label: 'First name'),
          const SizedBox(height: 16),
          VentosTextField(controller: lastName, label: 'Last name'),
          const SizedBox(height: 16),
          VentosTextField(controller: email, label: 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          VentosTextField(controller: phone, label: 'Phone', keyboardType: TextInputType.phone),
        ],
      ),
      onSubmit: () async {
        if (firstName.text.trim().isEmpty || lastName.text.trim().isEmpty) {
          throw Exception('First and last name are required.');
        }
        if (existing == null) {
          await widget.app.mutate(r'''
            mutation CreateCustomer($firstName: String!, $lastName: String!, $email: String, $phone: String) {
              createCustomer(firstName: $firstName, lastName: $lastName, email: $email, phone: $phone) { id }
            }
          ''', {
            'firstName': firstName.text.trim(),
            'lastName': lastName.text.trim(),
            'email': email.text.trim().isEmpty ? null : email.text.trim(),
            'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
          });
        } else {
          await widget.app.mutate(r'''
            mutation UpdateCustomer($id: ID!, $input: CustomerInput!) {
              updateCustomer(id: $id, input: $input) { id }
            }
          ''', {
            'id': existing['id'],
            'input': {
              'firstName': firstName.text.trim(),
              'lastName': lastName.text.trim(),
              'email': email.text.trim().isEmpty ? null : email.text.trim(),
              'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
            },
          });
        }
      },
    );

    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();

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
      builder: (context, customers, reload) {
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Customers',
                description: 'Customer directory and purchase history.',
                actions: VentosNewButton(
                  label: 'New customer',
                  onPressed: () => _openForm(onSaved: reload),
                ),
              ),
              VentosSimpleTable(
                columns: const ['Name', 'Email', 'Phone', ''],
                rows: [
                  for (final c in paginateSlice(customers, _page, _pageSize))
                    [
                      Text('${c['firstName']} ${c['lastName']}'.trim()),
                      Text(c['email'] as String? ?? '—'),
                      Text(c['phone'] as String? ?? '—'),
                      TableRowActions(
                        onEdit: () => _openForm(existing: c, onSaved: reload),
                        deleteTitle: 'Delete customer',
                        itemName: () {
                          final name = '${c['firstName']} ${c['lastName']}'.trim();
                          return name.isEmpty ? 'Customer' : name;
                        }(),
                        itemDescription: () {
                          final desc = [c['email'], c['phone']]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' · ');
                          return desc.isEmpty ? null : desc;
                        }(),
                        onDelete: () => widget.app.mutate(
                          r'mutation DeleteCustomer($id: ID!) { deleteCustomer(id: $id) }',
                          {'id': c['id']},
                        ),
                        onDeleted: reload,
                      ),
                    ],
                ],
              ),
              VentosPaginationBar(
                page: _page,
                totalPages: paginateTotalPages(customers.length, _pageSize),
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          ),
        );
      },
    );
  }
}
