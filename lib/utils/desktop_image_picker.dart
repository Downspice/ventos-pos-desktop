import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _macPickerChannel = MethodChannel('ventos/file_picker');

/// Opens an image file picker. On macOS uses [runModal] NSOpenPanel so the dialog
/// is not hidden behind Flutter modal routes (end sheets).
Future<XFile?> pickDesktopImageFile({
  List<XTypeGroup> acceptedTypeGroups = const [
    XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    ),
  ],
}) async {
  if (!kIsWeb && Platform.isMacOS) {
    final raw = await _macPickerChannel.invokeMethod<Object?>('pickImage');
    String? path;
    if (raw is String) {
      path = raw;
    } else if (raw is Map) {
      final p = raw['path'];
      if (p is String && p.isNotEmpty) path = p;
    }
    if (path == null || path.isEmpty) return null;
    return XFile(path);
  }
  return openFile(acceptedTypeGroups: acceptedTypeGroups);
}
