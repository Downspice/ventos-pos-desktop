import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/widgets/ventos/ventos_combobox.dart';

String posCustomerLabel(PosCustomer c) {
  final name = c.displayName;
  if (c.phone != null && c.phone!.trim().isNotEmpty) {
    return '$name · ${c.phone!.trim()}';
  }
  if (c.email != null && c.email!.trim().isNotEmpty) {
    return '$name · ${c.email!.trim()}';
  }
  return name.isEmpty ? 'Customer' : name;
}

/// Web `PosCustomerSelect` — combobox popover + searchable list.
class PosCustomerSelect extends StatelessWidget {
  const PosCustomerSelect({
    super.key,
    required this.customers,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PosCustomer> customers;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return VentosCombobox<String?>(
      enabled: enabled,
      value: value,
      onChanged: onChanged,
      placeholder: 'Walk-in customer',
      nullOptionLabel: 'Walk-in customer',
      searchPlaceholder: 'Search customers…',
      emptyText: 'No customers found.',
      items: [
        for (final c in customers)
          VentosComboboxItem<String?>(
            value: c.id,
            label: posCustomerLabel(c),
          ),
      ],
    );
  }
}
