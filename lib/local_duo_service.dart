import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'playback_service.dart';
import 'download_service.dart';
import 'database_service.dart';

enum DuoRole { host, guest, none }

class LocalDuoService {
  static final LocalDuoService instance = LocalDuoService._internal();
  LocalDuoService._internal();

  final Strategy strategy = Strategy.P2P_STAR;
  String? _connectedEndpointId;
  DuoRole role = DuoRole.none;
  final Map<String, String> _discoveredNames =
      {}; // Store names by id during discovery

  Function(String)? onDeviceFound;
  Function(String)? onConnected;
  Function()? onDisconnected;

  // Track ID waiting for a file payload
  SearchResult? _pendingTrack;

  // Callback for when remote library data is received
  Function(List<SearchResult>)? onLibraryReceived;

  // Callback for when a chat message is received
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
      bool a = await Nearby().startAdvertising(
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
      bool a = await Nearby().startDiscovery(
        username,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          _discoveredNames[id] = name;
          onDeviceFound?.call(name);
          Nearby().requestConnection(
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
    // Auto accept for now to simplify
    Nearby().acceptConnection(id, onPayloadReceived: (id, payload) {
      if (payload.type == PayloadType.BYTES) {
        final str = String.fromCharCodes(payload.bytes!);
        _handleIncomingMessage(jsonDecode(str));
      } else if (payload.type == PayloadType.FILE) {
        if (_pendingTrack != null && payload.filePath != null) {
          PlaybackService.instance
              .playLocalFile(payload.filePath!, _pendingTrack!);
          _pendingTrack = null;
        }
      }
    });
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpointId = id;
      onConnected?.call(id);
      final name = _discoveredNames[id] ?? "Convidado";
      DatabaseService.instance.saveGuest(id, name);
      Nearby().stopAdvertising();
      Nearby().stopDiscovery();
    }
  }

  void _onDisconnected(String id) {
    _connectedEndpointId = null;
    role = DuoRole.none;
    onDisconnected?.call();
  }

  void sendMessage(Map<String, dynamic> msg) {
    if (_connectedEndpointId != null) {
      Nearby().sendBytesPayload(
          _connectedEndpointId!, Uint8List.fromList(jsonEncode(msg).codeUnits));
    }
  }

  Future<void> sendFile(String path) async {
    if (_connectedEndpointId != null) {
      await Nearby().sendFilePayload(_connectedEndpointId!, path);
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    final data = msg['data'];

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
          // It's a local track, wait for the file payload
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
        // Automatically save remote tracks to this guest's session
        if (_connectedEndpointId != null) {
          for (var track in tracks) {
            DatabaseService.instance.saveTrack(track.toJson());
            DatabaseService.instance
                .addTrackToDuoSession(_connectedEndpointId!, track.id);
          }
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
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    _connectedEndpointId = null;
    role = DuoRole.none;
  }
}
