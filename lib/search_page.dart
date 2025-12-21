import 'package:flutter/material.dart';
import 'search_service.dart';
import 'download_service.dart';
import 'database_service.dart';
import 'dependency_manager.dart';
import 'playback_service.dart';
import 'mini_player.dart';
import 'player_screen.dart';
import 'dart:io';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _searchService = SearchService();
  final _downloadService = DownloadService();
  final _playbackService = PlaybackService.instance;

  List<SearchResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<MediaPlatform, SearchStatus> _platformStatuses = {};

  Map<String, List<DownloadFormat>> _formatsCache = {};
  Map<String, DownloadFormat?> _selectedFormats = {};
  Map<String, bool> _isExpanding = {};
  Map<String, double> _downloadingProgress = {};
  Map<String, String> _downloadingStatus = {};
  bool _isInitializing = true;
  String _initStatus = 'Iniciando ferramentas...';
  double _initProgress = 0;

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
      setState(() {
        _errorMessage = 'Erro ao inicializar: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

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
          setState(() {
            _platformStatuses[platform] = status;
          });
        },
      );
      setState(() {
        _results = results;
      });

      if (results.isEmpty) {
        setState(() => _errorMessage =
            'Nenhuma música encontrada nas plataformas selecionadas.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao buscar: $e');
    } finally {
      setState(() => _isLoading = false);
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
      setState(() {
        _formatsCache[result.url] = formats;
        if (formats.isNotEmpty) {
          _selectedFormats[result.url] = formats.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar formatos: $e')),
        );
      }
    }
  }

  Future<void> _startDownload(SearchResult result) async {
    final selectedFormat = _selectedFormats[result.url];
    if (selectedFormat == null) return;

    setState(() {
      _downloadingProgress[result.url] = 0;
      _downloadingStatus[result.url] = 'Iniciando...';
    });

    try {
      // Use user's Music folder
      final musicDir = '${Platform.environment['USERPROFILE']}\\Music';

      await _downloadService.download(
        result.url,
        selectedFormat,
        musicDir,
        onProgress: (progress, status) {
          setState(() {
            _downloadingProgress[result.url] = progress;
            _downloadingStatus[result.url] = status;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download de "${result.title}" concluído!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no download: $e')),
      );
    } finally {
      setState(() {
        _downloadingProgress.remove(result.url);
        _downloadingStatus.remove(result.url);
      });
    }
  }

  Future<void> _addToPlaylist(SearchResult result) async {
    final db = DatabaseService();
    final playlistsList = await db.getPlaylists();

    if (!mounted) return;

    if (playlistsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Crie uma playlist primeiro na aba "Playlists"')),
      );
      return;
    }

    final selectedPlaylistId = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar à Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistsList.length,
            itemBuilder: (context, index) {
              final p = playlistsList[index];
              return ListTile(
                title: Text(p['name']),
                onTap: () => Navigator.pop(context, p['id']),
              );
            },
          ),
        ),
      ),
    );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.title}" adicionada à playlist!')),
        );
      }
    }
  }

  Future<void> _playTrack(SearchResult result) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Carregando áudio de "${result.title}"...')),
        );
      }
      await _playbackService.playSearchResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reproduzir: $e')),
        );
      }
    }
  }

  void _openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerScreen()),
    );
  }

  Widget _getPlatformLogo(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.youtube:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/e/ef/Youtube_logo.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.play_circle, color: Colors.red),
        );
      case MediaPlatform.youtubeMusic:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/1024px-Youtube_Music_icon.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, color: Colors.red),
        );
      case MediaPlatform.spotify:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/1024px-Spotify_logo_without_text.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, color: Colors.green),
        );
      case MediaPlatform.unknown:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Busca de Músicas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_initStatus),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _initProgress),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca de Músicas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Digite o nome da música ou artista...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _performSearch,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_isLoading || _platformStatuses.isNotEmpty)
            _buildStatusIndicator(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            ),
          _buildFallbackInfo(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final isExpanded = _isExpanding[result.url] ?? false;
                final isDownloading =
                    _downloadingProgress.containsKey(result.url);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: result.thumbnail != null
                            ? Image.network(result.thumbnail!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.music_note))
                            : const Icon(Icons.music_note),
                        title: Text(result.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${result.artist} • ${result.durationFormatted}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow,
                                  color: Colors.blue),
                              onPressed: () => _playTrack(result),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'playlist') _addToPlaylist(result);
                                if (val == 'download') _loadFormats(result);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'playlist',
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_add),
                                    title: Text('Adicionar à Playlist'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'download',
                                  child: ListTile(
                                    leading: Icon(Icons.download),
                                    title: Text('Opções de Download'),
                                  ),
                                ),
                              ],
                            ),
                            _getPlatformLogo(result.platform),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(),
                              if (!_formatsCache.containsKey(result.url))
                                const Center(child: CircularProgressIndicator())
                              else ...[
                                Row(
                                  children: [
                                    const Text('Formato: '),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _selectedFormats[result.url]
                                            ?.formatId,
                                        items:
                                            _formatsCache[result.url]!.map((f) {
                                          return DropdownMenuItem<String>(
                                            value: f.formatId,
                                            child: Text(f.displayName),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedFormats[result.url] =
                                                _formatsCache[result.url]!
                                                    .firstWhere((f) =>
                                                        f.formatId == val);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (isDownloading)
                                  Column(
                                    children: [
                                      LinearProgressIndicator(
                                          value:
                                              _downloadingProgress[result.url]),
                                      const SizedBox(height: 4),
                                      Text(
                                          _downloadingStatus[result.url] ?? ''),
                                    ],
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: () => _startDownload(result),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Download'),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: InkWell(
        onTap: _openFullPlayer,
        child: const MiniPlayer(),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _platformStatusChip(MediaPlatform.youtube, 'YouTube'),
          _platformStatusChip(MediaPlatform.youtubeMusic, 'YT Music'),
          _platformStatusChip(MediaPlatform.spotify, 'Spotify'),
        ],
      ),
    );
  }

  Widget _platformStatusChip(MediaPlatform platform, String label) {
    final status = _platformStatuses[platform];
    if (status == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    bool spin = false;

    switch (status) {
      case SearchStatus.searching:
        icon = Icons.sync;
        color = Colors.blue;
        spin = true;
        break;
      case SearchStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SearchStatus.noResults:
        icon = Icons.info_outline;
        color = Colors.orange;
        break;
      case SearchStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spin)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInfo() {
    final spotifyStatus = _platformStatuses[MediaPlatform.spotify];
    final youtubeStatus = _platformStatuses[MediaPlatform.youtube];

    if (spotifyStatus == SearchStatus.noResults &&
        (youtubeStatus == SearchStatus.completed ||
            youtubeStatus == SearchStatus.searching)) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nenhuma correspondência exata no Spotify. Mostrando resultados similares do YouTube.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
