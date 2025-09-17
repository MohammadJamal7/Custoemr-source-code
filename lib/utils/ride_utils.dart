import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

import '../model/cancellation_reason_model.dart';
import '../widget/custom_dialog.dart';
// ✅ REMOVED: No longer needed since we don't navigate to dashboard
// import 'package:customer/ui/dashboard_screen.dart';
// import '../controller/dash_board_controller.dart';

class RideUtils {
  showCancelationBottomsheet(
    BuildContext context, {
    InterCityOrderModel? interCityOrderModel,
    OrderModel? orderModel,
    bool doubleBack = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context_) {
        return CustomDangerDialog(
          title: 'Cancel'.tr,
          desc: "Are you sure you want to cancel this ride?".tr,
          onPositivePressed: () async {
            // Handle positive action
            Navigator.of(context_).pop();
            // show cancellation reason bottomsheet
            showModalBottomSheet(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15)),
              ),
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              builder: (context1) {
                final themeChange = Provider.of<DarkThemeProvider>(context1);
                return FractionallySizedBox(
                  heightFactor: 0.75,
                  child: StatefulBuilder(
                    builder: (context1, setState) {
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: Responsive.height(90, context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 10,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Why are you cancelling this trip?".tr,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "Select a reason for cancellation from the list to help us improve your experience on the platform."
                                      .tr,
                                  style: GoogleFonts.poppins(),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _cancellationList(context1, themeChange,
                                    orderModel: orderModel,
                                    interCityOrderModel: interCityOrderModel,
                                    doubleBack: doubleBack),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          onNegativePressed: () {
            // Handle negative action
            Navigator.of(context_).pop();
          },
          positiveText: "Confirm".tr,
          negativeText: 'No'.tr,
        );
      },
    );
  }

  Widget _cancellationList(
    BuildContext context,
    DarkThemeProvider themeChange, {
    InterCityOrderModel? interCityOrderModel,
    OrderModel? orderModel,
    required bool doubleBack,
  }) {
    return FutureBuilder<List<CancellationReasonModel>>(
      future: FireStoreUtils.getCancellationReasons(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Constant.loader();
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text(
                snapshot.error.toString(),
              );
            } else {
              List<CancellationReasonModel> reasons = snapshot.requireData;

              return ListView.builder(
                itemCount: reasons.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  CancellationReasonModel reasonModel = reasons[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: InkWell(
                      onTap: () {
                        if (orderModel != null) {
                          onConfirmCancellation(
                              context, orderModel, reasonModel, doubleBack);
                        } else if (interCityOrderModel != null) {
                          onConfirmInterCityCancellation(context,
                              interCityOrderModel, reasonModel, doubleBack);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          border: Border.all(
                            color: AppColors.textFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Constant.localizationName(
                                    reasonModel.name,
                                  ),
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                              Radio(
                                value: false,
                                groupValue: true,
                                activeColor: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                                onChanged: (value) {
                                  if (orderModel != null) {
                                    onConfirmCancellation(context, orderModel,
                                        reasonModel, doubleBack);
                                  } else if (interCityOrderModel != null) {
                                    onConfirmInterCityCancellation(
                                        context,
                                        interCityOrderModel,
                                        reasonModel,
                                        doubleBack);
                                  }
                                  //Get.offAll(const DashBoardScreen());
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          default:
            return Text('Error'.tr);
        }
      },
    );
  }

  Future<void> onConfirmCancellation(
      BuildContext context,
      OrderModel orderModel,
      CancellationReasonModel cancellationReason,
      bool doubleBack) async {
    Navigator.pop(context);
    if (doubleBack) {
      Get.back();
    }
    // current driverId
    final String? driverId = orderModel.driverId;

    // update order
    List<dynamic> acceptDriverId = [];
    orderModel.status = Constant.rideCanceled;
    orderModel.acceptedDriverId = acceptDriverId;
    orderModel.driverId = '';
    orderModel.cancellationReasonId = cancellationReason.id!;
    orderModel.cancellationReason = Constant.localizationName(
      cancellationReason.name,
    );
    await FireStoreUtils.setOrder(orderModel);

    // send cancellation alert to driver
    if (driverId != null && driverId.isNotEmpty) {
      await FireStoreUtils.getDriver(driverId).then((value) async {
        if (value == null ||
            value.fcmToken == null ||
            value.fcmToken!.isEmpty) {
          return;
        }
        await SendNotification.sendOneNotification(
          token: value.fcmToken.toString(),
          title: 'Ride Canceled'.tr,
          body:
              'The passenger has canceled the ride. No action is required from your end.'
                  .tr,
          payload: {},
        );
      });
    }

    // ✅ REMOVED: No longer navigate to dashboard - keep user on current page
    // Previously: Get.offAll(() => const DashBoardScreen());
    // Previously: Get.find<DashBoardController>().selectedDrawerIndex.value = 2;
  }

  Future<void> onConfirmInterCityCancellation(
      BuildContext context,
      InterCityOrderModel orderModel,
      CancellationReasonModel cancellationReason,
      bool doubleBack) async {
    Navigator.pop(context);
    if (doubleBack) {
      Get.back();
    }
    // current driverId
    final String? driverId = orderModel.driverId;

    // update order
    List<dynamic> acceptDriverId = [];
    orderModel.status = Constant.rideCanceled;
    orderModel.acceptedDriverId = acceptDriverId;
    orderModel.driverId = '';
    orderModel.cancellationReasonId = cancellationReason.id!;
    orderModel.cancellationReason = Constant.localizationName(
      cancellationReason.name,
    );
    await FireStoreUtils.setInterCityOrder(orderModel);
    
    // Ensure user state is correctly maintained
    final currentUid = FireStoreUtils.getCurrentUid();
    Constant.isGuestUser = (currentUid == "Guest");

    // send cancellation alert to driver
    if (driverId != null && driverId.isNotEmpty) {
      await FireStoreUtils.getDriver(driverId).then((value) async {
        if (value == null ||
            value.fcmToken == null ||
            value.fcmToken!.isEmpty) {
          return;
        }
        await SendNotification.sendOneNotification(
          token: value.fcmToken.toString(),
          title: 'Ride Canceled'.tr,
          body:
              'The passenger has canceled the ride. No action is required from your end.'
                  .tr,
          payload: {},
        );
      });
    }

    // ✅ REMOVED: No longer navigate to dashboard - keep user on current page
    // Previously: Get.offAll(() => const DashBoardScreen());
    // Previously: Get.find<DashBoardController>().selectedDrawerIndex.value = 2;
  }
}
