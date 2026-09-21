import 'package:flutter/material.dart';

/// Standard modal (~ `DialogContent sm:max-w-md`).
Future<T?> showVentosDialog<T>({
  required BuildContext context,
  required String title,
  String? description,
  required Widget body,
  List<Widget>? actions,
  bool barrierDismissible = true,
  double maxWidth = 448,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(description!, style: Theme.of(ctx).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: body)),
              if (actions != null && actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Near-fullscreen order modal (web POS `Dialog` + `h-[calc(100dvh-1.5rem)]`).
Future<T?> showVentosFullscreenDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}
