import 'package:ventos_pos/modules/list_search.dart';
import 'package:ventos_pos/widgets/products/product_metadata_editor.dart';

double? parseOptionalProductListPrice(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final n = double.tryParse(t);
  return n;
}

List<String> metadataTagsForProductListFilter(
  Map<String, dynamic> product,
  List<ProductMetadataFieldDef> allFields,
) {
  final meta =
      (product['metadata'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {};
  final typeId = product['productTypeId'] as String?;
  final fields = allFields.where((f) => typeId == null || f.productTypeId == typeId);
  final tags = <String>[];
  final knownKeys = fields.map((f) => f.key).toSet();
  for (final f in fields) {
    final v = meta[f.key]?.trim();
    if (v == null || v.isEmpty) continue;
    final unit = f.unit?.trim();
    tags.add(unit != null && unit.isNotEmpty ? '$v $unit' : v);
  }
  for (final entry in meta.entries) {
    if (!knownKeys.contains(entry.key) && entry.value.trim().isNotEmpty) {
      tags.add(entry.value.trim());
    }
  }
  return tags;
}

List<String> collectMetadataFilterOptions(
  List<Map<String, dynamic>> products,
  List<ProductMetadataFieldDef> allFields,
) {
  final set = <String>{};
  for (final p in products) {
    set.addAll(metadataTagsForProductListFilter(p, allFields));
  }
  final list = set.toList()..sort();
  return list;
}

bool hasActiveProductListFilters({
  required String search,
  required Set<String> typeIds,
  required Set<String> metadataValues,
  required String minPrice,
  required String maxPrice,
}) {
  return search.trim().isNotEmpty ||
      typeIds.isNotEmpty ||
      metadataValues.isNotEmpty ||
      minPrice.trim().isNotEmpty ||
      maxPrice.trim().isNotEmpty;
}

bool productMatchesListFilters(
  Map<String, dynamic> product, {
  required String search,
  required Set<String> typeIds,
  required Set<String> metadataValues,
  required String minPrice,
  required String maxPrice,
  required Map<String, String> typeNames,
  required List<ProductMetadataFieldDef> allFields,
}) {
  if (typeIds.isNotEmpty) {
    final typeId = product['productTypeId'] as String?;
    if (typeId == null || !typeIds.contains(typeId)) return false;
  }

  final price = (product['price'] as num?)?.toDouble() ?? 0;
  final min = parseOptionalProductListPrice(minPrice);
  final max = parseOptionalProductListPrice(maxPrice);
  if (min != null && price < min) return false;
  if (max != null && price > max) return false;

  if (metadataValues.isNotEmpty) {
    final tags = metadataTagsForProductListFilter(product, allFields);
    if (!metadataValues.any(tags.contains)) return false;
  }

  final typeId = product['productTypeId'] as String?;
  return matchesListSearch(search, [
    product['name'] as String?,
    product['sku'] as String?,
    product['barcode'] as String?,
    typeId != null ? typeNames[typeId] : null,
    metadataTagsForProductListFilter(product, allFields).join(' '),
    '$price',
  ]);
}
