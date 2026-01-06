import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/utils/file_utils.dart';

void main() {
  group('sanitizeFilename', () {
    test('should replace colons with underscores', () {
      expect(sanitizeFilename('01: Intro.flac'), '01_ Intro.flac');
    });

    test('should replace forward and backward slashes', () {
      expect(sanitizeFilename('AC/DC.flac'), 'AC_DC.flac');
      expect(sanitizeFilename(r'Metal\Rock.mp3'), 'Metal_Rock.mp3');
    });

    test('should replace angle brackets', () {
      expect(sanitizeFilename('<Music>.mp3'), '_Music_.mp3');
    });

    test('should replace other reserved characters (*, ?, ", |)', () {
      expect(sanitizeFilename('what?.mp3'), 'what_.mp3');
      expect(sanitizeFilename('star*.flac'), 'star_.flac');
      expect(sanitizeFilename('"quotes".mp3'), '_quotes_.mp3');
      expect(sanitizeFilename('pipe|symbol.mp3'), 'pipe_symbol.mp3');
    });

    test('should handle nested paths by flattening them', () {
      expect(sanitizeFilename('path/to/my:song.mp3'), 'path_to_my_song.mp3');
    });

    test('should return same string if no illegal characters', () {
      expect(sanitizeFilename('perfect_filename.mp3'), 'perfect_filename.mp3');
    });
  });
}
