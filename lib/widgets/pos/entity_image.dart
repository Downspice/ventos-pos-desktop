import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/utils/resolve_entity_image_url.dart';

/// Matches web `EntityImage` + `DEFAULT_ENTITY_IMAGE_SRC`.
class EntityImage extends StatefulWidget {
  const EntityImage({
    super.key,
    this.imageUrl,
    required this.alt,
    this.width = 40,
    this.height = 40,
    this.borderRadius = 6,
    this.fit = BoxFit.cover,
    this.expand = false,
  });

  final String? imageUrl;
  final String alt;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  /// When true, fills the parent (e.g. grid tile) instead of [width]×[height].
  final bool expand;

  @override
  State<EntityImage> createState() => _EntityImageState();
}

class _EntityImageState extends State<EntityImage> {
  bool _failed = false;

  @override
  void didUpdateWidget(EntityImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl?.trim() != widget.imageUrl?.trim()) {
      _failed = false;
    }
  }

  bool get _usePlaceholder {
    final url = widget.imageUrl?.trim();
    return url == null || url.isEmpty || _failed;
  }

  Widget _placeholder() {
    return SvgPicture.asset(
      'assets/images/default_entity.svg',
      fit: BoxFit.cover,
      width: widget.expand ? null : widget.width,
      height: widget.expand ? null : widget.height,
    );
  }

  void _markFailed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  Uint8List? _decodeDataUrl(String url) {
    try {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      final meta = url.substring(0, comma);
      final payload = url.substring(comma + 1);
      if (meta.contains(';base64')) {
        return base64Decode(payload.replaceAll('\n', ''));
      }
      return Uint8List.fromList(Uri.decodeComponent(payload).codeUnits);
    } catch (_) {
      return null;
    }
  }

  Widget _buildImageContent(String url) {
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes == null || bytes.isEmpty) {
        _markFailed();
        return _placeholder();
      }
      return Image.memory(
        bytes,
        fit: widget.fit,
        errorBuilder: (_, __, ___) {
          _markFailed();
          return _placeholder();
        },
      );
    }

    final resolved = resolveEntityImageUrl(url);
    return Image.network(
      resolved,
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        _markFailed();
        return _placeholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: VentosColors.muted,
        border: Border.all(color: VentosColors.strokeSoft),
      ),
      child: _usePlaceholder ? _placeholder() : _buildImageContent(widget.imageUrl!.trim()),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.expand
          ? SizedBox.expand(child: content)
          : SizedBox(width: widget.width, height: widget.height, child: content),
    );
  }
}
