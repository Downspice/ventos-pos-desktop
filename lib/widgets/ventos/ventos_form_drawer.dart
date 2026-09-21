import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_button.dart';
import 'package:ventos_pos/widgets/ventos/ventos_end_sheet.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

/// Right-side form drawer — mirrors web [FormDrawer] (`sm:max-w-md`).
Future<bool?> showVentosFormDrawer({
  required BuildContext context,
  required String title,
  String? description,
  String submitLabel = 'Save',
  bool readOnly = false,
  required Widget body,
  required Future<void> Function() onSubmit,
  double width = 448,
}) {
  return showVentosEndSheet<bool>(
    context: context,
    width: width,
    child: _VentosFormDrawerShell(
      title: title,
      description: description,
      submitLabel: submitLabel,
      readOnly: readOnly,
      onSubmit: onSubmit,
      body: body,
    ),
  );
}

class _VentosFormDrawerShell extends StatefulWidget {
  const _VentosFormDrawerShell({
    required this.title,
    this.description,
    required this.submitLabel,
    required this.readOnly,
    required this.onSubmit,
    required this.body,
  });

  final String title;
  final String? description;
  final String submitLabel;
  final bool readOnly;
  final Future<void> Function() onSubmit;
  final Widget body;

  @override
  State<_VentosFormDrawerShell> createState() => _VentosFormDrawerShellState();
}

class _VentosFormDrawerShellState extends State<_VentosFormDrawerShell> {
  bool _submitting = false;
  String? _error;

  Future<void> _handleSubmit() async {
    if (widget.readOnly || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 6),
                Text(widget.description!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: VentosColors.strokeSoft),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IgnorePointer(
                  ignoring: widget.readOnly,
                  child: widget.body,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: VentosColors.destructive, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: VentosColors.strokeSoft),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VentosButton(
                variant: VentosButtonVariant.outline,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                child: Text(widget.readOnly ? 'Close' : 'Cancel'),
              ),
              if (!widget.readOnly) ...[
                const SizedBox(width: 8),
                VentosButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Primary action for list pages — web [NewButton].
class VentosNewButton extends StatelessWidget {
  const VentosNewButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return VentosButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.plus, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
