import 'package:ventos_pos/models/pos_models.dart';

/// `null` means no stock cap (inventory not tracked).
int? posMaxStock(PosProduct product, Map<String, int> stockByProductId) {
  if (!product.trackInventory) return null;
  final onHand = stockByProductId[product.id] ?? 0;
  return onHand < 0 ? 0 : onHand.floor();
}

int clampPosCartQuantity(int desired, int? max) {
  final qty = desired < 0 ? 0 : desired;
  if (max == null) return qty;
  return qty > max ? max : qty;
}
