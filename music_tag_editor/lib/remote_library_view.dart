import 'package:flutter/material.dart';
import 'local_duo_service.dart';
import 'download_service.dart';
import 'playback_service.dart';

class RemoteLibraryView extends StatefulWidget {
  const RemoteLibraryView({super.key});

  @override
  State<RemoteLibraryView> createState() => _RemoteLibraryViewState();
}

class _RemoteLibraryViewState extends State<RemoteLibraryView> {
  final _service = LocalDuoService.instance;
  List<SearchResult> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service.onLibraryReceived = (tracks) {
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    };
    _service.requestRemoteLibrary();
  }

  @override
  void dispose() {
    _service.onLibraryReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca do Amigo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _service.requestRemoteLibrary();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ))
          : _tracks.isEmpty
              ? const Center(
                  child: Text(
                      'Nenhuma música encontrada no dispositivo do seu amigo.'))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: track.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(track.thumbnail!,
                                  width: 40, height: 40, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_to_photos_outlined),
                            onPressed: () {
                              PlaybackService.instance.addToQueue(track);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Adicionado à fila compartilhada')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => PlaybackService.instance
                                .playSearchResult(track),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
