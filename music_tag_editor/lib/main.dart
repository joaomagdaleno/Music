import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:music_tag_editor/api/musicbrainz_api.dart';
import 'package:music_tag_editor/widgets/search_results_dialog.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/widgets/edit_track_dialog.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';
import 'package:music_tag_editor/services/metadata_service.dart';
import 'package:music_tag_editor/views/search_page.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/views/my_tracks_view.dart';
import 'package:music_tag_editor/views/smart_library_view.dart';
import 'package:music_tag_editor/views/mood_explorer_view.dart';
import 'package:music_tag_editor/views/ringtone_maker_view.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/views/login_page.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/music_track.dart';

import 'package:music_tag_editor/services/telemetry_service.dart';
import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Telemetry
    await TelemetryService.instance.init();

    // Initialize Core Services
    await SecurityService.instance.init();
    AuthService.instance.init();
    await ConnectivityService.instance.init();
    await PersonaService.instance.init();

    await ThemeService.instance.init();
    await DesktopIntegrationService.instance.init();
    await PlaybackService.instance.init();

    runApp(const MusicTagEditorApp());
  }, (error, stack) {
    debugPrint('Fatal error: $error');
    TelemetryService.instance.recordError(error, stack);
  });
}

class MusicTagEditorApp extends StatelessWidget {
  const MusicTagEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        final primaryColor = ThemeService.instance.primaryColor;
        return MaterialApp(
          title: 'Music Tag Editor',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          home: AuthService.instance.isAuthenticated
              ? const AppShell()
              : const LoginPage(),
        );
      },
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.title});

  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final List<MusicTrack> _musicTracks = [];
  bool _isLoading = false;
  final MusicBrainzApi _musicBrainzApi = MusicBrainzApi();
  final DatabaseService _dbService = DatabaseService.instance;
  final MetadataService _metadataService = MetadataService();
  String? _currentDirectory;

  Future<void> _addMusicFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      _currentDirectory = selectedDirectory;
      _loadMusicFromDirectory();
    }
  }

  Future<void> _loadMusicFromDirectory() async {
    if (_currentDirectory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final directory = Directory(_currentDirectory!);
      final List<MusicTrack> foundTracks = [];
      await for (var entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          // Read metadata for each found mp3 file.
          final metadata = await _metadataService.readMetadata(entity.path);
          foundTracks.add(MusicTrack(
            filePath: entity.path,
            title: metadata['title'] as String,
            artist: metadata['artist'] as String,
            album: metadata['album'] as String,
            trackNumber: metadata['track'] as int,
          ));
        }
      }
      setState(() {
        _musicTracks.clear();
        _musicTracks.addAll(foundTracks);
      });
    } catch (e) {
      // Handle exceptions
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchOnline(MusicTrack track) async {
    debugPrint('Searching online for: ${track.artist} - ${track.title}');
    try {
      final results = await _musicBrainzApi.searchRecording(
        artist: track.artist,
        title: track.title,
      );

      if (results['recordings'] != null && results['recordings'].isNotEmpty) {
        if (!mounted) return;
        final selectedRecording = await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SearchResultsDialog(recordings: results['recordings']);
          },
        );

        if (selectedRecording != null) {
          _applyTags(
              originalTrack: track, selectedRecording: selectedRecording);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found online.')),
        );
      }
    } catch (e) {
      debugPrint('Error searching online: $e');
    }
  }

  Future<void> _applyTags(
      {required MusicTrack originalTrack,
      dynamic selectedRecording,
      MusicTrack? manualTrack}) async {
    String newTitle, newArtist, newAlbum;
    int newTrackNumber;

    if (selectedRecording != null) {
      newTitle = selectedRecording['title'] as String? ?? originalTrack.title;
      newArtist = selectedRecording['artist-credit']?[0]?['name'] as String? ??
          originalTrack.artist;
      newAlbum = selectedRecording['releases']?[0]?['title'] as String? ??
          originalTrack.album;
      final trackNumberStr = selectedRecording['releases']?[0]?['media']?[0]
              ?['track-offset']
          ?.toString();
      newTrackNumber = trackNumberStr != null
          ? int.tryParse(trackNumberStr) ?? originalTrack.trackNumber
          : originalTrack.trackNumber;

      // Apply learning rules
      final rules = await _dbService.getLearningRules();
      for (var rule in rules) {
        bool artistMatch = rule.choice == LearningChoice.forThisArtist &&
            rule.artist == newArtist;
        bool forAll = rule.choice == LearningChoice.forAll;

        if (artistMatch || forAll) {
          if (rule.field == 'title' && newTitle == rule.originalValue) {
            newTitle = rule.correctedValue;
          }
          if (rule.field == 'artist' && newArtist == rule.originalValue) {
            newArtist = rule.correctedValue;
          }
          if (rule.field == 'album' && newAlbum == rule.originalValue) {
            newAlbum = rule.correctedValue;
          }
        }
      }
    } else if (manualTrack != null) {
      newTitle = manualTrack.title;
      newArtist = manualTrack.artist;
      newAlbum = manualTrack.album;
      newTrackNumber = manualTrack.trackNumber;
    } else {
      return; // Nothing to do
    }

    try {
      // Write metadata to the file using dart_tags (pure Dart, cross-platform)
      await _metadataService.writeMetadata(
        originalTrack.filePath,
        title: newTitle,
        artist: newArtist,
        album: newAlbum,
        trackNumber: newTrackNumber,
      );

      // Load the preferred filename format.
      final format = await _dbService.loadFilenameFormat();

      // Rename the file.
      final file = File(originalTrack.filePath);
      final directory = file.parent.path;
      final extension = p.extension(file.path);
      final newFileName =
          '${format.generateFilename(artist: newArtist, title: newTitle, trackNumber: newTrackNumber)}$extension';
      final newPath = p.join(directory, newFileName);

      if (originalTrack.filePath != newPath && !await File(newPath).exists()) {
        await file.rename(newPath);
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated: $newFileName')),
      );

      _loadMusicFromDirectory();
    } catch (e) {
      debugPrint('Error applying tags: $e');
    }
  }

  void _editTrack(MusicTrack track) async {
    final updatedTrack = await showDialog<MusicTrack>(
      context: context,
      builder: (context) => EditTrackDialog(track: track),
    );

    if (updatedTrack != null) {
      if (updatedTrack.title != track.title) {
        _handleManualEdit(track, 'title', track.title, updatedTrack.title);
      }
      if (updatedTrack.artist != track.artist) {
        _handleManualEdit(track, 'artist', track.artist, updatedTrack.artist);
      }
      if (updatedTrack.album != track.album) {
        _handleManualEdit(track, 'album', track.album, updatedTrack.album);
      }

      _applyTags(originalTrack: track, manualTrack: updatedTrack);
    }
  }

  void _handleManualEdit(MusicTrack track, String field, String originalValue,
      String correctedValue) async {
    final choice = await showDialog<LearningChoice>(
      context: context,
      builder: (context) => const LearningDialog(),
    );

    if (choice != null && choice != LearningChoice.justThisOnce) {
      final rule = LearningRule(
        artist: choice == LearningChoice.forThisArtist ? track.artist : null,
        field: field,
        originalValue: originalValue,
        correctedValue: correctedValue,
        choice: choice,
      );
      await _dbService.saveLearningRule(rule);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning rule saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download Music',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pastas Local'),
              Tab(text: 'Minha Biblioteca'),
              Tab(text: 'Smart Mix'),
              Tab(text: 'Mood Explorer'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFolderView(),
            const MyTracksView(),
            const SmartLibraryView(),
            MoodExplorerView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderView() {
    return Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : _musicTracks.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Nenhuma pasta selecionada.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _addMusicFolder,
                        child: const Text('Selecionar Pasta')),
                  ],
                )
              : ListView.builder(
                  itemCount: _musicTracks.length,
                  itemBuilder: (context, index) {
                    final track = _musicTracks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(track.title),
                      subtitle: Text('${track.artist} - ${track.album}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'ringtone') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RingtoneMakerView(
                                  track: SearchResult(
                                    id: index.toString(),
                                    title: track.title,
                                    artist: track.artist,
                                    url: '',
                                    platform: MediaPlatform.unknown,
                                    thumbnail:
                                        'https://via.placeholder.com/150',
                                    localPath: track.filePath,
                                    genre: 'Unknown',
                                  ),
                                ),
                              ),
                            );
                          } else if (value == 'search') {
                            _searchOnline(track);
                          } else if (value == 'edit') {
                            _editTrack(track);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'ringtone',
                            child: ListTile(
                              leading: Icon(Icons.content_cut),
                              title: Text('Criar Toque'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'search',
                            child: ListTile(
                              leading: Icon(Icons.search),
                              title: Text('Buscar Metadados'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Editar Manualmente'),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Selection logic or play
                      },
                      onLongPress: () => _editTrack(track),
                    );
                  },
                ),
    );
  }
}
