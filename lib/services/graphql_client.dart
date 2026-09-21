import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ventos_pos/config/api_config.dart';

class GraphqlException implements Exception {
  GraphqlException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VentosGraphqlClient {
  VentosGraphqlClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    return _post(document, variables);
  }

  Future<Map<String, dynamic>> mutate(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    return _post(document, variables);
  }

  Future<Map<String, dynamic>> _post(
    String document,
    Map<String, dynamic>? variables,
  ) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse(ApiConfig.graphqlUrl),
        headers: headers,
        body: jsonEncode({
          'query': document,
          if (variables != null) 'variables': variables,
        }),
      );
    } on http.ClientException catch (e) {
      throw GraphqlException(_friendlyNetworkMessage(e));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GraphqlException('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first as Map<String, dynamic>;
      throw GraphqlException(first['message']?.toString() ?? 'GraphQL error');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw GraphqlException('Empty GraphQL response');
    }
    return data;
  }
}

String _friendlyNetworkMessage(http.ClientException e) {
  final msg = e.message;
  if (msg.contains('Connection refused') ||
      msg.contains('Failed host lookup') ||
      msg.contains('Operation not permitted')) {
    return 'Cannot reach the Ventos API at ${ApiConfig.graphqlUrl}. '
        'In a terminal, run: cd backend && npm run dev';
  }
  return 'Network error: $msg';
}
