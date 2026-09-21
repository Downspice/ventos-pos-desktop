import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';

/// Branded shell for device login and other full-screen auth steps.
class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.footer,
    this.maxWidth = 440,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 48 : 24,
            vertical: wide ? 40 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 960 : maxWidth),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _BrandPanel(theme: theme)),
                        const SizedBox(width: 48),
                        Expanded(
                          child: _FormColumn(
                            theme: theme,
                            title: title,
                            description: description,
                            child: child,
                            footer: footer,
                            showMobileBrand: false,
                          ),
                        ),
                      ],
                    )
                  : _FormColumn(
                      theme: theme,
                      title: title,
                      description: description,
                      child: child,
                      footer: footer,
                      showMobileBrand: true,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VentosMark(size: 48),
          const SizedBox(height: 16),
          Text('Ventos POS', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Point of sale built for busy floors.',
            style: theme.textTheme.bodyMedium?.copyWith(color: VentosColors.textSub, height: 1.45),
          ),
          const SizedBox(height: 32),
          ...const [
            _Highlight(icon: Icons.point_of_sale_outlined, text: 'Fast checkout and returns'),
            _Highlight(icon: Icons.people_outline, text: 'Staff sign-in after device unlock'),
            _Highlight(icon: Icons.cloud_off_outlined, text: 'Works with your Ventos backend'),
          ],
        ],
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.theme,
    required this.title,
    required this.description,
    required this.child,
    required this.showMobileBrand,
    this.footer,
  });

  final ThemeData theme;
  final String title;
  final String description;
  final Widget child;
  final Widget? footer;
  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMobileBrand) ...[
          const Center(child: _VentosMark(size: 44)),
          const SizedBox(height: 20),
        ],
        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: VentosColors.mutedForeground,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        child,
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );
  }
}

class _VentosMark extends StatelessWidget {
  const _VentosMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: VentosColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: VentosColors.shadowXs, offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Text(
        'V',
        style: TextStyle(
          color: VentosColors.onPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VentosColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: VentosColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VentosColors.textSub,
                      height: 1.35,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
