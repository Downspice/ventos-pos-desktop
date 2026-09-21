import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos_button.dart';
import 'package:ventos_pos/theme/ventos_icons.dart';

/// Mirrors web [DeleteConfirmationModal] — switch-gated destructive confirm.
Future<bool> showVentosDeleteConfirmation({
  required BuildContext context,
  String title = 'Delete item',
  String description = 'Are you sure you want to delete this item?',
  String? itemName,
  String? itemDescription,
  String switchLabel = 'Confirm permanent deletion',
  String switchDescription = 'Toggle switch to authorize deletion of this item.',
  String confirmText = 'Yes, Delete',
  required Future<void> Function() onDelete,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _VentosDeleteConfirmationDialog(
      title: title,
      description: description,
      itemName: itemName,
      itemDescription: itemDescription,
      switchLabel: switchLabel,
      switchDescription: switchDescription,
      confirmText: confirmText,
      onDelete: onDelete,
    ),
  );
  return result == true;
}

class _VentosDeleteConfirmationDialog extends StatefulWidget {
  const _VentosDeleteConfirmationDialog({
    required this.title,
    required this.description,
    this.itemName,
    this.itemDescription,
    required this.switchLabel,
    required this.switchDescription,
    required this.confirmText,
    required this.onDelete,
  });

  final String title;
  final String description;
  final String? itemName;
  final String? itemDescription;
  final String switchLabel;
  final String switchDescription;
  final String confirmText;
  final Future<void> Function() onDelete;

  @override
  State<_VentosDeleteConfirmationDialog> createState() => _VentosDeleteConfirmationDialogState();
}

class _VentosDeleteConfirmationDialogState extends State<_VentosDeleteConfirmationDialog> {
  bool _confirmed = false;
  bool _deleting = false;

  Future<void> _handleDelete() async {
    if (!_confirmed || _deleting) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _WarningBanner(),
              if (widget.itemName != null) ...[
                const SizedBox(height: 12),
                _ItemPreviewCard(
                  name: widget.itemName!,
                  description: widget.itemDescription,
                ),
              ],
              const SizedBox(height: 12),
              _ConfirmSwitchTile(
                confirmed: _confirmed,
                enabled: !_deleting,
                label: widget.switchLabel,
                description: widget.switchDescription,
                onChanged: (v) => setState(() => _confirmed = v),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: VentosColors.strokeSoft),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    VentosButton(
                      variant: VentosButtonVariant.outline,
                      onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    VentosButton(
                      variant: VentosButtonVariant.destructive,
                      onPressed: (!_confirmed || _deleting) ? null : _handleDelete,
                      child: _deleting
                          ? const Text('Deleting…')
                          : Text(widget.confirmText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: VentosColors.destructive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
                children: [
                  TextSpan(
                    text: 'Warning: ',
                    style: TextStyle(fontWeight: FontWeight.w600, color: VentosColors.textStrong),
                  ),
                  const TextSpan(
                    text: 'This action cannot be undone. Deleting this item will permanently remove all associated data.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPreviewCard extends StatelessWidget {
  const _ItemPreviewCard({required this.name, this.description});

  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VentosColors.strokeSoft),
        color: VentosColors.cardOpaque,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VentosColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.package, size: 20, color: VentosColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (description != null && description!.isNotEmpty)
                  Text(
                    description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSwitchTile extends StatelessWidget {
  const _ConfirmSwitchTile({
    required this.confirmed,
    required this.enabled,
    required this.label,
    required this.description,
    required this.onChanged,
  });

  final bool confirmed;
  final bool enabled;
  final String label;
  final String description;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confirmed ? const Color(0xFFFECACA) : VentosColors.strokeSoft,
        ),
        color: confirmed ? const Color(0xFFFEF2F2).withValues(alpha: 0.35) : VentosColors.muted.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: confirmed,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: VentosColors.destructive.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}
