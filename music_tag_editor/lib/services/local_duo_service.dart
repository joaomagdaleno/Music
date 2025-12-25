import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:meta/meta.dart';

enum DuoRole { host, guest, none }

class LocalDuoService {
  static LocalDuoService? _instance;
  static LocalDuoService get instance =>
      _instance ??= LocalDuoService._internal();

  @visibleForTesting
  static void resetInstance() => _instance = null;

  @visibleForTesting
  @visibleForTesting
  static set instance(LocalDuoService mock) => _instance = mock;

  LocalDuoService._internal() : _nearby = Nearby();

  @visibleForTesting
  LocalDuoService.forTesting({Nearby? nearby}) : _nearby = nearby ?? Nearby();

  final Nearby _nearby;
  final Strategy strategy = Strategy.P2P_STAR;
  final Set<String> _connectedEndpoints = {};
  DuoRole role = DuoRole.none;
  final Map<String, String> _discoveredNames = {};

  Function(String)? onDeviceFound;
  Function(String)? onConnected;
  Function()? onDisconnected;

  Set<String> get connectedEndpoints => _connectedEndpoints;
  String? getDiscoveredName(String id) => _discoveredNames[id];

  SearchResult? _pendingTrack;
  Function(List<SearchResult>)? onLibraryReceived;
  Function(String)? onMessageReceived;

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startHost(String username) async {
    role = DuoRole.host;
    try {
      await _nearby.startAdvertising(
        username,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      role = DuoRole.none;
    }
  }

  Future<void> startDiscovery(String username) async {
    role = DuoRole.guest;
    try {
      await _nearby.startDiscovery(
        username,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          _discoveredNames[id] = name;
          onDeviceFound?.call(name);
          _nearby.requestConnection(
            username,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {},
      );
    } catch (e) {
      role = DuoRole.none;
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _nearby.acceptConnection(id, onPayLoadRecieved: (id, payload) {
      if (payload.type == PayloadType.BYTES) {
        final str = String.fromCharCodes(payload.bytes!);
        _handleIncomingMessage(id, jsonDecode(str));
      } else if (payload.type == PayloadType.FILE) {
        if (_pendingTrack != null && payload.uri != null) {
          PlaybackService.instance.playLocalFile(payload.uri!, _pendingTrack!);
          _pendingTrack = null;
        }
      }
    });
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      onConnected?.call(id);
      final name = _discoveredNames[id] ?? "Convidado";
      DatabaseService.instance.saveGuest(id, name);
      if (role == DuoRole.guest) {
        _nearby.stopDiscovery();
      }
    }
  }

  void _onDisconnected(String id) {
    _connectedEndpoints.remove(id);
    if (_connectedEndpoints.isEmpty) {
      role = DuoRole.none;
    }
    onDisconnected?.call();
  }

  void sendMessage(Map<String, dynamic> msg) {
    final payload = Uint8List.fromList(jsonEncode(msg).codeUnits);
    for (var id in _connectedEndpoints) {
      _nearby.sendBytesPayload(id, payload);
    }
  }

  Future<void> sendFile(String path) async {
    for (var id in _connectedEndpoints) {
      await _nearby.sendFilePayload(id, path);
    }
  }

  void _handleIncomingMessage(String id, Map<String, dynamic> msg) {
    final type = msg['type'];
    final data = msg['data'];
    (data); // Avoid unused warning

    switch (type) {
      case 'play':
        final pos = Duration(milliseconds: msg['positionMs']);
        PlaybackService.instance.playFromRemote(pos);
        break;
      case 'pause':
        PlaybackService.instance.pauseFromRemote();
        break;
      case 'seek':
        final pos = Duration(milliseconds: msg['positionMs']);
        PlaybackService.instance.seek(pos);
        break;
      case 'track':
        final result = SearchResult.fromJson(msg['track']);
        if (result.localPath != null) {
          _pendingTrack = result;
        } else {
          PlaybackService.instance.playSearchResult(result, fromRemote: true);
        }
        break;
      case 'request_library':
        _sendLocalLibrary();
        break;
      case 'library_data':
        final List<dynamic> list = msg['library'];
        final tracks = list.map((json) => SearchResult.fromJson(json)).toList();
        onLibraryReceived?.call(tracks);
        for (var track in tracks) {
          DatabaseService.instance.saveTrack(track.toJson());
          DatabaseService.instance.addTrackToDuoSession(id, track.id);
        }
        break;
      case 'add_to_queue':
        final track = SearchResult.fromJson(msg['track']);
        PlaybackService.instance.addToQueue(track, fromRemote: true);
        break;
      case 'chat':
        onMessageReceived?.call(msg['message']);
        break;
    }
  }

  void sendChatMessage(String message) {
    sendMessage({
      'type': 'chat',
      'message': message,
    });
  }

  Future<void> _sendLocalLibrary() async {
    final tracksData = await DatabaseService.instance.getTracks();
    final List<Map<String, dynamic>> tracks = [];

    for (var trackData in tracksData) {
      final result = SearchResult(
        id: trackData['id'],
        title: trackData['title'],
        artist: trackData['artist'] ?? '',
        thumbnail: trackData['thumbnail'],
        duration: trackData['duration'],
        url: trackData['url'],
        platform: MediaPlatform.values.firstWhere(
          (e) => e.toString() == trackData['platform'],
          orElse: () => MediaPlatform.unknown,
        ),
        localPath: trackData['local_path'],
      );
      tracks.add(result.toJson());
    }

    sendMessage({
      'type': 'library_data',
      'library': tracks,
    });
  }

  void requestRemoteLibrary() {
    sendMessage({'type': 'request_library'});
  }

  void stopAll() {
    _nearby.stopAllEndpoints();
    _nearby.stopAdvertising();
    _nearby.stopDiscovery();
    _connectedEndpoints.clear();
    role = DuoRole.none;
  }
}
