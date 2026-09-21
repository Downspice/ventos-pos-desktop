import 'package:ventos_pos/models/pos_models.dart';

class ComputedTaxLine {
  ComputedTaxLine({
    required this.name,
    required this.mode,
    required this.rate,
    required this.amount,
  });

  final String name;
  final TaxApplicationMode mode;
  final double rate;
  final double amount;
}

class SaleTaxSummary {
  SaleTaxSummary({
    required this.taxTotal,
    required this.exclusiveTax,
    required this.inclusiveTax,
    required this.lines,
    required this.total,
  });

  final double taxTotal;
  final double exclusiveTax;
  final double inclusiveTax;
  final List<ComputedTaxLine> lines;
  final double total;
}

double _round2(double n) => (n * 100).roundToDouble() / 100;

/// Mirrors web `computeSaleTax` for POS previews (major units).
SaleTaxSummary computeSaleTax(double taxableSubtotal, List<TaxRule> rules) {
  final active = rules.where((r) => r.isActive && r.rate > 0).toList();
  var exclusiveTax = 0.0;
  var inclusiveTax = 0.0;
  final lines = <ComputedTaxLine>[];

  for (final rule in active) {
    if (rule.mode == TaxApplicationMode.exclusive) {
      final amount = _round2(taxableSubtotal * (rule.rate / 100));
      exclusiveTax += amount;
      lines.add(ComputedTaxLine(
        name: rule.name,
        mode: rule.mode,
        rate: rule.rate,
        amount: amount,
      ));
    } else {
      final amount =
          _round2(taxableSubtotal - taxableSubtotal / (1 + rule.rate / 100));
      inclusiveTax += amount;
      lines.add(ComputedTaxLine(
        name: rule.name,
        mode: rule.mode,
        rate: rule.rate,
        amount: amount,
      ));
    }
  }

  final taxTotal = _round2(exclusiveTax + inclusiveTax);
  final total = _round2(taxableSubtotal + exclusiveTax);

  return SaleTaxSummary(
    taxTotal: taxTotal,
    exclusiveTax: exclusiveTax,
    inclusiveTax: inclusiveTax,
    lines: lines,
    total: total,
  );
}
