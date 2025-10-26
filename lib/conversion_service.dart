import 'dart:io';

class ConversionService {
  Future<void> convertFile({
    required String inputFile,
    required String outputFile,
    required Function(String) onProgress,
  }) async {
    final arguments = [
      '-i', inputFile,
      '-map_metadata', '0', // Preserve metadata
      '-y', // Overwrite output file if it exists
      outputFile,
    ];

    try {
      final process = await Process.start('ffmpeg', arguments);

      process.stderr.listen((data) {
        final output = String.fromCharCodes(data);
        onProgress(output); // Send ffmpeg output to a progress handler
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('FFmpeg process exited with code $exitCode');
      }
    } on ProcessException catch (e) {
      // This error is caught if ffmpeg is not installed or not in PATH
      throw Exception('FFmpeg not found. Please ensure FFmpeg is installed and in your system\'s PATH. Error: $e');
    }
  }
}
