import 'dart:async';

/// A simple Rate Limiter using Token Bucket algorithm.
class RateLimiter {
  final int maxRequests;
  final Duration interval;
  
  int _tokens;
  Timer? _replenishTimer;
  
  RateLimiter({
    required this.maxRequests,
    required this.interval,
  }) : _tokens = maxRequests {
    _startReplenish();
  }

  void _startReplenish() {
    _replenishTimer = Timer.periodic(interval, (_) {
      if (_tokens < maxRequests) {
        _tokens++;
      }
    });
  }

  /// Wait for a token to be available.
  Future<void> wait() async {
    while (_tokens <= 0) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _tokens--;
  }

  void dispose() {
    _replenishTimer?.cancel();
  }
}
