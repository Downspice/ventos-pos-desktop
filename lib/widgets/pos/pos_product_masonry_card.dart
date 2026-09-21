import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/pos/pos_product_meta.dart';
import 'package:ventos_pos/utils/product_line_pricing.dart';
import 'package:ventos_pos/utils/product_metadata_display.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Matches web `PosProductMasonryCard`.
class PosProductMasonryCard extends StatelessWidget {
  const PosProductMasonryCard({
    super.key,
    required this.product,
    this.categoryName,
    this.metadataFields = const [],
    required this.formatMoney,
    required this.cartQuantity,
    required this.maxQuantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final PosProduct product;
  final String? categoryName;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final int cartQuantity;
  final int? maxQuantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final displayName = posProductDisplayName(product, metadataFields);
    final outOfStock = maxQuantity == 0;
    final atMax = maxQuantity != null && cartQuantity >= maxQuantity!;

    return Opacity(
      opacity: outOfStock ? 0.75 : 1,
      child: VentosCard(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: EntityImage(
                imageUrl: product.imageUrl,
                alt: displayName,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: VentosColors.textStrong,
                        ),
                  ),
                  PosProductMeta(
                    product: product,
                    metadataFields: metadataFields,
                    categoryName: categoryName,
                    formatMoney: formatMoney,
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(product: product, formatMoney: formatMoney),
                  if (maxQuantity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        outOfStock ? 'Out of stock' : '$maxQuantity in stock',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: VentosColors.strokeSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: cartQuantity == 0
                  ? VentosButtonFull(
                      onPressed: outOfStock ? null : onAdd,
                      label: outOfStock ? 'Unavailable' : 'Add to cart',
                      variant: VentosButtonVariant.secondary,
                    )
                  : Row(
                      children: [
                        VentosButton.icon(
                          onPressed: onDecrement,
                          icon: LucideIcons.minus,
                          size: VentosButtonSize.iconSm,
                        ),
                        Expanded(
                          child: Text(
                            maxQuantity != null
                                ? '$cartQuantity / $maxQuantity'
                                : '$cartQuantity',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
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
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product, required this.formatMoney});

  final PosProduct product;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final effective = productEffectiveUnitPrice(product);
    final hasDiscount = effective < product.price;

    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    if (!hasDiscount) {
      return Text(formatMoney(product.price), style: style);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formatMoney(product.price),
            style: style?.copyWith(
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.lineThrough,
              color: VentosColors.mutedForeground,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(text: formatMoney(effective), style: style),
        ],
      ),
    );
  }
}
