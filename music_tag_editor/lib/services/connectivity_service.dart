import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  @visibleForTesting
  static set instance(ConnectivityService mock) => _instance = mock;

  final Connectivity _connectivity;
  final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService._internal({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @visibleForTesting
  factory ConnectivityService.test({Connectivity? connectivity}) {
    return ConnectivityService._internal(connectivity: connectivity);
  }

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If results is empty or contains only 'none'
    bool offline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    // Check if truly offline (sometimes multiple results include something and none)
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      offline = false;
    }

    if (isOffline.value != offline) {
      isOffline.value = offline;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
