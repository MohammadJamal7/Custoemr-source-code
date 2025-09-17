import 'package:get/get.dart';
import 'dart:async';


class TimerController extends GetxController {
  RxInt elapsedSeconds = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}