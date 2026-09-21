import 'package:flutter/material.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';

class ProductWithImage extends StatelessWidget {
  const ProductWithImage({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
  });

  final String name;
  final String? imageUrl;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EntityImage(imageUrl: imageUrl, alt: name, width: 40, height: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
