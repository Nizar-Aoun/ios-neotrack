import 'package:get/get.dart';
import 'package:taxi_driver_app/features/wallet/provider/ride_details_controller.dart';
import 'package:taxi_driver_app/models/ride.dart';

/// Binding for ride details screen
class RideDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Get arguments passed via Get.toNamed
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final ride = args['ride'] as Ride?;
    final baseUrl = args['baseUrl'] as String? ?? '';

    if (ride == null) {
      throw ArgumentError('Ride is required for RideDetailsBinding');
    }

    // Register controller with dependencies
    Get.lazyPut<RideDetailsController>(
      () => RideDetailsController(
        ride: ride,
        baseUrl: baseUrl,
      ),
    );
  }
}
