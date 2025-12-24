import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final comparator = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(comparator.basedir, 0.05);
  }

  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(),
  );
}

class _TolerantComparator extends LocalFileComparator {
  final double threshold;

  _TolerantComparator(Uri basedir, this.threshold) : super(basedir);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent > threshold) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }

    return true;
  }
}
