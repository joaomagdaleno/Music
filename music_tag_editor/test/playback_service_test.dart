import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockAudioHandler extends Mock implements BaseAudioHandler {}

class MockSearchService extends Mock implements SearchService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockThemeService extends Mock implements ThemeService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  group('PlaybackService Tests', () {
    late PlaybackService playbackService;
    late MockAudioPlayer mockPlayer;
    late MockAudioHandler mockHandler;
    late MockDatabaseService mockDb;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      mockHandler = MockAudioHandler();
      mockDb = MockDatabaseService();

      // Initialize the singleton with mock components BEFORE it's ever accessed
      // Since it's now lazy, we can set the instance directly
      PlaybackService.instance = PlaybackService.forTesting(
        player: mockPlayer,
        handler: mockHandler,
      );
      playbackService = PlaybackService.instance;

      DatabaseService.instance = mockDb;
      EqualizerService.instance = MockEqualizerService();
      ThemeService.instance = MockThemeService();
      LyricsService.instance = MockLyricsService();
      LocalDuoService.instance = MockLocalDuoService();

      // Mock streams
      when(() => mockPlayer.currentIndexStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockPlayer.processingStateStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockPlayer.playingStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockPlayer.positionStream)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    });

    test('pause calls player.pause and sends message', () async {
      when(() => mockPlayer.pause()).thenAnswer((_) async {});
      when(() => mockPlayer.position).thenReturn(Duration.zero);
      when(() => LocalDuoService.instance.sendMessage(any())).thenReturn(null);

      await playbackService.pause();

      verify(() => mockPlayer.pause()).called(1);
      verify(() => LocalDuoService.instance.sendMessage(any())).called(1);
    });

    test('resume calls player.play and sends message', () async {
      when(() => mockPlayer.play()).thenAnswer((_) async {});
      when(() => mockPlayer.position).thenReturn(Duration.zero);
      when(() => LocalDuoService.instance.sendMessage(any())).thenReturn(null);

      await playbackService.resume();

      verify(() => mockPlayer.play()).called(1);
      verify(() => LocalDuoService.instance.sendMessage(any())).called(1);
    });

    test('stop calls player.stop', () async {
      when(() => mockPlayer.stop()).thenAnswer((_) async {});
      await playbackService.stop();
      verify(() => mockPlayer.stop()).called(1);
    });

    test('seek calls player.seek and sends message', () async {
      final pos = Duration(seconds: 10);
      when(() => mockPlayer.seek(pos)).thenAnswer((_) async {});
      when(() => LocalDuoService.instance.sendMessage(any())).thenReturn(null);

      await playbackService.seek(pos);

      verify(() => mockPlayer.seek(pos)).called(1);
      verify(() => LocalDuoService.instance.sendMessage(any())).called(1);
    });
  });
}

