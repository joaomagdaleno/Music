import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/login_page.dart';
import 'package:music_tag_editor/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
    AuthService.instance = mockAuth;

    when(() => mockAuth.login(any(), any())).thenAnswer((_) async => true);
    when(() => mockAuth.register(any(), any())).thenAnswer((_) async => true);
  });

  Widget createTestWidget() {
    return const MaterialApp(home: LoginPage());
  }

  group('LoginPage', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has email and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('has login button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('can toggle to register mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.textContaining('Não tem conta?'));
      await tester.pump();

      expect(find.text('Criar Conta'), findsWidgets);
      expect(find.text('Cadastrar'), findsOneWidget);
    });

    testWidgets('calls login on button press', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@test.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Senha'), 'password');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      verify(() => mockAuth.login('test@test.com', 'password')).called(1);
    });
  });
}
