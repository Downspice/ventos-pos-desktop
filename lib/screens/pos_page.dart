import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/utils/barcode.dart';
import 'package:ventos_pos/utils/compute_sale_tax.dart';
import 'package:ventos_pos/utils/money.dart';
import 'package:ventos_pos/utils/pos_stock.dart';
import 'package:ventos_pos/utils/product_metadata_display.dart';
import 'package:ventos_pos/utils/product_line_pricing.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/pos/pos_customer_select.dart';
import 'package:ventos_pos/widgets/pos/pos_order_totals.dart';
import 'package:ventos_pos/widgets/pos/pos_payment_dialog.dart';
import 'package:ventos_pos/widgets/pos/pos_product_catalog_table.dart';
import 'package:ventos_pos/widgets/pos/pos_product_masonry_grid.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

enum _ProductCatalogView { list, masonry }

/// Mirrors web `PosPage` layout and behavior.
class PosPage extends StatefulWidget {
  const PosPage({
    super.key,
    required this.pos,
    this.businessName,
    this.onSaleFinalized,
  });

  final PosRepository pos;
  final String? businessName;
  final VoidCallback? onSaleFinalized;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  PosCatalogData? _catalog;
  String? _loadError;
  bool _loading = true;

  bool _orderActive = false;
  bool _payOpen = false;

  final _searchController = TextEditingController();
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();

