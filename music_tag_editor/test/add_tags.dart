// Script to add @Tags annotations to test files
// Run with: dart run test/add_tags.dart

import 'dart:io';

void main() async {
  final testDir = Directory('test');
  final files = testDir.listSync(recursive: true).whereType<File>().where(
        (f) => f.path.endsWith('_test.dart'),
      );

  for (final file in files) {
    final content = await file.readAsString();

    // Skip if already has @Tags
    if (content.contains('@Tags(')) continue;

    // Determine tag based on path/content
    String tag;
    if (file.path.contains('golden')) {
      tag = 'golden';
    } else if (file.path.contains('services') || file.path.contains('api')) {
      tag = 'unit';
    } else if (content.contains('testWidgets') ||
        content.contains('pumpWidget')) {
      tag = 'widget';
    } else {
      tag = 'unit';
    }

    // Add tag annotation
    final newContent = "@Tags(['$tag'])\nlibrary;\n\n$content";
    await file.writeAsString(newContent);
    print('Tagged: ${file.path} -> $tag');
  }

  print('Done!');
}
