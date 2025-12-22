import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!await file.exists()) {
    print('coverage/lcov.info not found');
    return;
  }

  final lines = await file.readAsLines();
  final Map<String, _Coverage> fileCoverage = {};
  String? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = _Coverage();
    } else if (line.startsWith('LF:') && currentFile != null) {
      fileCoverage[currentFile]!.total = int.parse(line.substring(3));
    } else if (line.startsWith('LH:') && currentFile != null) {
      fileCoverage[currentFile]!.covered = int.parse(line.substring(3));
    }
  }

  int totalGlobally = 0;
  int coveredGlobally = 0;

  final sortedEntries = fileCoverage.entries.toList()
    ..sort((a, b) => b.value.total.compareTo(a.value.total)); // Sort by size

  print('Coverage Breakdown (Top 20 files by size):');
  for (final entry in sortedEntries.take(20)) {
    final cov = entry.value;
    final percentage = cov.total > 0 ? (cov.covered / cov.total) * 100 : 0.0;
    print(
        '${entry.key}: ${percentage.toStringAsFixed(1)}% (${cov.covered}/${cov.total})');
    totalGlobally += cov.total;
    coveredGlobally += cov.covered;
  }

  // Sum rest
  for (final entry in sortedEntries.skip(20)) {
    totalGlobally += entry.value.total;
    coveredGlobally += entry.value.covered;
  }

  final totalPercentage =
      totalGlobally > 0 ? (coveredGlobally / totalGlobally) * 100 : 0.0;
  print('\nTotal Lines: $totalGlobally');
  print('Covered Lines: $coveredGlobally');
  print('Total Coverage: ${totalPercentage.toStringAsFixed(2)}%');
}

class _Coverage {
  int total = 0;
  int covered = 0;
}
