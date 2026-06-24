import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arrow_maze_cliente_copy/adapters/providers.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.login(
      _emailController.text,
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
      appBar: AppBar(title: Text(l10n.translate('login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.gamepad, size: 80, color: Color(0xFF00F5A0)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.translate('email'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.translate('password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (authState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  authState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(l10n.translate('login')),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.translate('register')),
            ),
          ],
        ),
      ),
    );
  }
}
