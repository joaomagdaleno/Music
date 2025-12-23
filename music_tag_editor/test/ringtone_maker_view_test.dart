import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/views/ringtone_maker_view.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

final List<int> _transparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late MockAudioPlayer mockPlayer;
  late SearchResult mockTrack;
  late MemoryImage mockImage;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    mockTrack = SearchResult(
      id: 'test_id',
      title: 'Test Song',
      artist: 'Test Artist',
      url: 'http://test',
      platform: MediaPlatform.youtube,
      localPath: '/path/to/song.mp3',
    );
    mockImage = MemoryImage(Uint8List.fromList(_transparentImage));

    when(() => mockPlayer.setFilePath(any()))
        .thenAnswer((_) async => const Duration(seconds: 120));
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
  });

  testWidgets('RingtoneMakerView displays track info and handles export',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RingtoneMakerView(
                      track: mockTrack,
                      player: mockPlayer,
                      coverImage: mockImage,
                    ),
                  )),
              child: const Text('Go'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      final exportBtn = find.text('Exportar Toque');
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pump(); // Show loading dialog

      // Delay in _saveRingtone simulation
      await Future.delayed(const Duration(seconds: 3));
      await tester.pump(); // Finished future
      await tester.pumpAndSettle(); // Navigate back, show snackbar

      expect(find.textContaining('salvo com sucesso!'), findsOneWidget);
    });
  });
}
