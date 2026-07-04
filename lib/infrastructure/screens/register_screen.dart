import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/domain/validators/auth_validator.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/password_requirements.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.clearError();

    final email = _emailController.text;
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final result = AuthValidator.validateEmail(email);
    setState(() => _emailError = result.isValid ? null : result.message);
  }

  void _onUsernameChanged() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.clearError();

    final username = _usernameController.text;
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    final result = AuthValidator.validateUsername(username);
    setState(() => _usernameError = result.isValid ? null : result.message);
  }

  void _onPasswordChanged() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.clearError();

    final password = _passwordController.text;
    final result = AuthValidator.validatePassword(password);
    final isValid = AuthValidator.isPasswordValid(result);

    setState(() => _passwordError = isValid ? null : result.getErrorMessage());
  }

  bool _canRegister() {
    final email = _emailController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      return false;
    }

    final emailValid = AuthValidator.validateEmail(email).isValid;
    final usernameValid = AuthValidator.validateUsername(username).isValid;
    final passwordValid =
        AuthValidator.isPasswordValid(AuthValidator.validatePassword(password));

    return emailValid && usernameValid && passwordValid;
  }

  void _handleRegister() async {
    if (!_canRegister()) {
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.register(
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
      if (isAuthenticated) {
        context.go('/levels');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('register'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.gamepad, size: 80, color: Color(0xFF00F5A0)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              enabled: !authState.isLoading,
              decoration: InputDecoration(
                labelText: l10n.translate('email'),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _emailError != null ? Colors.red : Colors.grey,
                  ),
                ),
                errorText: _emailError,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              enabled: !authState.isLoading,
              decoration: InputDecoration(
                labelText: l10n.translate('username'),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _usernameError != null ? Colors.red : Colors.grey,
                  ),
                ),
                errorText: _usernameError,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !authState.isLoading,
              decoration: InputDecoration(
                labelText: l10n.translate('password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            PasswordRequirements(
              password: _passwordController.text,
              showRequirements: _passwordController.text.isNotEmpty,
            ),
            const SizedBox(height: 24),
            if (authState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (authState.isLoading || !_canRegister()) ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(l10n.translate('register')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
