import 'package:get/get.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/wallet/data/wallet_repository.dart';

/// GetX binding for wallet feature
class WalletBinding extends Bindings {
  final String baseUrl;

  WalletBinding({required this.baseUrl});

  @override
  void dependencies() {
    // Register repository
    final repository = WalletRepository(baseUrl: baseUrl);

    // Register controller
    Get.lazyPut<WalletController>(
      () => WalletController(repository),
    );
  }
}

