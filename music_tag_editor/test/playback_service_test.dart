import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockThemeService extends Mock implements ThemeService {}

class MockSearchService extends Mock implements SearchService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockAudioHandler extends Mock implements AudioHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDatabaseService mockDb;
  late MockLocalDuoService mockDuo;
  late MockEqualizerService mockEqualizer;
  late MockThemeService mockTheme;
  late MockSearchService mockSearch;
  late MockLyricsService mockLyrics;
  late MockAudioPlayer mockPlayer;
  late MockAudioHandler mockHandler;
  late PlaybackService service;

  setUp(() {
    mockDb = MockDatabaseService();
    mockDuo = MockLocalDuoService();
    mockEqualizer = MockEqualizerService();
    mockTheme = MockThemeService();
    mockSearch = MockSearchService();
    mockLyrics = MockLyricsService();
    mockPlayer = MockAudioPlayer();
    mockHandler = MockAudioHandler();

    DatabaseService.instance = mockDb;
    LocalDuoService.instance = mockDuo;
    EqualizerService.instance = mockEqualizer;
    ThemeService.instance = mockTheme;
    SearchService.instance = mockSearch;
    LyricsService.instance = mockLyrics;

    // Stub necessary methods for initialization
    when(() => mockEqualizer.equalizer).thenReturn(FakeAndroidEqualizer());
    when(() => mockDuo.role).thenReturn(DuoRole.none);

    service = PlaybackService.forTesting(
      player: mockPlayer,
      handler: mockHandler,
    );
    PlaybackService.instance = service;
  });

  group('PlaybackService', () {
    test('instance is accessible', () {
      expect(PlaybackService.instance, isNotNull);
    });

    test('queue is a list', () {
      expect(PlaybackService.instance.queue, isA<List<SearchResult>>());
    });

    test('currentTrack is nullable SearchResult', () {
      final track = PlaybackService.instance.currentTrack;
      if (track != null) {
        expect(track, isA<SearchResult>());
      } else {
        expect(track, isNull);
      }
    });

    test('sleepTimerStream is a stream', () {
      expect(
          PlaybackService.instance.sleepTimerStream, isA<Stream<Duration?>>());
    });

    test('lyricsStream is a stream', () {
      expect(PlaybackService.instance.lyricsStream, isA<Stream>());
    });

    test('addToQueue does not throw', () {
      final track = SearchResult(
        id: 'test',
        title: 'Test',
        artist: 'Test Artist',
        url: 'http://test',
        platform: MediaPlatform.youtube,
      );

      expect(() => PlaybackService.instance.addToQueue(track), returnsNormally);
    });
  });
}

class FakeAndroidEqualizer extends Fake implements AndroidEqualizer {}
