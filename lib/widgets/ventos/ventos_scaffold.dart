import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

/// Page background matching web `--gradient-background`.
class VentosGradientBackground extends StatelessWidget {
  const VentosGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VentosColors.gradientStart,
            VentosColors.gradientMid,
            VentosColors.gradientEnd,
          ],
          stops: [0, 0.5, 1],
        ),
      ),
      child: child,
    );
  }
}

class VentosScaffold extends StatelessWidget {
  const VentosScaffold({
    super.key,
    this.appBar,
    required this.body,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return VentosGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
      ),
    );
  }
}
