@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:music_tag_editor/services/cast_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeUri extends Fake implements Uri {}

void main() {
  late CastService castService;
  late MockHttpClient mockHttpClient;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(Uri.parse('http://example.com'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockNetworkInfo = MockNetworkInfo();

    // Create isolated test instance
    castService = CastService.test(
      client: mockHttpClient,
      networkInfo: mockNetworkInfo,
    );
  });

  group('CastService', () {
    test('parseSsdpResponse adds device to stream on valid XML', () async {
      const location = 'http://192.168.1.50:8008/ssdp/device-desc.xml';
      const responseMsg = 'HTTP/1.1 200 OK\r\nLOCATION: $location\r\n\r\n';

      const xmlBody = '''
        <root>
          <device>
            <friendlyName>Living Room TV</friendlyName>
            <serviceList>
              <service>
                <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                <controlURL>/AVTransport/control</controlURL>
              </service>
            </serviceList>
          </device>
        </root>
      ''';

      when(() => mockHttpClient.get(Uri.parse(location)))
          .thenAnswer((_) async => http.Response(xmlBody, 200));

      // Expectation
      expectLater(
        castService.devicesStream,
        emits(predicate<List<CastDevice>>((devices) {
          return devices.isNotEmpty &&
              devices.first.name == 'Living Room TV' &&
              devices.first.host == '192.168.1.50';
        })),
      );

      await castService.parseSsdpResponse(responseMsg);
    });

    test('sendSoap sends correct POST request', () async {
      const url = 'http://192.168.1.50:8008/AVTransport/control';
      const action = 'Play';
      const body = '<xml>test</xml>';

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('OK', 200));

      await castService.sendSoap(url, action, body);

      verify(() => mockHttpClient.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'text/xml; charset="utf-8"',
              'SOAPAction': '"urn:schemas-upnp-org:service:AVTransport:1#Play"',
            },
            body: body,
          )).called(1);
    });

    test('parseSsdpResponse handles partial URLs in controlURL', () async {
      const location = 'http://192.168.1.50:8008/desc.xml';
      const responseMsg = 'LOCATION: $location\r\n';

      const xmlBody = '''
        <root>
          <device>
            <friendlyName>Chromecast</friendlyName>
             <serviceList>
              <service>
                <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                <controlURL>control</controlURL>
              </service>
             </serviceList>
          </device>
        </root>
      ''';

      when(() => mockHttpClient.get(Uri.parse(location)))
          .thenAnswer((_) async => http.Response(xmlBody, 200));

      expectLater(
        castService.devicesStream,
        emits(predicate<List<CastDevice>>((devices) {
          return devices.first.controlUrl == 'http://192.168.1.50:8008/control';
        })),
      );

      await castService.parseSsdpResponse(responseMsg);
    });
  });
}
