import 'package:flutter/material.dart';
import 'package:ventos_pos/constants/avatar_presets.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/resolve_avatar.dart';

class VentosAvatar extends StatelessWidget {
  const VentosAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.size = 40,
    this.borderRadius = 10,
  });

  final String displayName;
  final String? avatarUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = resolveAvatarAssetPath(avatarUrl);
    final network = isNetworkAvatarUrl(avatarUrl) ? avatarUrl!.trim() : null;

    Widget image;
    if (asset != null) {
      image = Image.asset(asset, fit: BoxFit.cover, width: size, height: size);
    } else if (network != null) {
      image = Image.network(
        network,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    } else {
      image = _fallback(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: VentosColors.muted,
      alignment: Alignment.center,
      child: Text(
        avatarInitials(displayName),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: VentosColors.mutedForeground,
            ),
      ),
    );
  }
}
