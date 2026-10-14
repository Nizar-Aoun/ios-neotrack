import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';

class AppLifecycleConnectivity extends StatefulWidget {
  final Widget child;

  const AppLifecycleConnectivity({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleConnectivity> createState() => _AppLifecycleConnectivityState();
}

class _AppLifecycleConnectivityState extends State<AppLifecycleConnectivity>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Check connectivity when app becomes active
      final connectivityService = Provider.of<ConnectivityService>(
        context, 
        listen: false
      );
      
      // Force immediate check
      connectivityService.forceCheckConnectivity();
      
      // Also trigger a quick check after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          connectivityService.forceCheckConnectivity();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 
