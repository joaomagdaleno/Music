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

  List<SearchResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<MediaPlatform, SearchStatus> _platformStatuses = {};

  Map<String, List<DownloadFormat>> _formatsCache = {};
  Map<String, DownloadFormat?> _selectedFormats = {};
  Map<String, bool> _isExpanding = {};
  final Map<String, double> _downloadingProgress = {};
  final Map<String, String> _downloadingStatus = {};
  bool _isInitializing = true;
  String _initStatus = 'Iniciando ferramentas...';
  double _initProgress = 0;

  bool get _isFluent {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    try {
      await DependencyManager.instance.ensureDependencies(
        onProgress: (status, progress) {
          setState(() {
            _initStatus = status;
            _initProgress = progress;
          });
        },
      );
      setState(() => _isInitializing = false);
    } catch (e) {
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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
      _formatsCache = {};
      _selectedFormats = {};
      _isExpanding = {};
      _platformStatuses = {
        MediaPlatform.youtube: SearchStatus.searching,
        MediaPlatform.youtubeMusic: SearchStatus.searching,
        MediaPlatform.spotify: SearchStatus.searching,
      };
    });

    try {
      final results = await _searchService.searchAll(
        query,
        onStatusUpdate: (platform, status) {
          if (mounted) {
            setState(() {
              _platformStatuses[platform] = status;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _results = results;
        });
      }

      if (results.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage =
              'Nenhuma música encontrada nas plataformas selecionadas.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao buscar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFormats(SearchResult result) async {
    if (_formatsCache.containsKey(result.url)) {
      setState(() =>
          _isExpanding[result.url] = !(_isExpanding[result.url] ?? false));
      return;
    }

    setState(() => _isExpanding[result.url] = true);

    try {
      final formats =
          await _searchService.getFormats(result.url, result.platform);
      if (mounted) {
        setState(() {
          _formatsCache[result.url] = formats;
          if (formats.isNotEmpty) {
            _selectedFormats[result.url] = formats.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao carregar formatos: $e');
      }
    }
  }

  Future<void> _startDownload(SearchResult result) async {
    final selectedFormat = _selectedFormats[result.url];
    if (selectedFormat == null) {
      return;
    }

    setState(() {
      _downloadingProgress[result.url] = 0;
      _downloadingStatus[result.url] = 'Buscando metadados ideais...';
    });

    try {
      // Find Spotify match for better cover if it's YouTube
      String? overrideThumbnail;
      if (result.platform == MediaPlatform.youtube ||
          result.platform == MediaPlatform.youtubeMusic) {
        final match = await _searchService.findSpotifyMatch(result);
        if (match != null) {
          overrideThumbnail = match.thumbnail;
        }
      }

      // Use user's Music folder
      final musicDir = '${Platform.environment['USERPROFILE']}\\Music';

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

      if (mounted) {
        _showSnackBar('Download de "${result.title}" concluído!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro no download: $e');
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

  Future<void> _addToPlaylist(SearchResult result) async {
    final db = DatabaseService.instance;
    final playlistsList = await db.getPlaylists();

    if (!mounted) {
      return;
    }

    if (playlistsList.isEmpty) {
      _showSnackBar('Crie uma playlist primeiro na aba "Playlists"');
      return;
    }

    final selectedPlaylistId = await _showPlaylistDialog(playlistsList);

    if (selectedPlaylistId != null) {
      // First save the track metadata to the tracks table
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

      if (mounted) {
        _showSnackBar('"${result.title}" adicionada à playlist!');
      }
    }
  }

  Future<void> _playTrack(SearchResult result) async {
    try {
      if (mounted) {
        _showSnackBar('Carregando áudio de "${result.title}"...');
      }
      await _playbackService.playSearchResult(result);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao reproduzir: $e');
      }
    }
  }

  void _openFullPlayer() {
    material.Navigator.push(
      context,
      material.MaterialPageRoute(builder: (context) => const PlayerScreen()),
    );
  }

  void _showSnackBar(String message) {
    if (_isFluent) {
      // Fluent UI doesn't have a standardized global snackbar without a Key/Overlay setup that mirrors Material's ScaffoldMessenger behavior easily in a localized child.
      // We will fallback to debugging print or a dialog if critical, but for now we can try to use a local InfoBar overlay or just rely on console for non-critical feedback
      // Or we can use `fluent.showDialog` for important messages.
      // For ephemeral messages like 'Downloading...', we might want a better solution in Fluent.
      // For now, logging to debug console and showing simple dialog for critical success/error.
      debugPrint('[Fluent] $message');
    } else {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text(message)),
      );
    }
  }

  Future<int?> _showPlaylistDialog(List<Map<String, dynamic>> playlistsList) {
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
      _loadFormats(result); // This method handles toggling too
    }

    if (_isFluent) {
      return FluentSearchView(
        searchController: _searchController,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        results: _results,
        platformStatuses: _platformStatuses,
        isExpanding: _isExpanding,
        formatsCache: _formatsCache,
        selectedFormats: _selectedFormats,
        downloadingProgress: _downloadingProgress,
        downloadingStatus: _downloadingStatus,
        onSearch: _performSearch,
        onPlay: _playTrack,
        onAddToPlaylist: _addToPlaylist,
        onLoadFormats: _loadFormats,
        onDownload: _startDownload,
        onFormatSelected: handleFormatSelected,
        onToggleExpand: handleToggleExpand,
        onOpenFullPlayer: _openFullPlayer,
      );
    }

    return MaterialSearchView(
      searchController: _searchController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      results: _results,
      platformStatuses: _platformStatuses,
      isExpanding: _isExpanding,
      formatsCache: _formatsCache,
      selectedFormats: _selectedFormats,
      downloadingProgress: _downloadingProgress,
      downloadingStatus: _downloadingStatus,
      onSearch: _performSearch,
      onPlay: _playTrack,
      onAddToPlaylist: _addToPlaylist,
      onLoadFormats: _loadFormats,
      onDownload: _startDownload,
      onFormatSelected: handleFormatSelected,
      onToggleExpand: handleToggleExpand,
      onOpenFullPlayer: _openFullPlayer,
    );
  }
}
