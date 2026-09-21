import 'package:ventos_pos/config/api_config.dart';

/// Resolves relative upload paths and returns the trimmed URL unchanged otherwise.
String resolveEntityImageUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('data:') ||
      trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('file://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    final gql = Uri.parse(ApiConfig.graphqlUrl);
    final port = gql.hasPort ? ':${gql.port}' : '';
    return '${gql.scheme}://${gql.host}$port$trimmed';
  }
  return trimmed;
}
