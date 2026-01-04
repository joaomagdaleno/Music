import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final query = 'stay';
  print('Searching for: $query');
  
  final stopwatch = Stopwatch()..start();
  try {
    final searchList = await yt.search.search(query);
    print('Search took: ${stopwatch.elapsedMilliseconds}ms');
    print('Results found: ${searchList.length}');
    
    if (searchList.isNotEmpty) {
      final video = searchList.first;
      print('First result: ${video.title} (${video.id})');
      
      stopwatch.reset();
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      print('Manifest fetch took: ${stopwatch.elapsedMilliseconds}ms');
      
      final audio = manifest.audioOnly.withHighestBitrate();
      print('Audio URL: ${audio.url}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
