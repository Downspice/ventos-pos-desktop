import 'package:ventos_pos/models/pos_models.dart';

String paymentChannelSummary(PaymentChannel row) {
  if (row.type == PaymentChannelType.bankAccount) {
    return row.accountNumber ?? '—';
  }
  final parts = [row.network, row.number].whereType<String>().where((s) => s.isNotEmpty);
  final joined = parts.join(' · ');
  return joined.isEmpty ? '—' : joined;
}

String paymentChannelSelectLabel(PaymentChannel row) {
  final detail = paymentChannelSummary(row);
  return detail == '—' ? row.name : '${row.name} · $detail';
}

List<PaymentChannel> paymentChannelsForMethod(
  PaymentMethod method,
  List<PaymentChannel> channels,
) {
  if (method == PaymentMethod.cash) return const [];
  if (method == PaymentMethod.bank) {
    return channels.where((c) => c.type == PaymentChannelType.bankAccount).toList();
  }
  return channels.where((c) => c.type == PaymentChannelType.mobileMoney).toList();
}

bool paymentChannelRequired(PaymentMethod method, List<PaymentChannel> channels) {
  return paymentChannelsForMethod(method, channels).isNotEmpty;
}
