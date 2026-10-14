import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';
import 'package:taxi_driver_app/screens/offline_screen.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

class ConnectivityWrapperV2 extends StatefulWidget {
  final Widget child;
  final bool showOfflineScreen;

  const ConnectivityWrapperV2({
    super.key,
    required this.child,
    this.showOfflineScreen = true,
  });

  @override
  State<ConnectivityWrapperV2> createState() => _ConnectivityWrapperV2State();
}

class _ConnectivityWrapperV2State extends State<ConnectivityWrapperV2>
    with WidgetsBindingObserver {
  late ConnectivityService _connectivityService;
  bool _isConnected = true;
  bool _isInitialized = false;
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState = WidgetsBinding.instance.lifecycleState;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService =
          Provider.of<ConnectivityService>(context, listen: false);
      _connectivityService.addListener(_onConnectivityChanged);
      _updateStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  void _onConnectivityChanged() {
    setState(() {
      _updateStatus();
    });
  }

  void _updateStatus() {
    if (_connectivityService.isInitialized != _isInitialized) {
      _isInitialized = _connectivityService.isInitialized;
    }

    if (_connectivityService.isConnected != _isConnected) {
      _isConnected = _connectivityService.isConnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingGif(width: 60, height: 60),
              SizedBox(height: 16),
              Text('Checking connectivity...'),
            ],
          ),
        ),
      );
    }

    // Show offline screen if not connected AND app is in foreground
    final bool shouldShowOffline = !_isConnected &&
        widget.showOfflineScreen &&
        (_appLifecycleState == AppLifecycleState.resumed ||
            _appLifecycleState == null);

    if (shouldShowOffline) {
      return OfflineScreen(
        onRetry: () async {
          // Force a connectivity check
          await _connectivityService.forceCheckConnectivity();
        },
      );
    }
    // Return just the child widget without any connectivity indicators
    return widget.child;
  }
}
