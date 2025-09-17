import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/controller/timer_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/hold_timer/hold_timer_screen.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/orders/order_details_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/banner_model.dart';
import '../../model/referral_model.dart';
import '../../utils/ride_utils.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final PageController pageController = PageController();
  var bannerList = <OtherBannerModel>[];
  Timer? _timer;

  @override
  void initState() {
    getBanners();
    super.initState();
  }

  void startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      try {
        if (pageController.hasClients && bannerList.isNotEmpty) {
          // Check if pageController has only one attached PageView
          if (pageController.positions.length != 1) return;

          // Safely get the current page with null check
          final currentPage = pageController.page;
          if (currentPage == null) return;

          int nextPage = currentPage.round() + 1;
          if (nextPage >= bannerList.length) {
            nextPage = 0;
          }
          pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      } catch (e) {
        print('Test banner auto-scroll error: $e');
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void getBanners() async {
    await FireStoreUtils.getBannerOrder().then((value) {
      setState(() {
        bannerList = value;
      });
      startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Container(
            height: Responsive.width(10, context),
            width: Responsive.width(100, context),
            color: AppColors.primary,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                          indicatorColor: AppColors.darkModePrimary,
                          tabs: [
                            Tab(
                                child: Text(
                              "Active Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                            Tab(
                                child: Text(
                              "Completed Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                            Tab(
                                child: Text(
                              "Canceled Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status", whereIn: [
                                      Constant.ridePlaced,
                                      Constant.rideInProgress,
                                      Constant.rideComplete,
                                      Constant.rideActive,
                                      Constant.rideHoldAccepted,
                                      Constant.rideHold,
                                    ])
                                    .where("paymentStatus", isEqualTo: false)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child:
                                              Text("No active rides found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);

                                            return Column(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    Get.to(
                                                        const CompleteOrderScreen(),
                                                        arguments: {
                                                          "orderModel":
                                                              orderModel,
                                                        });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppColors
                                                                .darkContainerBackground
                                                            : AppColors
                                                                .containerBackground,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    10)),
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
                                                                  color: Colors
                                                                      .black
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
                                                            const EdgeInsets
                                                                .all(12.0),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            orderModel.status ==
                                                                        Constant
                                                                            .rideComplete ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideActive
                                                                ? const SizedBox()
                                                                : Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          orderModel
                                                                              .status
                                                                              .toString()
                                                                              .tr,
                                                                          style:
                                                                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        orderModel.status ==
                                                                                Constant.ridePlaced
                                                                            ? Constant.amountShow(amount: double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))
                                                                            : Constant.amountShow(amount: double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                    ],
                                                                  ),
                                                            orderModel.status ==
                                                                        Constant
                                                                            .rideComplete ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideActive
                                                                ? Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            10),
                                                                    child:
                                                                        DriverView(
                                                                      driverId: orderModel
                                                                          .driverId
                                                                          .toString(),
                                                                      amount: orderModel.status ==
                                                                              Constant
                                                                                  .ridePlaced
                                                                          ? double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant
                                                                              .currencyModel!
                                                                              .decimalDigits!)
                                                                          : double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant
                                                                              .currencyModel!
                                                                              .decimalDigits!),
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            LocationView(
                                                              sourceLocation:
                                                                  orderModel
                                                                      .sourceLocationName
                                                                      .toString(),
                                                              destinationLocation:
                                                                  orderModel
                                                                      .destinationLocationName
                                                                      .toString(),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            orderModel.someOneElse !=
                                                                    null
                                                                ? Container(
                                                                    decoration: BoxDecoration(
                                                                        color: themeChange.getThem()
                                                                            ? AppColors
                                                                                .darkGray
                                                                            : AppColors
                                                                                .gray,
                                                                        borderRadius: const BorderRadius
                                                                            .all(
                                                                            Radius.circular(10))),
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                                        child: Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Row(
                                                                                children: [
                                                                                  Text(orderModel.someOneElse!.fullName.toString().tr, style: GoogleFonts.poppins()),
                                                                                  Text(orderModel.someOneElse!.contactNumber.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            InkWell(
                                                                                onTap: () async {
                                                                                  await Share.share(
                                                                                    subject: 'Ride Booked'.tr,
                                                                                    "${'The verification code is'.tr}: ${orderModel.otp}",
                                                                                  );
                                                                                },
                                                                                child: const Icon(Icons.share))
                                                                          ],
                                                                        )),
                                                                  )
                                                                : const SizedBox(),
                                                            if (orderModel
                                                                        .acceptHoldTime !=
                                                                    null &&
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideHoldAccepted)
                                                              HoldTimerWidget(
                                                                acceptHoldTime:
                                                                    orderModel
                                                                        .acceptHoldTime!,
                                                                holdingMinuteCharge:
                                                                    orderModel
                                                                        .service!
                                                                        .holdingMinuteCharge
                                                                        .toString(),
                                                                holdingMinute: orderModel
                                                                    .service!
                                                                    .holdingMinute
                                                                    .toString(),
                                                                orderId:
                                                                    orderModel
                                                                        .id!,
                                                                orderModel:
                                                                    orderModel,
                                                              ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          10),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                    color: themeChange.getThem()
                                                                        ? AppColors
                                                                            .darkGray
                                                                        : AppColors
                                                                            .gray,
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(10))),
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            10),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          child: orderModel.status == Constant.rideInProgress || orderModel.status == Constant.ridePlaced || orderModel.status == Constant.rideComplete
                                                                              ? Text(orderModel.status.toString().tr)
                                                                              : Row(
                                                                                  children: [
                                                                                    Text("OTP".tr, style: GoogleFonts.poppins()),
                                                                                    Text(" : ${orderModel.otp}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                                  ],
                                                                                ),
                                                                        ),
                                                                        Text(
                                                                            Constant().formatTimestamp(orderModel
                                                                                .createdDate),
                                                                            style:
                                                                                GoogleFonts.poppins(fontSize: 12)),
                                                                      ],
                                                                    )),
                                                              ),
                                                            ),
                                                            Visibility(
                                                                visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .ridePlaced,
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      "${"View bids".tr} (${orderModel.acceptedDriverId != null ? orderModel.acceptedDriverId!.length.toString() : "0"})"
                                                                          .tr,
                                                                  btnHeight: 44,
                                                                  onPress:
                                                                      () async {
                                                                    Get.to(
                                                                        const OrderDetailsScreen(),
                                                                        arguments: {
                                                                          "orderModel":
                                                                              orderModel,
                                                                        });
                                                                    // paymentMethodDialog(context, controller, orderModel);
                                                                  },
                                                                )),
                                                            const SizedBox(
                                                                height: 10),
                                                            // loader
                                                            Visibility(
                                                              visible: orderModel
                                                                      .status ==
                                                                  Constant
                                                                      .ridePlaced,
                                                              child:
                                                                  LinearProgressIndicator(),
                                                            ),
                                                            Visibility(
                                                                visible: orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideInProgress ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideHold ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideHoldAccepted,
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      "SOS".tr,
                                                                  btnHeight: 44,
                                                                  onPress:
                                                                      () async {
                                                                    await FireStoreUtils.getSOS(orderModel
                                                                            .id
                                                                            .toString())
                                                                        .then(
                                                                            (value) {
                                                                      if (value !=
                                                                          null) {
                                                                        ShowToastDialog.showToast(
                                                                            "Your request is".tr);
                                                                      } else {
                                                                        SosModel
                                                                            sosModel =
                                                                            SosModel();
                                                                        sosModel.id =
                                                                            Constant.getUuid();
                                                                        sosModel.orderId =
                                                                            orderModel.id;
                                                                        sosModel.status =
                                                                            "Initiated";
                                                                        sosModel.orderType =
                                                                            "city";
                                                                        FireStoreUtils.setSOS(
                                                                            sosModel);
                                                                      }
                                                                    });
                                                                  },
                                                                )),
                                                            const SizedBox(
                                                                height: 10),
                                                            Visibility(
                                                                visible: orderModel
                                                                        .status !=
                                                                    Constant
                                                                        .ridePlaced,
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          UserModel?
                                                                              customer =
                                                                              await FireStoreUtils.getUserProfile(orderModel.userId.toString());
                                                                          DriverUserModel?
                                                                              driver =
                                                                              await FireStoreUtils.getDriver(orderModel.driverId.toString());

                                                                          Get.to(
                                                                              ChatScreens(
                                                                            driverId:
                                                                                driver!.id,
                                                                            customerId:
                                                                                customer!.id,
                                                                            customerName:
                                                                                customer.fullName,
                                                                            customerProfileImage:
                                                                                customer.profilePic,
                                                                            driverName:
                                                                                driver.fullName,
                                                                            driverProfileImage:
                                                                                driver.profilePic,
                                                                            orderId:
                                                                                orderModel.id,
                                                                            token:
                                                                                driver.fcmToken,
                                                                          ));
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              44,
                                                                          decoration: BoxDecoration(
                                                                              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                                              borderRadius: BorderRadius.circular(5)),
                                                                          child: Icon(
                                                                              Icons.chat,
                                                                              color: themeChange.getThem() ? Colors.black : Colors.white),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          if (orderModel.status ==
                                                                              Constant.rideActive) {
                                                                            DriverUserModel?
                                                                                driver =
                                                                                await FireStoreUtils.getDriver(orderModel.driverId.toString());
                                                                            Constant.makePhoneCall("${driver!.countryCode}${driver.phoneNumber}");
                                                                          } else {
                                                                            String
                                                                                phone =
                                                                                await FireStoreUtils.getEmergencyPhoneNumber();
                                                                            Constant.makePhoneCall(phone);
                                                                          }
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              44,
                                                                          decoration: BoxDecoration(
                                                                              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                                              borderRadius: BorderRadius.circular(5)),
                                                                          child: Icon(
                                                                              Icons.call,
                                                                              color: themeChange.getThem() ? Colors.black : Colors.white),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          if (Constant.mapType ==
                                                                              "inappmap") {
                                                                            if (orderModel.status == Constant.rideActive ||
                                                                                orderModel.status == Constant.rideInProgress) {
                                                                              Get.to(const LiveTrackingScreen(), arguments: {
                                                                                "orderModel": orderModel,
                                                                                "type": "orderModel",
                                                                              });
                                                                            }
                                                                          } else {
                                                                            Utils.redirectMap(
                                                                                latitude: orderModel.destinationLocationLAtLng!.latitude!,
                                                                                longLatitude: orderModel.destinationLocationLAtLng!.longitude!,
                                                                                name: orderModel.destinationLocationName.toString());
                                                                          }
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              44,
                                                                          decoration: BoxDecoration(
                                                                              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                                              borderRadius: BorderRadius.circular(5)),
                                                                          child: Icon(
                                                                              Icons.map,
                                                                              color: themeChange.getThem() ? Colors.black : Colors.white),
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                )),
                                                            const SizedBox(
                                                                height: 10),
                                                            Visibility(
                                                                visible: orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideInProgress ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideHold ||
                                                                    orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideHoldAccepted,
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      "whatsapp"
                                                                          .tr,
                                                                  btnHeight: 44,
                                                                  onPress:
                                                                      () async {
                                                                    var phone =
                                                                        await FireStoreUtils
                                                                            .getWhatsAppNumber();
                                                                    String
                                                                        message =
                                                                        "wdniWhatsapp"
                                                                            .tr;
                                                                    final Uri
                                                                        whatsappUrl =
                                                                        Uri.parse(
                                                                            "https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
                                                                    try {
                                                                      await launchUrl(
                                                                        whatsappUrl,
                                                                        mode: LaunchMode
                                                                            .externalApplication,
                                                                      );
                                                                    } catch (e) {
                                                                      log("Error: ${e.toString()}");
                                                                      ShowToastDialog.showToast(
                                                                          "Could not launch"
                                                                              .tr);
                                                                    }
                                                                  },
                                                                )),
                                                            orderModel.status ==
                                                                    Constant
                                                                        .rideInProgress
                                                                ? const SizedBox(
                                                                    height: 10,
                                                                  )
                                                                : SizedBox
                                                                    .shrink(),
                                                            Visibility(
                                                                visible: orderModel
                                                                            .status ==
                                                                        Constant
                                                                            .rideComplete &&
                                                                    (orderModel.paymentStatus ==
                                                                            null ||
                                                                        orderModel.paymentStatus ==
                                                                            false),
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      "Pay".tr,
                                                                  btnHeight: 44,
                                                                  onPress:
                                                                      () async {
                                                                    Get.to(
                                                                        const PaymentOrderScreen(),
                                                                        arguments: {
                                                                          "orderModel":
                                                                              orderModel,
                                                                        });
                                                                    // paymentMethodDialog(context, controller, orderModel);
                                                                  },
                                                                )),

                                                            // cancel button
                                                            Visibility(
                                                              visible: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .ridePlaced ||
                                                                  orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .rideActive,
                                                              child: ButtonThem
                                                                  .buildBorderButton(
                                                                context,
                                                                title:
                                                                    "Cancel".tr,
                                                                color:
                                                                    Colors.red,
                                                                btnHeight: 44,
                                                                onPress: () =>
                                                                    RideUtils()
                                                                        .showCancelationBottomsheet(
                                                                  context,
                                                                  orderModel:
                                                                      orderModel,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (index ==
                                                    snapshot.data!.docs.length -
                                                        1)
                                                  _buildBanner(context),
                                              ],
                                            );
                                          },
                                        );
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status",
                                        isEqualTo: Constant.rideComplete)
                                    .where("paymentStatus", isEqualTo: true)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child: Text(
                                              "No completed rides found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);
                                            return Padding(
                                              padding: const EdgeInsets.all(10),
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
                                                child: InkWell(
                                                    onTap: () {
                                                      Get.to(
                                                          const CompleteOrderScreen(),
                                                          arguments: {
                                                            "orderModel":
                                                                orderModel,
                                                          });
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          DriverView(
                                                            driverId: orderModel
                                                                .driverId
                                                                .toString(),
                                                            amount: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .ridePlaced
                                                                ? double.parse(orderModel
                                                                        .offerRate
                                                                        .toString())
                                                                    .toStringAsFixed(Constant
                                                                        .currencyModel!
                                                                        .decimalDigits!)
                                                                : double.parse(orderModel
                                                                        .finalRate
                                                                        .toString())
                                                                    .toStringAsFixed(Constant
                                                                        .currencyModel!
                                                                        .decimalDigits!),
                                                          ),
                                                          const Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        4),
                                                            child: Divider(
                                                              thickness: 1,
                                                            ),
                                                          ),
                                                          LocationView(
                                                            sourceLocation:
                                                                orderModel
                                                                    .sourceLocationName
                                                                    .toString(),
                                                            destinationLocation:
                                                                orderModel
                                                                    .destinationLocationName
                                                                    .toString(),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        14),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: themeChange.getThem()
                                                                      ? AppColors
                                                                          .darkGray
                                                                      : AppColors
                                                                          .gray,
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .all(
                                                                          Radius.circular(
                                                                              10))),
                                                              child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          12),
                                                                  child: Center(
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            child:
                                                                                Text(orderModel.status.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                                                                        Text(
                                                                            Constant().formatTimestamp(orderModel
                                                                                .createdDate),
                                                                            style:
                                                                                GoogleFonts.poppins()),
                                                                      ],
                                                                    ),
                                                                  )),
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                  child: ButtonThem
                                                                      .buildButton(
                                                                context,
                                                                title:
                                                                    "Review".tr,
                                                                btnHeight: 44,
                                                                onPress:
                                                                    () async {
                                                                  Get.to(
                                                                      const ReviewScreen(),
                                                                      arguments: {
                                                                        "type":
                                                                            "orderModel",
                                                                        "orderModel":
                                                                            orderModel,
                                                                      });
                                                                },
                                                              )),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                              ),
                                            );
                                          });
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status",
                                        isEqualTo: Constant.rideCanceled)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child: Text(
                                              "No completed rides found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);
                                            return Padding(
                                              padding: const EdgeInsets.all(10),
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
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      orderModel.status ==
                                                                  Constant
                                                                      .rideComplete ||
                                                              orderModel
                                                                      .status ==
                                                                  Constant
                                                                      .rideActive
                                                          ? const SizedBox()
                                                          : Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    orderModel
                                                                        .status
                                                                        .toString()
                                                                        .tr,
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  Constant.amountShow(
                                                                      amount: double.parse(orderModel
                                                                              .offerRate
                                                                              .toString())
                                                                          .toStringAsFixed(Constant
                                                                              .currencyModel!
                                                                              .decimalDigits!)),
                                                                  style: GoogleFonts.poppins(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      LocationView(
                                                        sourceLocation: orderModel
                                                            .sourceLocationName
                                                            .toString(),
                                                        destinationLocation:
                                                            orderModel
                                                                .destinationLocationName
                                                                .toString(),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              color: themeChange
                                                                      .getThem()
                                                                  ? AppColors
                                                                      .darkGray
                                                                  : AppColors
                                                                      .gray,
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .all(
                                                                      Radius.circular(
                                                                          10))),
                                                          child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          10),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Expanded(
                                                                      child: Text(orderModel
                                                                          .status
                                                                          .toString()
                                                                          .tr)),
                                                                  Text(
                                                                      Constant().formatTimestamp(
                                                                          orderModel
                                                                              .createdDate),
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              12)),
                                                                ],
                                                              )),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Visibility(
      visible: bannerList.isNotEmpty,
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: PageView.builder(
              padEnds: true,
              allowImplicitScrolling: true,
              itemCount: bannerList.length,
              scrollDirection: Axis.horizontal,
              controller: pageController,
              itemBuilder: (context, index) {
                OtherBannerModel bannerModel = bannerList[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: CachedNetworkImage(
                    imageUrl: bannerModel.image.toString(),
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    color: Colors.black.withOpacity(0.5),
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    fit: BoxFit.cover,
                  ),
                );
              })),
    );
  }
}
