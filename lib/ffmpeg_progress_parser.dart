class FFmpegProgressParser {
  Duration? _totalDuration;

  void setTotalDuration(Duration duration) {
    _totalDuration = duration;
  }

  double parse(String log) {
    if (_totalDuration == null || _totalDuration == Duration.zero) {
      return 0.0;
    }

    final regExp = RegExp(r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})');
    final match = regExp.firstMatch(log);

    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final hundredths = int.parse(match.group(4)!);

      final currentTime = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: hundredths * 10,
      );

      final progress = currentTime.inMilliseconds / _totalDuration!.inMilliseconds;
      return progress.clamp(0.0, 1.0);
    }

    return -1; // Indicates no progress update found in this log line
  }
}
