import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/macos_image_pick_pending.dart';

/// Right-side sheet matching web `SheetContent side="right"`.
Future<T?> showVentosEndSheet<T>({
  required BuildContext context,
  required Widget child,
  double width = 576,
}) async {
  // macOS: avoid showGeneralDialog — it blocks/conflicts with NSOpenPanel.
  if (!kIsWeb && Platform.isMacOS) {
    while (context.mounted) {
      final result = await Navigator.of(context).push<Object?>(
        PageRouteBuilder<Object?>(
          opaque: false,
          barrierDismissible: true,
          barrierLabel: 'Close',
          barrierColor: VentosColors.overlayGray,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: VentosColors.cardOpaque,
                elevation: 8,
                child: SizedBox(
                  width: width,
                  height: MediaQuery.sizeOf(context).height,
                  child: child,
                ),
              ),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        ),
      );
      if (identical(result, ventosMacImagePickToken)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await MacImagePickPending.runIfPending();
        continue;
      }
      return result as T?;
    }
    return null;
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: VentosColors.overlayGray,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: VentosColors.cardOpaque,
          elevation: 8,
          child: SizedBox(
            width: width,
            height: MediaQuery.sizeOf(context).height,
            child: child,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}
