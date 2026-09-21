import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/product_metadata_display.dart';
import 'package:ventos_pos/widgets/ventos/ventos_badge.dart';

/// Matches web `PosProductMeta`.
class PosProductMeta extends StatelessWidget {
  const PosProductMeta({
    super.key,
    required this.product,
    required this.metadataFields,
    this.categoryName,
    required this.formatMoney,
    this.compact = false,
  });

  final PosProduct product;
  final List<ProductMetadataField> metadataFields;
  final String? categoryName;
  final String Function(double) formatMoney;
  final bool compact;

  String? _discountLabel() {
    final type = product.discountType;
    final value = product.discountValue;
    if (type == ProductDiscountType.none || value <= 0) return null;
    if (type == ProductDiscountType.percent) return '$value% off';
    return '${formatMoney(value)} off';
  }

  @override
  Widget build(BuildContext context) {
    final metaTags = buildProductMetadataTags(
      product,
      metadataFields,
      options: const ProductMetadataTagOptions(includeKeys: posProductDisplayNameExcludeKeys),
    );
    final discount = _discountLabel();
    final idParts = <String>[
      if (product.sku != null && product.sku!.isNotEmpty) 'SKU ${product.sku}',
      if (product.barcode != null && product.barcode!.isNotEmpty) 'Barcode ${product.barcode}',
    ];

    final hasContent =
        categoryName != null || idParts.isNotEmpty || metaTags.isNotEmpty || discount != null;
    if (!hasContent) return const SizedBox.shrink();

    final maxTags = compact ? 2 : 4;
    final visibleTags = metaTags.take(maxTags).toList();
    final hiddenTagCount = metaTags.length - visibleTags.length;

    final subtitleParts = <String>[
      if (categoryName != null) categoryName!,
      ...idParts,
    ];

    return Padding(
      padding: EdgeInsets.only(top: compact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleParts.isNotEmpty)
            Text(
              subtitleParts.join(' · '),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.3,
                    color: VentosColors.mutedForeground,
                  ),
            ),
          if (visibleTags.isNotEmpty || discount != null) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (discount != null)
                  VentosBadge(
                    label: discount,
                    variant: VentosBadgeVariant.gray,
                    dense: true,
                  ),
                for (final tag in visibleTags)
                  VentosBadge(
                    label: tag,
                    variant: VentosBadgeVariant.outline,
                    dense: true,
                  ),
                if (hiddenTagCount > 0)
                  VentosBadge(
                    label: '+$hiddenTagCount more',
                    variant: VentosBadgeVariant.outline,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
