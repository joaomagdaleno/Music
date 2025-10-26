import 'package:flutter/material.dart';
import 'database_service.dart';

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
  final DatabaseService _dbService = DatabaseService();
  FilenameFormat _selectedFormat = FilenameFormat.artistTitle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final format = await _dbService.loadFilenameFormat();
    setState(() {
      _selectedFormat = format;
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
                ],
              ),
            ),
    );
  }
}
