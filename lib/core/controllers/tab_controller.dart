import 'package:get/get.dart';

/// Tab Controller - Manages bottom navigation tab state
class AppTabController extends GetxController {
  final RxInt currentTabIndex = 0.obs;

  void switchTab(int index) {
    if (currentTabIndex.value != index) {
      currentTabIndex.value = index;
    }
  }
}
