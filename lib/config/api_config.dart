/// GraphQL API base URL. Override with `--dart-define=VENTOS_API_URL=...`
class ApiConfig {
  static const String graphqlUrl = String.fromEnvironment(
    'VENTOS_API_URL',
    defaultValue: 'http://127.0.0.1:4000/graphql',
  );

  /// Web app origin for embedded modules. Override with `--dart-define=VENTOS_WEB_URL=...`
  static const String webOrigin = String.fromEnvironment(
    'VENTOS_WEB_URL',
    defaultValue: 'http://127.0.0.1:5173',
  );

  static const String deviceLabel = 'Ventos POS Desktop';
}
