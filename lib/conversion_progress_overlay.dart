import 'package:flutter/material.dart';

// A simple class to hold conversion job state.
class ConversionJob {
  final String filename;
  double progress; // 0.0 to 1.0

  ConversionJob({required this.filename, this.progress = 0.0});
}

class ConversionProgressOverlay extends StatelessWidget {
  final List<ConversionJob> jobs;

  const ConversionProgressOverlay({super.key, required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const SizedBox.shrink(); // Render nothing if there are no jobs
    }

    return Positioned(
      bottom: 80, // Position above the playback controls
      left: 16,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Converting Files...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...jobs.map((job) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.filename,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: job.progress),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
