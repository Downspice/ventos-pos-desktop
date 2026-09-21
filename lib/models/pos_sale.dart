class PosSaleSummary {
  PosSaleSummary({
    required this.id,
    required this.status,
    required this.total,
    this.customerId,
    this.employeeId,
    required this.createdAt,
  });

  final String id;
  final String status;
  final double total;
  final String? customerId;
  final String? employeeId;
  final DateTime createdAt;

  factory PosSaleSummary.fromJson(Map<String, dynamic> json) {
    return PosSaleSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      customerId: json['customerId'] as String?,
      employeeId: json['employeeId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PosSaleLine {
  PosSaleLine({
    required this.lineType,
    this.productId,
    this.serviceId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.lineTotal,
  });

  final String lineType;
  final String? productId;
  final String? serviceId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double lineTotal;

  factory PosSaleLine.fromJson(Map<String, dynamic> json) {
    return PosSaleLine(
      lineType: json['lineType'] as String,
      productId: json['productId'] as String?,
      serviceId: json['serviceId'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}

class PosSaleDetail {
  PosSaleDetail({
    required this.id,
    required this.status,
    this.customerId,
    this.registerSessionId,
    this.employeeId,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.createdAt,
    required this.lines,
  });

  final String id;
  final String status;
  final String? customerId;
  final String? registerSessionId;
  final String? employeeId;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final DateTime createdAt;
  final List<PosSaleLine> lines;

  factory PosSaleDetail.fromJson(Map<String, dynamic> json) {
    return PosSaleDetail(
      id: json['id'] as String,
      status: json['status'] as String,
      customerId: json['customerId'] as String?,
      registerSessionId: json['registerSessionId'] as String?,
      employeeId: json['employeeId'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0,
      taxTotal: (json['taxTotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => PosSaleLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PosSaleViewContext {
  PosSaleViewContext({
    required this.sale,
    required this.customerLabel,
    this.employeeLabel,
    this.registerLabel,
    required this.productImageById,
    required this.serviceImageById,
  });

  final PosSaleDetail sale;
  final String customerLabel;
  final String? employeeLabel;
  final String? registerLabel;
  final Map<String, String?> productImageById;
  final Map<String, String?> serviceImageById;

  String? imageUrlForLine(PosSaleLine line) {
    if (line.productId != null) return productImageById[line.productId];
    if (line.serviceId != null) return serviceImageById[line.serviceId];
    return null;
  }
}

class PosSalesListData {
  PosSalesListData({
    required this.sales,
    required this.customerNames,
    required this.employeeNames,
  });

  final List<PosSaleSummary> sales;
  final Map<String, String> customerNames;
  final Map<String, String> employeeNames;
}
