import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';
import 'package:taxi_driver_app/screens/offline_screen.dart';
import 'package:taxi_driver_app/widgets/connectivity_banner.dart';
import 'package:taxi_driver_app/widgets/connectivity_debug_widget.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showOfflineScreen;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showOfflineScreen = true,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with WidgetsBindingObserver {
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState = WidgetsBinding.instance.lifecycleState;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        // Show loading indicator while initializing
        if (!connectivityService.isInitialized) {
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
        final bool shouldShowOffline = !connectivityService.isConnected &&
            widget.showOfflineScreen &&
            (_appLifecycleState == AppLifecycleState.resumed ||
                _appLifecycleState == null);

        if (shouldShowOffline) {
          return OfflineScreen(
            onRetry: () async {
              // Force a connectivity check
              await connectivityService.forceCheckConnectivity();
            },
          );
        }
        return Stack(
          children: [
            widget.child,
            const ConnectivityBanner(),
            if (kDebugMode) const ConnectivityDebugWidget(),
          ],
        );
      },
    );
  }
}
