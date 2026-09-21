import 'package:flutter/material.dart';
import 'package:ventos_pos/services/auth_repository.dart';
import 'package:ventos_pos/services/graphql_client.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

Future<bool?> showStaffSignInDialog({
  required BuildContext context,
  required PosEmployeeCard employee,
  required AuthRepository auth,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _StaffSignInDialog(employee: employee, auth: auth),
  );
}

class _StaffSignInDialog extends StatefulWidget {
  const _StaffSignInDialog({required this.employee, required this.auth});

  final PosEmployeeCard employee;
  final AuthRepository auth;

  @override
  State<_StaffSignInDialog> createState() => _StaffSignInDialogState();
}

class _StaffSignInDialogState extends State<_StaffSignInDialog> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.activateEmployee(widget.employee.id, _password.text);
      if (!mounted) return;
      Navigator.pop(context, true);
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.employee.displayName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Enter your password or POS PIN',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              VentosTextField(
                controller: _password,
                label: 'Password / PIN',
                size: VentosInputSize.lg,
                suffixIcon: VentosInputSuffixButton(
                  icon: _obscure ? LucideIcons.eye : LucideIcons.eye_off,
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: _busy ? null : () => setState(() => _obscure = !_obscure),
                ),
                obscureText: _obscure,
                autofocus: true,
                enabled: !_busy,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              Text(widget.employee.signInHint, style: Theme.of(context).textTheme.labelSmall),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VentosButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    variant: VentosButtonVariant.outline,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  VentosButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Start shift'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
