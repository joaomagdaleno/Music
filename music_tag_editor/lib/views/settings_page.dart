import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/views/backup_view.dart';

// Enum to represent the different filename formats.
enum FilenameFormat {
  artistTitle,
  titleArtist,
  trackArtistTitle,
}

extension FilenameFormatExtension on FilenameFormat {
  String generateFilename({
    required String artist,
    required String title,
    required int trackNumber,
  }) {
    switch (this) {
      case FilenameFormat.artistTitle:
        return '$artist - $title';
      case FilenameFormat.titleArtist:
        return '$title ($artist)';
      case FilenameFormat.trackArtistTitle:
        final trackStr = trackNumber.toString().padLeft(2, '0');
        return '$trackStr. $artist - $title';
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _dbService = DatabaseService.instance;
  FilenameFormat _selectedFormat = FilenameFormat.artistTitle;
  bool _ageBypass = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final format = await _dbService.loadFilenameFormat();
    final ageBypass = await _dbService.loadAgeBypass();
    setState(() {
      _selectedFormat = format;
      _ageBypass = ageBypass;
      _isLoading = false;
    });
  }

  Future<void> _saveFormat(FilenameFormat format) async {
    await _dbService.saveFilenameFormat(format);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferência salva!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
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
                      'Formato de Nome de Arquivo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Como os arquivos serão renomeados após a edição das tags.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<FilenameFormat>(
                      isExpanded: true,
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
                          child: Text('Artista - Título.mp3'),
                        ),
                        DropdownMenuItem(
                          value: FilenameFormat.titleArtist,
                          child: Text('Título (Artista).mp3'),
                        ),
                        DropdownMenuItem(
                          value: FilenameFormat.trackArtistTitle,
                          child: Text('01. Artista - Título.mp3'),
                        ),
                      ],
                    ),
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
                      leading:
                          const Icon(Icons.auto_fix_high, color: Colors.blue),
                      onTap: _cleanupLibrary,
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
                      leading: const Icon(Icons.backup, color: Colors.green),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BackupView()),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    Text(
                      'Conteúdo Restrito',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Sou maior de 18 anos'),
                      subtitle: const Text(
                          'Permite downloads de conteúdo restrito. Usa cookies do seu browser para verificar idade.'),
                      secondary:
                          const Icon(Icons.warning_amber, color: Colors.orange),
                      value: _ageBypass,
                      onChanged: (val) async {
                        if (val) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmação'),
                              content: const Text(
                                'Ao ativar, o app usará os cookies do seu navegador para acessar conteúdo com restrição de idade.\n\n'
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
