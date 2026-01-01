import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/widgets/mini_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class FluentSearchView extends StatelessWidget {
  final TextEditingController searchController;
  final bool isLoading;
  final String? errorMessage;
  final List<SearchResult> results;
  final Map<MediaPlatform, SearchStatus> platformStatuses;
  // Platform Selection
  final MediaPlatform? selectedPlatform;
  final Map<String, bool> isExpanding;
  final Map<String, List<DownloadFormat>> formatsCache;
  final Map<String, DownloadFormat?> selectedFormats;
  final Map<String, double> downloadingProgress;
  final Map<String, String> downloadingStatus;
  final Map<String, String> loadingFormatsStatus;

  // Callbacks
  final VoidCallback onSearch;
  final Function(SearchResult) onPlay;
  final Function(SearchResult) onAddToPlaylist;
  final Function(SearchResult) onLoadFormats;
  final Function(SearchResult) onDownload;
  final Function(SearchResult, String?) onFormatSelected;
  final Function(SearchResult) onToggleExpand;
  final VoidCallback onOpenFullPlayer;
  final Function(MediaPlatform?) onPlatformChanged;

  const FluentSearchView({
    super.key,
    required this.searchController,
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.platformStatuses,
    required this.selectedPlatform,
    required this.isExpanding,
    required this.formatsCache,
    required this.selectedFormats,
    required this.downloadingProgress,
    required this.downloadingStatus,
    required this.loadingFormatsStatus,
    required this.onSearch,
    required this.onPlay,
    required this.onAddToPlaylist,
    required this.onLoadFormats,
    required this.onDownload,
    required this.onFormatSelected,
    required this.onToggleExpand,
    required this.onOpenFullPlayer,
    required this.onPlatformChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Busca de Músicas')),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: searchController,
                        placeholder: 'Digite o nome da música ou artista...',
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
                const SizedBox(height: 12),
                _buildPlatformSelector(context),
              ],
            ),
          ),
          if (isLoading || platformStatuses.isNotEmpty) _buildStatusIndicator(),
          if (errorMessage != null && errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InfoBar(
                title: const Text('Erro'),
                content: Text(errorMessage!),
                severity: InfoBarSeverity.error,
              ),
            ),
          _buildFallbackInfo(),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final isExpanded = isExpanding[result.url] ?? false;
                final isDownloading = downloadingProgress.containsKey(result.url);

                final isVideo = result.platform == MediaPlatform.youtube;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: result.thumbnail != null
                                ? GestureDetector(
                                    onTap: isVideo 
                                      ? () => _playVideo(context, result)
                                      : () => onPlay(result),
                                    child: Image.network(result.thumbnail!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(FluentIcons.music_note)),
                                  )
                                : const Icon(FluentIcons.music_note, size: 32),
                          ),
                          title: Text(result.title, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${result.artist} • ${result.durationFormatted}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPlaybackButtons(context, result),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Mais Opções',
                                child: DropDownButton(
                                  title: const Icon(FluentIcons.more, size: 16),
                                  items: [
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.add),
                                      text: const Text('Adicionar à Playlist'),
                                      onPressed: () => onAddToPlaylist(result),
                                    ),
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.download),
                                      text: const Text('Opções de Download'),
                                      onPressed: () => onLoadFormats(result),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _getPlatformLogo(result.platform, hifiSource: result.hifiSource),
                            ],
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Divider(),
                                  const SizedBox(height: 12),
                                  if (loadingFormatsStatus.containsKey(result.url))
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const ProgressRing(strokeWidth: 2),
                                          const SizedBox(width: 12),
                                          Text(loadingFormatsStatus[result.url]!),
                                        ],
                                      ),
                                    )
                                  else if (!formatsCache.containsKey(result.url))
                                    const Center(child: ProgressRing())
                                  else ...[
                                  Row(
                                    children: [
                                      const Text('Formato: '),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ComboBox<String>(
                                          isExpanded: true,
                                          value: selectedFormats[result.url]?.formatId,
                                          items: formatsCache[result.url]!.map((f) {
                                            return ComboBoxItem<String>(
                                              value: f.formatId,
                                              child: Text(f.displayName),
                                            );
                                          }).toList(),
                                          onChanged: (val) => onFormatSelected(result, val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (isDownloading)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ProgressBar(
                                            value: downloadingProgress[result.url]! * 100,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            downloadingStatus[result.url] ?? 'Baixando...',
                                            style: TextStyle(
                                              color: Colors.blue.lighter,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Button(
                                      onPressed: () => onDownload(result),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(FluentIcons.download),
                                          SizedBox(width: 8),
                                          Text('Download'),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: GestureDetector(
        onTap: onOpenFullPlayer,
        child: const MiniPlayer(),
      ),
    );
  }

  Widget _buildPlatformSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _platformButton(context, null, 'Geral', FluentIcons.all_apps),
        const SizedBox(width: 8),
        _platformButton(context, MediaPlatform.spotify, 'Spotify', FluentIcons.music_note),
        const SizedBox(width: 8),
        _platformButton(context, MediaPlatform.youtube, 'YouTube', FluentIcons.video),
        const SizedBox(width: 8),
        _platformButton(context, MediaPlatform.youtubeMusic, 'YT Music', FluentIcons.music_in_collection),
      ],
    );
  }

  Widget _platformButton(BuildContext context, MediaPlatform? platform, String label, IconData icon) {
    final isSelected = selectedPlatform == platform;
    return Button(
      style: ButtonStyle(
        backgroundColor: isSelected ? WidgetStateProperty.all(FluentTheme.of(context).accentColor.withValues(alpha: 0.2)) : null,
      ),
      onPressed: () => onPlatformChanged(platform),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? FluentTheme.of(context).accentColor : null),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isSelected ? FluentTheme.of(context).accentColor : null)),
        ],
      ),
    );
  }

  Widget _buildPlaybackButtons(BuildContext context, SearchResult result) {
    final isVideo = result.platform == MediaPlatform.youtube;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVideo)
          IconButton(
            icon: const Icon(FluentIcons.video, size: 20),
            onPressed: () => _playVideo(context, result),
          ),
        IconButton(
          icon: Icon(isVideo ? FluentIcons.headset : FluentIcons.play, size: 20),
          onPressed: () => onPlay(result),
        ),
      ],
    );
  }

  void _playVideo(BuildContext context, SearchResult result) {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: result.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(result.title),
        constraints: const BoxConstraints(maxWidth: 800),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YoutubePlayer(
              controller: controller,
              aspectRatio: 16 / 9,
            ),
            const SizedBox(height: 12),
            Text('Artista: ${result.artist}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final status = platformStatuses[platform];
    if (status == null) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    bool spin = false;

    // Mapping colors roughly to Fluent standard or standard library colors
    switch (status) {
      case SearchStatus.searching:
        icon = FluentIcons.sync;
        color = Colors.blue;
        spin = true;
        break;
      case SearchStatus.completed:
        icon = FluentIcons.check_mark;
        color = Colors.green;
        break;
      case SearchStatus.noResults:
        icon = FluentIcons.info;
        color = Colors.orange;
        break;
      case SearchStatus.failed:
        icon = FluentIcons.error;
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
            child: ProgressRing(strokeWidth: 2),
          )
        else
          Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInfo() {
    final spotifyStatus = platformStatuses[MediaPlatform.spotify];
    final youtubeStatus = platformStatuses[MediaPlatform.youtube];

    if (spotifyStatus == SearchStatus.noResults &&
        (youtubeStatus == SearchStatus.completed || youtubeStatus == SearchStatus.searching)) {
      return InfoBar(
         title: const Text('Info'),
         content: const Text('Nenhuma correspondência exata no Spotify. Mostrando resultados similares do YouTube.'),
         severity: InfoBarSeverity.info,
         isLong: true,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _getPlatformLogo(MediaPlatform platform, {String? hifiSource}) {
    switch (platform) {
      case MediaPlatform.youtube:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/e/ef/Youtube_logo.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Icon(FluentIcons.play, color: Colors.red),
        );
      case MediaPlatform.youtubeMusic:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/1024px-Youtube_Music_icon.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Icon(FluentIcons.music_note, color: Colors.red),
        );
      case MediaPlatform.spotify:
        return Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/1024px-Spotify_logo_without_text.svg.png',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => Icon(FluentIcons.music_note, color: Colors.green),
        );
      case MediaPlatform.hifi:
        return _getHiFiLogo(hifiSource);
      case MediaPlatform.unknown:
        return Icon(FluentIcons.unknown, color: Colors.grey);
    }
  }

  Widget _getHiFiLogo(String? source) {
    // Reusing the same logic as Material but wrapped in Fluent-safe containers if needed.
    // Basic Images work fine.
    switch (source) {
      case 'qobuz':
        return Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Qobuz_Logo.svg/512px-Qobuz_Logo.svg.png',
             width: 24, height: 24, errorBuilder: (_,__,___) => const Text('Q'));
      case 'tidal':
        return Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Tidal_logo.svg/512px-Tidal_logo.svg.png',
             width: 24, height: 24, errorBuilder: (_,__,___) => const Text('T'));
      case 'deezer':
         return Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Deezer_Logo.svg/512px-Deezer_Logo.svg.png',
             width: 24, height: 24, errorBuilder: (_,__,___) => const Text('D'));
      default:
        return Icon(FluentIcons.diamond, color: Colors.purple);
    }
  }
}
