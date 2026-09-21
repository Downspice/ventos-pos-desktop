import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ventos_pos/models/home_dashboard.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

const _chartColors = [
  Color(0xFF2563EB),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
  Color(0xFFEA580C),
];

class PosHomeDashboardPanel extends StatefulWidget {
  const PosHomeDashboardPanel({
    super.key,
    required this.pos,
    required this.formatMoney,
    this.businessName,
    this.refreshKey = 0,
  });

  final PosRepository pos;
  final String Function(double) formatMoney;
  final String? businessName;
  final int refreshKey;

  @override
  State<PosHomeDashboardPanel> createState() => _PosHomeDashboardPanelState();
}

class _PosHomeDashboardPanelState extends State<PosHomeDashboardPanel> {
  HomeDashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PosHomeDashboardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _load(silent: _data != null);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await widget.pos.fetchHomeDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _shortDate(String isoDate) {
    try {
      final d = DateTime.parse('${isoDate}T12:00:00');
      return DateFormat.MMMd().format(d);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const VentosCard(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _data == null) {
      return VentosCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: VentosColors.destructive)),
            const SizedBox(height: 12),
            VentosButton(onPressed: () => _load(), child: const Text('Retry')),
          ],
        ),
      );
    }

    final dash = _data;
    if (dash == null) return const SizedBox.shrink();

    final kpis = dash.kpis;
    final business = widget.businessName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          business != null
              ? '$business — live sales, inventory, and appointment metrics.'
              : 'Operational dashboard',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: VentosColors.destructive, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final kpiCols = constraints.maxWidth >= 900 ? 4 : 2;
            final chartCols = constraints.maxWidth >= 900 ? 2 : 1;
            final kpiCards = [
              _KpiCard(
                title: 'Sales today',
                value: widget.formatMoney(kpis.salesToday),
                trendPercent: kpis.salesTodayChangePercent,
                icon: LucideIcons.banknote,
              ),
              _KpiCard(
                title: 'Last 7 days',
                value: widget.formatMoney(kpis.salesLast7Days),
                hint: '${kpis.ordersLast7Days} orders',
                icon: LucideIcons.shopping_bag,
              ),
              _KpiCard(
                title: 'Net (30 days)',
                value: widget.formatMoney(kpis.netRevenue30Days),
                hint: 'Expenses ${widget.formatMoney(kpis.expensesLast30Days)}',
                icon: LucideIcons.wallet,
              ),
              _KpiCard(
                title: 'Avg order (30d)',
                value: widget.formatMoney(kpis.avgOrderValue30Days),
                hint: '${kpis.ordersToday} orders today',
                icon: LucideIcons.trending_up,
              ),
              _KpiCard(
                title: 'Customers',
                value: '${kpis.customerCount}',
                hint: '+${kpis.newCustomers30Days} this month',
                icon: LucideIcons.users,
              ),
              _KpiCard(
                title: 'Products',
                value: '${kpis.productCount}',
                hint: '${kpis.lowStockCount} low-stock SKUs',
                icon: LucideIcons.package,
              ),
              _KpiCard(
                title: 'Appointments',
                value: '${kpis.appointmentsToday}',
                hint: '${kpis.appointmentsNext7Days} in next 7 days',
                icon: LucideIcons.calendar,
              ),
              _KpiCard(
                title: 'Open registers',
                value: '${kpis.openRegisterSessions}',
                hint: '30d sales ${widget.formatMoney(kpis.salesLast30Days)}',
                icon: LucideIcons.store,
              ),
            ];

            final charts = <Widget>[
              _ChartCard(
                title: 'Revenue trend',
                subtitle: 'Daily finalized sales (14 days)',
                child: _RevenueAreaChart(
                  data: dash.salesTrend,
                  formatMoney: widget.formatMoney,
                  shortDate: _shortDate,
                ),
              ),
              _ChartCard(
                title: 'Orders per day',
                subtitle: 'Transaction count',
                child: _OrdersBarChart(
                  data: dash.ordersTrend,
                  shortDate: _shortDate,
                ),
              ),
              _ChartCard(
                title: 'Revenue vs expenses',
                subtitle: 'Daily comparison (14 days)',
                child: _RevenueExpensesLineChart(
                  data: dash.revenueVsExpenses,
                  formatMoney: widget.formatMoney,
                  shortDate: _shortDate,
                ),
              ),
              _ChartCard(
                title: 'Sales by weekday',
                subtitle: 'Last 30 days aggregated',
                child: _WeekdayBarChart(
                  data: dash.salesByDayOfWeek,
                  formatMoney: widget.formatMoney,
                ),
              ),
              _ChartCard(
                title: 'Top products',
                subtitle: 'Revenue share (30 days)',
                child: _TopProductsPie(
                  data: dash.topProducts,
                  formatMoney: widget.formatMoney,
                ),
              ),
              _ChartCard(
                title: 'Appointments (7 days)',
                subtitle: 'Scheduled by day',
                child: _AppointmentsLineChart(
                  data: dash.appointmentsTrend,
                  shortDate: _shortDate,
                ),
              ),
            ];

            if (dash.lowStockProducts.isNotEmpty) {
              charts.add(
                _ChartCard(
                  title: 'Low stock alert',
                  subtitle: 'Products at or below threshold',
                  child: _LowStockBars(items: dash.lowStockProducts),
                ),
              );
            }

            final kpiGap = 12.0;
            final kpiWidth = (constraints.maxWidth - kpiGap * (kpiCols - 1)) / kpiCols;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: kpiGap,
                  runSpacing: kpiGap,
                  children: [
                    for (final card in kpiCards)
                      SizedBox(width: kpiWidth, child: card),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: chartCols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: chartCols >= 2 ? 1.35 : 1.15,
                  children: charts,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.hint,
    this.trendPercent,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? hint;
  final double? trendPercent;

  @override
  Widget build(BuildContext context) {
    final trend = trendPercent;
    return VentosCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                ),
              ),
              Icon(icon, size: 16, color: VentosColors.mutedForeground),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)),
          ],
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(
              '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}% vs yesterday',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: trend >= 0 ? const Color(0xFF059669) : VentosColors.destructive,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VentosCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RevenueAreaChart extends StatelessWidget {
  const _RevenueAreaChart({
    required this.data,
    required this.formatMoney,
    required this.shortDate,
  });

  final List<DashboardSeriesPoint> data;
  final String Function(double) formatMoney;
  final String Function(String) shortDate;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No sales yet.'));
    final spots = [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].value),
    ];
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: VentosColors.strokeSoft, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                formatMoney(v),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortDate(data[i].label),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _chartColors[0],
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _chartColors[0].withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersBarChart extends StatelessWidget {
  const _OrdersBarChart({required this.data, required this.shortDate});

  final List<DashboardSeriesPoint> data;
  final String Function(String) shortDate;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No orders yet.'));
    final maxY = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: VentosColors.strokeSoft, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(shortDate(data[i].label), style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  color: _chartColors[1],
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueExpensesLineChart extends StatelessWidget {
  const _RevenueExpensesLineChart({
    required this.data,
    required this.formatMoney,
    required this.shortDate,
  });

  final List<DashboardFinancePoint> data;
  final String Function(double) formatMoney;
  final String Function(String) shortDate;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data yet.'));
    final revSpots = [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].revenue)];
    final expSpots = [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].expenses)];
    final maxY = [
      ...revSpots.map((s) => s.y),
      ...expSpots.map((s) => s.y),
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            _LegendDot(color: _chartColors[0], label: 'Revenue'),
            const SizedBox(width: 16),
            _LegendDot(color: _chartColors[2], label: 'Expenses'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY * 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: VentosColors.strokeSoft, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) =>
                        Text(formatMoney(v), style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Text(shortDate(data[i].label), style: Theme.of(context).textTheme.labelSmall);
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: revSpots,
                  isCurved: true,
                  color: _chartColors[0],
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: expSpots,
                  isCurved: true,
                  color: _chartColors[2],
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _WeekdayBarChart extends StatelessWidget {
  const _WeekdayBarChart({required this.data, required this.formatMoney});

  final List<DashboardSeriesPoint> data;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No sales yet.'));
    final maxY = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: VentosColors.strokeSoft, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(formatMoney(v), style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(data[i].label, style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  color: _chartColors[3],
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TopProductsPie extends StatelessWidget {
  const _TopProductsPie({required this.data, required this.formatMoney});

  final List<DashboardRankedItem> data;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No product sales yet.'));
    }
    final total = data.fold<double>(0, (s, p) => s + p.value);
    if (total <= 0) return const Center(child: Text('No product sales yet.'));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].value,
                    color: _chartColors[i % _chartColors.length],
                    radius: 52,
                    title: '',
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final name = data[i].name;
              final short = name.length > 18 ? '${name.substring(0, 16)}…' : name;
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _chartColors[i % _chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(short, style: Theme.of(context).textTheme.labelSmall)),
                  Text(formatMoney(data[i].value), style: Theme.of(context).textTheme.labelSmall),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AppointmentsLineChart extends StatelessWidget {
  const _AppointmentsLineChart({required this.data, required this.shortDate});

  final List<DashboardSeriesPoint> data;
  final String Function(String) shortDate;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No appointments scheduled.'));
    final spots = [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].value)];
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: VentosColors.strokeSoft, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(shortDate(data[i].label), style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _chartColors[4],
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _LowStockBars extends StatelessWidget {
  const _LowStockBars({required this.items});

  final List<DashboardRankedItem> items;

  @override
  Widget build(BuildContext context) {
    final maxQty = items.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        final name = item.name.length > 14 ? '${item.name.substring(0, 12)}…' : item.name;
        final fraction = maxQty > 0 ? item.value / maxQty : 0.0;
        return Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(name, style: Theme.of(context).textTheme.labelSmall),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.05, 1.0),
                  minHeight: 10,
                  backgroundColor: VentosColors.muted.withValues(alpha: 0.4),
                  color: VentosColors.destructive.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${item.value.toInt()}', style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      },
    );
  }
}
