import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

enum DesktopDestinationKind { nativeHome, nativePos, nativeModule }

class DesktopDestination {
  const DesktopDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.kind,
    this.permission,
  });

  final String id;
  final String label;
  final IconData icon;
  final DesktopDestinationKind kind;
  final String? permission;

  bool visibleFor(Set<String> permissions) {
    if (permission == null) return true;
    return permissions.contains(permission);
  }
}

/// Mirrors web [VentosSidebar] routes — all native Flutter UI.
const kDesktopDestinations = <DesktopDestination>[
  DesktopDestination(
    id: 'home',
    label: 'Home',
    icon: LucideIcons.house,
    kind: DesktopDestinationKind.nativeHome,
  ),
  DesktopDestination(
    id: 'pos',
    label: 'POS',
    icon: LucideIcons.shopping_cart,
    kind: DesktopDestinationKind.nativePos,
    permission: 'sales.pos.access',
  ),
  DesktopDestination(
    id: 'sales',
    label: 'Sales',
    icon: LucideIcons.receipt,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'sales.read',
  ),
  DesktopDestination(
    id: 'customers',
    label: 'Customers',
    icon: LucideIcons.users,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'customers.read',
  ),
  DesktopDestination(
    id: 'returns',
    label: 'Returns',
    icon: LucideIcons.undo_2,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'sales.refund.create',
  ),
  DesktopDestination(
    id: 'products',
    label: 'Products',
    icon: LucideIcons.tag,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'inventory.read',
  ),
  DesktopDestination(
    id: 'product-types',
    label: 'Types',
    icon: LucideIcons.shapes,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'inventory.read',
  ),
  DesktopDestination(
    id: 'product-metadata',
    label: 'Metadata',
    icon: LucideIcons.layers,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'inventory.read',
  ),
  DesktopDestination(
    id: 'inventory',
    label: 'Stock',
    icon: LucideIcons.package,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'inventory.read',
  ),
  DesktopDestination(
    id: 'purchases',
    label: 'Purchasing',
    icon: LucideIcons.truck,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'purchases.read',
  ),
  DesktopDestination(
    id: 'appointments',
    label: 'Appointments',
    icon: LucideIcons.calendar,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'appointments.read',
  ),
  DesktopDestination(
    id: 'services',
    label: 'Services',
    icon: LucideIcons.scissors,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'appointments.read',
  ),
  DesktopDestination(
    id: 'attendance',
    label: 'Attendance',
    icon: LucideIcons.clock,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'employees.read',
  ),
  DesktopDestination(
    id: 'media',
    label: 'Media',
    icon: LucideIcons.image,
    kind: DesktopDestinationKind.nativeModule,
    permission: 'media.read',
  ),
  DesktopDestination(
    id: 'notifications',
    label: 'Notifications',
    icon: LucideIcons.bell,
    kind: DesktopDestinationKind.nativeModule,
  ),
  DesktopDestination(
    id: 'sync',
    label: 'Sync',
    icon: LucideIcons.cloud_upload,
    kind: DesktopDestinationKind.nativeModule,
  ),
];

List<DesktopDestination> visibleDestinations(Set<String> permissions) {
  return kDesktopDestinations.where((d) => d.visibleFor(permissions)).toList();
}
