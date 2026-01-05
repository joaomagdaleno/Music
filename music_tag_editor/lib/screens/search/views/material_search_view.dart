import 'package:flutter/material.dart';
import 'package:music_tag_editor/models/download_models.dart';
import 'package:music_tag_editor/services/global_navigation_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/models/search_models.dart';

class MaterialSearchView extends StatelessWidget {
  final TextEditingController searchController;
  final bool isLoading;
  final String? errorMessage;
  final List<SearchResult> results;
  final Map<MediaPlatform, SearchStatus> platformStatuses;
  final Map<String, bool> isExpanding;
  final Map<String, List<DownloadFormat>> formatsCache;
  final Map<String, DownloadFormat?> selectedFormats;
  final Map<String, double> downloadingProgress;
  final Map<String, String> downloadingStatus;
  final Set<String> downloadedUrls;
  final String? currentlyPlayingUrl;

  // Callbacks
  final VoidCallback onSearch;
  final Function(SearchResult) onPlay;
  final Function(SearchResult) onAddToPlaylist;
  final Function(SearchResult) onLoadFormats;
  final Function(SearchResult) onDownload;
  final Function(SearchResult, String?) onFormatSelected;
  final Function(SearchResult) onToggleExpand;
  final VoidCallback onOpenFullPlayer;

  const MaterialSearchView({
    super.key,
    required this.searchController,
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.platformStatuses,
    required this.isExpanding,
    required this.formatsCache,
    required this.selectedFormats,
    required this.downloadingProgress,
    required this.downloadingStatus,
    required this.onSearch,
    required this.onPlay,
    required this.onAddToPlaylist,
    required this.onLoadFormats,
    required this.onDownload,
    required this.onFormatSelected,
    required this.onToggleExpand,
    required this.onOpenFullPlayer,
    required this.downloadedUrls,
    this.currentlyPlayingUrl,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
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
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Digite o nome da música ou artista...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => onSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isLoading ? null : onSearch,
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),
            if (isLoading) _buildStatusIndicator(context),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            _buildFallbackInfo(),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  final isExpanded = isExpanding[result.url] ?? false;
                  final isDownloading =
                      downloadingProgress.containsKey(result.url);

                  final isPlaying = result.url == currentlyPlayingUrl;

                  return Card(
                    color: isPlaying
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.7)
                        : null,
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
                                  cacheWidth: 150, // ⚡ Bolt: Optimize memory
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.music_note))
                              : const Icon(Icons.music_note),
                          title: Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: downloadedUrls.contains(result.url)
                                  ? Colors.green
                                  : (result.localPath != null
                                      ? Colors.blue
                                      : null),
                              fontWeight:
                                  (downloadedUrls.contains(result.url) ||
                                          result.localPath != null)
                                      ? FontWeight.bold
                                      : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${result.artist} • ${result.durationFormatted}',
                                style: TextStyle(
                                  color: downloadedUrls.contains(result.url)
                                      ? Colors.green.withValues(alpha: 0.7)
                                      : (result.localPath != null
                                          ? Colors.blue.withValues(alpha: 0.7)
                                          : null),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (downloadedUrls.contains(result.url))
                                    _buildBadge('Baixada', Colors.green),
                                  if (result.localPath != null &&
                                      !downloadedUrls.contains(result.url))
                                    _buildBadge('Na Biblioteca', Colors.blue),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.blue),
                                onPressed: () => onPlay(result),
                              ),
                              _buildOptionsButton(context, result),
                              _getPlatformLogo(result.platform,
                                  hifiSource: result.hifiSource),
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
                                if (!formatsCache.containsKey(result.url))
                                  const Center(
                                      child: CircularProgressIndicator())
                                else ...[
                                  Row(
                                    children: [
                                      const Text('Formato: '),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: selectedFormats[result.url]
                                              ?.formatId,
                                          items: formatsCache[result.url]!
                                              .map((f) =>
                                                  DropdownMenuItem<String>(
                                                    value: f.formatId,
                                                    child: Text(f.displayName),
                                                  ))
                                              .toList(),
                                          onChanged: (val) =>
                                              onFormatSelected(result, val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (isDownloading)
                                    Column(
                                      children: [
                                        LinearProgressIndicator(
                                            value: downloadingProgress[
                                                result.url]),
                                        const SizedBox(height: 4),
                                        Text(downloadingStatus[result.url] ??
                                            ''),
                                      ],
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: () => onDownload(result),
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
      );

  Widget _buildStatusIndicator(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _platformStatusChip(MediaPlatform.youtube, 'Busca'),
          ],
        ),
      );

  Widget _platformStatusChip(MediaPlatform platform, String label) {
    final status = platformStatuses[platform];
    if (status == null) {
      return const SizedBox.shrink();
    }

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
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInfo() => const SizedBox.shrink();

  Widget _getPlatformLogo(MediaPlatform platform, {String? hifiSource}) {
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
      case MediaPlatform.hifi:
        return _getHiFiLogo(hifiSource);
      case MediaPlatform.local:
        return const Icon(Icons.folder, color: Colors.brown);
      case MediaPlatform.unknown:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  Widget _getHiFiLogo(String? source) {
    switch (source) {
      case 'qobuz':
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Qobuz_Logo.svg/512px-Qobuz_Logo.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Color(0xFF1A237E), shape: BoxShape.circle),
            child: const Center(
              child: Text('Q',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      case 'tidal':
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Tidal_logo.svg/512px-Tidal_logo.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Colors.black, shape: BoxShape.circle),
            child: const Center(
              child: Text('T',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      case 'deezer':
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Deezer_Logo.svg/512px-Deezer_Logo.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Color(0xFFFF0092), shape: BoxShape.circle),
            child: const Center(
              child: Text('D',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      default:
        return const Icon(Icons.high_quality, color: Colors.purple);
    }
  }

  Widget _buildBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildOptionsButton(BuildContext context, SearchResult result) {
    final isDownloaded = downloadedUrls.contains(result.url);

    return PopupMenuButton<String>(
      tooltip: 'Mais Opções',
      onSelected: (val) {
        if (val == 'playlist') {
          onAddToPlaylist(result);
        }
        if (val == 'download') {
          onLoadFormats(result);
        }
      },
      child: OutlinedButton.icon(
        onPressed: null, // PopupMenuButton handles the tap
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        label: const Text('Opções'),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'playlist',
          child: ListTile(
            leading: Icon(Icons.playlist_add),
            title: Text('Adicionar à Playlist'),
          ),
        ),
        PopupMenuItem(
          value: 'download',
          enabled: !isDownloaded,
          child: ListTile(
            leading: Icon(isDownloaded ? Icons.check_circle : Icons.download),
            title: Text(isDownloaded ? 'Música Baixada' : 'Opções de Download'),
          ),
        ),
        if (result.localPath != null)
          PopupMenuItem(
            value: 'library',
            onTap: () {
              GlobalNavigationService.instance
                  .navigateToPersonaTab(AppPersona.librarian, 1);
            },
            child: const ListTile(
              leading: Icon(Icons.library_music),
              title: Text('Ver na Biblioteca'),
            ),
          ),
      ],
    );
  }
}
