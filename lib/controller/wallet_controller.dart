import 'dart:io';

import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../constant/constant.dart';
import '../constant/show_toast_dialog.dart';

class WalletController extends GetxController {
  Rx<TextEditingController> amountController = TextEditingController().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxString selectedPaymentMethod = "".obs;
  Rxn<XFile> imagePrice = Rxn<XFile>();
  RxBool isLoading = false.obs;
  RxList transactionList = <WalletTransactionModel>[].obs;
  bool viewWallet = false;

  @override
  void onInit() {
    // TODO: implement onInit
    viewWalletCharge();
    getTraction();
    getUser();
    super.onInit();
  }

  void viewWalletCharge() async {
    viewWallet = await FireStoreUtils.viewWallet();
    update();
  }

  void setCharge() async {
    if (imagePrice.value == null) {
      ShowToastDialog.showToast("Select Image".tr);
    } else if (amountController.value.text.isEmpty) {
      ShowToastDialog.showToast("Enter Amount".tr);
    } else {
      File imageFile = File(imagePrice.value!.path);
      FireStoreUtils.setChargeTransaction(
        imageFile,
        Constant.getAmountShow(amount: amountController.value.text),
      ).then((value) {
        imagePrice.value = null;
        amountController.value.clear();
        getTraction();
        Get.back();
      });
    }
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
      isLoading.value = false;
    });
  }

  getTraction() async {
    await FireStoreUtils.getWalletTransaction().then((value) {
      if (value != null) {
        transactionList.value = value;
      }
      isLoading.value = false;
    });
  }
}
