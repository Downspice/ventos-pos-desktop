import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

ThemeData buildVentosTheme() {
  const font = VentosFont.family;

  TextStyle ventosText({
    required double size,
    required double height,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? VentosColors.textStrong,
    );
  }

  final textTheme = TextTheme(
    headlineSmall: ventosText(
      size: 20,
      height: 28,
      weight: FontWeight.w600,
      letterSpacing: -0.2,
      color: VentosColors.foreground,
    ),
    titleLarge: ventosText(size: 18, height: 28, weight: FontWeight.w600, color: VentosColors.foreground),
    titleMedium: ventosText(size: 16, height: 24, weight: FontWeight.w500, color: VentosColors.foreground),
    titleSmall: ventosText(size: 14, height: 20, weight: FontWeight.w600, color: VentosColors.foreground),
    bodyLarge: ventosText(size: 16, height: 24, color: VentosColors.textStrong),
    bodyMedium: ventosText(
      size: 14,
      height: 20,
      letterSpacing: -0.084,
      color: VentosColors.textStrong,
    ),
    bodySmall: ventosText(
      size: 14,
      height: 20,
      letterSpacing: -0.084,
      color: VentosColors.mutedForeground,
    ),
    labelLarge: ventosText(size: 14, height: 20, weight: FontWeight.w500),
    labelMedium: ventosText(size: 12, height: 16, weight: FontWeight.w500, color: VentosColors.textSub),
    labelSmall: ventosText(size: 12, height: 16, color: VentosColors.mutedForeground),
  );

  final colorScheme = ColorScheme.light(
    primary: VentosColors.primary,
    onPrimary: VentosColors.onPrimary,
    secondary: VentosColors.secondary,
    onSecondary: VentosColors.secondaryForeground,
    surface: VentosColors.cardOpaque,
    onSurface: VentosColors.textStrong,
    onSurfaceVariant: VentosColors.mutedForeground,
    error: VentosColors.destructive,
    outline: VentosColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: font,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: VentosColors.cardOpaque,
    textTheme: textTheme,
    dividerTheme: const DividerThemeData(color: VentosColors.strokeSoft, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: VentosColors.cardOpaque,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VentosRadii.card),
        side: const BorderSide(color: VentosColors.strokeSoft),
      ),
      shadowColor: VentosColors.shadowSm,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VentosColors.cardOpaque,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintStyle: ventosText(size: 14, height: 20, color: VentosColors.textSoft),
      labelStyle: ventosText(size: 14, height: 20, color: VentosColors.textSub),
      floatingLabelStyle: ventosText(size: 12, height: 16, color: VentosColors.textSub),
      errorStyle: ventosText(size: 12, height: 16, color: VentosColors.destructive),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VentosRadii.input),
        borderSide: const BorderSide(color: VentosColors.strokeSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VentosRadii.input),
        borderSide: const BorderSide(color: VentosColors.strokeSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VentosRadii.input),
        borderSide: const BorderSide(color: VentosColors.textStrong, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VentosRadii.input),
        borderSide: const BorderSide(color: VentosColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VentosRadii.input),
        borderSide: const BorderSide(color: VentosColors.destructive, width: 2),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(VentosColors.cardOpaque),
        elevation: WidgetStateProperty.all(8),
        shadowColor: WidgetStateProperty.all(VentosColors.shadowSm),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VentosRadii.input),
            side: const BorderSide(color: VentosColors.strokeSoft),
          ),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: VentosColors.primary,
        foregroundColor: VentosColors.onPrimary,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shadowColor: VentosColors.shadowXs,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VentosRadii.button)),
        textStyle: ventosText(size: 14, height: 20, weight: FontWeight.w500, color: VentosColors.onPrimary),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return VentosColors.primaryDark.withValues(alpha: 0.15);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.black.withValues(alpha: 0.04);
          }
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VentosColors.textStrong,
        backgroundColor: VentosColors.cardOpaque,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: const BorderSide(color: VentosColors.strokeSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VentosRadii.button)),
        textStyle: ventosText(size: 14, height: 20, weight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VentosColors.textSub,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: ventosText(size: 14, height: 20, weight: FontWeight.w500),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: VentosColors.cardOpaque,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VentosRadii.dialog),
        side: const BorderSide(color: VentosColors.strokeSoft),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: VentosColors.foreground,
      titleTextStyle: ventosText(size: 18, height: 28, weight: FontWeight.w600, color: VentosColors.foreground),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: ventosText(size: 14, height: 20),
    ),
  );
}
