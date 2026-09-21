import 'package:ventos_pos/models/pos_models.dart';

String normalizeScannedBarcode(String raw) {
  return raw.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

bool barcodesMatch(String a, String b) {
  final na = normalizeScannedBarcode(a);
  final nb = normalizeScannedBarcode(b);
  if (na.isEmpty || nb.isEmpty) return false;
  if (na == nb) return true;

  final da = _digitsOnly(na);
  final db = _digitsOnly(nb);
  if (da.isEmpty || db.isEmpty) return false;
  if (da == db) return true;

  String pad13(String d) => d.padLeft(13, '0');
  if (pad13(da) == pad13(db)) return true;

  String core12(String d) =>
      d.length >= 12 ? d.substring(d.length - 12) : d.padLeft(12, '0');
  return core12(da) == core12(db);
}

PosProduct? findProductByBarcode(List<PosProduct> products, String scanned) {
  final code = normalizeScannedBarcode(scanned);
  if (code.isEmpty) return null;
  for (final p in products) {
    final bc = p.barcode;
    if (bc != null && bc.isNotEmpty && barcodesMatch(bc, code)) {
      return p;
    }
  }
  return null;
}

PosProduct? findProductByScanCode(List<PosProduct> products, String scanned) {
  final byBarcode = findProductByBarcode(products, scanned);
  if (byBarcode != null) return byBarcode;
  final code = normalizeScannedBarcode(scanned);
  if (code.isEmpty) return null;
  final lower = code.toLowerCase();
  for (final p in products) {
    final sku = p.sku;
    if (sku != null &&
        normalizeScannedBarcode(sku).toLowerCase() == lower) {
      return p;
    }
  }
  return null;
}
