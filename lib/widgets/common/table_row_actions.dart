import 'package:flutter/material.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Matches web `TableRowActions` (outline icon buttons, right-aligned).
class TableRowActions extends StatelessWidget {
  const TableRowActions({
    super.key,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.deleteTitle = 'Delete item',
    this.deleteDescription =
        'Are you sure you want to delete this item? It will be archived and recorded in the audit log.',
    this.itemName,
    this.itemDescription,
    this.onDeleted,
  });

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final VoidCallback? onDeleted;
  final String deleteTitle;
  final String deleteDescription;
  final String? itemName;
  final String? itemDescription;

  @override
  Widget build(BuildContext context) {
    if (onView == null && onEdit == null && onDelete == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onView != null)
          Tooltip(
            message: 'View',
            child: VentosOutlineIconButton(
              onPressed: onView,
              icon: LucideIcons.eye,
            ),
          ),
        if (onEdit != null) ...[
          if (onView != null) const SizedBox(width: 2),
          Tooltip(
            message: 'Edit',
            child: VentosOutlineIconButton(
              onPressed: onEdit,
              icon: LucideIcons.pencil,
            ),
          ),
        ],
        if (onDelete != null) ...[
          if (onView != null || onEdit != null) const SizedBox(width: 2),
          Tooltip(
            message: 'Delete',
            child: VentosOutlineIconButton(
              destructive: true,
              onPressed: () async {
                final deleted = await showVentosDeleteConfirmation(
                  context: context,
                  title: deleteTitle,
                  description: deleteDescription,
                  itemName: itemName ?? 'Item',
                  itemDescription: itemDescription,
                  onDelete: onDelete!,
                );
                if (deleted) onDeleted?.call();
              },
              icon: LucideIcons.trash,
            ),
          ),
        ],
      ],
    );
  }
}
