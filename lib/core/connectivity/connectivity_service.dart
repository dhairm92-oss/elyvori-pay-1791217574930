import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Online / offline signal for the whole app.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> get isOnline async => _isOnline(await _connectivity.checkConnectivity());

  /// Distinct online/offline changes.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged.map(_isOnline).distinct();
}
