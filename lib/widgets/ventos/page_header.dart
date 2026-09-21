import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

/// Matches web `PageHeader`.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions,
  });

  final String title;
  final String? description;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: VentosColors.foreground,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VentosColors.mutedForeground,
                          fontSize: 14,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 16),
            actions!,
          ],
        ],
      ),
    );
  }
}
