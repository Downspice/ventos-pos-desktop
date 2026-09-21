import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ventos_pos/models/pos_models.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/compute_sale_tax.dart';
import 'package:ventos_pos/utils/payment_channel_display.dart';
import 'package:ventos_pos/widgets/pos/pos_order_totals.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class PosPaymentDialog extends StatefulWidget {
  const PosPaymentDialog({
    super.key,
    required this.orderTotal,
    required this.subtotal,
    required this.taxSummary,
    required this.formatMoney,
    required this.paymentChannels,
    required this.onComplete,
  });

  final double orderTotal;
  final double subtotal;
  final SaleTaxSummary taxSummary;
  final String Function(double) formatMoney;
  final List<PaymentChannel> paymentChannels;
  final Future<void> Function(
    PaymentMethod method,
    String? reference,
    String? paymentChannelId,
  ) onComplete;

  @override
  State<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  String? _paymentChannelId;
  final _cashController = TextEditingController();
  final _refController = TextEditingController();
  bool _checkingOut = false;
  String? _checkoutError;

  List<PaymentChannel> get _channelsForMethod =>
      paymentChannelsForMethod(_method, widget.paymentChannels);

  bool get _channelOk {
    if (!paymentChannelRequired(_method, widget.paymentChannels)) return true;
    final id = _paymentChannelId;
    return id != null && id.isNotEmpty;
  }

  void _syncChannelForMethod(PaymentMethod method) {
    final options = paymentChannelsForMethod(method, widget.paymentChannels);
    _paymentChannelId = options.isEmpty ? null : options.first.id;
  }

  @override
  void initState() {
    super.initState();
    if (widget.orderTotal > 0) {
      _cashController.text = widget.orderTotal.toStringAsFixed(2);
    }
    _syncChannelForMethod(_method);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _refController.dispose();
    super.dispose();
  }

  double? get _tendered => double.tryParse(_cashController.text.trim());

  double get _change {
    if (_method != PaymentMethod.cash) return 0;
    final t = _tendered;
    if (t == null) return 0;
    final c = t - widget.orderTotal;
    return c > 0 ? c : 0;
  }

  bool get _canConfirm {
    if (widget.orderTotal <= 0) return false;
    if (_method == PaymentMethod.cash) {
      final t = _tendered;
      return t != null && t >= widget.orderTotal;
    }
    return _refController.text.trim().isNotEmpty && _channelOk;
  }

  Future<void> _confirm() async {
    if (!_canConfirm || _checkingOut) return;
    setState(() {
      _checkingOut = true;
      _checkoutError = null;
    });
    try {
      await widget.onComplete(
        _method,
        _method == PaymentMethod.cash ? null : _refController.text.trim(),
        _method == PaymentMethod.cash ? null : _paymentChannelId,
      );
      if (mounted) Navigator.pop(context, true);
    } on GraphqlException catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingOut = false;
        _checkoutError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingOut = false;
        _checkoutError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Take payment', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'Order total: '),
                    TextSpan(
                      text: widget.formatMoney(widget.orderTotal),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PosOrderTotals(
                subtotal: widget.subtotal,
                taxLines: widget.taxSummary.lines,
                taxTotal: widget.taxSummary.taxTotal,
                total: widget.orderTotal,
                formatMoney: widget.formatMoney,
                size: PosOrderTotalsSize.sm,
              ),
              const SizedBox(height: 16),
              VentosSelect<PaymentMethod>(
                label: 'Payment method',
                triggerHeight: 40,
                value: _method,
                entries: const [
                  VentosSelectEntry(value: PaymentMethod.cash, label: 'Cash'),
                  VentosSelectEntry(value: PaymentMethod.bank, label: 'Bank'),
                  VentosSelectEntry(value: PaymentMethod.mobileMoney, label: 'Mobile money'),
                ],
                onChanged: _checkingOut
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() {
                          _method = v;
                          _checkoutError = null;
                          _syncChannelForMethod(v);
                          if (v == PaymentMethod.cash && _cashController.text.isEmpty) {
                            _cashController.text =
                                widget.orderTotal.toStringAsFixed(2);
                          } else if (v != PaymentMethod.cash) {
                            _refController.clear();
                          }
                        });
                      },
              ),
              const SizedBox(height: 12),
              if (_method == PaymentMethod.cash) ...[
                VentosTextField(
                  controller: _cashController,
                  label: 'Amount received',
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: VentosColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Change due', style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        _tendered != null && _tendered! >= widget.orderTotal
                            ? widget.formatMoney(_change)
                            : '—',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (_tendered != null && _tendered! < widget.orderTotal)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Amount received is less than the total.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.amber.shade800),
                    ),
                  ),
              ] else ...[
                if (_channelsForMethod.isNotEmpty)
                  VentosSelect<String>(
                    label: 'Payment channel',
                    triggerHeight: 40,
                    value: _paymentChannelId,
                    entries: [
                      for (final ch in _channelsForMethod)
                        VentosSelectEntry(
                          value: ch.id,
                          label: paymentChannelSelectLabel(ch),
                        ),
                    ],
                    onChanged: _checkingOut
                        ? null
                        : (v) => setState(() => _paymentChannelId = v),
                  )
                else
                  Text(
                    _method == PaymentMethod.bank
                        ? 'No bank channels configured. Add them in Admin → Settings.'
                        : 'No mobile money channels configured. Add them in Admin → Settings.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                VentosTextField(
                  controller: _refController,
                  label: 'Transaction code / reference',
                  hintText: _method == PaymentMethod.bank
                      ? 'e.g. bank transaction ID'
                      : 'e.g. MoMo reference',
                  autofocus: _channelsForMethod.isEmpty,
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Full order amount (${widget.formatMoney(widget.orderTotal)}) will be recorded for this payment.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
              if (_checkoutError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_checkoutError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VentosButton(
                    onPressed: _checkingOut ? null : () => Navigator.pop(context),
                    variant: VentosButtonVariant.outline,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  VentosButton(
                    onPressed: _canConfirm && !_checkingOut ? _confirm : null,
                    child: Text(_checkingOut ? 'Processing…' : 'Complete sale'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
