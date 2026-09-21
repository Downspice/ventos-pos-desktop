import 'package:ventos_pos/constants/avatar_presets.dart';

/// Asset path for bundled preset avatars, or null for network / fallback initials.
String? resolveAvatarAssetPath(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
  final v = avatarUrl.trim();
  if (!v.startsWith('/avatars/')) return null;
  final id = parseAvatarPresetId(v);
  if (id == null) return null;
  return id == '11' ? 'assets/avatars/11.jpg' : 'assets/avatars/$id.png';
}

bool isNetworkAvatarUrl(String? avatarUrl) {
  return avatarUrl != null && avatarUrl.trim().startsWith('https://');
}
