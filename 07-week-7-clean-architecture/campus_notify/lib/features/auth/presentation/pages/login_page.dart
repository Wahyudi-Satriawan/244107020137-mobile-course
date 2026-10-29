import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(
    text: 'mahasiswa@polinema.ac.id',
  );
  final _passwordController = TextEditingController(text: 'password123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login Campus Notify')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Kampus'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (authState.isLoading)
              const AppLoadingView()
            else
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(authStateProvider.notifier)
                      .login(_emailController.text, _passwordController.text);
                },
                child: const Text('Login'),
              ),
            if (authState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: AppErrorView(message: 'Error: ${authState.error}'),
              ),
          ],
        ),
      ),
    );
  }
}
