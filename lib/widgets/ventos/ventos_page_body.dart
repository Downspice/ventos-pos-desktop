import 'package:flutter/material.dart';

/// Main content inset matching web app pages.
class VentosPageBody extends StatelessWidget {
  const VentosPageBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: child,
    );
  }
}
