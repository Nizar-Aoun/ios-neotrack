import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  Timer? _quickCheckTimer;
  Timer? _qualityCheckTimer;
  Timer? _disconnectionTimer;
  bool _isConnected = true;
  bool _isInitialized = false;
  bool _useConnectivityPlugin = true;
  NetworkQuality _currentQuality = NetworkQuality.excellent;
  bool _hasGoodConnection = true;
  DateTime? _disconnectionStartTime;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  NetworkQuality get currentQuality => _currentQuality;
  bool get hasGoodConnection => _hasGoodConnection;

  ConnectivityService() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      // Try to use connectivity plugin first
      try {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result as ConnectivityResult);
        _setupConnectivityStream();
        _setupPeriodicCheck();
        _setupQualityCheck();
      } catch (e) {
        _useConnectivityPlugin = false;
        // Fall back to HTTP-based connectivity check
        await _checkConnectivityViaHttp();
        _setupPeriodicCheck();
        _setupQuickCheck();
        _setupQualityCheck();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _hasGoodConnection = false;
      _currentQuality = NetworkQuality.poor;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _setupQualityCheck() {
    // Check network quality every 5 seconds when connected
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isConnected && _isInitialized) {
        _checkNetworkQualityPeriodically();
      }
    });
  }

  void _setupConnectivityStream() {
    if (!_useConnectivityPlugin) return;

    try {
      // Newer versions of connectivity_plus may emit a List<ConnectivityResult>
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          // Prefer any non-none result, otherwise treat as none
          final ConnectivityResult result = results.firstWhere(
            (r) => r != ConnectivityResult.none,
            orElse: () => ConnectivityResult.none,
          );
          _updateConnectionStatus(result);
        },
        onError: (error) {
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _useConnectivityPlugin = false;
    }
  }

  void _setupPeriodicCheck() {
    // Less frequent checks to improve performance
    final checkInterval = _useConnectivityPlugin ? 10 : 5; // Reduced frequency
    _periodicCheckTimer =
        Timer.periodic(Duration(seconds: checkInterval), (timer) {
      if (_isInitialized) {
        _checkConnectivityPeriodically();
      }
    });
  }

  void _setupQuickCheck() {
    if (_useConnectivityPlugin) return; // Only needed for HTTP fallback

    _quickCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Reduced from 1 to 3 seconds
      if (_isInitialized) {
        // Only do quick checks when we think we might be offline
        if (!_isConnected) {
          _quickConnectivityCheck();
        }
      }
    });
  }

  Future<void> _quickConnectivityCheck() async {
    try {
      // Quick check with shorter timeout
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        // We're online
        if (!_isConnected) {
          _updateConnectionStatusHttp(true);
        }
      } else {
        // We might be offline
        if (_isConnected) {
          await _checkConnectivityViaHttp();
        }
      }
    } catch (e) {
      // Network error - we might be offline
      if (_isConnected) {
        await _checkConnectivityViaHttp();
      }
    }
  }

  Future<void> _checkConnectivityPeriodically() async {
    try {
      if (_useConnectivityPlugin) {
        final result = await _connectivity.checkConnectivity();
        final newConnectionStatus = result != ConnectivityResult.none;

        if (_isConnected != newConnectionStatus) {
          _updateConnectionStatus(result as ConnectivityResult);
        }
      } else {
        // Use HTTP-based check
        await _checkConnectivityViaHttp();
      }
    } catch (e) {
      // Fall back to HTTP check if plugin fails
      if (_useConnectivityPlugin) {
        _useConnectivityPlugin = false;
        await _checkConnectivityViaHttp();
      }
    }
  }

  Future<bool> _checkConnectivityViaHttp() async {
    try {
      // Try multiple reliable endpoints with shorter timeouts
      final endpoints = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://httpbin.org/get',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await http.get(Uri.parse(endpoint)).timeout(
              const Duration(
                  seconds: 4)); // Increased timeout for better reliability

          if (response.statusCode == 200) {
            _updateConnectionStatusHttp(true);
            return true;
          }
        } catch (e) {
          continue;
        }
      }

      _updateConnectionStatusHttp(false);
      return false;
    } catch (e) {
      _updateConnectionStatusHttp(false);
      return false;
    }
  }

  void _updateConnectionStatusHttp(bool isConnected) {
    final wasConnected = _isConnected;
    _isConnected = isConnected;

    if (isConnected) {
      // Connection restored - cancel disconnection timer
      _disconnectionTimer?.cancel();
      _disconnectionTimer = null;
      _disconnectionStartTime = null;

      // If we were previously disconnected (hasGoodConnection was false), restore it
      if (!_hasGoodConnection) {
        _hasGoodConnection = true;
        _currentQuality = NetworkQuality.good;
        notifyListeners();
      }
    } else {
      // Connection lost - start or continue tracking disconnection time
      if (_disconnectionStartTime == null) {
        _disconnectionStartTime = DateTime.now();
        _startDisconnectionTimer();
      }
    }

    if (wasConnected != _isConnected) {
      notifyListeners();

      // Force additional notification after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        notifyListeners();
      });
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (_isConnected) {
      // Connection restored - cancel disconnection timer
      _disconnectionTimer?.cancel();
      _disconnectionTimer = null;
      _disconnectionStartTime = null;

      // If we were previously disconnected (hasGoodConnection was false), restore it
      if (!_hasGoodConnection) {
        _hasGoodConnection = true;
        _currentQuality = NetworkQuality.good;
        notifyListeners();
      }
    } else {
      // Connection lost - start or continue tracking disconnection time
      if (_disconnectionStartTime == null) {
        _disconnectionStartTime = DateTime.now();
        _startDisconnectionTimer();
      }
    }

    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      if (_useConnectivityPlugin) {
        try {
          final result = await _connectivity.checkConnectivity();
          _updateConnectionStatus(result as ConnectivityResult);
          return _isConnected;
        } catch (e) {
          _useConnectivityPlugin = false;
          return await _checkConnectivityViaHttp();
        }
      } else {
        return await _checkConnectivityViaHttp();
      }
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Force a connectivity check and update the status
  Future<bool> forceCheckConnectivity() async {
    try {
      if (_useConnectivityPlugin) {
        try {
          final result = await _connectivity.checkConnectivity();

          // Always update status regardless of previous state
          _isConnected = result != ConnectivityResult.none;

          notifyListeners();
          return _isConnected;
        } catch (e) {
          _useConnectivityPlugin = false;
          return await _checkConnectivityViaHttp();
        }
      } else {
        return await _checkConnectivityViaHttp();
      }
    } catch (e) {
      _isConnected = false;
      _hasGoodConnection = false;
      _currentQuality = NetworkQuality.poor;
      notifyListeners();
      return false;
    }
  }

  /// Trigger an immediate connectivity check
  void triggerImmediateCheck() {
    if (_isInitialized) {
      _checkConnectivityPeriodically();
    }
  }

  /// Force a UI update by notifying listeners
  void forceUpdate() {
    notifyListeners();
  }

  /// Check network quality by measuring response time
  Future<NetworkQuality> checkNetworkQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 6));
      stopwatch.stop();

      final responseTime = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        if (responseTime < 800) {
          return NetworkQuality.excellent;
        } else if (responseTime < 2500) {
          return NetworkQuality.good;
        } else if (responseTime < 6000) {
          return NetworkQuality.fair;
        } else {
          return NetworkQuality.poor;
        }
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      return NetworkQuality.poor;
    }
  }

  /// Start timer to track disconnection duration
  void _startDisconnectionTimer() {
    _disconnectionTimer?.cancel();
    _disconnectionTimer = Timer(const Duration(seconds: 10), () {
      // After 10 seconds of disconnection, mark as poor connection
      if (!_isConnected && _disconnectionStartTime != null) {
        final disconnectionDuration =
            DateTime.now().difference(_disconnectionStartTime!);
        if (disconnectionDuration.inSeconds >= 10) {
          _hasGoodConnection = false;
          _currentQuality = NetworkQuality.poor;
          notifyListeners();
        }
      }
    });
  }

  /// Periodically check network quality and update status
  Future<void> _checkNetworkQualityPeriodically() async {
    try {
      final quality = await checkNetworkQuality();
      final wasGoodConnection = _hasGoodConnection;
      _currentQuality = quality;

      // If quality check succeeds, we have connection
      if (quality != NetworkQuality.poor) {
        // Connection is good - cancel any disconnection timer
        _disconnectionTimer?.cancel();
        _disconnectionTimer = null;
        _disconnectionStartTime = null;
        _hasGoodConnection = true;
      } else {
        // Poor quality detected - start disconnection timer if not already started
        if (_disconnectionStartTime == null) {
          _disconnectionStartTime = DateTime.now();
          _startDisconnectionTimer();
        }
      }

      // If connection quality changed, notify listeners
      if (wasGoodConnection != _hasGoodConnection) {
        notifyListeners();
      }
    } catch (e) {
      // Error checking quality - start disconnection timer if not already started
      if (_disconnectionStartTime == null) {
        _disconnectionStartTime = DateTime.now();
        _startDisconnectionTimer();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _quickCheckTimer?.cancel();
    _qualityCheckTimer?.cancel();
    _disconnectionTimer?.cancel();
    super.dispose();
  }
}

enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
}
