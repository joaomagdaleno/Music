import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print(
        'Error: coverage/lcov.info not found. Run "flutter test --coverage" first.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  int totalLines = 0;
  int coveredLines = 0;
  Map<String, List<int>> fileCoverage = {};
  String? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = [0, 0]; // [covered, total]
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length == 2) {
        final count = int.parse(parts[1]);
        fileCoverage[currentFile]![1]++;
        if (count > 0) {
          fileCoverage[currentFile]![0]++;
        }
      }
    } else if (line == 'end_of_record') {
      totalLines += fileCoverage[currentFile]![1];
      coveredLines += fileCoverage[currentFile]![0];
      currentFile = null;
    }
  }

  print('Coverage Breakdown (Top 20 files by size):');
  final sortedFiles = fileCoverage.entries.toList()
    ..sort((a, b) => b.value[1].compareTo(a.value[1]));

  for (final entry in sortedFiles.take(20)) {
    final covered = entry.value[0];
    final total = entry.value[1];
    final pct = (covered / total * 100).toStringAsFixed(1);
    print('${entry.key}: $pct% ($covered/$total)');
  }

  final totalPct = (coveredLines / totalLines * 100).toStringAsFixed(2);
  print('\nTotal Lines: $totalLines');
  print('Covered Lines: $coveredLines');
  print('Total Coverage: $totalPct%');
}
