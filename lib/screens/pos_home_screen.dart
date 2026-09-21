import 'package:flutter/material.dart';
import 'package:ventos_pos/navigation/desktop_destinations.dart';
import 'package:ventos_pos/screens/dashboard_screen.dart';
import 'package:ventos_pos/screens/pos_page.dart';
import 'package:ventos_pos/modules/module_router.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/services/auth_repository.dart' show PosSessionState;
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class PosHomeScreen extends StatefulWidget {
  const PosHomeScreen({
    super.key,
    required this.session,
    required this.pos,
    required this.app,
    required this.onSwitchStaff,
    required this.onDeviceLogout,
  });

  final PosSessionState session;
  final PosRepository pos;
  final AppRepository app;
  final VoidCallback onSwitchStaff;
  final VoidCallback onDeviceLogout;

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  late String _selectedId;
  int _salesRefreshKey = 0;
  String? _pendingProductMetadataTypeId;

  @override
  void initState() {
    super.initState();
    _selectedId = _pickInitialDestination().id;
  }

  DesktopDestination _pickInitialDestination() {
    final destinations = visibleDestinations(widget.session.permissions.toSet());
    return destinations.firstWhere(
      (d) => d.id == 'home',
      orElse: () => destinations.first,
    );
  }

  DesktopDestination? _findSelected(List<DesktopDestination> destinations) {
    for (final d in destinations) {
      if (d.id == _selectedId) return d;
    }
    return null;
  }

  void _onDestinationSelected(DesktopDestination dest) {
    setState(() {
      _selectedId = dest.id;
      if (dest.id != 'product-metadata') {
        _pendingProductMetadataTypeId = null;
      }
    });
  }

  void _openProductMetadataFields(String productTypeId) {
    setState(() {
      _pendingProductMetadataTypeId = productTypeId;
      _selectedId = 'product-metadata';
    });
  }

  void _onSaleFinalized() {
    setState(() => _salesRefreshKey++);
  }

  Widget _buildContent(DesktopDestination dest) {
    final canCheckout = widget.session.permissions.contains('sales.pos.checkout');
    final canViewSales = widget.session.permissions.contains('sales.read');

    switch (dest.kind) {
      case DesktopDestinationKind.nativeHome:
        return DashboardScreen(
          pos: widget.pos,
          businessName: widget.session.businessName,
          canViewSales: canViewSales,
          refreshKey: _salesRefreshKey,
        );
      case DesktopDestinationKind.nativePos:
        if (!canCheckout) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'You can access POS but checkout is not allowed for this role.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        return PosPage(
          pos: widget.pos,
          businessName: widget.session.businessName,
          onSaleFinalized: _onSaleFinalized,
        );
      case DesktopDestinationKind.nativeModule:
        return ModuleRouter(
          destination: dest,
          app: widget.app,
          pos: widget.pos,
          reloadKey: _salesRefreshKey,
          permissions: widget.session.permissions.toSet(),
          initialProductMetadataTypeId: _pendingProductMetadataTypeId,
          onProductMetadataTypeIdApplied: () {
            if (_pendingProductMetadataTypeId != null) {
              setState(() => _pendingProductMetadataTypeId = null);
            }
          },
          onOpenProductMetadataFields: _openProductMetadataFields,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.session.permissions.toSet();
    final destinations = visibleDestinations(permissions);
    final selected = _findSelected(destinations) ?? _pickInitialDestination();
    final canUseApp = destinations.isNotEmpty;

    return VentosScaffold(
      appBar: AppBar(
        title: Text(selected.label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                widget.session.activeEmployeeName ?? 'Staff',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          VentosButton(
            onPressed: widget.onSwitchStaff,
            variant: VentosButtonVariant.ghost,
            child: const Text('Switch staff'),
          ),
          VentosButton(
            onPressed: widget.onDeviceLogout,
            variant: VentosButtonVariant.ghost,
            child: const Text('Lock device'),
          ),
        ],
      ),
      body: !canUseApp
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'This role has no modules assigned. Contact your manager.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(selected.id),
                    child: _buildContent(selected),
                  ),
                ),
                VentosDock(
                  destinations: destinations,
                  selectedId: selected.id,
                  onSelected: _onDestinationSelected,
                ),
              ],
            ),
    );
  }
}
