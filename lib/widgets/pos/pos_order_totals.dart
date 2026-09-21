import 'package:flutter/material.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/utils/compute_sale_tax.dart';

enum PosOrderTotalsSize { sm, md }

/// Matches web `PosOrderTotals`.
class PosOrderTotals extends StatelessWidget {
  const PosOrderTotals({
    super.key,
    required this.subtotal,
    required this.taxLines,
    required this.taxTotal,
    required this.total,
    required this.formatMoney,
    this.size = PosOrderTotalsSize.md,
  });

  final double subtotal;
  final List<ComputedTaxLine> taxLines;
  final double taxTotal;
  final double total;
  final String Function(double) formatMoney;
  final PosOrderTotalsSize size;

  @override
  Widget build(BuildContext context) {
    final totalStyle = size == PosOrderTotalsSize.md
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleSmall;
    final rowStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      children: [
        if (taxLines.isNotEmpty) ...[
          _Row(label: 'Subtotal', value: formatMoney(subtotal), style: rowStyle),
          for (final line in taxLines)
            _Row(
              label:
                  '${line.name} (${line.rate.toStringAsFixed(0)}% ${line.mode == TaxApplicationMode.inclusive ? 'in price' : 'on top'})',
              value: formatMoney(line.amount),
              style: rowStyle,
            ),
          if (taxTotal > 0)
            _Row(label: 'Tax', value: formatMoney(taxTotal), style: rowStyle),
        ],
        _Row(label: 'Total', value: formatMoney(total), style: totalStyle),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
