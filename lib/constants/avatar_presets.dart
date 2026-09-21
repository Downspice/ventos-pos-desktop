/// Preset avatar ids — bundled under `assets/avatars/` (synced from `shared/avatar-presets`).
const avatarPresetIds = [
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
  '08',
  '09',
  '10',
  '11',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18',
  '19',
  '20',
];

String avatarPresetPath(String id) {
  return id == '11' ? '/avatars/11.jpg' : '/avatars/$id.png';
}

String? parseAvatarPresetId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final m = RegExp(r'^/avatars/(\d{2})\.(png|jpg)$').firstMatch(url.trim());
  if (m == null) return null;
  final id = m.group(1)!;
  return avatarPresetIds.contains(id) ? id : null;
}

String avatarInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
