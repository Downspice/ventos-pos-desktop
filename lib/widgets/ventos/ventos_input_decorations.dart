import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

enum VentosInputSize { sm, md, lg }

extension VentosInputSizeX on VentosInputSize {
  double get height {
    switch (this) {
      case VentosInputSize.sm:
        return 32;
      case VentosInputSize.md:
        return 36;
      case VentosInputSize.lg:
        return 40;
    }
  }

  EdgeInsets get contentPadding {
    switch (this) {
      case VentosInputSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case VentosInputSize.md:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case VentosInputSize.lg:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    }
  }

  double get fontSize {
    switch (this) {
      case VentosInputSize.sm:
        return 12;
      case VentosInputSize.md:
      case VentosInputSize.lg:
        return 14;
    }
  }

  /// Line box height for single-line fields (matches web input line-height).
  double get singleLineTextBlockHeight => fontSize * 1.25;

  /// Horizontal + vertical padding so text is centered in [height] (or [outerHeight]).
  EdgeInsets singleLineShellPadding([double? outerHeight]) {
    final h = outerHeight ?? height;
    final vertical = ((h - singleLineTextBlockHeight) / 2).clamp(0.0, 16.0);
    return EdgeInsets.symmetric(horizontal: 12, vertical: vertical);
  }
}

/// Padding for custom-height triggers (e.g. select) using default 14px text.
EdgeInsets ventosSingleLineShellPadding({
  required double height,
  double fontSize = 14,
}) {
  final textBlock = fontSize * 1.25;
  final vertical = ((height - textBlock) / 2).clamp(0.0, 16.0);
  return EdgeInsets.symmetric(horizontal: 12, vertical: vertical);
}

double ventosSingleLineTextBlockHeight({double fontSize = 14}) => fontSize * 1.25;

/// Web `shadow-regular-xs`.
List<BoxShadow> get ventosInputShadow => const [
      BoxShadow(
        color: Color(0x080A0D14),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x050A0D14),
        blurRadius: 0,
        offset: Offset(0, 1),
      ),
    ];

/// Fallback for rare raw [TextField] — prefer [VentosTextField].
InputDecoration ventosInputDecoration({
  VentosInputSize size = VentosInputSize.md,
  String? hintText,
  String? errorText,
  bool enabled = true,
}) {
  final radius = BorderRadius.circular(VentosRadii.input);
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: enabled ? VentosColors.cardOpaque : VentosColors.muted.withValues(alpha: 0.5),
    hintText: hintText,
    errorText: errorText,
    contentPadding: size.contentPadding,
    hintStyle: TextStyle(fontSize: size.fontSize, color: VentosColors.textSoft, height: 1.25),
    errorStyle: const TextStyle(fontSize: 12, color: VentosColors.destructive, height: 1.3),
    border: border(VentosColors.strokeSoft),
    enabledBorder: border(VentosColors.strokeSoft),
    disabledBorder: border(VentosColors.strokeSoft.withValues(alpha: 0.6)),
    focusedBorder: border(VentosColors.textStrong, width: 2),
    errorBorder: border(VentosColors.destructive),
    focusedErrorBorder: border(VentosColors.destructive, width: 2),
  );
}

/// Field label above inputs (web `Label` / form rows).
class VentosFieldLabel extends StatelessWidget {
  const VentosFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 14,
              color: VentosColors.textSub,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
      ),
    );
  }
}
