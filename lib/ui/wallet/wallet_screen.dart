import 'dart:io';

import 'package:customer/constant/constant.dart';
import 'package:customer/controller/wallet_controller.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/intercityOrders/intercity_complete_order_screen.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constant/show_toast_dialog.dart';
import '../../themes/button_them.dart';
import '../../themes/text_field_them.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<WalletController>(
        init: WalletController(),
        builder: (controller) {
          return Scaffold(
            body: controller.isLoading.value
                ? Constant.loader()
                : Column(
                    children: [
                      Container(
                        height: Responsive.width(28, context),
                        width: Responsive.width(100, context),
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Balance".tr,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      Constant.amountShow(
                                          amount: controller
                                              .userModel.value.walletAmount
                                              .toString()),
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 24),
                                    ),
                                  ],
                                ),
                              ),
                                if(controller.viewWallet)
                                Transform.translate(
                                  offset: const Offset(0, -22),
                                  child: MaterialButton(
                                    onPressed: () async {
                                      if (!await FireStoreUtils
                                          .hasChargeWalletPending()) {
                                        paymentMethodDialog(
                                            context, controller);
                                      } else {
                                        ShowToastDialog.showToast(
                                            "WaitAdminApproval".tr);
                                      }
                                    },
                                    height: 40,
                                    elevation: 0.5,
                                    minWidth: 0.40,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    color: themeChange.getThem()
                                        ? AppColors.darkModePrimary
                                        : Colors.white,
                                    child: Text(
                                      "Topup Wallet".tr.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -22),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.background,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25))),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: controller.transactionList.isEmpty
                                  ? Center(
                                      child: Text("No transaction found".tr))
                                  : ListView.builder(
                                      itemCount:
                                          controller.transactionList.length,
                                      itemBuilder: (context, index) {
                                        WalletTransactionModel
                                            walletTransactionModel =
                                            controller.transactionList[index];
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: InkWell(
                                            onTap: () async {
                                              if (walletTransactionModel
                                                      .orderType ==
                                                  "city") {
                                                await FireStoreUtils.getOrder(
                                                        walletTransactionModel
                                                            .transactionId
                                                            .toString())
                                                    .then((value) {
                                                  if (value != null) {
                                                    OrderModel orderModel =
                                                        value;
                                                    Get.to(
                                                        const CompleteOrderScreen(),
                                                        arguments: {
                                                          "orderModel":
                                                              orderModel,
                                                        });
                                                  }
                                                });
                                              } else if (walletTransactionModel
                                                      .orderType ==
                                                  "intercity") {
                                                await FireStoreUtils
                                                        .getInterCityOrder(
                                                            walletTransactionModel
                                                                .transactionId
                                                                .toString())
                                                    .then((value) {
                                                  if (value != null) {
                                                    InterCityOrderModel
                                                        orderModel = value;
                                                    Get.to(
                                                        const IntercityCompleteOrderScreen(),
                                                        arguments: {
                                                          "orderModel":
                                                              orderModel,
                                                        });
                                                  }
                                                });
                                              } else {
                                                showTransactionDetails(
                                                    context: context,
                                                    walletTransactionModel:
                                                        walletTransactionModel);
                                              }
                                            },
                                            child: Container(
                                                decoration: BoxDecoration(
                                                  color: themeChange.getThem()
                                                      ? AppColors
                                                          .darkContainerBackground
                                                      : AppColors
                                                          .containerBackground,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(10)),
                                                  border: Border.all(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors
                                                              .darkContainerBorder
                                                          : AppColors
                                                              .containerBorder,
                                                      width: 0.5),
                                                  boxShadow: themeChange
                                                          .getThem()
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.10),
                                                            blurRadius: 5,
                                                            offset: const Offset(
                                                                0,
                                                                4), // changes position of shadow
                                                          ),
                                                        ],
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                          decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .lightGray,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50)),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12.0),
                                                            child: SvgPicture
                                                                .asset(
                                                              'assets/icons/ic_wallet.svg',
                                                              width: 24,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          )),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    Constant.dateFormatTimestamp(
                                                                        walletTransactionModel
                                                                            .createdDate),
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  "${Constant.IsNegative(double.parse(walletTransactionModel.amount.toString())) ? "(-" : "+"}${Constant.amountShow(amount: walletTransactionModel.amount.toString().replaceAll("-", ""))}${Constant.IsNegative(double.parse(walletTransactionModel.amount.toString())) ? ")" : ""}",
                                                                  style: GoogleFonts.poppins(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Constant.IsNegative(double.parse(walletTransactionModel
                                                                              .amount
                                                                              .toString()))
                                                                          ? Colors
                                                                              .red
                                                                          : Colors
                                                                              .green),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    walletTransactionModel.note.toString() ==
                                                                            "Referral Amount"
                                                                        ? "Referral Amount"
                                                                            .tr


                                                                        :

                                                                    walletTransactionModel
                                                                        .note
                                                                        .toString() ==
                                                                        "Charge Wallet"
                                                                        ? "Charge Wallet"
                                                                        .tr


                                                                        : walletTransactionModel
                                                                            .note
                                                                            .toString(),
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w400),
                                                                  ),
                                                                ),
                                                                if(walletTransactionModel.note != "Charge Wallet")
                                                                Text(walletTransactionModel
                                                                    .paymentType
                                                                    .toString()
                                                                    .tr),
                                                                if(walletTransactionModel.note == "Charge Wallet")
                                                                  Text(
                                                                    walletTransactionModel.state == "pending"  ? "Pending".tr :
                                                                    walletTransactionModel.state == "accepted"  ? "Approved".tr : "Rejected".tr,
                                                                    style: TextStyle(
                                                                      color: walletTransactionModel.state == "pending"  ? Colors.amber :
                                                                      walletTransactionModel.state == "accepted"  ? Colors.green : Colors.red,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        });
  }

  showTransactionDetails(
      {required BuildContext context,
      required WalletTransactionModel walletTransactionModel}) {
    return showModalBottomSheet(
        elevation: 5,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            final themeChange = Provider.of<DarkThemeProvider>(context);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        "Transaction Details".tr,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBorder
                                : AppColors.containerBorder,
                            width: 0.5),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 4), // changes position of shadow
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Transaction ID".tr,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "#${walletTransactionModel.transactionId!.toUpperCase().tr}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBorder
                                : AppColors.containerBorder,
                            width: 0.5),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 4), // changes position of shadow
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Payment Details".tr,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        Opacity(
                                          opacity: 0.7,
                                          child: Text(
                                            "Pay Via".tr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          walletTransactionModel.paymentType
                                              .toString()
                                              .tr,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Divider(),
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Date in UTC Format".tr,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Opacity(
                                        opacity: 0.7,
                                        child: Text(
                                          DateFormat('KK:mm:ss a, dd MMM yyyy')
                                              .format(walletTransactionModel
                                                  .createdDate!
                                                  .toDate())
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  _buildSteps(String text){
    return Text(text, style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500));
  }

  paymentMethodDialog(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(30), topLeft: Radius.circular(30))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: StatefulBuilder(builder: (context1, setState) {
              return Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: const Icon(Icons.arrow_back_ios)),
                            // Expanded(
                            //     child: Center(
                            //         child: Text(
                            //   "Topup Wallet".tr,
                            //   style: GoogleFonts.poppins(),
                            // ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Add Topup Amount".tr,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFieldThem.buildTextFiled(
                                  context,
                                  hintText: 'Enter Amount'.tr,
                                  keyBoardType: TextInputType.number,
                                  controller: controller.amountController.value,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9*]')),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    parcelImageWidget(context, controller),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "خطوات شحن المحفظة :",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _buildSteps("١- الإيداع  في احدى الحسابات التالية."),
                                _buildSteps("٢-رفع  إشعار الإيداع وتسجيل البيانات المطلوبة."),
                                _buildSteps("٣-الإنتظار حتى الانتهاء من المراجعة."),
                                _buildSteps("وأرقام الحسابات البنكية :"),
                                _buildSteps("حساب بنك الكريمي 3004591096"),
                                _buildSteps("حساب بنك القطيبي 435491446"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(context, title: "Topup".tr,
                          onPress: () {
                        controller.setCharge();
                      }),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  parcelImageWidget(BuildContext context, WalletController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            Obx(() {
              if (controller.imagePrice.value != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(
                                File(controller.imagePrice.value!.path)),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            controller.imagePrice.value = null;
                          },
                          child: const Icon(
                            Icons.remove_circle,
                            size: 30,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox();
              }
            }),
            Obx(() => controller.imagePrice.value == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        _onCameraClick(context, controller);
                      },
                      child: Image.asset(
                        'assets/images/parcel_add_image.png',
                        height: 100,
                        width: 100,
                      ),
                    ),
                  )
                : const SizedBox()),
          ],
        ),
      ),
    );
  }

  _onCameraClick(BuildContext context, WalletController controller) {
    final action = CupertinoActionSheet(
      // message: Text(
      //   'Add your parcel image.'.tr,
      //   style: const TextStyle(fontSize: 15.0),
      // ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () async {
            Get.back();
            await ImagePicker()
                .pickImage(source: ImageSource.gallery)
                .then((value) {
              if (value != null) {
                controller.imagePrice.value = value;
              }
            });
          },
          child: Text('Choose image from gallery'.tr),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Get.back();
            final XFile? photo =
                await ImagePicker().pickImage(source: ImageSource.camera);
            if (photo != null) {
              controller.imagePrice.value = photo;
            }
          },
          child: Text('Take a picture'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Get.back();
        },
        child: Text('Cancel'.tr),
      ),
    );

    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
