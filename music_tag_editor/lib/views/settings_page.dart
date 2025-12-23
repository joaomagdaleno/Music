import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/views/backup_view.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';

// Enum to represent the different filename formats.
enum FilenameFormat {
  artistTitle,
  titleArtist,
  trackArtistTitle,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _dbService = DatabaseService.instance;
  FilenameFormat _selectedFormat = FilenameFormat.artistTitle;
  int _crossfadeSeconds = 3;
  bool _ageBypass = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final format = await _dbService.loadFilenameFormat();
    final crossfade = await _dbService.loadCrossfadeDuration();
    final ageBypass = await _dbService.loadAgeBypass();
    setState(() {
      _selectedFormat = format;
      _crossfadeSeconds = crossfade;
      _ageBypass = ageBypass;
      _isLoading = false;
    });
  }

  Future<void> _saveFormat(FilenameFormat format) async {
    await _dbService.saveFilenameFormat(format);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preference saved!')),
    );
  }

  Future<void> _cleanupLibrary() async {
    setState(() => _isLoading = true);
    final count = await MetadataCleanupService.instance.cleanupLibrary();
    setState(() => _isLoading = false);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count músicas foram polidas e organizadas!')),
    );
  }

  Widget _buildCloudSyncSection() {
    final syncService = FirebaseSyncService.instance;

    return Card(
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
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final success = await syncService.enableSync();
                      setState(() => _isLoading = false);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Sincronização ativada!'
                                : 'Erro ao ativar sincronização'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Sincronizar Agora'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final count = await syncService.pullFromCloud();
                    setState(() => _isLoading = false);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$count itens sincronizados!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_download),
                  tooltip: 'Baixar da Nuvem',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                  onSelected: (selected) {
                    if (selected) {
                      themeService.setAutoMode();
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Personalizado'),
                  selected: themeService.useCustomColor,
                  onSelected: (selected) {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filename Format',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<FilenameFormat>(
                      value: _selectedFormat,
                      onChanged: (FilenameFormat? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFormat = newValue;
                          });
                          _saveFormat(newValue);
                        }
                      },
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
                      onTap: _cleanupLibrary,
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
                          'Transição suave de $_crossfadeSeconds segundos entre músicas.'),
                      leading: const Icon(Icons.av_timer),
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: _crossfadeSeconds.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: '$_crossfadeSeconds s',
                          onChanged: (val) {
                            setState(() => _crossfadeSeconds = val.toInt());
                          },
                          onChangeEnd: (val) async {
                            await _dbService.saveCrossfadeDuration(val.toInt());
                            PlaybackService.instance.updateCrossfadeDuration(
                                Duration(seconds: val.toInt()));
                          },
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
                          MaterialPageRoute(builder: (_) => const BackupView()),
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
                      secondary:
                          const Icon(Icons.warning_amber, color: Colors.orange),
                      value: _ageBypass,
                      onChanged: (val) async {
                        if (val) {
                          // Show confirmation dialog
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
                                  child: const Text(
                                      'Confirmo que sou maior de 18'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }
                        }
                        setState(() => _ageBypass = val);
                        await _dbService.saveAgeBypass(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

