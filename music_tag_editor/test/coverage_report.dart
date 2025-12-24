import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!await file.exists()) {
    print('Coverage file not found.');
    return;
  }

  final lines = await file.readAsLines();
  final fileCoverage = <String, Map<String, int>>{};
  String currentFile = '';

  for (var line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = {'total': 0, 'covered': 0};
    } else if (line.startsWith('DA:')) {
      fileCoverage[currentFile]!['total'] =
          fileCoverage[currentFile]!['total']! + 1;
      final parts = line.split(',');
      if (parts.length > 1 && int.parse(parts[1]) > 0) {
        fileCoverage[currentFile]!['covered'] =
            fileCoverage[currentFile]!['covered']! + 1;
      }
    }
  }

  final sortedFiles = fileCoverage.entries.toList()
    ..sort((a, b) {
      final aCov = a.value['covered']! / a.value['total']!;
      final bCov = b.value['covered']! / b.value['total']!;
      return aCov.compareTo(bCov);
    });

  print('--- Low Coverage Files (Top 15) ---');
  for (final entry in sortedFiles.take(20)) {
    final total = entry.value['total']!;
    final covered = entry.value['covered']!;
    final percentage = (covered / total) * 100;
    if (percentage < 80) {
      print(
          '${percentage.toStringAsFixed(2)}% ($covered/$total) - ${entry.key}');
    }
  }
}
