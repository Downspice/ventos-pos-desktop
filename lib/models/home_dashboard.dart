class HomeDashboardData {
  HomeDashboardData({
    required this.kpis,
    required this.salesTrend,
    required this.ordersTrend,
    required this.salesByDayOfWeek,
    required this.topProducts,
    required this.lowStockProducts,
    required this.appointmentsTrend,
    required this.revenueVsExpenses,
  });

  final HomeDashboardKpis kpis;
  final List<DashboardSeriesPoint> salesTrend;
  final List<DashboardSeriesPoint> ordersTrend;
  final List<DashboardSeriesPoint> salesByDayOfWeek;
  final List<DashboardRankedItem> topProducts;
  final List<DashboardRankedItem> lowStockProducts;
  final List<DashboardSeriesPoint> appointmentsTrend;
  final List<DashboardFinancePoint> revenueVsExpenses;

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    List<DashboardSeriesPoint> series(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .map((e) => DashboardSeriesPoint.fromJson(e as Map<String, dynamic>))
            .toList();

    return HomeDashboardData(
      kpis: HomeDashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {}),
      salesTrend: series('salesTrend'),
      ordersTrend: series('ordersTrend'),
      salesByDayOfWeek: series('salesByDayOfWeek'),
      topProducts: (json['topProducts'] as List<dynamic>? ?? [])
          .map((e) => DashboardRankedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowStockProducts: (json['lowStockProducts'] as List<dynamic>? ?? [])
          .map((e) => DashboardRankedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      appointmentsTrend: series('appointmentsTrend'),
      revenueVsExpenses: (json['revenueVsExpenses'] as List<dynamic>? ?? [])
          .map((e) => DashboardFinancePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HomeDashboardKpis {
  HomeDashboardKpis({
    required this.salesToday,
    required this.salesYesterday,
    required this.salesTodayChangePercent,
    required this.salesLast7Days,
    required this.salesLast30Days,
    required this.ordersToday,
    required this.ordersLast7Days,
    required this.avgOrderValue30Days,
    required this.openRegisterSessions,
    required this.lowStockCount,
    required this.appointmentsToday,
    required this.appointmentsNext7Days,
    required this.customerCount,
    required this.newCustomers30Days,
    required this.productCount,
    required this.expensesLast30Days,
    required this.netRevenue30Days,
  });

  final double salesToday;
  final double salesYesterday;
  final double salesTodayChangePercent;
  final double salesLast7Days;
  final double salesLast30Days;
  final int ordersToday;
  final int ordersLast7Days;
  final double avgOrderValue30Days;
  final int openRegisterSessions;
  final int lowStockCount;
  final int appointmentsToday;
  final int appointmentsNext7Days;
  final int customerCount;
  final int newCustomers30Days;
  final int productCount;
  final double expensesLast30Days;
  final double netRevenue30Days;

  factory HomeDashboardKpis.fromJson(Map<String, dynamic> json) {
    return HomeDashboardKpis(
      salesToday: (json['salesToday'] as num?)?.toDouble() ?? 0,
      salesYesterday: (json['salesYesterday'] as num?)?.toDouble() ?? 0,
      salesTodayChangePercent: (json['salesTodayChangePercent'] as num?)?.toDouble() ?? 0,
      salesLast7Days: (json['salesLast7Days'] as num?)?.toDouble() ?? 0,
      salesLast30Days: (json['salesLast30Days'] as num?)?.toDouble() ?? 0,
      ordersToday: (json['ordersToday'] as num?)?.toInt() ?? 0,
      ordersLast7Days: (json['ordersLast7Days'] as num?)?.toInt() ?? 0,
      avgOrderValue30Days: (json['avgOrderValue30Days'] as num?)?.toDouble() ?? 0,
      openRegisterSessions: (json['openRegisterSessions'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      appointmentsToday: (json['appointmentsToday'] as num?)?.toInt() ?? 0,
      appointmentsNext7Days: (json['appointmentsNext7Days'] as num?)?.toInt() ?? 0,
      customerCount: (json['customerCount'] as num?)?.toInt() ?? 0,
      newCustomers30Days: (json['newCustomers30Days'] as num?)?.toInt() ?? 0,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      expensesLast30Days: (json['expensesLast30Days'] as num?)?.toDouble() ?? 0,
      netRevenue30Days: (json['netRevenue30Days'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardSeriesPoint {
  DashboardSeriesPoint({required this.label, required this.value, this.count = 0});

  final String label;
  final double value;
  final int count;

  factory DashboardSeriesPoint.fromJson(Map<String, dynamic> json) {
    return DashboardSeriesPoint(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardRankedItem {
  DashboardRankedItem({
    required this.id,
    required this.name,
    required this.value,
    this.secondary,
  });

  final String id;
  final String name;
  final double value;
  final double? secondary;

  factory DashboardRankedItem.fromJson(Map<String, dynamic> json) {
    return DashboardRankedItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      secondary: (json['secondary'] as num?)?.toDouble(),
    );
  }
}

class DashboardFinancePoint {
  DashboardFinancePoint({
    required this.label,
    required this.revenue,
    required this.expenses,
  });

  final String label;
  final double revenue;
  final double expenses;

  factory DashboardFinancePoint.fromJson(Map<String, dynamic> json) {
    return DashboardFinancePoint(
      label: json['label'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
    );
  }
}
