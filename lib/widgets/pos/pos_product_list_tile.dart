import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/utils/product_metadata_display.dart';
import 'package:ventos_pos/widgets/pos/pos_product_meta.dart';

class PosProductListTile extends StatelessWidget {
  const PosProductListTile({
    super.key,
    required this.product,
    this.categoryName,
    this.metadataFields = const [],
    required this.formatMoney,
    required this.onTap,
  });

  final PosProduct product;
  final String? categoryName;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = posProductDisplayName(product, metadataFields);
    return Material(
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              EntityImage(imageUrl: product.imageUrl, alt: displayName),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    PosProductMeta(
                      product: product,
                      metadataFields: metadataFields,
                      categoryName: categoryName,
                      formatMoney: formatMoney,
                      compact: true,
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(product.price),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
