import 'package:flutter/material.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class VentosPaginationBar extends StatelessWidget {
  const VentosPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Page $page of $totalPages', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 12),
          VentosButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            variant: VentosButtonVariant.outline,
            child: const Icon(LucideIcons.chevron_left, size: 18),
          ),
          const SizedBox(width: 4),
          VentosButton(
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            variant: VentosButtonVariant.outline,
            child: const Icon(LucideIcons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }
}

int paginateTotalPages(int itemCount, int pageSize) {
  if (itemCount == 0) return 1;
  return ((itemCount + pageSize - 1) / pageSize).ceil();
}

List<T> paginateSlice<T>(List<T> items, int page, int pageSize) {
  final start = (page - 1) * pageSize;
  if (start >= items.length) return [];
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}
