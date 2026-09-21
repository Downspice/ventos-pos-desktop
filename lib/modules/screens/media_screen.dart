import 'package:flutter/material.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/common/module_async.dart';
import 'package:ventos_pos/widgets/common/ventos_pagination_bar.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key, required this.app, this.reloadKey = 0});

  final AppRepository app;
  final int reloadKey;

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  static const _pageSize = 12;
  int _page = 1;

  Future<List<Map<String, dynamic>>> _load() async {
    const document = r'''
      query MediaPage {
        mediaAssets {
          id filename url mimeType sizeBytes altText entityType entityId createdAt
        }
      }
    ''';
    final data = await widget.app.query(document);
    return (data['mediaAssets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ModuleAsyncBody<List<Map<String, dynamic>>>(
      reloadKey: widget.reloadKey,
      loader: _load,
      builder: (context, assets, reload) {
        final pageItems = paginateSlice(assets, _page, _pageSize);
        return VentosPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Media',
                description: 'Images and files linked to products, services, and people.',
              ),
              if (assets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(LucideIcons.image, size: 40, color: VentosColors.mutedForeground),
                      const SizedBox(height: 8),
                      Text(
                        'No images yet. Upload from a product or service form.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VentosColors.mutedForeground,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: pageItems.length,
                  itemBuilder: (context, i) {
                    final a = pageItems[i];
                    final url = a['url'] as String?;
                    final filename = a['filename'] as String? ?? 'File';
                    final entityType = a['entityType'] as String?;
                    return VentosCard(
                      padding: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: EntityImage(
                              imageUrl: url,
                              alt: a['altText'] as String? ?? filename,
                              expand: true,
                              borderRadius: 0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatBytes(a['sizeBytes'] as int?),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: VentosColors.mutedForeground,
                                      ),
                                ),
                                if (entityType != null && entityType.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entityType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: VentosColors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (assets.isNotEmpty)
                VentosPaginationBar(
                  page: _page,
                  totalPages: paginateTotalPages(assets.length, _pageSize),
                  onPageChanged: (p) => setState(() => _page = p),
                ),
            ],
          ),
        );
      },
    );
  }
}
