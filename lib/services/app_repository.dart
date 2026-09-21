import 'package:ventos_pos/services/graphql_client.dart';

class AppRepository {
  AppRepository(this._client);

  final VentosGraphqlClient _client;

  Future<Map<String, dynamic>> query(String document, [Map<String, dynamic>? variables]) {
    return _client.query(document, variables: variables);
  }

  Future<Map<String, dynamic>> mutate(String document, [Map<String, dynamic>? variables]) {
    return _client.mutate(document, variables: variables);
  }
}
