import 'dart:convert';
import 'dart:io';
import 'main.dart'; // For MusicTrack

class MetadataService {

  Future<Map<String, String>> getMetadata(String filePath) async {
    final arguments = [
      '-v', 'quiet',
      '-print_format', 'json',
      '-show_format',
      filePath,
    ];

    try {
      final result = await Process.run('ffprobe', arguments);
      if (result.exitCode == 0) {
        final jsonOutput = jsonDecode(result.stdout);
        final tags = jsonOutput['format']?['tags'] as Map<String, dynamic>? ?? {};
        // FFprobe returns tags with various capitalizations, so let's normalize them.
        return tags.map((key, value) => MapEntry(key.toLowerCase(), value.toString()));
      } else {
        throw Exception('ffprobe exited with code ${result.exitCode}');
      }
    } on ProcessException catch (e) {
      throw Exception('ffprobe not found. Please ensure FFmpeg is installed and in your system\'s PATH. Error: $e');
    }
  }

  Future<void> writeMetadata(MusicTrack track) async {
    final inputFile = track.filePath;
    // Create a temporary file for the output
    final outputFile = '$inputFile.tmp.mp3';

    final arguments = [
      '-i', inputFile,
      '-c', 'copy', // Copy the audio stream without re-encoding
      '-map_metadata', '0', // Copy existing metadata
      '-metadata', 'title=${track.title}',
      '-metadata', 'artist=${track.artist}',
      '-metadata', 'album=${track.album}',
      // Add other tags as needed, e.g., lyrics
      '-y', // Overwrite temp file if it exists
      outputFile,
    ];

    try {
      final result = await Process.run('ffmpeg', arguments);
      if (result.exitCode == 0) {
        // Replace the original file with the new one
        await File(outputFile).rename(inputFile);
      } else {
        throw Exception('ffmpeg exited with code ${result.exitCode}:\n${result.stderr}');
      }
    } on ProcessException catch (e) {
      throw Exception('ffmpeg not found. Please ensure FFmpeg is installed and in your system\'s PATH. Error: $e');
    }
  }
}
