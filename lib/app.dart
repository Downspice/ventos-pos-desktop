import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_theme.dart';
import 'package:ventos_pos/widgets/ventos/ventos_scaffold.dart';
import 'package:ventos_pos/services/auth_repository.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/services/app_repository.dart';
import 'package:ventos_pos/services/pos_repository.dart';
import 'package:ventos_pos/screens/device_login_screen.dart';
import 'package:ventos_pos/screens/employee_select_screen.dart';
import 'package:ventos_pos/screens/pos_home_screen.dart';

enum AppRoute { loading, deviceLogin, employeeSelect, posHome }

class VentosPosApp extends StatefulWidget {
  const VentosPosApp({super.key});

  @override
  State<VentosPosApp> createState() => _VentosPosAppState();
}

class _VentosPosAppState extends State<VentosPosApp> {
  late final VentosGraphqlClient _graphql;
  late final AuthRepository _auth;
  late final PosRepository _pos;
  late final AppRepository _app;
  AppRoute _route = AppRoute.loading;
  PosSessionState? _session;

  @override
  void initState() {
    super.initState();
    _graphql = VentosGraphqlClient();
    _auth = AuthRepository(_graphql);
    _pos = PosRepository(_graphql);
    _app = AppRepository(_graphql);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _auth.restoreSession();
      final session = await _auth.fetchPosSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        _route = session.hasActiveStaff ? AppRoute.posHome : AppRoute.employeeSelect;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _route = AppRoute.deviceLogin);
    }
  }

  Future<void> _onDeviceLoggedIn() async {
    setState(() => _route = AppRoute.employeeSelect);
  }

  Future<void> _onStaffActivated() async {
    final session = await _auth.fetchPosSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _route = AppRoute.posHome;
    });
  }

  Future<void> _onSwitchStaff() async {
    await _auth.deactivateEmployee();
    if (!mounted) return;
    setState(() {
      _session = null;
      _route = AppRoute.employeeSelect;
    });
  }

  Future<void> _onDeviceLogout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() {
      _session = null;
      _route = AppRoute.deviceLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ventos POS',
      theme: buildVentosTheme(),
      home: switch (_route) {
        AppRoute.loading => const VentosScaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        AppRoute.deviceLogin => DeviceLoginScreen(
            auth: _auth,
            onSuccess: _onDeviceLoggedIn,
          ),
        AppRoute.employeeSelect => EmployeeSelectScreen(
            auth: _auth,
            onStaffActivated: _onStaffActivated,
            onDeviceLogout: _onDeviceLogout,
          ),
        AppRoute.posHome => PosHomeScreen(
            session: _session!,
            pos: _pos,
            app: _app,
            onSwitchStaff: _onSwitchStaff,
            onDeviceLogout: _onDeviceLogout,
          ),
      },
    );
  }
}
