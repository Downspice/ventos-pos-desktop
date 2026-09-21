import 'package:ventos_pos/models/pos_models.dart';

/// Metadata kept out of the POS display name (shown as badges / subtitle instead).
const posProductDisplayNameExcludeKeys = ['type'];

class ProductMetadataTagOptions {
  const ProductMetadataTagOptions({this.excludeKeys, this.includeKeys});

  final List<String>? excludeKeys;
  final List<String>? includeKeys;
}

bool _shouldIncludeMetadataKey(String key, ProductMetadataTagOptions? options) {
  final include = options?.includeKeys;
  if (include != null && include.isNotEmpty) {
    return include.contains(key);
  }
  final exclude = options?.excludeKeys;
  if (exclude != null && exclude.contains(key)) return false;
  return true;
}

/// Compact metadata values for tags or POS display names (value + unit, no field labels).
List<String> buildProductMetadataTags(
  PosProduct product,
  List<ProductMetadataField> metadataFields, {
  ProductMetadataTagOptions? options,
}) {
  final meta = product.metadata;
  if (meta == null || meta.isEmpty) return [];

  final knownKeys = metadataFields.map((f) => f.key).toSet();
  final tags = <String>[];

  for (final f in metadataFields) {
    if (!_shouldIncludeMetadataKey(f.key, options)) continue;
    final v = meta[f.key]?.trim();
    if (v == null || v.isEmpty) continue;
    final unit = f.unit?.trim();
    tags.add(unit != null && unit.isNotEmpty ? '$v $unit' : v);
  }

  if (options?.includeKeys != null && options!.includeKeys!.isNotEmpty) {
    return tags;
  }

  for (final entry in meta.entries) {
    if (!knownKeys.contains(entry.key) &&
        _shouldIncludeMetadataKey(entry.key, options) &&
        entry.value.trim().isNotEmpty) {
      tags.add(entry.value.trim());
    }
  }

  return tags;
}

/// POS catalog / cart title: base name plus variant attributes (product type stays in badges).
String posProductDisplayName(
  PosProduct product,
  List<ProductMetadataField> metadataFields, {
  List<String> excludeKeys = posProductDisplayNameExcludeKeys,
}) {
  final suffix = buildProductMetadataTags(
    product,
    metadataFields,
    options: ProductMetadataTagOptions(excludeKeys: excludeKeys),
  );
  if (suffix.isEmpty) return product.name;
  return '${product.name} · ${suffix.join(' · ')}';
}
