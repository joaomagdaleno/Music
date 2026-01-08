import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/features/discovery/services/search_service.dart';
import 'package:music_hub/features/player/screens/player_screen.dart';
import 'package:music_hub/features/discovery/screens/views/material_search_view.dart';
import 'package:music_hub/features/discovery/screens/views/fluent_search_view.dart';
import 'package:music_hub/core/services/startup_logger.dart';
import 'package:music_hub/core/services/music_manager_service.dart';
import 'package:music_hub/features/library/models/download_models.dart';
import 'package:music_hub/features/library/models/search_models.dart';

class DiscoveryScreen extends material.StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  material.State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends material.State<DiscoveryScreen>
    with material.AutomaticKeepAliveClientMixin {
  final _searchController = material.TextEditingController();
  final _searchService = SearchService.instance;
  final _downloadService = DownloadService.instance;
  final _playbackService = PlaybackService.instance;
  final _musicManager = MusicManagerService.instance;

  final List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<MediaPlatform, SearchStatus> _platformStatuses = {};
  int _currentSearchId = 0;
  String? _currentlyPlayingUrl;
  StreamSubscription? _playbackSubscription;
  StreamSubscription? _managerProgressSubscription;

  @override
  bool get wantKeepAlive => true;

  final Map<String, List<DownloadFormat>> _formatsCache = {};
  final Map<String, DownloadFormat?> _selectedFormats = {};
  final Map<String, bool> _isExpanding = {};
  final Map<String, double> _downloadingProgress = {};
  final Map<String, String> _downloadingStatus = {};
  final Map<String, String> _loadingFormatsStatus = {};
  bool _isInitializing = true;
  String _initStatus = 'Iniciando ferramentas...';
  double _initProgress = 0;
  Set<String> _downloadedUrls = {};
  Set<String> _localMetadataKeys = {}; // artist:title

  bool _isFluent(material.BuildContext context) {
    if (kIsWeb) return false;
    final platform = material.Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _initDependencies();
    _setupPlaybackListener();
    _setupManagerListener();
  }

  void _setupManagerListener() {
    _managerProgressSubscription =
        _musicManager.progressStream.listen((progressMap) {
      if (mounted) {
        setState(() {
          for (final entry in progressMap.entries) {
            _downloadingProgress[entry.key] = entry.value.progress;
            _downloadingStatus[entry.key] = entry.value.status;
          }
        });
      }
    });
  }

  void _setupPlaybackListener() {
    _playbackSubscription = _playbackService.currentTrackStream.listen((track) {
      if (mounted) {
        setState(() {
          _currentlyPlayingUrl = track?.url;
        });
      }
    });
  }

  Future<void> _initDependencies() async {
    StartupLogger.log('[DiscoveryScreen] Initializing dependencies...');
    try {
      await DependencyManager.instance.ensureDependencies(
        onProgress: (status, progress) {
          setState(() {
            _initStatus = status;
            _initProgress = progress;
          });
        },
      );
      StartupLogger.log(
          '[DiscoveryScreen] Dependencies initialized successfully');
      setState(() => _isInitializing = false);
    } catch (e, stack) {
      StartupLogger.logError('Dependency initialization FAILED', e, stack);
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
    _playbackSubscription?.cancel();
    _managerProgressSubscription?.cancel();
    super.dispose();
  }

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _platformStatuses.clear();
      });
      return;
    }

    final searchId = ++_currentSearchId;
    StartupLogger.log(
        '[DiscoveryScreen] Starting search #$searchId for: "$query"');

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
      final results =
          await _searchService.searchAll(query, onStatusUpdate: (p, s) {
        if (mounted && searchId == _currentSearchId) {
          StartupLogger.log('[DiscoveryScreen] Status update for $p: $s');
          setState(() => _platformStatuses[p] = s);
        }
      });

      if (mounted && searchId == _currentSearchId) {
        StartupLogger.log(
            '[DiscoveryScreen] Search returned ${results.length} results');
        await _refreshDownloadedStatus();

        final filtered = results;

        final Set<String> updatedDownloaded = Set.from(_downloadedUrls);
        for (final res in filtered) {
          final key =
              '${SearchResult.toMatchKey(res.artist)}:${SearchResult.toMatchKey(res.title)}';
          if (_localMetadataKeys.contains(key)) {
            updatedDownloaded.add(res.url);
          }
        }

        setState(() {
          _downloadedUrls = updatedDownloaded;
          _searchResults.addAll(filtered);
        });
      }

      if (mounted && searchId == _currentSearchId && _searchResults.isEmpty) {
        StartupLogger.log(
            '[DiscoveryScreen] No results found for query: "$query"');
        setState(() => _errorMessage =
            'Nenhuma música encontrada nas plataformas selecionadas.');
      }
    } catch (e, stack) {
      StartupLogger.log('[DiscoveryScreen] Error during search: $e\n$stack');
      if (mounted && searchId == _currentSearchId) {
        setState(() => _errorMessage = 'Erro ao buscar: $e');
      }
    } finally {
      if (mounted && searchId == _currentSearchId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> loadFormats(SearchResult result) async {
    StartupLogger.log(
        '[DiscoveryScreen] Loading formats for ${result.id} (${result.platform})');
    if (_formatsCache.containsKey(result.url)) {
      StartupLogger.log(
          '[DiscoveryScreen] Using cached formats for ${result.id}');
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
      StartupLogger.log(
          '[DiscoveryScreen] Retrived ${formats.length} formats for ${result.id}');
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
      StartupLogger.log('[DiscoveryScreen] Error loading formats: $e\n$stack');
      if (mounted) {
        // showSnackBar('Erro ao carregar formatos: $e'); // Removed as per request
        setState(() => _loadingFormatsStatus.remove(result.url));
      }
    }
  }

  Future<void> startDownload(SearchResult result) async {
    final selectedFormat = _selectedFormats[result.url];
    StartupLogger.log(
        '[DiscoveryScreen] Starting download for ${result.id} with format: ${selectedFormat?.formatId}');
    if (selectedFormat == null) {
      return;
    }

    setState(() {
      _downloadingProgress[result.url] = 0;
      _downloadingStatus[result.url] = 'Buscando metadados ideais...';
    });

    try {
      final musicDir = '${Platform.environment['USERPROFILE']}\\Music';
      StartupLogger.log('[DiscoveryScreen] Target directory: $musicDir');

      final path = await _downloadService.download(
        result.url,
        selectedFormat,
        musicDir,
        title: result.title,
        artist: result.artist,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _downloadingProgress[result.url] = progress;
              _downloadingStatus[result.url] = status;
            });
          }
        },
      );

      StartupLogger.log(
          '[DiscoveryScreen] Download COMPLETED for ${result.id} at $path');

      result.localPath = path;
      await DatabaseService.instance.saveTrack(result.toJson());

      await _refreshDownloadedStatus();
      // showSnackBar('Download de "${result.title}" concluído!'); // Removed redundant snackbar
    } catch (e, stack) {
      StartupLogger.log('[DiscoveryScreen] Download FAILED: $e\n$stack');
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
    debugPrint('[DiscoveryScreen] Adding ${result.id} to playlist');
    final db = DatabaseService.instance;
    final playlistsList = await db.getPlaylists();

    if (!mounted) return;

    if (playlistsList.isEmpty) {
      showSnackBar('Crie uma playlist primeiro na aba "Playlists"');
      return;
    }

    final selectedPlaylistId = await showPlaylistDialog(playlistsList);

    if (selectedPlaylistId != null) {
      debugPrint('[DiscoveryScreen] Selected playlist ID: $selectedPlaylistId');
      await db.saveTrack(result.toJson());

      await db.addTrackToPlaylist(selectedPlaylistId, result.id);
      await _refreshDownloadedStatus();
      debugPrint('[DiscoveryScreen] Track added to playlist successfully');
    }
  }

  Future<void> playTrack(SearchResult result) async {
    StartupLogger.log(
        '[DiscoveryScreen] Playing track (Instant): ${result.id}');
    try {
      await _musicManager.playInstant(result);
      StartupLogger.log('[DiscoveryScreen] Playback started for ${result.id}');
    } catch (e, stack) {
      StartupLogger.logError('Playback FAILED in DiscoveryScreen', e, stack);
      if (mounted) {
        showSnackBar('Erro ao reproduzir: $e', isError: true);
      }
    }
  }

  Future<void> instantDownload(SearchResult result) async {
    StartupLogger.log(
        '[DiscoveryScreen] Requesting instant download for: ${result.id}');
    try {
      showSnackBar('Iniciando download de "${result.title}" em background...');
      await _musicManager.downloadTrack(result);
    } catch (e, stack) {
      StartupLogger.logError('Instant download FAILED', e, stack);
      if (mounted) {
        showSnackBar('Erro ao iniciar download: $e', isError: true);
      }
    }
  }

  void openFullPlayer() {
    StartupLogger.log('[DiscoveryScreen] Opening player');
    if (_isFluent(context)) {
      fluent.Navigator.push(
        context,
        fluent.FluentPageRoute(builder: (context) => const PlayerScreen()),
      );
    } else {
      material.Navigator.push(
        context,
        material.MaterialPageRoute(builder: (context) => const PlayerScreen()),
      );
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    if (_isFluent(context)) {
      StartupLogger.log('[DiscoveryScreen][SnackBar/Fluent] $message');
      fluent.displayInfoBar(
        context,
        builder: (context, close) => fluent.InfoBar(
          title: fluent.Text(isError ? 'Erro' : 'Sucesso'),
          content: fluent.Text(message),
          action: fluent.IconButton(
            icon: const fluent.Icon(fluent.FluentIcons.clear),
            onPressed: close,
          ),
          severity: isError
              ? fluent.InfoBarSeverity.error
              : fluent.InfoBarSeverity.success,
        ),
      );
    } else {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(
          content: material.Text(message),
          backgroundColor: isError ? material.Colors.red : null,
        ),
      );
    }
  }

  Future<int?> showPlaylistDialog(List<Map<String, dynamic>> playlistsList) {
    if (_isFluent(context)) {
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
    super.build(context);
    if (_isInitializing) {
      if (_isFluent(context)) {
        return fluent.ScaffoldPage(
          header:
              const fluent.PageHeader(title: fluent.Text('Busca de Músicas')),
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
          appBar:
              material.AppBar(title: const material.Text('Busca de Músicas')),
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

    void handleFormatSelected(SearchResult result, String? val) {
      setState(() {
        _selectedFormats[result.url] =
            _formatsCache[result.url]!.firstWhere((f) => f.formatId == val);
      });
    }

    void handleToggleExpand(SearchResult result) {
      loadFormats(result);
    }

    if (_isFluent(context)) {
      return FluentSearchView(
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
        loadingFormatsStatus: _loadingFormatsStatus,
        downloadedUrls: _downloadedUrls,
        onSearch: () => _onSearch(_searchController.text),
        onPlay: playTrack,
        onAddToPlaylist: addToPlaylist,
        onLoadFormats: loadFormats,
        onDownload: startDownload,
        onInstantDownload: instantDownload,
        onFormatSelected: handleFormatSelected,
        onToggleExpand: handleToggleExpand,
        onOpenFullPlayer: openFullPlayer,
        currentlyPlayingUrl: _currentlyPlayingUrl,
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
      onInstantDownload: instantDownload,
      onFormatSelected: handleFormatSelected,
      onToggleExpand: handleToggleExpand,
      onOpenFullPlayer: openFullPlayer,
      downloadedUrls: _downloadedUrls,
      currentlyPlayingUrl: _currentlyPlayingUrl,
    );
  }

  Future<void> _refreshDownloadedStatus() async {
    try {
      final downloadedData = await DatabaseService.instance.getDownloadedUrls();
      final verifiedUrls = await _verifyFiles(downloadedData);

      final allLocalTracks = await DatabaseService.instance.getAllTracks();
      final metadataKeys = allLocalTracks
          .map((t) =>
              '${SearchResult.toMatchKey(t.artist)}:${SearchResult.toMatchKey(t.title)}')
          .toSet();

      if (mounted) {
        setState(() {
          _downloadedUrls = verifiedUrls;
          _localMetadataKeys = metadataKeys;
        });
      }
    } catch (e) {
      StartupLogger.log(
          '[DiscoveryScreen] Error refreshing downloaded status: $e');
    }
  }

  Future<Set<String>> _verifyFiles(Map<String, String?> data) async {
    final Set<String> verified = {};
    for (final entry in data.entries) {
      if (entry.value != null && await File(entry.value!).exists()) {
        verified.add(entry.key);
      }
    }
    return verified;
  }
}
