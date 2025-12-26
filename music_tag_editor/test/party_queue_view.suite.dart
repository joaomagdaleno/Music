@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/views/party_queue_view.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(home: PartyQueueView());
  }

  group('PartyQueueView', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Fila de Festa (Party Queue)'), findsOneWidget);
    });

    testWidgets('renders start party UI', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.text('Comece uma Festa'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('amigos escanearem'), findsOneWidget);
    });

    testWidgets('has generate QR button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Gerar QR Code da Festa'), findsOneWidget);
    });

    testWidgets('has scan button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Escanear QR de Amigo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('tapping generate shows QR code', (tester) async {
      await tester.pumpWidget(createTestWidget());
      final button = find.text('Gerar QR Code da Festa');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.textContaining('Código da Sessão'), findsOneWidget);
      expect(find.text('Encerrar Festa'), findsOneWidget);
    });

    testWidgets('tapping end party returns to initial state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      final generateButton = find.text('Gerar QR Code da Festa');
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pump();

      final endButton = find.text('Encerrar Festa');
      await tester.ensureVisible(endButton);
      await tester.tap(endButton);
      await tester.pump();

      expect(find.text('Gerar QR Code da Festa'), findsOneWidget);
    });
  });
}
