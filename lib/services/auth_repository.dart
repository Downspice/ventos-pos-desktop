import 'package:ventos_pos/config/api_config.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/services/token_storage.dart';

class PosEmployeeCard {
  PosEmployeeCard({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.canSignInWithPassword,
    required this.canSignInWithPin,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final bool canSignInWithPassword;
  final bool canSignInWithPin;
  final String? avatarUrl;

  String get displayName => '$firstName $lastName'.trim();

  String get signInHint {
    if (canSignInWithPassword && canSignInWithPin) {
      return 'Use account password or POS PIN';
    }
    if (canSignInWithPassword) return 'Use account password';
    if (canSignInWithPin) return 'Use POS PIN';
    return 'No sign-in method — set PIN in Control Hub';
  }

  factory PosEmployeeCard.fromJson(Map<String, dynamic> json) {
    return PosEmployeeCard(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      canSignInWithPassword: json['canSignInWithPassword'] as bool? ?? false,
      canSignInWithPin: json['canSignInWithPin'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class PosSessionState {
  PosSessionState({
    required this.businessName,
    required this.deviceUserEmail,
    this.activeEmployeeName,
    required this.permissions,
  });

  final String? businessName;
  final String? deviceUserEmail;
  final String? activeEmployeeName;
  final List<String> permissions;

  bool get hasActiveStaff => activeEmployeeName != null;

  factory PosSessionState.fromJson(Map<String, dynamic> json) {
    final business = json['business'] as Map<String, dynamic>?;
    final deviceUser = json['deviceUser'] as Map<String, dynamic>?;
    final active = json['activeEmployee'] as Map<String, dynamic>?;
    final perms = json['permissions'] as List<dynamic>? ?? [];
    String? activeName;
    if (active != null) {
      activeName =
          '${active['firstName']} ${active['lastName']}'.trim();
    }
    return PosSessionState(
      businessName: business?['name'] as String?,
      deviceUserEmail: deviceUser?['email'] as String?,
      activeEmployeeName: activeName,
      permissions: perms.map((e) => e.toString()).toList(),
    );
  }
}

class AuthRepository {
  AuthRepository(this._client, {TokenStorage? storage})
      : _storage = storage ?? TokenStorage();

  final VentosGraphqlClient _client;
  final TokenStorage _storage;

  Future<void> restoreSession() async {
    final token = await _storage.read();
    _client.setAccessToken(token);
  }

  Future<String?> accessToken() => _storage.read();

  Future<void> deviceLogin(String email, String password) async {
    const document = r'''
      mutation DeviceLogin($input: LoginInput!) {
        login(input: $input) {
          accessToken
        }
      }
    ''';
    final data = await _client.mutate(document, variables: {
      'input': {
        'email': email.trim(),
        'password': password,
        'deviceLabel': ApiConfig.deviceLabel,
      },
    });
    final token =
        (data['login'] as Map<String, dynamic>)['accessToken'] as String;
    await _storage.write(token);
    _client.setAccessToken(token);
  }

  Future<List<PosEmployeeCard>> fetchEmployeeRoster() async {
    const document = r'''
      query PosRoster {
        posEmployeeRoster {
          id
          firstName
          lastName
          canSignInWithPassword
          canSignInWithPin
          avatarUrl
        }
      }
    ''';
    final data = await _client.query(document);
    final list = data['posEmployeeRoster'] as List<dynamic>;
    return list
        .map((e) => PosEmployeeCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PosSessionState> fetchPosSession() async {
    const document = r'''
      query PosSession {
        posSession {
          business { name }
          deviceUser { email }
          activeEmployee { firstName lastName }
          permissions
        }
      }
    ''';
    final data = await _client.query(document);
    return PosSessionState.fromJson(data['posSession'] as Map<String, dynamic>);
  }

  Future<PosSessionState> activateEmployee(String employeeId, String password) async {
    const document = r'''
      mutation Activate($employeeId: ID!, $password: String!) {
        activatePosEmployee(employeeId: $employeeId, password: $password) {
          activeEmployee { firstName lastName }
          permissions
        }
      }
    ''';
    await _client.mutate(document, variables: {
      'employeeId': employeeId,
      'password': password,
    });
    return fetchPosSession();
  }

  Future<void> deactivateEmployee() async {
    const document = r'''
      mutation Deactivate {
        deactivatePosEmployee
      }
    ''';
    await _client.mutate(document);
  }

  Future<void> logout() async {
    const document = r'''
      mutation Logout {
        logout
      }
    ''';
    try {
      await _client.mutate(document);
    } catch (_) {
      // Still clear local session if network fails.
    }
    await _storage.delete();
    _client.setAccessToken(null);
  }
}
