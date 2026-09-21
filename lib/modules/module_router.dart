import 'package:flutter/material.dart';
import 'package:ventos_pos/modules/screens/appointments_screen.dart';
import 'package:ventos_pos/modules/screens/attendance_screen.dart';
import 'package:ventos_pos/modules/screens/customers_screen.dart';
import 'package:ventos_pos/modules/screens/inventory_screen.dart';
import 'package:ventos_pos/modules/screens/media_screen.dart';
import 'package:ventos_pos/modules/screens/notifications_screen.dart';
import 'package:ventos_pos/modules/screens/product_metadata_screen.dart';
import 'package:ventos_pos/modules/screens/product_types_screen.dart';
import 'package:ventos_pos/modules/screens/products_screen.dart';
import 'package:ventos_pos/modules/screens/purchases_screen.dart';
import 'package:ventos_pos/modules/screens/returns_screen.dart';
import 'package:ventos_pos/modules/screens/sales_screen.dart';
import 'package:ventos_pos/modules/screens/services_screen.dart';
import 'package:ventos_pos/modules/screens/sync_screen.dart';
import 'package:ventos_pos/navigation/desktop_destinations.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/services/pos_repository.dart';

class ModuleRouter extends StatelessWidget {
  const ModuleRouter({
    super.key,
    required this.destination,
    required this.app,
    required this.pos,
    this.reloadKey = 0,
    this.permissions = const {},
    this.initialProductMetadataTypeId,
    this.onProductMetadataTypeIdApplied,
    this.onOpenProductMetadataFields,
  });

  final DesktopDestination destination;
  final AppRepository app;
  final PosRepository pos;
  final int reloadKey;
  final Set<String> permissions;
  final String? initialProductMetadataTypeId;
  final VoidCallback? onProductMetadataTypeIdApplied;
  final void Function(String productTypeId)? onOpenProductMetadataFields;

  @override
  Widget build(BuildContext context) {
    switch (destination.id) {
      case 'sales':
        return SalesScreen(app: app, pos: pos, reloadKey: reloadKey);
      case 'customers':
        return CustomersScreen(app: app, reloadKey: reloadKey);
      case 'returns':
        return ReturnsScreen(app: app, reloadKey: reloadKey);
      case 'products':
        return ProductsScreen(app: app, reloadKey: reloadKey, permissions: permissions);
      case 'product-types':
        return ProductTypesScreen(
          app: app,
          reloadKey: reloadKey,
          onOpenMetadataFields: onOpenProductMetadataFields,
        );
      case 'product-metadata':
        return ProductMetadataScreen(
          app: app,
          reloadKey: reloadKey,
          initialProductTypeId: initialProductMetadataTypeId,
          onInitialProductTypeIdApplied: onProductMetadataTypeIdApplied,
        );
      case 'inventory':
        return InventoryScreen(app: app, reloadKey: reloadKey);
      case 'purchases':
        return PurchasesScreen(app: app, reloadKey: reloadKey);
      case 'appointments':
        return AppointmentsScreen(app: app, reloadKey: reloadKey);
      case 'services':
        return ServicesScreen(app: app, reloadKey: reloadKey, permissions: permissions);
      case 'attendance':
        return AttendanceScreen(app: app, reloadKey: reloadKey);
      case 'media':
        return MediaScreen(app: app, reloadKey: reloadKey);
      case 'notifications':
        return NotificationsScreen(app: app, reloadKey: reloadKey);
      case 'sync':
        return SyncScreen(app: app, reloadKey: reloadKey);
      default:
        return Center(child: Text('Unknown module: ${destination.id}'));
    }
  }
}
