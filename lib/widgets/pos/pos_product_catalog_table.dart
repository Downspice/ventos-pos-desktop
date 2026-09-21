import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/product_line_pricing.dart';
import 'package:ventos_pos/utils/product_metadata_display.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Matches web `PosProductCatalogTable` and catalog Products table layout.
class PosProductCatalogTable extends StatelessWidget {
  const PosProductCatalogTable({
    super.key,
    required this.products,
    required this.metadataFields,
    required this.formatMoney,
    required this.cartQtyByProductId,
    required this.maxForProduct,
    required this.onAdd,
    required this.onSetQuantity,
  });

  final List<PosProduct> products;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final Map<String, int> cartQtyByProductId;
  final int? Function(PosProduct product) maxForProduct;
  final void Function(PosProduct product) onAdd;
  final void Function(PosProduct product, int quantity) onSetQuantity;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: VentosColors.mutedForeground,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 52),
              Expanded(flex: 3, child: Text('Name', style: headerStyle)),
              Expanded(flex: 2, child: Text('SKU', style: headerStyle)),
              Expanded(flex: 2, child: Text('Barcode', style: headerStyle)),
              Expanded(flex: 3, child: Text('Metadata', style: headerStyle)),
              Expanded(
                flex: 2,
                child: Text('Price', style: headerStyle, textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 108,
                child: Text('Cart', style: headerStyle, textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: VentosColors.strokeSoft),
            itemBuilder: (context, index) {
              final product = products[index];
              return _PosProductTableRow(
                product: product,
                metadataFields: metadataFields,
                formatMoney: formatMoney,
                cartQty: cartQtyByProductId[product.id] ?? 0,
                maxQty: maxForProduct(product),
                onAdd: () => onAdd(product),
                onDecrement: () {
                  final q = cartQtyByProductId[product.id] ?? 0;
                  onSetQuantity(product, q - 1);
                },
                onIncrement: () => onAdd(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PosProductTableRow extends StatelessWidget {
  const _PosProductTableRow({
    required this.product,
    required this.metadataFields,
    required this.formatMoney,
    required this.cartQty,
    required this.maxQty,
    required this.onAdd,
    required this.onDecrement,
    required this.onIncrement,
  });

  final PosProduct product;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final int cartQty;
  final int? maxQty;
  final VoidCallback onAdd;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final displayName = posProductDisplayName(product, metadataFields);
    final tags = buildProductMetadataTags(product, metadataFields);
    final outOfStock = maxQty == 0;
    final atMax = maxQty != null && cartQty >= maxQty!;
    final effective = productEffectiveUnitPrice(product);
    final hasDiscount = effective < product.price;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: outOfStock ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: outOfStock ? 0.6 : 1,
                child: EntityImage(imageUrl: product.imageUrl, alt: displayName),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VentosColors.textStrong,
                      ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(product.sku ?? '—', style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  product.barcode ?? '—',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              Expanded(
                flex: 3,
                child: tags.isEmpty
                    ? Text('—', style: Theme.of(context).textTheme.bodySmall)
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final tag in tags)
                            VentosBadge(
                              label: tag,
                              variant: VentosBadgeVariant.gray,
                              dense: true,
                            ),
                        ],
                      ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: hasDiscount
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${formatMoney(product.price)} ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: VentosColors.mutedForeground,
                                    ),
                              ),
                              TextSpan(
                                text: formatMoney(effective),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          formatMoney(product.price),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ),
              SizedBox(
                width: 108,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: outOfStock
                      ? Text(
                          'Out of stock',
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.right,
                        )
                      : cartQty == 0
                          ? VentosButton(
                              onPressed: onAdd,
                              variant: VentosButtonVariant.secondary,
                              size: VentosButtonSize.sm,
                              child: const Text('Add'),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VentosButton.icon(
                                  onPressed: onDecrement,
                                  icon: LucideIcons.minus,
                                  size: VentosButtonSize.iconSm,
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$cartQty',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                                VentosButton.icon(
                                  onPressed: atMax ? null : onIncrement,
                                  icon: LucideIcons.plus,
                                  size: VentosButtonSize.iconSm,
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
