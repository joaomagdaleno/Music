import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/screens/login/views/fluent_login_view.dart';
import 'package:music_tag_editor/screens/login/views/material_login_view.dart';

/// LoginScreen controller - platform-adaptive
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('[LoginScreen] Starting ${_isLogin ? 'LOGIN' : 'REGISTRATION'} process for: $email');
    bool success = _isLogin
        ? await AuthService.instance.login(email, password)
        : await AuthService.instance.register(email, password);
    debugPrint('[LoginScreen] Auth process finished. Result: ${success ? 'SUCCESS' : 'FAILURE'}');

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      } else {
        _showError();
      }
    }
  }

  void _showError() {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux) {
      fluent.displayInfoBar(context, builder: (_, close) => fluent.InfoBar(title: const Text('Falha na autenticação'), severity: fluent.InfoBarSeverity.error, onClose: close));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha na autenticação')));
    }
  }

  void _showRecoveryDialog() {
    final recoveryEmailController = TextEditingController(text: _emailController.text);
    
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux) {
      fluent.showDialog(context: context, builder: (_) => fluent.ContentDialog(
        title: const Text('Recuperação 2FA'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Enviaremos um link de recuperação para o seu email.'), const SizedBox(height: 16), fluent.TextBox(controller: recoveryEmailController, placeholder: 'Confirmar Email')]),
        actions: [
          fluent.Button(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          fluent.FilledButton(child: const Text('Enviar'), onPressed: () async {
            final email = recoveryEmailController.text.trim();
            if (email.isNotEmpty) {
              await AuthService.instance.sendPasswordReset(email);
              if (mounted) Navigator.pop(context);
            }
          }),
        ],
      ));
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Recuperação 2FA'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Enviaremos um link de recuperação para o seu email.'), const SizedBox(height: 16), TextField(controller: recoveryEmailController, decoration: const InputDecoration(labelText: 'Confirmar Email'))]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            final email = recoveryEmailController.text.trim();
            if (email.isNotEmpty) {
              await AuthService.instance.sendPasswordReset(email);
              if (mounted) Navigator.pop(context);
            }
          }, child: const Text('Enviar')),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentLoginView(
          emailController: _emailController,
          passwordController: _passwordController,
          isLoading: _isLoading,
          isLogin: _isLogin,
          onAuth: _handleAuth,
          onToggleMode: () => setState(() => _isLogin = !_isLogin),
          onRecovery: _showRecoveryDialog,
        );
      default:
        return MaterialLoginView(
          emailController: _emailController,
          passwordController: _passwordController,
          isLoading: _isLoading,
          isLogin: _isLogin,
          onAuth: _handleAuth,
          onToggleMode: () => setState(() => _isLogin = !_isLogin),
          onRecovery: _showRecoveryDialog,
        );
    }
  }
}
