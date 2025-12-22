import 'package:flutter/material.dart';
import 'database_service.dart';
import 'metadata_cleanup_service.dart';
import 'playback_service.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final format = await _dbService.loadFilenameFormat();
    final crossfade = await _dbService.loadCrossfadeDuration();
    setState(() {
      _selectedFormat = format;
      _crossfadeSeconds = crossfade;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                ],
              ),
            ),
    );
  }
}
