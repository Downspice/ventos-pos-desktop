import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/widgets/pos/pos_product_masonry_card.dart';

/// Max tile width — keeps masonry cards compact in wide order panels.
const double kPosProductMasonryMaxTileWidth = 200;

/// Masonry product catalog — web `columns-*` + `PosProductMasonryCard`.
class PosProductMasonryGrid extends StatelessWidget {
  const PosProductMasonryGrid({
    super.key,
    required this.products,
    required this.categoryNameById,
    required this.metadataFields,
    required this.formatMoney,
    required this.cartQtyByProductId,
    required this.maxForProduct,
    required this.onAdd,
    required this.onSetQuantity,
  });

  final List<PosProduct> products;
  final Map<String, String> categoryNameById;
  final List<ProductMetadataField> metadataFields;
  final String Function(double) formatMoney;
  final Map<String, int> cartQtyByProductId;
  final int? Function(PosProduct) maxForProduct;
  final void Function(PosProduct) onAdd;
  final void Function(PosProduct, int) onSetQuantity;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.extent(
      padding: const EdgeInsets.all(12),
      maxCrossAxisExtent: kPosProductMasonryMaxTileWidth,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final maxQ = maxForProduct(product);
        final qty = cartQtyByProductId[product.id] ?? 0;
        return PosProductMasonryCard(
          product: product,
          categoryName: product.categoryId != null
              ? categoryNameById[product.categoryId]
              : null,
          metadataFields: metadataFields,
          formatMoney: formatMoney,
          cartQuantity: qty,
          maxQuantity: maxQ,
          onAdd: () => onAdd(product),
          onIncrement: () => onAdd(product),
          onDecrement: () => onSetQuantity(product, qty - 1),
        );
      },
    );
  }
}
