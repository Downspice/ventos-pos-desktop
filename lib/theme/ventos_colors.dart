import 'package:flutter/material.dart';

/// Tokens from `frontend/web/src/styles/globals.css` (AlignUI + shadcn compat).
abstract final class VentosColors {
  static const foreground = Color(0xFF122C32);
  static const background = Color(0xFFFFFFFF);
  static const card = Color(0xE3FFFFFF); // rgba(255,255,255,0.892) on gradient
  static const cardOpaque = Color(0xFFFFFFFF);

  static const primary = Color(0xFFF97316);
  static const primaryDark = Color(0xFF9A3412); // orange-800
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFF5F5F5);
  static const secondaryForeground = Color(0xFF171717);

  static const muted = Color(0xFFF5F5F5);
  static const mutedForeground = Color(0xFF737373);
  /// --color-bg-weak-50 (neutral-50)
  static const bgWeak50 = Color(0xFFFAFAFA);

  static const border = Color(0xFFEBEBEB);
  static const input = Color(0xFFEBEBEB);
  static const ring = Color(0xFFF97316);

  static const destructive = Color(0xFFEF4444);
  static const errorDark = Color(0xFF7F1D1D);

  static const textStrong = Color(0xFF0A0A0A);
  static const textSub = Color(0xFF525252);
  static const textSoft = Color(0xFFA3A3A3);

  static const strokeSoft = Color(0xFFEBEBEB);
  static const strokeSub = Color(0xFFD4D4D4);

  static const gradientStart = Color(0xFFCAE7EE);
  static const gradientMid = Color(0xFFE3E8EE);
  static const gradientEnd = Color(0xFFFFFFFF);

  static const shadowSm = Color(0x1A1B1C1D);
  static const shadowXs = Color(0x080A0D14);

  /// --color-overlay-gray (~24% neutral)
  static const overlayGray = Color(0x3D525252);
}

abstract final class VentosRadii {
  static const button = 10.0;
  static const input = 10.0;
  static const card = 16.0; // rounded-2xl
  static const dialog = 12.0;
}

abstract final class VentosFont {
  static const family = 'Google Sans';
}
