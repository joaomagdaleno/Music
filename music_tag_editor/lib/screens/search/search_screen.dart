import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';
import 'package:music_tag_editor/screens/search/views/material_search_view.dart';
import 'package:music_tag_editor/screens/search/views/fluent_search_view.dart';

class SearchScreen extends material.StatefulWidget {
  const SearchScreen({super.key});

  @override
  material.State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends material.State<SearchScreen> {
  final _searchController = material.TextEditingController();
  final _searchService = SearchService.instance;
  final _downloadService = DownloadService.instance;
  final _playbackService = PlaybackService.instance;

  final List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<MediaPlatform, SearchStatus> _platformStatuses = {};
  MediaPlatform? _selectedPlatform;

  final Map<String, List<DownloadFormat>> _formatsCache = {};
  final Map<String, DownloadFormat?> _selectedFormats = {};
  final Map<String, bool> _isExpanding = {};
  final Map<String, double> _downloadingProgress = {};
  final Map<String, String> _downloadingStatus = {};
  final Map<String, String> _loadingFormatsStatus = {};
  bool _isInitializing = true;
  String _initStatus = 'Iniciando ferramentas...';
  double _initProgress = 0;

  bool get _isFluent {
    final platform = material.Theme.of(context).platform;
    return platform == material.TargetPlatform.windows ||
        platform == material.TargetPlatform.linux ||
        platform == material.TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    debugPrint('[SearchScreen] Initializing dependencies...');
    try {
      await DependencyManager.instance.ensureDependencies(
        onProgress: (status, progress) {
          setState(() {
            _initStatus = status;
            _initProgress = progress;
          });
        },
      );
      debugPrint('[SearchScreen] Dependencies initialized successfully');
      setState(() => _isInitializing = false);
    } catch (e, stack) {
      debugPrint('[SearchScreen] Dependency initialization FAILED: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) async {
    if (query.trim().isEmpty) return;

    debugPrint('[SearchScreen] Starting search for: "$query" (Platform: $_selectedPlatform)');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults.clear();
      _platformStatuses.clear();
      _formatsCache.clear();
      _selectedFormats.clear();
      _isExpanding.clear();
    });

    try {
      if (_selectedPlatform != null) {
        debugPrint('[SearchScreen] Searching single platform: $_selectedPlatform');
        _platformStatuses[_selectedPlatform!] = SearchStatus.searching;
        
        List<SearchResult> filtered = [];
        if (_selectedPlatform == MediaPlatform.youtube) {
          filtered = await _searchService.searchYouTube(query);
        } else if (_selectedPlatform == MediaPlatform.youtubeMusic) {
          filtered = await _searchService.searchYouTubeMusic(query);
        } else if (_selectedPlatform == MediaPlatform.spotify) {
          filtered = await _searchService.searchSpotify(query);
        }
        
        if (mounted) {
          debugPrint('[SearchScreen] Single platform search returned ${filtered.length} results');
          setState(() {
            _searchResults.addAll(filtered);
            _platformStatuses[_selectedPlatform!] = filtered.isEmpty ? SearchStatus.noResults : SearchStatus.completed;
          });
        }
      } else {
        debugPrint('[SearchScreen] Searching all platforms');
        final results = await _searchService.searchAll(query, 
          onStatusUpdate: (p, s) {
            debugPrint('[SearchScreen] Status update for $p: $s');
            if (mounted) setState(() => _platformStatuses[p] = s);
          }
        );
        if (mounted) {
          debugPrint('[SearchScreen] Search all returned ${results.length} results');
          setState(() {
            _searchResults.addAll(results);
          });
        }
      }

      if (_searchResults.isEmpty && mounted) {
        debugPrint('[SearchScreen] No results found for query: "$query"');
        setState(() => _errorMessage =
            'Nenhuma música encontrada nas plataformas selecionadas.');
      }
    } catch (e, stack) {
      debugPrint('[SearchScreen] Error during search: $e\n$stack');
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao buscar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setPlatform(MediaPlatform? platform) {
    debugPrint('[SearchScreen] Platform changed to: $platform');
    setState(() {
      _selectedPlatform = platform;
    });
  }

  Future<void> loadFormats(SearchResult result) async {
    debugPrint('[SearchScreen] Loading formats for ${result.id} (${result.platform})');
    if (_formatsCache.containsKey(result.url)) {
      debugPrint('[SearchScreen] Using cached formats for ${result.id}');
      setState(() =>
          _isExpanding[result.url] = !(_isExpanding[result.url] ?? false));
      return;
    }

    setState(() {
      _isExpanding[result.url] = true;
      _loadingFormatsStatus[result.url] = 'Obtendo formatos...';
    });

    try {
      final formats =
          await _searchService.getFormats(result.url, result.platform);
      debugPrint('[SearchScreen] Retrived ${formats.length} formats for ${result.id}');
      if (mounted) {
        setState(() {
          _formatsCache[result.url] = formats;
          if (formats.isNotEmpty) {
            _selectedFormats[result.url] = formats.first;
          }
          _loadingFormatsStatus.remove(result.url);
        });
      }
    } catch (e, stack) {
      debugPrint('[SearchScreen] Error loading formats: $e\n$stack');
      if (mounted) {
        showSnackBar('Erro ao carregar formatos: $e');
        setState(() => _loadingFormatsStatus.remove(result.url));
      }
    }
  }

  Future<void> startDownload(SearchResult result) async {
    final selectedFormat = _selectedFormats[result.url];
    debugPrint('[SearchScreen] Starting download for ${result.id} with format: ${selectedFormat?.formatId}');
    if (selectedFormat == null) {
      return;
    }

    setState(() {
      _downloadingProgress[result.url] = 0;
      _downloadingStatus[result.url] = 'Buscando metadados ideais...';
    });

    try {
      String? overrideThumbnail;
      if (result.platform == MediaPlatform.youtube ||
          result.platform == MediaPlatform.youtubeMusic) {
        debugPrint('[SearchScreen] Looking for Spotify metadata match for YouTube result...');
        final match = await _searchService.findSpotifyMatch(result);
        if (match != null) {
          debugPrint('[SearchScreen] Found Spotify match for metadata');
          overrideThumbnail = match.thumbnail;
        }
      }

      final musicDir = '${Platform.environment['USERPROFILE']}\\Music';
      debugPrint('[SearchScreen] Target directory: $musicDir');

      await _downloadService.download(
        result.url,
        selectedFormat,
        musicDir,
        overrideThumbnailUrl: overrideThumbnail,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _downloadingProgress[result.url] = progress;
              _downloadingStatus[result.url] = status;
            });
          }
        },
      );

      debugPrint('[SearchScreen] Download COMPLETED for ${result.id}');
      if (mounted) {
        showSnackBar('Download de "${result.title}" concluído!');
      }
    } catch (e, stack) {
      debugPrint('[SearchScreen] Download FAILED: $e\n$stack');
      if (mounted) {
        showSnackBar('Erro no download: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingProgress.remove(result.url);
          _downloadingStatus.remove(result.url);
        });
      }
    }
  }

  Future<void> addToPlaylist(SearchResult result) async {
    debugPrint('[SearchScreen] Adding ${result.id} to playlist');
    final db = DatabaseService.instance;
    final playlistsList = await db.getPlaylists();

    if (!mounted) return;

    if (playlistsList.isEmpty) {
      showSnackBar('Crie uma playlist primeiro na aba "Playlists"');
      return;
    }

    final selectedPlaylistId = await showPlaylistDialog(playlistsList);

    if (selectedPlaylistId != null) {
      debugPrint('[SearchScreen] Selected playlist ID: $selectedPlaylistId');
      await db.saveTrack({
        'id': result.id,
        'title': result.title,
        'artist': result.artist,
        'thumbnail': result.thumbnail,
        'duration': result.duration,
        'platform': result.platform.toString(),
        'url': result.url,
      });

      await db.addTrackToPlaylist(selectedPlaylistId, result.id);
      debugPrint('[SearchScreen] Track added to playlist successfully');
      if (mounted) {
        showSnackBar('"${result.title}" adicionada à playlist!');
      }
    }
  }

  Future<void> playTrack(SearchResult result) async {
    debugPrint('[SearchScreen] Playing track: ${result.id}');
    try {
      if (mounted) {
        showSnackBar('Carregando áudio de "${result.title}"...');
      }
      await _playbackService.playSearchResult(result);
      debugPrint('[SearchScreen] Playback started for ${result.id}');
    } catch (e, stack) {
      debugPrint('[SearchScreen] Playback FAILED: $e\n$stack');
      if (mounted) {
        showSnackBar('Erro ao reproduzir: $e');
      }
    }
  }

  void openFullPlayer() {
    debugPrint('[SearchScreen] Opening full player');
    material.Navigator.push(
      context,
      material.MaterialPageRoute(builder: (context) => const PlayerScreen()),
    );
  }

  void showSnackBar(String message) {
    if (_isFluent) {
      debugPrint('[SearchScreen][SnackBar/Fluent] $message');
    } else {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text(message)),
      );
    }
  }

  Future<int?> showPlaylistDialog(List<Map<String, dynamic>> playlistsList) {
    if (_isFluent) {
       return fluent.showDialog<int?>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const fluent.Text('Adicionar à Playlist'),
          content: fluent.SizedBox(
            width: double.maxFinite,
            child: fluent.ListView.builder(
              shrinkWrap: true,
              itemCount: playlistsList.length,
              itemBuilder: (context, index) {
                final p = playlistsList[index];
                return fluent.ListTile(
                  title: fluent.Text(p['name']),
                  onPressed: () => fluent.Navigator.pop(context, p['id']),
                );
              },
            ),
          ),
          actions: [
            fluent.Button(
              onPressed: () => fluent.Navigator.pop(context),
              child: const fluent.Text('Cancelar'),
            ),
          ],
        ),
      );
    } else {
      return material.showDialog<int?>(
        context: context,
        builder: (context) => material.AlertDialog(
          title: const material.Text('Adicionar à Playlist'),
          content: material.SizedBox(
            width: double.maxFinite,
            child: material.ListView.builder(
              shrinkWrap: true,
              itemCount: playlistsList.length,
              itemBuilder: (context, index) {
                final p = playlistsList[index];
                return material.ListTile(
                  title: material.Text(p['name']),
                  onTap: () => material.Navigator.pop(context, p['id']),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    if (_isInitializing) {
      if (_isFluent) {
         return fluent.ScaffoldPage(
          header: const fluent.PageHeader(title: fluent.Text('Busca de Músicas')),
          content: fluent.Center(
            child: fluent.Padding(
              padding: const fluent.EdgeInsets.all(32),
              child: fluent.Column(
                mainAxisSize: fluent.MainAxisSize.min,
                children: [
                  const fluent.ProgressRing(),
                  const fluent.SizedBox(height: 24),
                  fluent.Text(_initStatus),
                  const fluent.SizedBox(height: 16),
                  fluent.ProgressBar(value: _initProgress),
                ],
              ),
            ),
          ),
        );
      } else {
        return material.Scaffold(
          appBar: material.AppBar(title: const material.Text('Busca de Músicas')),
          body: material.Center(
            child: material.Padding(
              padding: const material.EdgeInsets.all(32),
              child: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                children: [
                  const material.CircularProgressIndicator(),
                  const material.SizedBox(height: 24),
                  material.Text(_initStatus),
                  const material.SizedBox(height: 16),
                  material.LinearProgressIndicator(value: _initProgress),
                ],
              ),
            ),
          ),
        );
      }
    }
    
    // Callback methods wrapper
    void handleFormatSelected(SearchResult result, String? val) {
       setState(() {
          _selectedFormats[result.url] =
              _formatsCache[result.url]!
                  .firstWhere((f) => f.formatId == val);
        });
    }

    void handleToggleExpand(SearchResult result) {
      loadFormats(result);
    }

    if (_isFluent) {
      return FluentSearchView(
        searchController: _searchController,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        results: _searchResults,
        platformStatuses: _platformStatuses,
        selectedPlatform: _selectedPlatform,
        isExpanding: _isExpanding,
        formatsCache: _formatsCache,
        selectedFormats: _selectedFormats,
        downloadingProgress: _downloadingProgress,
        downloadingStatus: _downloadingStatus,
        loadingFormatsStatus: _loadingFormatsStatus,
        onSearch: () => _onSearch(_searchController.text),
        onPlay: playTrack,
        onAddToPlaylist: addToPlaylist,
        onLoadFormats: loadFormats,
        onDownload: startDownload,
        onFormatSelected: handleFormatSelected,
        onToggleExpand: handleToggleExpand,
        onOpenFullPlayer: openFullPlayer,
        onPlatformChanged: _setPlatform,
      );
    }

    return MaterialSearchView(
      searchController: _searchController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      results: _searchResults,
      platformStatuses: _platformStatuses,
      isExpanding: _isExpanding,
      formatsCache: _formatsCache,
      selectedFormats: _selectedFormats,
      downloadingProgress: _downloadingProgress,
      downloadingStatus: _downloadingStatus,
      onSearch: () => _onSearch(_searchController.text),
      onPlay: playTrack,
      onAddToPlaylist: addToPlaylist,
      onLoadFormats: loadFormats,
      onDownload: startDownload,
      onFormatSelected: handleFormatSelected,
      onToggleExpand: handleToggleExpand,
      onOpenFullPlayer: openFullPlayer,
    );
  }
}
