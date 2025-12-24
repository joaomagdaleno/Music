import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: const PlatformGoldensConfig(
        enabled: true,
      ),
    ),
    run: testMain,
  );
}
