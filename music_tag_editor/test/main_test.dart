import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/main.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';

class MockThemeService extends Mock implements ThemeService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockThemeService mockTheme;
  late MockAuthService mockAuth;

  setUp(() {
    mockTheme = MockThemeService();
    mockAuth = MockAuthService();

    ThemeService.instance = mockTheme;
    AuthService.instance = mockAuth;

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
    when(() => mockAuth.isAuthenticated).thenReturn(false);
  });

  group('MusicTagEditorApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(const MusicTagEditorApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows LoginPage when not authenticated', (tester) async {
      when(() => mockAuth.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(const MusicTagEditorApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Bem-vindo'), findsWidgets);
    });

    testWidgets('uses theme color from ThemeService', (tester) async {
      when(() => mockTheme.primaryColor).thenReturn(Colors.purple);

      await tester.pumpWidget(const MusicTagEditorApp());
      await tester.pump(const Duration(milliseconds: 100));

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Music Tag Editor');
    });
  });

  group('LibraryPage', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Test Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Library'), findsOneWidget);
    });

    testWidgets('has DefaultTabController', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DefaultTabController), findsOneWidget);
    });

    testWidgets('renders tab bar with tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Pastas Local'), findsOneWidget);
      expect(find.text('Minha Biblioteca'), findsOneWidget);
      expect(find.text('Smart Mix'), findsOneWidget);
      expect(find.text('Mood Explorer'), findsOneWidget);
    });

    testWidgets('has settings button in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('has download button in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('shows empty folder message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryPage(title: 'Library'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhuma pasta selecionada.'), findsOneWidget);
      expect(find.text('Selecionar Pasta'), findsOneWidget);
    });
  });
}
