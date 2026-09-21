import 'package:flutter/material.dart';
import 'package:ventos_pos/config/api_config.dart';
import 'package:ventos_pos/services/auth_repository.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/auth_page_frame.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

class DeviceLoginScreen extends StatefulWidget {
  const DeviceLoginScreen({
    super.key,
    required this.auth,
    required this.onSuccess,
  });

  final AuthRepository auth;
  final VoidCallback onSuccess;

  @override
  State<DeviceLoginScreen> createState() => _DeviceLoginScreenState();
}

class _DeviceLoginScreenState extends State<DeviceLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.deviceLogin(_email.text, _password.text);
      if (!mounted) return;
      widget.onSuccess();
    } on GraphqlException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VentosScaffold(
      body: Center(
        child: AuthPageFrame(
          title: 'Unlock this register',
          description:
              'Sign in with a manager or admin account to open the POS. '
              'Staff will sign in on the next screen.',
          footer: Text(
            'API · ${ApiConfig.graphqlUrl}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: VentosColors.textSoft,
                ),
            textAlign: TextAlign.center,
          ),
          child: VentosCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                VentosTextField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_busy,
                ),
                const SizedBox(height: 12),
                VentosTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_busy,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: VentosColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VentosColors.destructive.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: VentosColors.destructive, fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                VentosButtonFull(
                  onPressed: _submit,
                  label: 'Continue',
                  busy: _busy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
