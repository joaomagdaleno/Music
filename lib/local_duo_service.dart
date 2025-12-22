import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'playback_service.dart';
import 'search_service.dart';

enum DuoRole { host, guest, none }

class LocalDuoService {
  static final LocalDuoService instance = LocalDuoService._internal();
  LocalDuoService._internal();

  final Strategy strategy = Strategy.P2P_STAR;
  String? _connectedEndpointId;
  DuoRole role = DuoRole.none;

  Function(String)? onDeviceFound;
  Function(String)? onConnected;
  Function()? onDisconnected;

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
      }
    });
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpointId = id;
      onConnected?.call(id);
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
        PlaybackService.instance.playSearchResult(result, fromRemote: true);
        break;
    }
  }

  void stopAll() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    _connectedEndpointId = null;
    role = DuoRole.none;
  }
}
