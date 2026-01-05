import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/screens/backup/backup_screen.dart';
import 'package:music_tag_editor/models/filename_format.dart';

class FluentSettingsView extends StatefulWidget {
  final bool isLoading;
  final FilenameFormat selectedFormat;
  final int crossfadeSeconds;
  final bool ageBypass;

  final bool isAuthenticated;
  final ValueChanged<FilenameFormat?> onFormatChanged;
  final ValueChanged<double> onCrossfadeChanged;
  final ValueChanged<int> onCrossfadeSaved;
  final ValueChanged<bool> onAgeBypassChanged;
  final VoidCallback onCleanupLibrary;
  final VoidCallback onEnableCloudSync;
  final VoidCallback onPullFromCloud;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const FluentSettingsView({
    super.key,
    required this.isLoading,
    required this.selectedFormat,
    required this.crossfadeSeconds,
    required this.ageBypass,
    required this.isAuthenticated,
    required this.onFormatChanged,
    required this.onCrossfadeChanged,
    required this.onCrossfadeSaved,
    required this.onAgeBypassChanged,
    required this.onCleanupLibrary,
    required this.onEnableCloudSync,
    required this.onPullFromCloud,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  State<FluentSettingsView> createState() => _FluentSettingsViewState();
}

class _FluentSettingsViewState extends State<FluentSettingsView> {
  @override
  Widget build(BuildContext context) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Configurações'),
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
        content: widget.isLoading
            ? const Center(child: ProgressRing())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text('Formato do Nome do Arquivo',
                        style: FluentTheme.of(context).typography.subtitle),
                    const SizedBox(height: 8),
                    ComboBox<FilenameFormat>(
                      value: widget.selectedFormat,
                      onChanged: widget.onFormatChanged,
                      items: const [
                        ComboBoxItem(
                          value: FilenameFormat.artistTitle,
                          child: Text('Artist - Title.mp3'),
                        ),
                        ComboBoxItem(
                          value: FilenameFormat.titleArtist,
                          child: Text('Title (Artist).mp3'),
                        ),
                        ComboBoxItem(
                          value: FilenameFormat.trackArtistTitle,
                          child: Text('01. Artist - Title.mp3'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildThemeColorSection(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('Manutenção da Biblioteca',
                        style: FluentTheme.of(context).typography.subtitle),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: const Text('Polir Biblioteca'),
                        subtitle: const Text(
                            'Remove lixo dos nomes (ex: [OFFICIAL VIDEO]) e organiza gêneros.'),
                        leading: const Icon(FluentIcons.auto_enhance_on),
                        onPressed: widget.onCleanupLibrary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('Áudio Avançado',
                        style: FluentTheme.of(context).typography.subtitle),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(FluentIcons.timer),
                                const SizedBox(width: 8),
                                Text(
                                    'Duração do Crossfade: ${widget.crossfadeSeconds}s'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: widget.crossfadeSeconds.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              label: '${widget.crossfadeSeconds} s',
                              onChanged: widget.onCrossfadeChanged,
                              onChangeEnd: (val) =>
                                  widget.onCrossfadeSaved(val.toInt()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('Segurança de Dados',
                        style: FluentTheme.of(context).typography.subtitle),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: const Text('Backup & Restauração'),
                        subtitle: const Text(
                            'Exporte ou importe sua biblioteca e configurações.'),
                        leading: const Icon(FluentIcons.cloud_download),
                        onPressed: () {
                          Navigator.push(
                            context,
                            FluentPageRoute(
                                builder: (_) => const BackupScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCloudSyncSection(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('Conteúdo Restrito',
                        style: FluentTheme.of(context).typography.subtitle),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(FluentIcons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sou maior de 18 anos',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'Permite downloads de conteúdo restrito. Usa cookies do navegador.',
                                        style: FluentTheme.of(context)
                                            .typography
                                            .caption),
                                  ]),
                            ),
                            ToggleSwitch(
                              checked: widget.ageBypass,
                              onChanged: _handleAgeBypassChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
      );

  Future<void> _handleAgeBypassChanged(bool val) async {
    if (val) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('Confirmação'),
          content: const Text(
            'Ao ativar, o app usará os cookies do seu navegador Chrome para acessar conteúdo com restrição de idade.\n\n'
            '• Seu navegador precisa estar logado no Google\n'
            '• Risco para sua conta: MUITO BAIXO\n'
            '• O app apenas LÊ cookies, não modifica sua conta\n\n'
            'Deseja continuar?',
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmo que sou maior de 18'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    widget.onAgeBypassChanged(val);
  }

  Widget _buildCloudSyncSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(FluentIcons.cloud, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Sincronização na Nuvem',
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                  const Spacer(),
                  if (!widget.isAuthenticated)
                    Button(
                      onPressed: widget.onLogin,
                      child: const Text('Conectar Conta'),
                    )
                  else
                    Button(
                      onPressed: widget.onLogout,
                      child: const Text('Sair'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sincronize sua biblioteca entre dispositivos.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton(
                    onPressed: widget.isAuthenticated
                        ? widget.onEnableCloudSync
                        : null,
                    child: const Row(
                      children: [
                        Icon(FluentIcons.cloud_import_export),
                        SizedBox(width: 8),
                        Text('Sincronizar Agora'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed:
                        widget.isAuthenticated ? widget.onPullFromCloud : null,
                    child: const Tooltip(
                      message: 'Baixar da Nuvem',
                      child: Icon(FluentIcons.cloud_download),
                    ),
                  ),
                  if (!widget.isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '(Necessário Login)',
                        style: FluentTheme.of(context)
                            .typography
                            .caption
                            ?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildThemeColorSection() {
    final themeService = ThemeService.instance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.color, color: Colors.purple),
                const SizedBox(width: 8),
                Text('Tema de Cores',
                    style: FluentTheme.of(context).typography.bodyStrong),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                RadioButton(
                    checked: !themeService.useCustomColor,
                    content: const Text('Auto'),
                    onChanged: (v) {
                      if (v) {
                        themeService.setAutoMode();
                        setState(() {});
                      }
                    }),
                const SizedBox(width: 16),
                RadioButton(
                    checked: themeService.useCustomColor,
                    content: const Text('Personalizado'),
                    onChanged: (v) {
                      if (v) {
                        setState(() {});
                      }
                    }),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThemeService.presetColors.map((color) {
                final isSelected = themeService.customColor == color &&
                    themeService.useCustomColor;
                return GestureDetector(
                  onTap: () {
                    themeService.setCustomColor(color);
                    setState(() {});
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: FluentTheme.of(context).accentColor,
                              width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(FluentIcons.check_mark,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