  String _search = '';
  String? _scanError;
  _ProductCatalogView _productView = _ProductCatalogView.masonry;
  final List<CartLine> _cart = [];
  String? _customerId;
  String _checkoutSuccessMessage = 'Payment recorded successfully.';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _search = _searchController.text));
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final catalog = await widget.pos.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  PosCatalogData? get _data => _catalog;

  String _money(double amount) {
    final data = _data;
    if (data == null) return amount.toStringAsFixed(2);
    return formatMoneyMajor(amount, data.currency);
  }

  Map<String, PosProduct> get _productById {
    final data = _data;
    if (data == null) return {};
    return {for (final p in data.products) p.id: p};
  }

  Map<String, int> get _cartQtyByProductId {
    return {for (final l in _cart) l.productId: l.quantity};
  }

  Map<String, String> get _categoryNameById {
    final data = _data;
    if (data == null) return {};
    return {for (final c in data.categories) c.id: c.name};
  }

  List<PosProduct> get _filteredProducts {
    final data = _data;
    if (data == null) return [];
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return data.products;
    final fields = data.metadataFields;
    return data.products.where((p) {
      if (p.name.toLowerCase().contains(q)) return true;
      if (posProductDisplayName(p, fields).toLowerCase().contains(q)) return true;
      if (p.sku?.toLowerCase().contains(q) ?? false) return true;
      if (p.barcode?.toLowerCase().contains(q) ?? false) return true;
      final cat = p.categoryId != null ? _categoryNameById[p.categoryId] : null;
      if (cat != null && cat.toLowerCase().contains(q)) return true;
      final tags = buildProductMetadataTags(p, fields);
      if (tags.any((t) => t.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  double get _subtotal => _cart.fold(0, (sum, line) => sum + line.lineTotal);

  SaleTaxSummary get _taxSummary {
    final rules = _data?.taxRules ?? [];
    return computeSaleTax(_subtotal, rules);
  }

  double get _orderTotal => _taxSummary.total;

  int? _maxForProduct(PosProduct product) {
    final data = _data;
    if (data == null) return null;
    return posMaxStock(product, data.stockByProductId);
  }

  void _startOrder() {
    setState(() {
      _cart.clear();
      _customerId = null;
      _searchController.clear();
      _scanController.clear();
      _scanError = null;
      _orderActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orderActive && !_payOpen) _scanFocus.requestFocus();
    });
  }

  void _cancelOrder() {
    setState(() {
      _cart.clear();
      _customerId = null;
      _orderActive = false;
      _payOpen = false;
      _scanError = null;
    });
  }

  void _setProductQuantity(PosProduct product, int desired) {
    if (!_orderActive) return;
    final max = _maxForProduct(product);
    final quantity = clampPosCartQuantity(desired, max);
    setState(() {
      if (quantity <= 0) {
        _cart.removeWhere((l) => l.productId == product.id);
        return;
      }
      final idx = _cart.indexWhere((l) => l.productId == product.id);
      final discountAmount = productLineDiscountAmount(
        quantity: quantity,
        unitPrice: product.price,
        discountType: product.discountType,
        discountValue: product.discountValue,
      );
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: quantity, discountAmount: discountAmount);
      } else {
        _cart.add(CartLine(
          productId: product.id,
          name: posProductDisplayName(product, _data?.metadataFields ?? const []),
          unitPrice: product.price,
          quantity: quantity,
          discountAmount: discountAmount,
        ));
      }
    });
  }

  void _addProduct(PosProduct product) {
    final current = _cartQtyByProductId[product.id] ?? 0;
    _setProductQuantity(product, current + 1);
  }

  void _setLineQuantity(String productId, int quantity) {
    final product = _productById[productId];
    if (product == null) {
      if (quantity <= 0) {
        setState(() => _cart.removeWhere((l) => l.productId == productId));
      }
      return;
    }
    _setProductQuantity(product, quantity);
  }

  void _resolveScan(String raw) {
    final data = _data;
    if (data == null) return;
    setState(() => _scanError = null);
    final code = normalizeScannedBarcode(raw);
    if (code.isEmpty) return;

    final product = findProductByScanCode(data.products, code);
    if (product == null) {
      setState(() {
        _scanError = 'No product found for $code';
        _scanController.clear();
      });
      return;
    }
    final max = _maxForProduct(product);
    if (max == 0) {
      setState(() {
        _scanError = '${product.name} is out of stock';
        _scanController.clear();
      });
      return;
    }
    final current = _cartQtyByProductId[product.id] ?? 0;
    if (max != null && current >= max) {
      setState(() {
        _scanError = 'Maximum stock for ${product.name}';
        _scanController.clear();
      });
      return;
    }
    _addProduct(product);
    _scanController.clear();
    _scanFocus.requestFocus();
  }

  Future<void> _openPayDialog() async {
    if (_cart.isEmpty || _data == null) return;
    setState(() => _payOpen = true);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PosPaymentDialog(
        orderTotal: _orderTotal,
        subtotal: _subtotal,
        taxSummary: _taxSummary,
        formatMoney: _money,
        paymentChannels: _data!.paymentChannels,
        onComplete: (method, reference, paymentChannelId) async {
          final refreshed = await widget.pos.fetchCatalog();
          final sessionId = await widget.pos.ensureRegisterSession(refreshed);
          final checkout = await widget.pos.checkout(
            registerSessionId: sessionId,
            customerId: _customerId,
            cart: List.of(_cart),
            paymentMethod: method,
            paymentReference: reference,
            paymentChannelId: paymentChannelId,
            orderTotal: _orderTotal,
          );
          var receiptMessage = 'Payment recorded and receipt sent to the printer.';
          try {
            await widget.pos.printSaleReceipt(checkout.saleId);
          } catch (_) {
            receiptMessage =
                'Payment recorded, but the receipt could not be printed. Check your printer and try reprinting from the sale.';
          }
          if (!mounted) return;
          setState(() {
            _checkoutSuccessMessage = receiptMessage;
            _catalog = refreshed;
            _cart.clear();
            _customerId = null;
            _orderActive = false;
          });
          widget.onSaleFinalized?.call();
        },
      ),
    );
    if (!mounted) return;
    setState(() => _payOpen = false);
    if (completed == true) {
      await showVentosDialog<void>(
        context: context,
        title: 'Sale complete',
        description: _checkoutSuccessMessage,
        body: const SizedBox.shrink(),
        actions: [
          VentosButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            VentosButton(onPressed: _loadCatalog, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = _data!;
    final session = data.openSessions.isNotEmpty ? data.openSessions.first : null;
    final registerName = data.registerNameForSession(session);

    return SizedBox.expand(
      child: Stack(
        children: [
          VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Point of sale',
                description: 'Create an order, add products, and take payment at checkout.',
                actions: VentosButton(
                  onPressed: _startOrder,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shopping_cart, size: 18),
                      SizedBox(width: 8),
                      Text('Create order'),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (session != null)
                    VentosBadge(
                      label: registerName != null
                          ? 'Register open: $registerName'
                          : 'Register open',
                    )
                  else
                    Text(
                      'No open session — open one in Admin → Registers, or one will open at checkout if a register exists.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Use Create order to scan or search products and take payment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_orderActive)
          Positioned.fill(
            child: _OrderModal(
              payOpen: _payOpen,
              onClose: _cancelOrder,
              onPay: _openPayDialog,
              sessionLabel: session != null
                  ? (registerName != null ? 'Register open: $registerName' : 'Register open')
                  : null,
              cartEmpty: _cart.isEmpty,
              orderTotalLabel: _money(_orderTotal),
              child: _OrderWorkspace(
                onPay: _openPayDialog,
                productView: _productView,
                onViewChanged: (v) => setState(() => _productView = v),
                scanController: _scanController,
                scanFocus: _scanFocus,
                scanError: _scanError,
                onScan: _resolveScan,
                searchController: _searchController,
                filteredProducts: _filteredProducts,
                categoryNameById: _categoryNameById,
                metadataFields: data.metadataFields,
                formatMoney: _money,
                cartQtyByProductId: _cartQtyByProductId,
                maxForProduct: _maxForProduct,
                onAdd: _addProduct,
                onSetQuantity: _setProductQuantity,
                customers: data.customers,
                customerId: _customerId,
                onCustomerChanged: (id) => setState(() => _customerId = id),
                cart: _cart,
                productById: _productById,
                onLineQuantity: _setLineQuantity,
                subtotal: _subtotal,
                taxSummary: _taxSummary,
                orderTotal: _orderTotal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderModal extends StatelessWidget {
  const _OrderModal({
    required this.payOpen,
    required this.onClose,
    required this.onPay,
    required this.sessionLabel,
    required this.cartEmpty,
    required this.orderTotalLabel,
    required this.child,
  });

  final bool payOpen;
  final VoidCallback onClose;
  final VoidCallback onPay;
  final String? sessionLabel;
  final bool cartEmpty;
  final String orderTotalLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VentosColors.overlayGray,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: PopScope(
            canPop: !payOpen,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && !payOpen) onClose();
            },
            child: VentosCard(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New order', style: Theme.of(context).textTheme.titleLarge),
                              Text(
                                'Add products, set customer, then pay.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (sessionLabel != null)
                                    VentosBadge(label: sessionLabel!, dense: true),
                                  const VentosBadge(
                                    label: 'Order in progress',
                                    variant: VentosBadgeVariant.gray,
                                    dense: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        VentosButton(
                          onPressed: payOpen ? null : onClose,
                          variant: VentosButtonVariant.outline,
                          child: const Text('Cancel order'),
                        ),
                        const SizedBox(width: 8),
                        VentosButton(
                          onPressed: cartEmpty ? null : onPay,
                          child: Text('Pay now · $orderTotalLabel'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderWorkspace extends StatelessWidget {
  const _OrderWorkspace({
    required this.onPay,
    required this.productView,
    required this.onViewChanged,
    required this.scanController,
    required this.scanFocus,
    required this.scanError,
    required this.onScan,
    required this.searchController,
    required this.filteredProducts,
    required this.categoryNameById,
    required this.metadataFields,
    required this.formatMoney,
    required this.cartQtyByProductId,
    required this.maxForProduct,
    required this.onAdd,
    required this.onSetQuantity,
    required this.customers,
    required this.customerId,
    required this.onCustomerChanged,
    required this.cart,
    required this.productById,
    required this.onLineQuantity,
    required this.subtotal,
    required this.taxSummary,
    required this.orderTotal,
  });

  final VoidCallback onPay;
  final _ProductCatalogView productView;
  final ValueChanged<_ProductCatalogView> onViewChanged;
  final TextEditingController scanController;
  final FocusNode scanFocus;
  final String? scanError;
  final ValueChanged<String> onScan;
  final TextEditingController searchController;
  final List<PosProduct> filteredProducts;
  final Map<String, String> categoryNameById;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final Map<String, int> cartQtyByProductId;
  final int? Function(PosProduct) maxForProduct;
  final void Function(PosProduct) onAdd;
  final void Function(PosProduct, int) onSetQuantity;
  final List<PosCustomer> customers;
  final String? customerId;
  final ValueChanged<String?> onCustomerChanged;
  final List<CartLine> cart;
  final Map<String, PosProduct> productById;
  final void Function(String productId, int qty) onLineQuantity;
  final double subtotal;
  final SaleTaxSummary taxSummary;
  final double orderTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final catalog = _ProductsPanel(
            productView: productView,
            onViewChanged: onViewChanged,
            scanController: scanController,
            scanFocus: scanFocus,
            scanError: scanError,
            onScan: onScan,
            searchController: searchController,
            filteredProducts: filteredProducts,
            categoryNameById: categoryNameById,
            metadataFields: metadataFields,
            formatMoney: formatMoney,
            cartQtyByProductId: cartQtyByProductId,
            maxForProduct: maxForProduct,
            onAdd: onAdd,
            onSetQuantity: onSetQuantity,
          );
          final order = _CartPanel(
            customers: customers,
            customerId: customerId,
            onCustomerChanged: onCustomerChanged,
            cart: cart,
            productById: productById,
            maxForProduct: maxForProduct,
            formatMoney: formatMoney,
            onLineQuantity: onLineQuantity,
            subtotal: subtotal,
            taxSummary: taxSummary,
            orderTotal: orderTotal,
            onPay: onPay,
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: catalog),
                const SizedBox(width: 16),
                SizedBox(width: 304, child: order),
              ],
            );
          }
          return Column(
            children: [
              Expanded(flex: 3, child: catalog),
              const SizedBox(height: 16),
              Expanded(flex: 2, child: order),
            ],
          );
        },
      ),
    );
  }
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel({
    required this.productView,
    required this.onViewChanged,
    required this.scanController,
    required this.scanFocus,
    required this.scanError,
    required this.onScan,
    required this.searchController,
    required this.filteredProducts,
    required this.categoryNameById,
    required this.metadataFields,
    required this.formatMoney,
    required this.cartQtyByProductId,
    required this.maxForProduct,
    required this.onAdd,
    required this.onSetQuantity,
  });

  final _ProductCatalogView productView;
  final ValueChanged<_ProductCatalogView> onViewChanged;
  final TextEditingController scanController;
  final FocusNode scanFocus;
  final String? scanError;
  final ValueChanged<String> onScan;
  final TextEditingController searchController;
  final List<PosProduct> filteredProducts;
  final Map<String, String> categoryNameById;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final Map<String, int> cartQtyByProductId;
  final int? Function(PosProduct) maxForProduct;
  final void Function(PosProduct) onAdd;
  final void Function(PosProduct, int) onSetQuantity;

  @override
  Widget build(BuildContext context) {
    return VentosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Products', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    _ViewToggle(
                      view: productView,
                      onChanged: onViewChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                VentosTextField(
                  controller: scanController,
                  focusNode: scanFocus,
                  prefixIcon: const Icon(LucideIcons.scan_line, size: 20),
                  hintText: 'Scan barcode to add to cart',
                  errorText: scanError,
                  onSubmitted: onScan,
                ),
                if (scanError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'USB scanners work here — scan sends Enter to add one unit.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                const SizedBox(height: 8),
                VentosTextField(
                  controller: searchController,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  hintText: 'Search products…',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(child: Text('No products found.', style: Theme.of(context).textTheme.bodySmall))
                : productView == _ProductCatalogView.list
                    ? PosProductCatalogTable(
                        products: filteredProducts,
                        metadataFields: metadataFields,
                        formatMoney: formatMoney,
                        cartQtyByProductId: cartQtyByProductId,
                        maxForProduct: maxForProduct,
                        onAdd: onAdd,
                        onSetQuantity: onSetQuantity,
                      )
                    : PosProductMasonryGrid(
                        products: filteredProducts,
                        categoryNameById: categoryNameById,
                        metadataFields: metadataFields,
                        formatMoney: formatMoney,
                        cartQtyByProductId: cartQtyByProductId,
                        maxForProduct: maxForProduct,
                        onAdd: onAdd,
                        onSetQuantity: onSetQuantity,
                      ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _ProductCatalogView view;
  final ValueChanged<_ProductCatalogView> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleIcon(
              icon: LucideIcons.list,
              selected: view == _ProductCatalogView.list,
              onTap: () => onChanged(_ProductCatalogView.list),
            ),
            _ToggleIcon(
              icon: LucideIcons.layout_grid,
              selected: view == _ProductCatalogView.masonry,
              onTap: () => onChanged(_ProductCatalogView.masonry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VentosColors.secondary : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.customers,
    required this.customerId,
    required this.onCustomerChanged,
    required this.cart,
    required this.productById,
    required this.maxForProduct,
    required this.formatMoney,
    required this.onLineQuantity,
    required this.subtotal,
    required this.taxSummary,
    required this.orderTotal,
    required this.onPay,
  });

  final List<PosCustomer> customers;
  final String? customerId;
  final ValueChanged<String?> onCustomerChanged;
  final List<CartLine> cart;
  final Map<String, PosProduct> productById;
  final int? Function(PosProduct) maxForProduct;
  final String Function(double) formatMoney;
  final void Function(String productId, int qty) onLineQuantity;
  final double subtotal;
  final SaleTaxSummary taxSummary;
  final double orderTotal;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return VentosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current order', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Customer', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                PosCustomerSelect(
                  customers: customers,
                  value: customerId,
                  onChanged: onCustomerChanged,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'Tap products to add them here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final line = cart[index];
                      final cartProduct = productById[line.productId];
                      final lineMax = cartProduct != null ? maxForProduct(cartProduct) : null;
                      final lineAtMax = lineMax != null && line.quantity >= lineMax;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EntityImage(
                            imageUrl: cartProduct?.imageUrl,
                            alt: line.name,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.name, style: Theme.of(context).textTheme.bodyMedium),
                                Text(
                                  line.discountAmount > 0
                                      ? '${formatMoney(line.unitPrice)} → ${formatMoney(line.lineTotal / line.quantity)} each'
                                      : formatMoney(line.unitPrice),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Row(
                                  children: [
                                    IconButton.outlined(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 18,
                                      onPressed: () => onLineQuantity(line.productId, line.quantity - 1),
                                      icon: const Icon(LucideIcons.minus, size: 16),
                                    ),
                                    SizedBox(
                                      width: 28,
                                      child: Text('${line.quantity}', textAlign: TextAlign.center),
                                    ),
                                    IconButton.outlined(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 18,
                                      onPressed: lineAtMax
                                          ? null
                                          : () => onLineQuantity(line.productId, line.quantity + 1),
                                      icon: const Icon(LucideIcons.plus, size: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatMoney(line.lineTotal), style: Theme.of(context).textTheme.titleSmall),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                                ),
                                onPressed: () => onLineQuantity(line.productId, 0),
                                icon: const Icon(LucideIcons.trash, size: 18),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosOrderTotals(
                  subtotal: subtotal,
                  taxLines: taxSummary.lines,
                  taxTotal: taxSummary.taxTotal,
                  total: orderTotal,
                  formatMoney: formatMoney,
                ),
                const SizedBox(height: 12),
                VentosButtonFull(
                  onPressed: cart.isEmpty ? null : onPay,
                  label: 'Pay now',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
