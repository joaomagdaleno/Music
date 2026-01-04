import 'package:flutter/material.dart';

/// Material Design view for LoginScreen
class MaterialLoginView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isLogin;
  final VoidCallback onAuth;
  final VoidCallback onToggleMode;
  final VoidCallback onRecovery;

  const MaterialLoginView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.isLogin,
    required this.onAuth,
    required this.onToggleMode,
    required this.onRecovery,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.surface
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(isLogin ? 'Bem-vindo' : 'Criar Conta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      TextField(
                          key: const Key('email_field'),
                          controller: emailController,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(
                          key: const Key('password_field'),
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder())),
                      const SizedBox(height: 32),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: onAuth,
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(isLogin ? 'Entrar' : 'Cadastrar'))),
                        const SizedBox(height: 16),
                        TextButton(
                            onPressed: onToggleMode,
                            child: Text(isLogin
                                ? 'Não tem conta? Cadastre-se'
                                : 'Já tem conta? Entre')),
                        if (isLogin)
                          TextButton(
                              onPressed: onRecovery,
                              child: const Text('Esqueceu a senha?')),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
