import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:mime/mime.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/utils/desktop_image_picker.dart';

/// Pop result from an end sheet when macOS needs a file panel outside modal routes.
const ventosMacImagePickToken = Object();

/// Holds image-upload context while the end sheet is dismissed for NSOpenPanel.
class MacImagePickPending {
  MacImagePickPending({
    required this.app,
    required this.libraryEntityType,
    required this.canUploadLibrary,
    required this.onPicked,
    this.onError,
  });

  final AppRepository app;
  final String libraryEntityType;
  final bool canUploadLibrary;
  final ValueChanged<String> onPicked;
  final ValueChanged<String>? onError;

  static MacImagePickPending? _pending;

  /// Set when a pick finishes while the form sheet was dismissed (macOS).
  static String? imageUrlForReopenedForm;

  static void register(MacImagePickPending pending) {
    _pending = pending;
  }

  /// Image URL to apply when a form drawer is recreated after macOS file pick.
  static String? takeImageUrlForReopenedForm() {
    final url = imageUrlForReopenedForm;
    imageUrlForReopenedForm = null;
    return url;
  }

  static Future<void> runIfPending() async {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    await pending._pickUploadAndApply();
  }

  Future<void> _pickUploadAndApply() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );
    XFile? picked;
    try {
      picked = await pickDesktopImageFile(acceptedTypeGroups: [typeGroup]);
    } catch (e) {
      onError?.call('Could not open file picker: $e');
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      onError?.call('Could not read the selected file.');
      return;
    }

    final name = picked.name;
    final mime = lookupMimeType(name, headerBytes: bytes) ?? 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    try {
      if (!canUploadLibrary) {
        imageUrlForReopenedForm = dataUrl;
        onPicked(dataUrl);
        return;
      }
      final data = await app.mutate(r'''
        mutation EntityImageUpload($input: CreateMediaAssetInput!) {
          createMediaAsset(input: $input) { url }
        }
      ''', {
        'input': {
          'filename': name,
          'mimeType': mime,
          'dataBase64': dataUrl,
          'entityType': libraryEntityType,
        },
      });
      final url = data['createMediaAsset']?['url'] as String?;
      if (url != null && url.isNotEmpty) {
        imageUrlForReopenedForm = url;
        onPicked(url);
      } else {
        onError?.call('Upload failed. Try again or pick from library.');
      }
    } catch (e) {
      onError?.call('Upload failed. Try again or pick from library.');
    }
  }
}
