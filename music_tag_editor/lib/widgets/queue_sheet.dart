import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/playback_service.dart';
// import 'package:music_tag_editor/services/search_service.dart'; // For SearchResult if needed

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = PlaybackService.instance.queue;
    
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Fila de Reprodução', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: queue.isEmpty
                ? const Center(child: Text('A fila está vazia.'))
                : ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      // Highlight current track if needed
                      final isCurrent = PlaybackService.instance.currentTrack == track;
                      
                      return ListTile(
                        leading: track.thumbnail != null 
                             ? Image.network(track.thumbnail!, width: 40, height: 40, fit: BoxFit.cover)
                             : const Icon(Icons.music_note),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                        trailing: isCurrent ? const Icon(Icons.equalizer, color: Colors.blue) : null,
                        tileColor: isCurrent ? Colors.blue.withValues(alpha: 0.1) : null,
                        onTap: () {
                          PlaybackService.instance.playSearchResult(track);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
