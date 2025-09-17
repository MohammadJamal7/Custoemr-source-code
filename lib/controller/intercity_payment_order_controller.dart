import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_order_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IntercityPaymentOrderController extends GetxController {
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    getPaymentData();
    super.onInit();
  }

  Rx<InterCityOrderModel> orderModel = InterCityOrderModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    update();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;

  RxString selectedPaymentMethod = "".obs;

  completeOrder() async {
    ShowToastDialog.showLoader("Please wait".tr);
    orderModel.value.paymentStatus = true;
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: calculateAmount().toString(),
        createdDate: Timestamp.now(),
        paymentType: "wallet",
        transactionId: orderModel.value.id,
        userId: orderModel.value.driverId.toString(),
        orderType: "intercity",
        userType: "driver",
        note: "Ride amount credited".tr);

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(
            amount: calculateAmount().toString(),
            driverId: orderModel.value.driverId.toString());
      }
    });

    WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
        id: Constant.getUuid(),
        amount:
            "-${Constant.calculateOrderAdminCommission(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.value.toString())).toString(), adminCommission: orderModel.value.adminCommission)}",
        createdDate: Timestamp.now(),
        paymentType: "wallet",
        transactionId: orderModel.value.id,
        orderType: "intercity",
        userType: "driver",
        userId: orderModel.value.driverId.toString(),
        note: "Admin commission debited");

    await FireStoreUtils.setWalletTransaction(adminCommissionWallet)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(
            amount:
                "-${Constant.calculateOrderAdminCommission(amount: (double.parse(orderModel.value.finalRate.toString()) - double.parse(couponAmount.toString())).toString())}",
            driverId: orderModel.value.driverId.toString());
      }
    });

    await FireStoreUtils.getIntercityFirstOrderOrNOt(orderModel.value)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateIntercityReferralAmount(orderModel.value);
      }
    });

    if (driverUserModel.value.fcmToken != null) {
      Map<String, dynamic> playLoad = <String, dynamic>{
        "type": "intercity_order_payment_complete",
        "orderId": orderModel.value.id
      };

      await SendNotification.sendOneNotification(
          token: driverUserModel.value.fcmToken.toString(),
          title: 'Payment Received'.tr,
          body:
              '${userModel.value.fullName}  ${"has paid".tr} ${Constant.amountShow(amount: calculateAmount().toString())} ${"for the completed ride.Check your earnings for details.".tr}',
          payload: playLoad);
    }

    await FireStoreUtils.setInterCityOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Ride Complete Successfully'.tr);

        // ✅ BULLETPROOF DIRECT NAVIGATION: Navigate immediately after payment confirmation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(
              "🚀 DIRECT NAVIGATION: Intercity payment confirmed, going to completed rides tab");
          Get.offAll(() => const InterCityOrderScreen(initialTabIndex: 1));
        });
      }
    });
  }

  completeCashOrder() async {
    log("here");
    ShowToastDialog.showLoader("Please wait".tr);

    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    await SendNotification.sendOneNotification(
        token: driverUserModel.value.fcmToken.toString(),
        title: 'Payment changed'.tr,
        body: '${userModel.value.fullName} ${'has changed payment method'.tr}',
        payload: {});

    await FireStoreUtils.setInterCityOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Payment method update successfully".tr);

        // ✅ FIXED: For cash payments, DON'T navigate immediately
        // Wait for driver confirmation (paymentStatus = true) via global listeners
        print(
            "💰 INTERCITY CASH PAYMENT: Request sent to driver, waiting for confirmation...");
      }
    });
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  double calculateAmount() {
    // Base = finalRate - coupon, clamped to >= 0
    final double finalRate =
        double.tryParse(orderModel.value.finalRate.toString()) ?? 0.0;
    final double coupon =
        double.tryParse(couponAmount.value.toString()) ?? 0.0;

    double base = finalRate - coupon;
    if (base < 0) base = 0;

    // Calculate tax on the clamped base
    double tax = 0.0;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        tax += Constant().calculateTax(
            amount: base.toString(), taxModel: element);
      }
    }

    final total = base + tax;
    return double.parse(
        total.toStringAsFixed(Constant.currencyModel!.decimalDigits!));
  }

  getPaymentData() async {
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
        selectedPaymentMethod.value = orderModel.value.paymentType.toString();
      }
    });

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    await FireStoreUtils.getDriver(orderModel.value.driverId.toString())
        .then((value) {
      if (value != null) {
        driverUserModel.value = value;
      }
    });
    isLoading.value = false;
    update();
  }
}
