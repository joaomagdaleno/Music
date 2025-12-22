import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class CastDevice {
  final String name;
  final String controlUrl;
  final String host;

  CastDevice(
      {required this.name, required this.controlUrl, required this.host});

  @override
  bool operator ==(Object other) =>
      other is CastDevice && other.controlUrl == controlUrl;

  @override
  int get hashCode => controlUrl.hashCode;
}

class CastService {
  static final CastService instance = CastService._internal();
  CastService._internal();

  final List<CastDevice> _devices = [];
  final StreamController<List<CastDevice>> _devicesController =
      StreamController.broadcast();
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  HttpServer? _server;
  String? _localIp;

  Future<void> startDiscovery() async {
    _devices.clear();
    _devicesController.add([]);

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data);
            _parseSsdpResponse(msg);
          }
        }
      });

      const discoveryMsg = 'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 3\r\n'
          'ST: urn:schemas-upnp-org:service:AVTransport:1\r\n'
          '\r\n';

      socket.send(
          utf8.encode(discoveryMsg), InternetAddress('239.255.255.250'), 1900);

      // Stop listening after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        socket.close();
      });
    } catch (e) {
      debugPrint('SSDP Discovery Error: $e');
    }
  }

  Future<void> _parseSsdpResponse(String response) async {
    final lines = response.split('\r\n');
    String? location;
    for (var line in lines) {
      if (line.toUpperCase().startsWith('LOCATION:')) {
        location = line.substring(9).trim();
        break;
      }
    }

    if (location != null) {
      try {
        final resp = await http.get(Uri.parse(location));
        if (resp.statusCode == 200) {
          final xml = resp.body;
          final nameReg = RegExp(r'<friendlyName>(.*?)</friendlyName>');
          final name = nameReg.firstMatch(xml)?.group(1) ?? 'Unknown Device';

          if (xml.contains('urn:schemas-upnp-org:service:AVTransport:1')) {
            final serviceBlock =
                xml.split('urn:schemas-upnp-org:service:AVTransport:1')[1];
            final controlUrlReg = RegExp(r'<controlURL>(.*?)</controlURL>');
            final match = controlUrlReg.firstMatch(serviceBlock);
            var controlUrl = match?.group(1);

            if (controlUrl != null) {
              if (!controlUrl.startsWith('http')) {
                final uri = Uri.parse(location);
                if (controlUrl.startsWith('/')) {
                  controlUrl =
                      '${uri.scheme}://${uri.host}:${uri.port}$controlUrl';
                } else {
                  controlUrl =
                      '${uri.scheme}://${uri.host}:${uri.port}/$controlUrl';
                }
              }

              final device = CastDevice(
                  name: name,
                  controlUrl: controlUrl,
                  host: Uri.parse(location).host);
              if (!_devices.contains(device)) {
                _devices.add(device);
                _devicesController.add(_devices);
              }
            }
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  Future<void> castFile(String filePath, CastDevice device) async {
    await stopCasting();

    final info = NetworkInfo();
    _localIp = await info.getWifiIP() ?? '127.0.0.1';

    final handler = createStaticHandler(File(filePath).parent.path,
        defaultDocument: File(filePath).uri.pathSegments.last);

    _server = await shelf_io.serve(handler, _localIp ?? '0.0.0.0', 0);
    final fileUrl =
        'http://$_localIp:${_server!.port}/${File(filePath).uri.pathSegments.last}';

    debugPrint('Hosting at $fileUrl');

    await _setAvTransportUri(device.controlUrl, fileUrl);
    await _play(device.controlUrl);
  }

  Future<void> stopCasting() async {
    await _server?.close(force: true);
    _server = null;
  }

  // SOAP Actions
  Future<void> _setAvTransportUri(String controlUrl, String currentUri) async {
    final body = '''
      <?xml version="1.0" encoding="utf-8"?>
      <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Body>
          <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <CurrentURI>$currentUri</CurrentURI>
            <CurrentURIMetaData></CurrentURIMetaData>
          </u:SetAVTransportURI>
        </s:Body>
      </s:Envelope>
    ''';
    await _sendSoap(controlUrl, 'SetAVTransportURI', body);
  }

  Future<void> _play(String controlUrl) async {
    final body = '''
      <?xml version="1.0" encoding="utf-8"?>
      <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Body>
          <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Speed>1</Speed>
          </u:Play>
        </s:Body>
      </s:Envelope>
    ''';
    await _sendSoap(controlUrl, 'Play', body);
  }

  Future<void> _sendSoap(String url, String action, String body) async {
    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"urn:schemas-upnp-org:service:AVTransport:1#$action"',
        },
        body: body,
      );
    } catch (e) {
      debugPrint('SOAP Error ($action): $e');
    }
  }
}

// Stub for debugPrint if not imported (it's in foundation.dart or material.dart)
void debugPrint(String message) {
  // Use log or foundation debugPrint in real apps
}
