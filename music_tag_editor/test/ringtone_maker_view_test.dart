import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/ringtone_maker_view.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82
]);

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer mockPlayer;

  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  setUp(() {
    mockPlayer = MockAudioPlayer();
    when(() => mockPlayer.setFilePath(any()))
        .thenAnswer((_) async => const Duration(minutes: 3));
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: RingtoneMakerView(
        track: SearchResult(
          id: '1',
          title: 'Test Song',
          artist: 'Test Artist',
          url: 'http://test.mp3',
          platform: MediaPlatform.youtube,
          localPath: 'c:/test.mp3', // specific path to trigger init
        ),
        player: mockPlayer,
        coverImage: MemoryImage(kTransparentImage),
      ),
    );
  }

  group('RingtoneMakerView', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays track title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Song'), findsWidgets);
    });

    testWidgets('has play/pause button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    });

    testWidgets('has app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Criador de Toques'), findsOneWidget);
    });
  });
}
