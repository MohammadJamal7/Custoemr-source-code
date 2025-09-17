import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

class HoldTimerWidget extends StatelessWidget {
  final Timestamp acceptHoldTime;
  final String holdingMinuteCharge;
  final String holdingMinute;
  final String orderId;
  final OrderModel orderModel;

  const HoldTimerWidget({
    super.key,
    required this.acceptHoldTime,
    required this.holdingMinuteCharge,
    required this.holdingMinute,
    required this.orderId,
    required this.orderModel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Calculating...".tr);
        }
        DateTime now = DateTime.now();
        Duration elapsedTime = now.difference(acceptHoldTime.toDate());
        int elapsedMinutes = elapsedTime.inMinutes;
        int elapsedSeconds = elapsedTime.inSeconds % 60;

        int chargePerInterval = int.parse(holdingMinuteCharge);
        int holdingInterval = int.parse(holdingMinute);

        int intervals = elapsedMinutes ~/ holdingInterval;
        int extraTime = elapsedMinutes % holdingInterval;

        int totalCharges = intervals * chargePerInterval;
        if (extraTime > 0 || elapsedSeconds > 0) {
          totalCharges += chargePerInterval;
        }

        return Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                "${"Hold Time:".tr} $elapsedMinutes ${"min".tr} $elapsedSeconds ${"sec".tr}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                "${"Hold Charges:".tr} \$${isNightCharge() ? totalCharges * double.parse(orderModel.service!.nightCharge.toString()) : totalCharges} ($holdingMinute Minute)",
                textAlign: TextAlign.start,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  isNightCharge() {
    DateTime currentTime = DateTime.now();
    DateTime currentDate = DateTime.now();

    RxString startNightTime = "".obs;
    RxString endNightTime = "".obs;

    DateTime startNightTimeString = DateTime.now();
    DateTime endNightTimeString = DateTime.now();

    startNightTime.value = formatTime(orderModel.service!.startNightTime);
    endNightTime.value = formatTime(orderModel.service!.endNightTime);

    List<String> startParts = startNightTime.split(':');
    List<String> endParts = endNightTime.split(':');

    startNightTimeString = DateTime(currentDate.year, currentDate.month, currentDate.day, int.parse(startParts[0]), int.parse(startParts[1]));
    endNightTimeString = DateTime(currentDate.year, currentDate.month, currentDate.day, int.parse(endParts[0]), int.parse(endParts[1]));

    if (currentTime.isAfter(startNightTimeString) && currentTime.isBefore(endNightTimeString)) {
      return true;
    }
    return false;
  }

  String formatTime(String? time) {
    if (time == null || !time.contains(":")) {
      return "00:00";
    }
    List<String> parts = time.split(':');
    if (parts.length != 2) return "00:00";
    return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
  }
}
