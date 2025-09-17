import 'dart:async';
import 'package:customer/ui/update_screen/update_screen.dart';
import 'package:get/get.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/utils/utils.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // ✅ CRITICAL FIX: Don't request location here!
    // Location will be requested when DashBoardScreen is actually displayed
    _proceedToNextScreen();
  }

  void _proceedToNextScreen() async {
    // ✅ Simple 3-second splash delay, no location fetching
    Timer(const Duration(seconds: 3), () => redirectScreen());
  }

  redirectScreen() async {
    Get.offAll(const UpdateScreen());
  }
}
