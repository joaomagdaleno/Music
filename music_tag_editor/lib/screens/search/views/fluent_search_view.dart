import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/global_navigation_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';

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
  final Set<String> downloadedUrls;

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
    required this.downloadedUrls,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Busca de Músicas'),
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
      ),
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
          if (isLoading) _buildStatusIndicator(context),
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
                final isDownloaded = downloadedUrls.contains(result.url);

                final isVideo = result.mediaType == 'video';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          onPressed: () => onToggleExpand(result),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: result.thumbnail != null
                                ? GestureDetector(
                                    onTap: isVideo
                                      ? () => _playVideo(context, result)
                                      : () => onPlay(result),
                                    child: Image.network(
                                      result.thumbnail!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      cacheWidth: 150, // ⚡ Bolt: Optimize memory
                                      errorBuilder: (_, __, ___) => const Icon(FluentIcons.music_note, size: 24),
                                    ),
                                  )
                                : const Icon(FluentIcons.music_note, size: 32),
                          ),
                          title: Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDownloaded ? Colors.green.lighter : (result.localPath != null ? Colors.blue.lighter : null),
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${result.artist} • ${result.durationFormatted}',
                                style: TextStyle(
                                  color: isDownloaded ? Colors.green.lighter.withValues(alpha: 0.8) : (result.localPath != null ? Colors.blue.lighter.withValues(alpha: 0.8) : null),
                                ),
                              ),
                              if (isDownloaded) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.lighter.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.lighter.withValues(alpha: 0.5)),
                                  ),
                                  child: Text('Baixada', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                              ] else if (result.localPath != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.lighter.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.lighter.withValues(alpha: 0.5)),
                                  ),
                                  child: Text('Na Biblioteca', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPlaybackButtons(context, result),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Mais Opções',
                                child: DropDownButton(
                                  title: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Opções', style: TextStyle(color: FluentTheme.of(context).accentColor)),
                                        const SizedBox(width: 4),
                                        const Icon(FluentIcons.chevron_down, size: 8),
                                      ],
                                    ),
                                  ),
                                  items: [
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.add),
                                      text: const Text('Adicionar à Playlist'),
                                      onPressed: () => onAddToPlaylist(result),
                                    ),
                                    MenuFlyoutItem(
                                      leading: Icon(isDownloaded ? FluentIcons.check_mark : FluentIcons.download),
                                      text: Text(isDownloaded ? 'Música Baixada' : 'Opções de Download'),
                                      onPressed: isDownloaded ? null : () => onLoadFormats(result),
                                    ),
                                    if (result.localPath != null)
                                      MenuFlyoutItem(
                                        leading: const Icon(FluentIcons.library),
                                        text: const Text('Ver na Biblioteca'),
                                        onPressed: () {
                                          GlobalNavigationService.instance.navigateToPersonaTab(AppPersona.librarian, 1);
                                        },
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
                                            value: (downloadingProgress[result.url] ?? 0) * 100,
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
    );
  }

  Widget _buildPlatformSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _platformButton(context, MediaPlatform.youtube, 'Vídeos (YouTube)', FluentIcons.video),
        const SizedBox(width: 12),
        _platformButton(context, MediaPlatform.youtubeMusic, 'Músicas (YT Music)', FluentIcons.music_in_collection),
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
    final isVideo = result.mediaType == 'video';
    
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

  void _playVideo(BuildContext context, SearchResult result) async {
    // Play the track using PlaybackService
    await PlaybackService.instance.playSearchResult(result);
    
    // Navigate to the native PlayerScreen ONLY if it's a video
    if (context.mounted && result.mediaType == 'video') {
      Navigator.of(context).push(
        FluentPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 300,
              child: ProgressBar(),
            ),
            const SizedBox(height: 12),
            Text(
              'Buscando nas plataformas...',
              style: TextStyle(
                color: FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInfo() {
    // Simplified: No longer needing complex cross-platform fallback messages.
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
      case MediaPlatform.local:
        return const Icon(FluentIcons.folder_list, size: 20);
      case MediaPlatform.unknown:
        return const Icon(FluentIcons.unknown, color: Colors.grey);
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
