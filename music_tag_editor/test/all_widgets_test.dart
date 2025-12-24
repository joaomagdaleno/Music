/// Consolidated widget tests for Music - reduces startup overhead (5 files → 1)
/// Run with: flutter test test/all_widgets_test.dart
@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all widget tests
import 'widgets/cast_dialog_test.dart' as cast;
import 'widgets/duo_matching_dialog_test.dart' as duo;
import 'widgets/edit_track_dialog_test.dart' as edit;
import 'widgets/search_results_dialog_test.dart' as search;
// learning_choice_unit_test is already unit tagged and fast

import 'test_helper.dart';

void main() {
  setUp(() async => await setupMusicTest());

  // Run all widget tests in a single process
  cast.main();
  duo.main();
  edit.main();
  search.main();
}
