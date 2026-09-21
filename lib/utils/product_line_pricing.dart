import 'package:ventos_pos/models/pos_models.dart';

double productUnitDiscount(
  ProductDiscountType discountType,
  double discountValue,
  double unitPrice,
) {
  if (discountType == ProductDiscountType.none || discountValue <= 0 || unitPrice <= 0) {
    return 0;
  }
  if (discountType == ProductDiscountType.percent) {
    return unitPrice * (discountValue / 100);
  }
  if (discountType == ProductDiscountType.fixed) {
    return discountValue > unitPrice ? unitPrice : discountValue;
  }
  return 0;
}

double productLineDiscountAmount({
  required int quantity,
  required double unitPrice,
  required ProductDiscountType discountType,
  required double discountValue,
}) {
  return quantity * productUnitDiscount(discountType, discountValue, unitPrice);
}

double productLineTotal({
  required int quantity,
  required double unitPrice,
  required ProductDiscountType discountType,
  required double discountValue,
}) {
  final gross = quantity * unitPrice;
  final discount = productLineDiscountAmount(
    quantity: quantity,
    unitPrice: unitPrice,
    discountType: discountType,
    discountValue: discountValue,
  );
  final total = gross - discount;
  return total < 0 ? 0 : total;
}

double productEffectiveUnitPrice(PosProduct product) {
  final off = productUnitDiscount(product.discountType, product.discountValue, product.price);
  final price = product.price - off;
  return price < 0 ? 0 : price;
}
