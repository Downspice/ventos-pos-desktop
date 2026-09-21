import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/utils/desktop_image_picker.dart';
import 'package:ventos_pos/utils/macos_image_pick_pending.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/pos/entity_image.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

/// Matches web `EntityImageField` — upload, media library, remove.
class EntityImageField extends StatefulWidget {
  const EntityImageField({
    super.key,
    required this.app,
    required this.value,
    required this.onChanged,
    this.label = 'Image',
    this.libraryEntityType = 'PRODUCT',
    this.canReadLibrary = true,
    this.canUploadLibrary = true,
  });

  final AppRepository app;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String libraryEntityType;
  final bool canReadLibrary;
  final bool canUploadLibrary;

  @override
  State<EntityImageField> createState() => _EntityImageFieldState();
}

class _EntityImageFieldState extends State<EntityImageField> {
  bool _uploading = false;
  bool _pickInProgress = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    if (_uploading || _pickInProgress) return;

    if (!kIsWeb && Platform.isMacOS) {
      _pickInProgress = true;
      MacImagePickPending.register(
        MacImagePickPending(
          app: widget.app,
          libraryEntityType: widget.libraryEntityType,
          canUploadLibrary: widget.canUploadLibrary,
          onPicked: widget.onChanged,
          onError: (message) {
            if (!mounted) return;
            setState(() => _error = message);
          },
        ),
      );
      Navigator.of(context).pop(ventosMacImagePickToken);
      _pickInProgress = false;
      return;
    }

    setState(() {
      _error = null;
      _uploading = true;
    });

    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );

    try {
      XFile? picked;
      try {
        picked = await pickDesktopImageFile(acceptedTypeGroups: [typeGroup]);
      } on MissingPluginException {
        setState(() {
          _error =
              'File picker is unavailable. Quit the app completely and run it again (hot reload does not load native plugins).';
        });
        return;
      } catch (e) {
        setState(() => _error = 'Could not open file picker: $e');
        return;
      }

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => _error = 'Could not read the selected file.');
        return;
      }

      final name = picked.name;
      final mime = lookupMimeType(name, headerBytes: bytes) ?? 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      if (!widget.canUploadLibrary) {
        widget.onChanged(dataUrl);
        return;
      }

      final data = await widget.app.mutate(r'''
        mutation EntityImageUpload($input: CreateMediaAssetInput!) {
          createMediaAsset(input: $input) { url }
        }
      ''', {
        'input': {
          'filename': name,
          'mimeType': mime,
          'dataBase64': dataUrl,
          'entityType': widget.libraryEntityType,
        },
      });
      final url = data['createMediaAsset']?['url'] as String?;
      if (url != null && url.isNotEmpty) {
        widget.onChanged(url);
      } else {
        setState(() => _error = 'Upload failed. Try again or pick from library.');
      }
    } catch (e) {
      setState(() => _error = 'Upload failed. Try again or pick from library.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openLibrary() async {
    if (!widget.canReadLibrary) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _MediaLibraryDialog(
        app: widget.app,
        currentUrl: widget.value,
        entityType: widget.libraryEntityType,
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        EntityImage(
          imageUrl: widget.value.isEmpty ? null : widget.value,
          alt: widget.label,
          width: 96,
          height: 96,
          borderRadius: 8,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VentosButton(
              onPressed: _uploading ? null : _pickAndUpload,
              variant: VentosButtonVariant.outline,
              size: VentosButtonSize.sm,
              child: Text(_uploading ? 'Uploading…' : 'Upload'),
            ),
            if (widget.canReadLibrary)
              VentosButton(
                onPressed: _openLibrary,
                variant: VentosButtonVariant.outline,
                size: VentosButtonSize.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.images, size: 14),
                    const SizedBox(width: 6),
                    const Text('Choose from library'),
                  ],
                ),
              ),
            if (widget.value.isNotEmpty)
              VentosButton(
                onPressed: () => widget.onChanged(''),
                variant: VentosButtonVariant.ghost,
                size: VentosButtonSize.sm,
                child: const Text('Remove'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Upload a new file or pick an existing image from your media library.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: VentosColors.mutedForeground,
              ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.destructive)),
        ],
      ],
    );
  }
}

class _MediaLibraryDialog extends StatefulWidget {
  const _MediaLibraryDialog({
    required this.app,
    required this.currentUrl,
    required this.entityType,
  });

  final AppRepository app;
  final String currentUrl;
  final String entityType;

  @override
  State<_MediaLibraryDialog> createState() => _MediaLibraryDialogState();
}

class _MediaLibraryDialogState extends State<_MediaLibraryDialog> {
  String _search = '';
  String _filter = 'ALL';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _filter = widget.entityType;
    _load();
  }

  void _load() {
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await widget.app.query(r'''
      query EntityImageLibrary($entityType: MediaEntityType, $search: String) {
        mediaAssets(entityType: $entityType, search: $search) {
          id url filename altText entityType
        }
      }
    ''', {
      if (_filter != 'ALL') 'entityType': _filter,
      if (_search.trim().isNotEmpty) 'search': _search.trim(),
    });
    return (data['mediaAssets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Media library', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Select an image for this record.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.mutedForeground),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: VentosTextField(
                      hintText: 'Search filename or alt text',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      onChanged: (v) {
                        _search = v;
                        setState(_load);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: VentosSelect<String>(
                      value: _filter,
                      entries: const [
                        VentosSelectEntry(value: 'ALL', label: 'All types'),
                        VentosSelectEntry(value: 'PRODUCT', label: 'Products'),
                        VentosSelectEntry(value: 'SERVICE', label: 'Services'),
                        VentosSelectEntry(value: 'BUSINESS', label: 'Business'),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _filter = v;
                          _load();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load media library.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No images found. Upload one first.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: VentosColors.mutedForeground),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final url = item['url'] as String? ?? '';
                      final selected = widget.currentUrl == url;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(url),
                          borderRadius: BorderRadius.circular(10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? VentosColors.primary : VentosColors.strokeSoft,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                    child: EntityImage(
                                      imageUrl: url,
                                      alt: item['filename'] as String? ?? 'Image',
                                      expand: true,
                                      borderRadius: 0,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    item['filename'] as String? ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: VentosButton(
                  onPressed: () => Navigator.of(context).pop(),
                  variant: VentosButtonVariant.outline,
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
