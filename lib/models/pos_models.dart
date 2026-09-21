import 'package:ventos_pos/utils/money.dart';

enum TaxApplicationMode { inclusive, exclusive }

TaxApplicationMode taxModeFromApi(String raw) {
  return raw == 'EXCLUSIVE'
      ? TaxApplicationMode.exclusive
      : TaxApplicationMode.inclusive;
}

enum PaymentMethod { cash, bank, mobileMoney }

enum PaymentChannelType { bankAccount, mobileMoney }

PaymentChannelType paymentChannelTypeFromApi(String raw) {
  return raw == 'BANK_ACCOUNT'
      ? PaymentChannelType.bankAccount
      : PaymentChannelType.mobileMoney;
}

class PaymentChannel {
  PaymentChannel({
    required this.id,
    required this.type,
    required this.name,
    this.accountNumber,
    this.network,
    this.number,
  });

  final String id;
  final PaymentChannelType type;
  final String name;
  final String? accountNumber;
  final String? network;
  final String? number;

  factory PaymentChannel.fromJson(Map<String, dynamic> json) {
    return PaymentChannel(
      id: json['id'] as String,
      type: paymentChannelTypeFromApi(json['type'] as String),
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String?,
      network: json['network'] as String?,
      number: json['number'] as String?,
    );
  }
}

String paymentMethodToApi(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'CASH';
    case PaymentMethod.bank:
      return 'BANK';
    case PaymentMethod.mobileMoney:
      return 'MOBILE_MONEY';
  }
}

enum ProductDiscountType { none, percent, fixed }

ProductDiscountType productDiscountTypeFromApi(String? raw) {
  switch (raw) {
    case 'PERCENT':
      return ProductDiscountType.percent;
    case 'FIXED':
      return ProductDiscountType.fixed;
    default:
      return ProductDiscountType.none;
  }
}

class ProductMetadataField {
  ProductMetadataField({
    required this.key,
    required this.label,
    this.unit,
    this.active = true,
  });

  final String key;
  final String label;
  final String? unit;
  final bool active;

  factory ProductMetadataField.fromJson(Map<String, dynamic> json) {
    return ProductMetadataField(
      key: json['key'] as String,
      label: json['label'] as String,
      unit: json['unit'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class PosProduct {
  PosProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.sku,
    this.barcode,
    this.categoryId,
    this.metadata,
    this.discountType = ProductDiscountType.none,
    this.discountValue = 0,
    required this.trackInventory,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final Map<String, String>? metadata;
  final ProductDiscountType discountType;
  final double discountValue;
  final bool trackInventory;

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      categoryId: json['categoryId'] as String?,
      metadata: _metadataFromJson(json['metadata']),
      discountType: productDiscountTypeFromApi(json['discountType'] as String?),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      trackInventory: json['trackInventory'] as bool? ?? false,
    );
  }

  static Map<String, String>? _metadataFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    return raw.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
  }
}

class StockLevel {
  StockLevel({required this.productId, required this.quantity});

  final String productId;
  final double quantity;

  factory StockLevel.fromJson(Map<String, dynamic> json) {
    return StockLevel(
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

class ProductCategory {
  ProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class PosCustomer {
  PosCustomer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  String get displayName => '$firstName $lastName'.trim();

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class TaxRule {
  TaxRule({
    required this.id,
    required this.name,
    required this.rate,
    required this.mode,
    required this.isActive,
  });

  final String id;
  final String name;
  final double rate;
  final TaxApplicationMode mode;
  final bool isActive;

  factory TaxRule.fromJson(Map<String, dynamic> json) {
    return TaxRule(
      id: json['id'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
      mode: taxModeFromApi(json['mode'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class RegisterSession {
  RegisterSession({required this.id, required this.registerId});

  final String id;
  final String registerId;

  factory RegisterSession.fromJson(Map<String, dynamic> json) {
    return RegisterSession(
      id: json['id'] as String,
      registerId: json['registerId'] as String,
    );
  }
}

class CashRegister {
  CashRegister({required this.id, required this.name});

  final String id;
  final String name;

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class PosCatalogData {
  PosCatalogData({
    required this.products,
    required this.stockLevels,
    required this.categories,
    required this.customers,
    required this.taxRules,
    required this.openSessions,
    required this.registers,
    required this.currency,
    this.metadataFields = const [],
    this.paymentChannels = const [],
  });

  final List<PosProduct> products;
  final List<StockLevel> stockLevels;
  final List<ProductCategory> categories;
  final List<PosCustomer> customers;
  final List<TaxRule> taxRules;
  final List<RegisterSession> openSessions;
  final List<CashRegister> registers;
  final CurrencyCode currency;
  final List<ProductMetadataField> metadataFields;
  final List<PaymentChannel> paymentChannels;

  Map<String, int> get stockByProductId {
    final map = <String, int>{};
    for (final row in stockLevels) {
      map[row.productId] = (map[row.productId] ?? 0) + row.quantity.floor();
    }
    return map;
  }

  String? registerNameForSession(RegisterSession? session) {
    if (session == null) return null;
    for (final r in registers) {
      if (r.id == session.registerId) return r.name;
    }
    return null;
  }
}

class CartLine {
  CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.discountAmount = 0,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double discountAmount;

  double get lineTotal {
    final total = quantity * unitPrice - discountAmount;
    return total < 0 ? 0 : total;
  }

  CartLine copyWith({int? quantity, double? discountAmount}) {
    return CartLine(
      productId: productId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

class CheckoutResult {
  CheckoutResult({required this.saleId, required this.total});

  final String saleId;
  final double total;
}
