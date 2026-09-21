import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/models/home_dashboard.dart';
import 'package:ventos_pos/models/pos_sale.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/services/receipt_printer.dart';
import 'package:ventos_pos/utils/money.dart';

class PosRepository {
  PosRepository(this._client);

  final VentosGraphqlClient _client;

  static const _catalogQuery = r'''
    query PosCheckoutData {
      business {
        currency
      }
      products {
        id
        name
        price
        imageUrl
        sku
        barcode
        categoryId
        metadata
        discountType
        discountValue
        trackInventory
      }
      stockLevels {
        productId
        quantity
      }
      productCategories {
        id
        name
      }
      customers {
        id
        firstName
        lastName
        email
        phone
      }
      taxRules {
        id
        name
        rate
        mode
        isActive
      }
      openRegisterSessions {
        id
        registerId
      }
      cashRegisters {
        id
        name
      }
      paymentChannels {
        id
        type
        name
        accountNumber
        network
        number
      }
    }
  ''';

  Future<PosCatalogData> fetchCatalog() async {
    final data = await _client.query(_catalogQuery);
    final business = data['business'] as Map<String, dynamic>?;
    final metadataFields = await _tryFetchProductMetadataFields();
    return PosCatalogData(
      products: (data['products'] as List<dynamic>? ?? [])
          .map((e) => PosProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      stockLevels: (data['stockLevels'] as List<dynamic>? ?? [])
          .map((e) => StockLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (data['productCategories'] as List<dynamic>? ?? [])
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      customers: (data['customers'] as List<dynamic>? ?? [])
          .map((e) => PosCustomer.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxRules: (data['taxRules'] as List<dynamic>? ?? [])
          .map((e) => TaxRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      openSessions: (data['openRegisterSessions'] as List<dynamic>? ?? [])
          .map((e) => RegisterSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      registers: (data['cashRegisters'] as List<dynamic>? ?? [])
          .map((e) => CashRegister.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentChannels: (data['paymentChannels'] as List<dynamic>? ?? [])
          .map((e) => PaymentChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currency: currencyCodeFromApi(business?['currency'] as String?),
      metadataFields: metadataFields,
    );
  }

  Future<List<ProductMetadataField>> _tryFetchProductMetadataFields() async {
    const document = r'''
      query PosProductMetadataFields {
        productMetadataFields(includeInactive: false) {
          key
          label
          unit
          active
        }
      }
    ''';
    try {
      final data = await _client.query(document);
      return (data['productMetadataFields'] as List<dynamic>? ?? [])
          .map((e) => ProductMetadataField.fromJson(e as Map<String, dynamic>))
          .where((f) => f.active)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> ensureRegisterSession(PosCatalogData catalog) async {
    final existing = catalog.openSessions.isNotEmpty
        ? catalog.openSessions.first.id
        : null;
    if (existing != null) return existing;
    final registerId =
        catalog.registers.isNotEmpty ? catalog.registers.first.id : null;
    if (registerId == null) return null;

    const document = r'''
      mutation OpenSession($registerId: ID!) {
        openRegisterSession(registerId: $registerId, openingFloat: 0) {
          id
        }
      }
    ''';
    final data = await _client.mutate(document, variables: {
      'registerId': registerId,
    });
    final session =
        data['openRegisterSession'] as Map<String, dynamic>?;
    return session?['id'] as String?;
  }

  Future<CheckoutResult> checkout({
    required String? registerSessionId,
    required String? customerId,
    required List<CartLine> cart,
    required PaymentMethod paymentMethod,
    required String? paymentReference,
    required String? paymentChannelId,
    required double orderTotal,
  }) async {
    const createDocument = r'''
      mutation CreateSale(
        $registerSessionId: ID
        $customerId: ID
        $lines: [SaleLineInput!]!
      ) {
        createSaleDraft(
          registerSessionId: $registerSessionId
          customerId: $customerId
          lines: $lines
        ) {
          id
          total
        }
      }
    ''';

    final lines = cart
        .map((line) => {
              'lineType': 'PRODUCT',
              'productId': line.productId,
              'name': line.name,
              'quantity': line.quantity,
              'unitPrice': line.unitPrice,
              'discountAmount': line.discountAmount,
            })
        .toList();

    final draftData = await _client.mutate(createDocument, variables: {
      'registerSessionId': registerSessionId,
      'customerId': customerId,
      'lines': lines,
    });
    final draft = draftData['createSaleDraft'] as Map<String, dynamic>?;
    final saleId = draft?['id'] as String?;
    final total = (draft?['total'] as num?)?.toDouble() ?? orderTotal;
    if (saleId == null) {
      throw GraphqlException('Could not create sale.');
    }

    final payments = paymentMethod == PaymentMethod.cash
        ? [
            {
              'method': paymentMethodToApi(paymentMethod),
              'amount': total,
            },
          ]
        : [
            {
              'method': paymentMethodToApi(paymentMethod),
              'amount': total,
              'reference': paymentReference?.trim(),
              if (paymentChannelId != null && paymentChannelId.isNotEmpty)
                'paymentChannelId': paymentChannelId,
            },
          ];

    const finalizeDocument = r'''
      mutation Finalize($id: ID!, $payments: [PaymentInput!]!) {
        finalizeSale(id: $id, payments: $payments) {
          id
          total
        }
      }
    ''';

    await _client.mutate(finalizeDocument, variables: {
      'id': saleId,
      'payments': payments,
    });

    return CheckoutResult(saleId: saleId, total: total);
  }

  Future<void> printSaleReceipt(String saleId) async {
    const document = r'''
      query SaleReceipt($saleId: ID!) {
        saleReceipt(saleId: $saleId) {
          html
        }
      }
    ''';
    final data = await _client.query(document, variables: {'saleId': saleId});
    final receipt = data['saleReceipt'] as Map<String, dynamic>?;
    final html = receipt?['html'] as String?;
    if (html == null || html.isEmpty) {
      throw GraphqlException('Could not load receipt.');
    }
    await ReceiptPrinter.printReceiptHtml(html);
  }

  Future<HomeDashboardData> fetchHomeDashboard({int trendDays = 14}) async {
    const document = r'''
      query HomeDashboard($trendDays: Int) {
        homeDashboard(trendDays: $trendDays) {
          kpis {
            salesToday
            salesYesterday
            salesTodayChangePercent
            salesLast7Days
            salesLast30Days
            ordersToday
            ordersLast7Days
            avgOrderValue30Days
            openRegisterSessions
            lowStockCount
            appointmentsToday
            appointmentsNext7Days
            customerCount
            newCustomers30Days
            productCount
            expensesLast30Days
            netRevenue30Days
          }
          salesTrend {
            label
            value
            count
          }
          ordersTrend {
            label
            value
            count
          }
          salesByDayOfWeek {
            label
            value
            count
          }
          topProducts {
            id
            name
            value
            secondary
          }
          lowStockProducts {
            id
            name
            value
            secondary
          }
          appointmentsTrend {
            label
            value
            count
          }
          revenueVsExpenses {
            label
            revenue
            expenses
          }
        }
      }
    ''';
    final data = await _client.query(document, variables: {'trendDays': trendDays});
    final dashboard = data['homeDashboard'] as Map<String, dynamic>?;
    if (dashboard == null) {
      throw GraphqlException('Could not load dashboard.');
    }
    return HomeDashboardData.fromJson(dashboard);
  }

  Future<PosSalesListData> fetchSales({String? status}) async {
    const document = r'''
      query PosSales($status: String) {
        sales(status: $status) {
          id
          status
          total
          customerId
          employeeId
          createdAt
        }
        customers {
          id
          firstName
          lastName
        }
      }
    ''';
    final data = await _client.query(document, variables: {
      if (status != null) 'status': status,
    });
    final sales = (data['sales'] as List<dynamic>? ?? [])
        .map((e) => PosSaleSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    final customerNames = <String, String>{};
    for (final c in data['customers'] as List<dynamic>? ?? []) {
      final m = c as Map<String, dynamic>;
      customerNames[m['id'] as String] =
          '${m['firstName']} ${m['lastName']}'.trim();
    }
    final employeeNames = await _tryFetchEmployeeNames();
    return PosSalesListData(
      sales: sales,
      customerNames: customerNames,
      employeeNames: employeeNames,
    );
  }

  Future<Map<String, String>> _tryFetchEmployeeNames() async {
    const document = r'''
      query PosSaleEmployees {
        employees {
          id
          firstName
          lastName
        }
      }
    ''';
    try {
      final data = await _client.query(document);
      final employeeNames = <String, String>{};
      for (final e in data['employees'] as List<dynamic>? ?? []) {
        final m = e as Map<String, dynamic>;
        employeeNames[m['id'] as String] =
            '${m['firstName']} ${m['lastName']}'.trim();
      }
      return employeeNames;
    } catch (_) {
      return {};
    }
  }

  Future<PosSaleViewContext?> fetchSaleViewContext(
    String id, {
    Map<String, String> fallbackCustomerNames = const {},
    Map<String, String> fallbackEmployeeNames = const {},
  }) async {
    const document = r'''
      query PosSaleDetail($id: ID!) {
        sale(id: $id) {
          id
          status
          customerId
          registerSessionId
          employeeId
          subtotal
          discountTotal
          taxTotal
          total
          createdAt
          lines {
            lineType
            productId
            serviceId
            name
            quantity
            unitPrice
            discountAmount
            lineTotal
          }
        }
        customers {
          id
          firstName
          lastName
        }
        cashRegisters {
          id
          name
        }
      }
    ''';
    final data = await _client.query(document, variables: {'id': id});
    final saleJson = data['sale'];
    if (saleJson == null) return null;
    final sale = PosSaleDetail.fromJson(saleJson as Map<String, dynamic>);

    final customerNames = <String, String>{};
    for (final c in data['customers'] as List<dynamic>? ?? []) {
      final m = c as Map<String, dynamic>;
      customerNames[m['id'] as String] =
          '${m['firstName']} ${m['lastName']}'.trim();
    }
    final employeeNames = Map<String, String>.from(fallbackEmployeeNames);
    employeeNames.addAll(await _tryFetchEmployeeNames());
    final registerNames = <String, String>{};
    for (final r in data['cashRegisters'] as List<dynamic>? ?? []) {
      final m = r as Map<String, dynamic>;
      registerNames[m['id'] as String] = m['name'] as String;
    }
    final productImageById = <String, String?>{};
    try {
      const productsDoc = r'''
        query SaleProductImages {
          products {
            id
            imageUrl
          }
        }
      ''';
      final productData = await _client.query(productsDoc);
      for (final p in productData['products'] as List<dynamic>? ?? []) {
        final m = p as Map<String, dynamic>;
        productImageById[m['id'] as String] = m['imageUrl'] as String?;
      }
    } catch (_) {
      // Cashiers may lack inventory.read; line items still show without images.
    }

    final serviceImageById = <String, String?>{};
    try {
      const servicesDoc = r'''
        query SaleServiceImages {
          services {
            id
            imageUrl
          }
        }
      ''';
      final serviceData = await _client.query(servicesDoc);
      for (final s in serviceData['services'] as List<dynamic>? ?? []) {
        final m = s as Map<String, dynamic>;
        serviceImageById[m['id'] as String] = m['imageUrl'] as String?;
      }
    } catch (_) {
      // Optional; service lines still show without images.
    }

    String? registerLabel;
    if (sale.registerSessionId != null) {
      const sessionDoc = r'''
        query SaleRegisterSession($id: ID!) {
          registerSession(id: $id) {
            registerId
          }
        }
      ''';
      final sessionData = await _client.query(sessionDoc, variables: {
        'id': sale.registerSessionId,
      });
      final session = sessionData['registerSession'] as Map<String, dynamic>?;
      final registerId = session?['registerId'] as String?;
      if (registerId != null) {
        registerLabel = registerNames[registerId] ?? 'Unknown register';
      }
    }

    final customerNamesMerged = Map<String, String>.from(fallbackCustomerNames);
    customerNamesMerged.addAll(customerNames);

    final customerLabel = sale.customerId != null
        ? customerNamesMerged[sale.customerId] ?? 'Unknown customer'
        : 'Walk-in';
    final employeeLabel = sale.employeeId != null
        ? employeeNames[sale.employeeId] ?? 'Unknown employee'
        : null;

    return PosSaleViewContext(
      sale: sale,
      customerLabel: customerLabel,
      employeeLabel: employeeLabel,
      registerLabel: registerLabel,
      productImageById: productImageById,
      serviceImageById: serviceImageById,
    );
  }
}
