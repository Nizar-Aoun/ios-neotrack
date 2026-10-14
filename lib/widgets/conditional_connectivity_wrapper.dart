import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';
import 'package:taxi_driver_app/screens/offline_screen.dart';

class ConditionalConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool requireConnection;
  final VoidCallback? onRetry;

  const ConditionalConnectivityWrapper({
    super.key,
    required this.child,
    this.offlineWidget,
    this.requireConnection = true,
    this.onRetry,
  });

  @override
  State<ConditionalConnectivityWrapper> createState() =>
      _ConditionalConnectivityWrapperState();
}

class _ConditionalConnectivityWrapperState
    extends State<ConditionalConnectivityWrapper> with WidgetsBindingObserver {
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
    if (!widget.requireConnection) {
      return widget.child;
    }

    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        // Only show offline screen when app is in foreground (resumed)
        final bool shouldShowOffline = !connectivityService.isConnected &&
            (_appLifecycleState == AppLifecycleState.resumed ||
                _appLifecycleState == null);

        if (shouldShowOffline) {
          if (widget.offlineWidget != null) {
            return widget.offlineWidget!;
          }

          return OfflineScreen(
            onRetry: widget.onRetry ??
                () {
                  connectivityService.checkConnectivity();
                },
          );
        }

        return widget.child;
      },
    );
  }
}
