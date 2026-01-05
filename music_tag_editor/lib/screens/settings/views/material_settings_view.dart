import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/screens/backup/backup_screen.dart';
import 'package:music_tag_editor/models/filename_format.dart';

class MaterialSettingsView extends StatefulWidget {
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

  const MaterialSettingsView({
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
  State<MaterialSettingsView> createState() => _MaterialSettingsViewState();
}

class _MaterialSettingsViewState extends State<MaterialSettingsView> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Filename Format',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<FilenameFormat>(
                        value: widget.selectedFormat,
                        onChanged: widget.onFormatChanged,
                        items: const [
                          DropdownMenuItem(
                            value: FilenameFormat.artistTitle,
                            child: Text('Artist - Title.mp3'),
                          ),
                          DropdownMenuItem(
                            value: FilenameFormat.titleArtist,
                            child: Text('Title (Artist).mp3'),
                          ),
                          DropdownMenuItem(
                            value: FilenameFormat.trackArtistTitle,
                            child: Text('01. Artist - Title.mp3'),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildThemeColorSection(),
                      const Divider(height: 32),
                      Text(
                        'Manutenção da Biblioteca',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Polir Biblioteca'),
                        subtitle: const Text(
                            'Remove lixo dos nomes (ex: [OFFICIAL VIDEO]) e organiza gêneros.'),
                        leading: const Icon(Icons.auto_fix_high),
                        onTap: widget.onCleanupLibrary,
                      ),
                      const Divider(height: 32),
                      Text(
                        'Áudio Avançado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Duração do Crossfade'),
                        subtitle: Text(
                            'Transição suave de ${widget.crossfadeSeconds} segundos entre músicas.'),
                        leading: const Icon(Icons.av_timer),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: widget.crossfadeSeconds.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: '${widget.crossfadeSeconds} s',
                            onChanged: widget.onCrossfadeChanged,
                            onChangeEnd: (val) =>
                                widget.onCrossfadeSaved(val.toInt()),
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Segurança de Dados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Backup & Restauração'),
                        subtitle: const Text(
                            'Exporte ou importe sua biblioteca e configurações.'),
                        leading: const Icon(Icons.backup),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BackupScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCloudSyncSection(),
                      const Divider(height: 32),
                      Text(
                        'Conteúdo Restrito',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Sou maior de 18 anos'),
                        subtitle: const Text(
                            'Permite downloads de conteúdo restrito. Usa cookies do seu browser para verificar idade. Risco de conta: MUITO BAIXO (apenas leitura).'),
                        secondary: const Icon(Icons.warning_amber,
                            color: Colors.orange),
                        value: widget.ageBypass,
                        onChanged: _handleAgeBypassChanged,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      );

  Future<void> _handleAgeBypassChanged(bool val) async {
    if (val) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmação'),
          content: const Text(
            'Ao ativar, o app usará os cookies do seu navegador Chrome para acessar conteúdo com restrição de idade.\n\n'
            '• Seu navegador precisa estar logado no Google\n'
            '• Risco para sua conta: MUITO BAIXO\n'
            '• O app apenas LÊ cookies, não modifica sua conta\n\n'
            'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
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
                  const Icon(Icons.cloud_sync, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Sincronização na Nuvem',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (!widget.isAuthenticated)
                    TextButton(
                      onPressed: widget.onLogin,
                      child: const Text('Conectar'),
                    )
                  else
                    TextButton(
                      onPressed: widget.onLogout,
                      child: const Text('Sair'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sincronize sua biblioteca entre dispositivos.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isAuthenticated
                          ? widget.onEnableCloudSync
                          : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Sincronizar Agora'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        widget.isAuthenticated ? widget.onPullFromCloud : null,
                    icon: const Icon(Icons.cloud_download),
                    tooltip: 'Baixar da Nuvem',
                  ),
                ],
              ),
              if (!widget.isAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Login necessário para sincronização',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildThemeColorSection() {
    final themeService = ThemeService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Tema de Cores',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Auto'),
                  selected: !themeService.useCustomColor,
                  onSelected: (val) {
                    if (val) {
                      themeService.setAutoMode();
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Personalizado'),
                  selected: themeService.useCustomColor,
                  onSelected: (val) {
                    if (val) {
                      themeService.setCustomColor(ThemeService.presetColors.first);
                      setState(() {});
                    }
                  },
                ),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
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
