import 'package:flutter/material.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/utils/money.dart';
import 'package:ventos_pos/widgets/pos/pos_home_dashboard.dart';
import 'package:ventos_pos/widgets/pos/pos_sales_list.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.pos,
    required this.businessName,
    required this.canViewSales,
    required this.refreshKey,
  });

  final PosRepository pos;
  final String? businessName;
  final bool canViewSales;
  final int refreshKey;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _money(double n) => formatMoneyMajor(n, CurrencyCode.ghs);

  @override
  Widget build(BuildContext context) {
    return VentosPageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosHomeDashboardPanel(
            pos: widget.pos,
            formatMoney: _money,
            businessName: widget.businessName,
            refreshKey: widget.refreshKey,
          ),
          if (widget.canViewSales) ...[
            const SizedBox(height: 24),
            PosSalesList(
              pos: widget.pos,
              formatMoney: _money,
              refreshKey: widget.refreshKey,
            ),
          ],
        ],
      ),
    );
  }
}
