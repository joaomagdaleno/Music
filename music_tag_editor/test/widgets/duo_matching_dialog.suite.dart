@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/widgets/duo_matching_dialog.dart';

class FakeLocalDuoService extends Fake implements LocalDuoService {
  @override
  Function(String)? onDeviceFound;
  @override
  Function(String)? onConnected;
  @override
  Function()? onDisconnected;
  @override
  DuoRole role = DuoRole.none;
  @override
  final Set<String> connectedEndpoints = {};

  // Methods to simulate internal state
  void emitDeviceFound(String name) {
    onDeviceFound?.call(name);
  }

  void emitConnected(String id) {
    connectedEndpoints.add(id);
    onConnected?.call(id);
  }

  void emitDisconnected(String id) {
    connectedEndpoints.remove(id);
    onDisconnected?.call();
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> startHost(String username) async {
    role = DuoRole.host;
  }

  @override
  Future<void> startDiscovery(String username) async {
    role = DuoRole.guest;
  }

  @override
  void stopAll() {
    role = DuoRole.none;
    connectedEndpoints.clear();
  }

  @override
  String? getDiscoveredName(String id) => "Guest $id";
}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late FakeLocalDuoService fakeLocalDuoService;
  late MockDatabaseService mockDatabaseService;
  late MockPlaybackService mockPlaybackService;

  setUp(() {
    fakeLocalDuoService = FakeLocalDuoService();
    mockDatabaseService = MockDatabaseService();
    mockPlaybackService = MockPlaybackService();

    LocalDuoService.instance = fakeLocalDuoService;
    DatabaseService.instance = mockDatabaseService;
    PlaybackService.instance = mockPlaybackService;

    // stub db calls
    when(() => mockDatabaseService.getGuestHistory())
        .thenAnswer((_) async => []);
    when(() => mockDatabaseService.saveGuest(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockDatabaseService.getDuoSessionTracks(any()))
        .thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        body: DuoMatchingDialog(),
      ),
    );
  }

  testWidgets('DuoMatchingDialog displays initial state correctly',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100)); // load history

    expect(find.text('Modo Duo (Sincronizar)'), findsOneWidget);
    expect(find.text('Hospedar Sessão'), findsOneWidget);
    expect(find.text('Entrar na Sessão'), findsOneWidget);
  });

  testWidgets('Start Host button updates state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Hospedar Sessão'));
    await tester.pump();

    expect(fakeLocalDuoService.role, DuoRole.host);
    expect(find.text('Aguardando amigo...'), findsOneWidget);
  });

  testWidgets('Start Discovery button updates state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Entrar na Sessão'));
    await tester.pump();

    expect(fakeLocalDuoService.role, DuoRole.guest);
    expect(find.text('Procurando amigos...'), findsOneWidget);
  });

  testWidgets('Displays connected guests', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 100));

    // Start host to enable connection logic listening
    await tester.tap(find.text('Hospedar Sessão'));
    await tester.pump();

    // Simulate connection
    fakeLocalDuoService.emitConnected('guest123');
    await tester.pump();

    expect(find.text('Broadcast Ativo (1)'), findsOneWidget);
    expect(find.text('Guest guest123'), findsOneWidget);
  });
}
