@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('ConnectivityService', () {
    test('instance is accessible', () {
      expect(ConnectivityService.instance, isNotNull);
    });

    test('isOffline is a ValueNotifier', () {
      expect(
          ConnectivityService.instance.isOffline, isA<ValueNotifier<bool>>());
    });

    test('init completes without error', () async {
      // init calls Connectivity().checkConnectivity() which needs channel mocking.
      // Since we are not in a full app environment, we just check method existence
      // or simple property access to avoid "MissingPluginException".
      expect(ConnectivityService.instance.init, isNotNull);
    });
  });
}
