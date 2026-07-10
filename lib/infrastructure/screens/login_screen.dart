import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';
import 'package:arrow_maze_cliente_copy/domain/validators/auth_validator.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/mappers/validation_error_mapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailOrUsernameError;
  bool _showPassword = false;
  bool _canUseFaceIdForEmail = false;

  @override
  void initState() {
    super.initState();
    _emailOrUsernameController.addListener(_onEmailOrUsernameChanged);
    _passwordController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailOrUsernameChanged() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.clearError();

    final input = _emailOrUsernameController.text;
    if (input.isEmpty) {
      setState(() {
        _emailOrUsernameError = null;
        _canUseFaceIdForEmail = false;
      });
      return;
    }

    final result = AuthValidator.validateEmailOrUsername(input);
    setState(() {
      _emailOrUsernameError = result.isValid
          ? null
          : (result.errorType != null
              ? ValidationErrorMapper.toTranslationKey(result.errorType!)
              : null);
    });

    if (result.isValid) {
      _checkFaceIdForEmail(input);
    }
  }

  Future<void> _checkFaceIdForEmail(String email) async {
    try {
      final faceIdLoginWithEmailUseCase = ref.read(faceIdLoginWithEmailUseCaseProvider);
      final canUse = await faceIdLoginWithEmailUseCase.canUseFaceIdForEmail(email);
      debugPrint('📱 LoginScreen: Face ID available for $email = $canUse');
      if (mounted) {
        setState(() => _canUseFaceIdForEmail = canUse);
      }
    } catch (e) {
      debugPrint('❌ LoginScreen._checkFaceIdForEmail: Error - $e');
    }
  }

  void _onInputChanged() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.clearError();
  }

  bool _canLogin() {
    final emailOrUsername = _emailOrUsernameController.text;
    final password = _passwordController.text;

    if (emailOrUsername.isEmpty || password.isEmpty) {
      return false;
    }

    final credentialsValid =
        AuthValidator.validateEmailOrUsername(emailOrUsername).isValid;
    return credentialsValid;
  }

  void _handleLogin() async {
    if (!_canLogin()) {
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.login(
      _emailOrUsernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
      if (isAuthenticated) {
        context.go('/home');
      }
    }
  }

  void _handleFaceIdLoginWithEmail() async {
    final email = _emailOrUsernameController.text.trim();
    if (email.isEmpty) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.loginWithFaceIdAndEmail(email);

    if (mounted) {
      final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
      if (isAuthenticated) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.gamepad, size: 80, color: Color(0xFF00F5A0)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailOrUsernameController,
              enabled: !authState.isLoading,
              decoration: InputDecoration(
                labelText: l10n.translate('email'),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        _emailOrUsernameError != null ? Colors.red : Colors.grey,
                  ),
                ),
                errorText: _emailOrUsernameError != null ? l10n.translate(_emailOrUsernameError!) : null,
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
              obscureText: !_showPassword,
              enabled: !authState.isLoading,
              decoration: InputDecoration(
                labelText: l10n.translate('password'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF00F5A0),
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (_emailOrUsernameController.text.isNotEmpty &&
                            _canUseFaceIdForEmail &&
                            !authState.isLoading)
                        ? _handleFaceIdLoginWithEmail
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.translate('biometricIdentification'),
                          style: TextStyle(
                            color: _emailOrUsernameController.text.isNotEmpty &&
                                    _canUseFaceIdForEmail &&
                                    !authState.isLoading
                                ? Colors.blue
                                : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.face,
                          color: _emailOrUsernameController.text.isNotEmpty &&
                                  _canUseFaceIdForEmail &&
                                  !authState.isLoading
                              ? Colors.blue
                              : Colors.grey,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    (authState.isLoading || !_canLogin()) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(l10n.translate('login')),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: authState.isLoading ? null : () => context.go('/register'),
              child: Text(l10n.translate('register')),
            ),
          ],
        ),
      ),
    );
  }
}
