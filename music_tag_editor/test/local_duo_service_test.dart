import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockNearby extends Mock implements Nearby {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late LocalDuoService service;
  late MockNearby mockNearby;
  late MockPlaybackService mockPlayback;
  late MockDatabaseService mockDb;

  setUpAll(() {
    registerFallbackValue(Strategy.P2P_STAR);
    registerFallbackValue(
        Payload(type: PayloadType.BYTES, bytes: Uint8List(0), id: 0));
    registerFallbackValue(ConnectionInfo('name', 'serviceId', true));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(SearchResult(
        id: '0',
        title: '0',
        artist: '0',
        url: '0',
        platform: MediaPlatform.unknown));
  });

  setUp(() {
    mockNearby = MockNearby();
    mockPlayback = MockPlaybackService();
    mockDb = MockDatabaseService();

    PlaybackService.instance = mockPlayback;
    DatabaseService.instance = mockDb;

    service = LocalDuoService.forTesting(nearby: mockNearby);
  });

  group('LocalDuoService', () {
    test('startHost sets role and starts advertising', () async {
      when(() => mockNearby.startAdvertising(
            any(),
            any(),
            onConnectionInitiated: any(named: 'onConnectionInitiated'),
            onConnectionResult: any(named: 'onConnectionResult'),
            onDisconnected: any(named: 'onDisconnected'),
          )).thenAnswer((_) async => true);

      await service.startHost('TestUser');

      expect(service.role, DuoRole.host);
      verify(() => mockNearby.startAdvertising(
            'TestUser',
            any(),
            onConnectionInitiated: any(named: 'onConnectionInitiated'),
            onConnectionResult: any(named: 'onConnectionResult'),
            onDisconnected: any(named: 'onDisconnected'),
          )).called(1);
    });

    test('startDiscovery sets role and starts discovery', () async {
      when(() => mockNearby.startDiscovery(
            any(),
            any(),
            onEndpointFound: any(named: 'onEndpointFound'),
            onEndpointLost: any(named: 'onEndpointLost'),
          )).thenAnswer((_) async => true);

      await service.startDiscovery('TestUser');

      expect(service.role, DuoRole.guest);
      verify(() => mockNearby.startDiscovery(
            'TestUser',
            any(),
            onEndpointFound: any(named: 'onEndpointFound'),
            onEndpointLost: any(named: 'onEndpointLost'),
          )).called(1);
    });

    test('stopAll cleans up state', () {
      when(() => mockNearby.stopAllEndpoints()).thenAnswer((_) async => {});
      when(() => mockNearby.stopAdvertising()).thenAnswer((_) async => {});
      when(() => mockNearby.stopDiscovery()).thenAnswer((_) async => {});

      service.stopAll();

      expect(service.role, DuoRole.none);
      expect(service.connectedEndpoints, isEmpty);
      verify(() => mockNearby.stopAllEndpoints()).called(1);
      verify(() => mockNearby.stopAdvertising()).called(1);
      verify(() => mockNearby.stopDiscovery()).called(1);
    });

    test('sendMessage sends bytes to all connected endpoints', () {
      service.connectedEndpoints.add('endpoint1');
      service.connectedEndpoints.add('endpoint2');
      when(() => mockNearby.sendBytesPayload(any(), any()))
          .thenAnswer((_) async => 0);

      final msg = {'type': 'test', 'data': 'hello'};
      service.sendMessage(msg);

      verify(() => mockNearby.sendBytesPayload('endpoint1', any())).called(1);
      verify(() => mockNearby.sendBytesPayload('endpoint2', any())).called(1);
    });

    test('sendFile sends file to all connected endpoints', () async {
      service.connectedEndpoints.add('endpoint1');
      when(() => mockNearby.sendFilePayload(any(), any()))
          .thenAnswer((_) async => 0);

      await service.sendFile('path/to/file');

      verify(() => mockNearby.sendFilePayload('endpoint1', 'path/to/file'))
          .called(1);
    });

    test('handleIncomingMessage play/pause/seek', () async {
      when(() => mockPlayback.playFromRemote(any())).thenAnswer((_) async {});
      when(() => mockPlayback.pauseFromRemote()).thenAnswer((_) async {});
      when(() => mockPlayback.seek(any())).thenAnswer((_) async => {});

      void Function(String, Payload)? captureCallback;
      when(() => mockNearby.acceptConnection(any(),
              onPayLoadRecieved: any(named: 'onPayLoadRecieved')))
          .thenAnswer((inv) {
        captureCallback = inv.namedArguments[#onPayLoadRecieved];
        return Future.value(true);
      });

      when(() => mockNearby.startAdvertising(any(), any(),
          onConnectionInitiated: any(named: 'onConnectionInitiated'),
          onConnectionResult: any(named: 'onConnectionResult'),
          onDisconnected: any(named: 'onDisconnected'))).thenAnswer((inv) {
        final onInit = inv.namedArguments[#onConnectionInitiated] as void
            Function(String, ConnectionInfo);
        onInit('endpoint1', ConnectionInfo('Name', 'Service', true));
        return Future.value(true);
      });

      await service.startHost('User');

      expect(captureCallback, isNotNull);

      // Play
      final playMsg = jsonEncode({'type': 'play', 'positionMs': 1234});
      captureCallback!(
          'endpoint1',
          Payload(
              type: PayloadType.BYTES,
              bytes: Uint8List.fromList(playMsg.codeUnits),
              id: 1));
      verify(() => mockPlayback.playFromRemote(any())).called(1);

      // Pause
      final pauseMsg = jsonEncode({'type': 'pause'});
      captureCallback!(
          'endpoint1',
          Payload(
              type: PayloadType.BYTES,
              bytes: Uint8List.fromList(pauseMsg.codeUnits),
              id: 2));
      verify(() => mockPlayback.pauseFromRemote()).called(1);

      // Seek
      final seekMsg = jsonEncode({'type': 'seek', 'positionMs': 5000});
      captureCallback!(
          'endpoint1',
          Payload(
              type: PayloadType.BYTES,
              bytes: Uint8List.fromList(seekMsg.codeUnits),
              id: 3));
      verify(() => mockPlayback.seek(any())).called(1);
    });

    test('handleIncomingMessage track/chat', () async {
      when(() => mockPlayback.playSearchResult(any(), fromRemote: true))
          .thenAnswer((_) async => {});

      void Function(String, Payload)? captureCallback;
      when(() => mockNearby.acceptConnection(any(),
              onPayLoadRecieved: any(named: 'onPayLoadRecieved')))
          .thenAnswer((inv) {
        captureCallback = inv.namedArguments[#onPayLoadRecieved];
        return Future.value(true);
      });

      when(() => mockNearby.startAdvertising(any(), any(),
          onConnectionInitiated: any(named: 'onConnectionInitiated'),
          onConnectionResult: any(named: 'onConnectionResult'),
          onDisconnected: any(named: 'onDisconnected'))).thenAnswer((inv) {
        final onInit = inv.namedArguments[#onConnectionInitiated] as void
            Function(String, ConnectionInfo);
        onInit('endpoint1', ConnectionInfo('Name', 'Service', true));
        return Future.value(true);
      });

      await service.startHost('User');

      // Track
      final track = SearchResult(
          id: '1',
          title: 'Song',
          artist: 'Artist',
          platform: MediaPlatform.youtube,
          url: 'http');
      final trackMsg = jsonEncode({'type': 'track', 'track': track.toJson()});
      captureCallback!(
          'endpoint1',
          Payload(
              type: PayloadType.BYTES,
              bytes: Uint8List.fromList(trackMsg.codeUnits),
              id: 1));
      verify(() => mockPlayback.playSearchResult(any(), fromRemote: true))
          .called(1);

      // Chat
      bool chatCalled = false;
      service.onMessageReceived = (msg) => chatCalled = msg == 'Hello';
      final chatMsg = jsonEncode({'type': 'chat', 'message': 'Hello'});
      captureCallback!(
          'endpoint1',
          Payload(
              type: PayloadType.BYTES,
              bytes: Uint8List.fromList(chatMsg.codeUnits),
              id: 2));
      expect(chatCalled, true);
    });
  });
}
