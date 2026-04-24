import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/views/playlist_importer_view.dart';
import 'package:music_tag_editor/src/rust/api/spectral.dart' as rust_spectral;
import 'package:music_tag_editor/widgets/spectrogram_painter.dart';

class MyTracksView extends StatefulWidget {
  const MyTracksView({super.key});

  @override
  State<MyTracksView> createState() => _MyTracksViewState();
}

class _MyTracksViewState extends State<MyTracksView> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await _dbService.getTracks();
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Músicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Importar Playlist',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PlaylistImporterView()),
              );
              _loadTracks(); // Refresh after import
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(
                  child: Text(
                      'Nenhuma música salva ainda. Comece buscando e adicionando à sua biblioteca!'))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: track['thumbnail'] != null
                          ? Image.network(track['thumbnail'],
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.music_note))
                          : const Icon(Icons.music_note),
                      title: Text(track['title']),
                      subtitle: Text(track['artist'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.analytics_outlined),
                        onPressed: () => _showTechnicalAnalysis(context, track),
                      ),
                    );
                  },
                ),
    );
  }

  void _showTechnicalAnalysis(BuildContext context, Map<String, dynamic> track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _TechnicalAnalysisView(track: track);
      },
    );
  }
}

class _TechnicalAnalysisView extends StatefulWidget {
  final Map<String, dynamic> track;
  const _TechnicalAnalysisView({required this.track});

  @override
  State<_TechnicalAnalysisView> createState() => _TechnicalAnalysisViewState();
}

class _TechnicalAnalysisViewState extends State<_TechnicalAnalysisView> {
  rust_spectral.SpectralAnalysisResult? _analysis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final localPath = widget.track['localPath'];
    if (localPath == null || localPath.isEmpty) {
      setState(() {
        _error = "Arquivo local não encontrado. A música não foi baixada.";
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await rust_spectral.analyzeSpectralQuality(path: localPath);
      setState(() {
        _analysis = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao analisar áudio: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Análise Técnica: ${widget.track['title']}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent))
          else if (_analysis != null) ...[
            Text(
              _analysis!.qualityStatus,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _analysis!.isFakeHighRes ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text("Espectrograma de Frequências:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            SpectrogramView(
              magnitudes: _analysis!.frequencyMagnitudes,
              color: _analysis!.isFakeHighRes ? Colors.orangeAccent : Colors.cyanAccent,
              height: 120,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Baixas Freq.", style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text("Altas Freq.", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
