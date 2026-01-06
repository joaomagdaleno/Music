import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for LoginScreen - WinUI 3 styling
class FluentLoginView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isLogin;
  final VoidCallback onAuth;
  final VoidCallback onToggleMode;
  final VoidCallback onRecovery;

  const FluentLoginView({
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
  Widget build(BuildContext context) => NavigationView(
        appBar: NavigationAppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: IconButton(
                    icon: const Icon(FluentIcons.back),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null,
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
                Colors.transparent
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.music_note,
                        size: 64, color: FluentTheme.of(context).accentColor),
                    const SizedBox(height: 16),
                    Text(isLogin ? 'Bem-vindo' : 'Criar Conta',
                        style: FluentTheme.of(context).typography.title),
                    const SizedBox(height: 32),
                    TextBox(
                        controller: emailController,
                        placeholder: 'Email',
                        prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(FluentIcons.mail))),
                    const SizedBox(height: 16),
                    PasswordBox(
                        controller: passwordController, placeholder: 'Senha'),
                    const SizedBox(height: 32),
                    if (isLoading)
                      const ProgressRing()
                    else ...[
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: onAuth,
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child:
                                      Text(isLogin ? 'Entrar' : 'Cadastrar')))),
                      const SizedBox(height: 16),
                      HyperlinkButton(
                          onPressed: onToggleMode,
                          child: Text(isLogin
                              ? 'Não tem conta? Cadastre-se'
                              : 'Já tem conta? Entre')),
                      if (isLogin)
                        HyperlinkButton(
                            onPressed: onRecovery,
                            child: const Text('Esqueceu a senha?')),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
