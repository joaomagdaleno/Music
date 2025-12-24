@Tags(['unit'])
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late ConnectivityService service;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    service = ConnectivityService.test(connectivity: mockConnectivity);
  });

  group('ConnectivityService', () {
    test('init updates isOffline status correctly', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      await service.init();

      expect(service.isOffline.value, true);
    });

    test('Becomes online when wifi connected', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

      await service.init();

      expect(service.isOffline.value, false);
    });
  });
}
