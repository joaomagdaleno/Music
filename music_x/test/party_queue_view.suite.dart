@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_hub/features/party_mode/disco/party_queue_screen.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupHttpOverrides();
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PartyQueueScreen(),
      );

  group('PartyQueueScreen', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Party Queue'), findsOneWidget);
    });

    testWidgets('renders start party UI', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
      expect(find.text('Comece uma Festa'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('Escaneie para adicionar músicas!'),
          findsOneWidget);
    });

    testWidgets('has generate QR button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Gerar QR Code'), findsOneWidget);
    });

    testWidgets('has scan button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Escanear Amigo'), findsOneWidget);
    });

    testWidgets('tapping generate shows QR code', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Gerar QR Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sessão:'), findsOneWidget);
      expect(find.text('Encerrar'), findsOneWidget);
    });

    testWidgets('tapping end party returns to initial state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      final generateButton = find.text('Gerar QR Code');
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pump();

      final endButton = find.text('Encerrar');
      await tester.ensureVisible(endButton);
      await tester.tap(endButton);
      await tester.pump();

      expect(find.text('Gerar QR Code'), findsOneWidget);
    });
  });
}
