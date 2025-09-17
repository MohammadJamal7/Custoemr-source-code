import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/payment_order_controller.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/payment/createRazorPayOrderModel.dart';
import 'package:customer/payment/rozorpayConroller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/coupon_screen/coupon_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../themes/button_them.dart';
import '../auth_screen/login_screen.dart';
import '../dashboard_screen.dart';
import '../orders/order_screen.dart';

class DrawerItem {
  final String title;
  final String icon;

  DrawerItem(this.title, this.icon);
}

class PaymentOrderScreen extends StatelessWidget {
  const PaymentOrderScreen({super.key});

  // Drawer navigation method
  void _onSelectDrawerItem(int index) async {
    // Close drawer first
    Get.back();

    // Add a small delay to ensure drawer is closed before navigation
    await Future.delayed(const Duration(milliseconds: 200));

    if (index == 11) {
      // Logout
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      // Navigate to appropriate screen using a safer approach
      try {
        switch (index) {
          case 0:
            Get.offAll(() => const DashBoardScreen());
            break;
          case 1:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 1;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 2:
            Get.offAll(
                () => const OrderScreen(showDrawer: true, initialTabIndex: 0));
            break;
          case 3:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 3;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 4:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 4;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 5:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 5;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 6:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 6;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 7:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 7;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 8:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 8;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 9:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 9;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
          case 10:
            Get.offAll(() => const DashBoardScreen());
            await Future.delayed(const Duration(milliseconds: 100));
            // ✅ CRITICAL FIX: Safely access DashBoardController
            try {
              Get.find<DashBoardController>().selectedDrawerIndex.value = 10;
            } catch (e) {
              print(
                  'DashBoardController not found, will be created by DashBoardScreen');
            }
            break;
        }
      } catch (e) {
        print('Navigation error: $e');
        // Fallback navigation
        Get.offAll(() => const DashBoardScreen());
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    // ✅ CRITICAL FIX: Safely get DashBoardController or create a temporary one
    DashBoardController controller;
    try {
      controller = Get.find<DashBoardController>();
    } catch (e) {
      // If controller doesn't exist, create a temporary one
      controller = Get.put(DashBoardController());
    }

    RxList<DrawerItem> drawerItems = [
      DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
      DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
      DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
      DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
      DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
      DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
      DrawerItem('Referral a friends'.tr, "assets/icons/ic_referral.svg"),
      DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
      DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
      DrawerItem('Contact us'.tr, "assets/icons/ic_contact_us.svg"),
      DrawerItem('FAQs'.tr, "assets/icons/ic_faq.svg"),
      DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
    ].obs;

    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(InkWell(
        onTap: () {
          _onSelectDrawerItem(i);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                color: i == controller.selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SvgPicture.asset(
                  d.icon,
                  width: 20,
                  color: i == controller.selectedDrawerIndex.value
                      ? themeChange.getThem()
                          ? Colors.black
                          : Colors.white
                      : themeChange.getThem()
                          ? Colors.white
                          : AppColors.drawerIcon,
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  d.title,
                  style: GoogleFonts.poppins(
                      color: i == controller.selectedDrawerIndex.value
                          ? themeChange.getThem()
                              ? Colors.black
                              : Colors.white
                          : themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ),
      ));
    }

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        children: [
          DrawerHeader(
            child: FutureBuilder<UserModel?>(
              future:
                  FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Constant.loader();
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Icon(Icons.account_circle, size: 36);
                } else {
                  UserModel driverModel = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            height: Responsive.width(20, context),
                            width: Responsive.width(20, context),
                            imageUrl: driverModel.profilePic ??
                                Constant.userPlaceHolder,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(),
                            errorWidget: (context, url, error) =>
                                Image.network(Constant.userPlaceHolder),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(driverModel.fullName.toString(),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            driverModel.email.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          Column(children: drawerOptions),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PaymentOrderController>(
        init: PaymentOrderController(),
        builder: (controller) {
          return Scaffold(
              drawerEnableOpenDragGesture: false,
              drawer: _buildDrawer(context),
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                title: Text("Ride Details".tr),
                leading: Builder(
                  builder: (context) {
                    return InkWell(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 20, top: 20, bottom: 20),
                        child: SvgPicture.asset('assets/icons/ic_humber.svg'),
                      ),
                    );
                  },
                ),
              ),
              body: Column(
                children: [
                  Container(
                    height: Responsive.width(10, context),
                    width: Responsive.width(100, context),
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: controller.isLoading.value
                          ? Constant.loader()
                          : Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection(CollectionName.orders)
                                        .doc(controller.orderModel.value.id)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Something went wrong'.tr));
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Constant.loader();
                                      }
                                      OrderModel orderModel =
                                          OrderModel.fromJson(
                                              snapshot.data!.data()!);

                                      // 🔍 DEBUG: Print all relevant values
                                      print(
                                          "🔄 STREAMBUILDER CALLED - ConnectionState: ${snapshot.connectionState}");
                                      print(
                                          "🔍 DEBUG: paymentStatus = ${orderModel.paymentStatus}");
                                      print(
                                          "🔍 DEBUG: status = ${orderModel.status}");
                                      print(
                                          "🔍 DEBUG: paymentType = ${orderModel.paymentType}");
                                      print(
                                          "🔍 DEBUG: rideComplete = ${Constant.rideComplete}");
                                      print(
                                          "🔍 DEBUG: orderId = ${orderModel.id}");

                                      // Check if payment is confirmed by driver and navigate to completed rides tab
                                      // For cash payments, wait for driver confirmation
                                      // For online payments, payment is confirmed immediately

                                      // Auto-navigate to completed rides tab when payment is confirmed
                                      if (orderModel.paymentStatus == true &&
                                          orderModel.status ==
                                              Constant.rideComplete) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          print(
                                              "🚀 NAVIGATING TO COMPLETED RIDES TAB");
                                          Get.offAll(() => const OrderScreen(
                                              showDrawer: true,
                                              initialTabIndex: 1));
                                        });
                                      }

                                      return SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DriverView(
                                                  driverId: controller
                                                      .orderModel.value.driverId
                                                      .toString(),
                                                  amount: controller.orderModel
                                                      .value.finalRate
                                                      .toString()),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 5),
                                                child: Divider(thickness: 1),
                                              ),
                                              Text(
                                                "Vehicle Details".tr,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              FutureBuilder<DriverUserModel?>(
                                                  future:
                                                      FireStoreUtils.getDriver(
                                                          controller.orderModel
                                                              .value.driverId
                                                              .toString()),
                                                  builder: (context, snapshot) {
                                                    switch (snapshot
                                                        .connectionState) {
                                                      case ConnectionState
                                                            .waiting:
                                                        return Constant
                                                            .loader();
                                                      case ConnectionState.done:
                                                        if (snapshot.hasError) {
                                                          return Text(snapshot
                                                              .error
                                                              .toString());
                                                        } else {
                                                          DriverUserModel
                                                              driverModel =
                                                              snapshot.data!;
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
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
                                                                  color: themeChange.getThem()
                                                                      ? AppColors
                                                                          .darkContainerBorder
                                                                      : AppColors
                                                                          .containerBorder,
                                                                  width: 0.5),
                                                              boxShadow:
                                                                  themeChange
                                                                          .getThem()
                                                                      ? null
                                                                      : [
                                                                          BoxShadow(
                                                                            color:
                                                                                Colors.black.withOpacity(0.10),
                                                                            blurRadius:
                                                                                5,
                                                                            offset:
                                                                                const Offset(0, 4), // changes position of shadow
                                                                          ),
                                                                        ],
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          10),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      SvgPicture
                                                                          .asset(
                                                                        'assets/icons/ic_car.svg',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Text(
                                                                        Constant.localizationName(driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleType),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      SvgPicture
                                                                          .asset(
                                                                        'assets/icons/ic_color.svg',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Text(
                                                                        driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleColor
                                                                            .toString(),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        'assets/icons/ic_number.png',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Text(
                                                                        driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleNumber
                                                                            .toString(),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      default:
                                                        return Text('Error'.tr);
                                                    }
                                                  }),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              Text(
                                                "Pickup and drop-off locations"
                                                    .tr,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Container(
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
                                                  child: LocationView(
                                                    sourceLocation: controller
                                                        .orderModel
                                                        .value
                                                        .sourceLocationName
                                                        .toString(),
                                                    destinationLocation: controller
                                                        .orderModel
                                                        .value
                                                        .destinationLocationName
                                                        .toString(),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors.darkGray
                                                          : AppColors.gray,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  10))),
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 12),
                                                      child: Center(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                                child: Text(
                                                                    orderModel
                                                                        .status
                                                                        .toString()
                                                                        .tr,
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w500))),
                                                            Text(
                                                                Constant().formatTimestamp(
                                                                    orderModel
                                                                        .createdDate),
                                                                style: GoogleFonts
                                                                    .poppins()),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ),
                                              Container(
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
                                                  child: InkWell(
                                                    onTap: () {
                                                      Get.to(const CouponScreen())!
                                                          .then((value) {
                                                        if (value != null) {
                                                          controller.selectedCouponModel.value = value;

                                                          // Determine base fare for discount calculations
                                                          final double baseFare = controller.subTotal.value == 0.0
                                                              ? double.tryParse(controller.orderModel.value.finalRate.toString()) ?? 0.0
                                                              : controller.subTotal.value;

                                                          double discount = 0.0;
                                                          if (controller.selectedCouponModel.value.type == "fix") {
                                                            discount = double.tryParse(
                                                                  controller.selectedCouponModel.value.amount.toString(),
                                                                ) ??
                                                                0.0;
                                                          } else {
                                                            final double percent = double.tryParse(
                                                                  controller.selectedCouponModel.value.amount.toString(),
                                                                ) ??
                                                                0.0;
                                                            discount = (percent * baseFare) / 100.0;
                                                          }

                                                          // Clamp discount to not exceed base fare
                                                          if (discount > baseFare) discount = baseFare;

                                                          controller.couponAmount.value = discount
                                                              .toStringAsFixed(Constant.currencyModel!.decimalDigits!);

                                                          // Recompute totals and refresh UI
                                                          controller.calculateAmount();
                                                          controller.update();
                                                        }
                                                      });
                                                    },
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Image.asset(
                                                          'assets/icons/ic_offer.png',
                                                          width: 50,
                                                          height: 50,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "Redeem Coupon"
                                                                    .tr,
                                                                style: GoogleFonts.poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700),
                                                              ),
                                                              Text(
                                                                "Add coupon code"
                                                                    .tr,
                                                                style: GoogleFonts
                                                                    .poppins(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SvgPicture.asset(
                                                          "assets/icons/ic_add_offer.svg",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              Container(
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
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Booking summary"
                                                                  .tr,
                                                              style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                          Container(
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
                                                                            5))),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          2),
                                                              child: Text(
                                                                controller
                                                                            .orderModel
                                                                            .value
                                                                            .paymentType ==
                                                                        "Wallet"
                                                                    ? "Wallet"
                                                                        .tr
                                                                    : "Cash".tr,
                                                                style: GoogleFonts.poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                        thickness: 1,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Ride Amount".tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: orderModel
                                                                    .finalRate
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                        thickness: 1,
                                                      ),
                                                      controller
                                                                  .orderModel
                                                                  .value
                                                                  .taxList ==
                                                              null
                                                          ? const SizedBox()
                                                          : ListView.builder(
                                                              itemCount:
                                                                  controller
                                                                      .orderModel
                                                                      .value
                                                                      .taxList!
                                                                      .length,
                                                              shrinkWrap: true,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                TaxModel
                                                                    taxModel =
                                                                    controller
                                                                        .orderModel
                                                                        .value
                                                                        .taxList![index];
                                                                return Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            "${taxModel.title.toString()} (${taxModel.type == "fix" ? Constant.amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                                                            style:
                                                                                GoogleFonts.poppins(color: AppColors.subTitleColor),
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          Constant.amountShow(
                                                                              amount: Constant().calculateTax(amount: (double.parse(controller.subTotal.value.toString()) - double.parse(controller.couponAmount.value.toString())).toString(), taxModel: taxModel).toString()),
                                                                          style:
                                                                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const Divider(
                                                                      thickness:
                                                                          1,
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Discount".tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "(-${controller.couponAmount.value == "0.0" ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.couponAmount.value)})",
                                                                style: GoogleFonts.poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                        thickness: 1,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Payable amount"
                                                                  .tr,
                                                              style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .total
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              ButtonThem.buildButton(
                                                context,
                                                title: "Pay".tr,
                                                onPress: () {
                                                  paymentMethodDialog(context,
                                                      controller, orderModel);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                    ),
                  ),
                ],
              ));
        });
  }

  paymentMethodDialog(BuildContext context, PaymentOrderController controller,
      OrderModel orderModel) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);

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
                            Expanded(
                                child: Center(
                                    child: Text(
                              "Select Payment Method".tr,
                              style: GoogleFonts.poppins(),
                            ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Visibility(
                                  visible: controller
                                          .paymentModel.value.cash!.enable ==
                                      true,
                                  child: Obx(
                                    () => Column(
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            controller.selectedPaymentMethod
                                                    .value =
                                                controller.paymentModel.value
                                                    .cash!.name
                                                    .toString();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                              border: Border.all(
                                                  color: controller
                                                              .selectedPaymentMethod
                                                              .value ==
                                                          controller
                                                              .paymentModel
                                                              .value
                                                              .cash!
                                                              .name
                                                              .toString()
                                                      ? themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary
                                                      : AppColors
                                                          .textFieldBorder,
                                                  width: 1),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: 40,
                                                    width: 80,
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: AppColors
                                                                .lightGray,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5))),
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Icon(Icons.money,
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                                  .paymentModel
                                                                  .value
                                                                  .cash!
                                                                  .name
                                                                  .toString() ==
                                                              "Cash"
                                                          ? "Cash".tr
                                                          : "Wallet".tr,
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                  ),
                                                  Radio(
                                                    value: controller
                                                        .paymentModel
                                                        .value
                                                        .cash!
                                                        .name
                                                        .toString(),
                                                    groupValue: controller
                                                        .selectedPaymentMethod
                                                        .value,
                                                    activeColor:
                                                        themeChange.getThem()
                                                            ? AppColors
                                                                .darkModePrimary
                                                            : AppColors.primary,
                                                    onChanged: (value) {
                                                      controller
                                                              .selectedPaymentMethod
                                                              .value =
                                                          controller
                                                              .paymentModel
                                                              .value
                                                              .cash!
                                                              .name
                                                              .toString();
                                                    },
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: controller
                                          .paymentModel.value.wallet!.enable ==
                                      true,
                                  child: Obx(
                                    () => Column(
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            controller.selectedPaymentMethod
                                                    .value =
                                                controller.paymentModel.value
                                                    .wallet!.name
                                                    .toString();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                              border: Border.all(
                                                  color: controller
                                                              .selectedPaymentMethod
                                                              .value ==
                                                          controller
                                                              .paymentModel
                                                              .value
                                                              .wallet!
                                                              .name
                                                              .toString()
                                                      ? themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary
                                                      : AppColors
                                                          .textFieldBorder,
                                                  width: 1),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: 40,
                                                    width: 80,
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: AppColors
                                                                .lightGray,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: SvgPicture.asset(
                                                          'assets/icons/ic_wallet.svg',
                                                          color: AppColors
                                                              .primary),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      controller.paymentModel
                                                          .value.wallet!.name
                                                          .toString()
                                                          .tr,
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                  ),
                                                  Text(
                                                      "(${Constant.amountShow(amount: controller.userModel.value.walletAmount.toString())})",
                                                      style: GoogleFonts.poppins(
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppColors
                                                                  .darkModePrimary
                                                              : AppColors
                                                                  .primary)),
                                                  Radio(
                                                    value: controller
                                                        .paymentModel
                                                        .value
                                                        .wallet!
                                                        .name
                                                        .toString(),
                                                    groupValue: controller
                                                        .selectedPaymentMethod
                                                        .value,
                                                    activeColor:
                                                        themeChange.getThem()
                                                            ? AppColors
                                                                .darkModePrimary
                                                            : AppColors.primary,
                                                    onChanged: (value) {
                                                      controller
                                                              .selectedPaymentMethod
                                                              .value =
                                                          controller
                                                              .paymentModel
                                                              .value
                                                              .wallet!
                                                              .name
                                                              .toString();
                                                    },
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Pay".tr,
                        onPress: () async {
                          Get.back();
                          if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.strip!.name) {
                            controller.stripeMakePayment(
                                amount: controller
                                    .calculateAmount()
                                    .toStringAsFixed(Constant
                                        .currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.paypal!.name) {
                            // controller.paypalPaymentSheet(controller.calculateAmount().toStringAsFixed(Constant.currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.payStack!.name) {
                            controller.payStackPayment(controller
                                .calculateAmount()
                                .toStringAsFixed(
                                    Constant.currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.mercadoPago!.name) {
                            controller.mercadoPagoMakePayment(
                                context: context,
                                amount: controller
                                    .calculateAmount()
                                    .toStringAsFixed(Constant
                                        .currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.flutterWave!.name) {
                            controller.flutterWaveInitiatePayment(
                                context: context,
                                amount: controller
                                    .calculateAmount()
                                    .toStringAsFixed(Constant
                                        .currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.payfast!.name) {
                            controller.payFastPayment(
                                context: context,
                                amount: controller
                                    .calculateAmount()
                                    .toStringAsFixed(Constant
                                        .currencyModel!.decimalDigits!));
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.paytm!.name) {
                            controller.getPaytmCheckSum(context,
                                amount: controller.calculateAmount());
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.razorpay!.name) {
                            RazorPayController()
                                .createOrderRazorPay(
                                    amount:
                                        controller.calculateAmount().toInt(),
                                    razorpayModel:
                                        controller.paymentModel.value.razorpay)
                                .then((value) {
                              if (value == null) {
                                Get.back();
                                ShowToastDialog.showToast(
                                    "Something went wrong, please contact admin."
                                        .tr
                                        .tr);
                              } else {
                                CreateRazorPayOrderModel result = value;
                                controller.openCheckout(
                                    amount:
                                        controller.calculateAmount().toInt(),
                                    orderId: result.id);
                              }
                            });
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.wallet!.name) {
                            if (double.parse(controller
                                    .userModel.value.walletAmount
                                    .toString()) >=
                                controller.calculateAmount()) {
                              WalletTransactionModel transactionModel =
                                  WalletTransactionModel(
                                      id: Constant.getUuid(),
                                      amount:
                                          "-${controller.calculateAmount().toString()}",
                                      createdDate: Timestamp.now(),
                                      paymentType: controller
                                          .selectedPaymentMethod.value,
                                      transactionId: orderModel.id,
                                      note: "Ride amount debit".tr,
                                      orderType: "city",
                                      userType: "customer",
                                      userId: FireStoreUtils.getCurrentUid());
                              await FireStoreUtils.setWalletTransaction(
                                      transactionModel)
                                  .then((value) async {
                                if (value == true) {
                                  await FireStoreUtils.updateUserWallet(
                                          amount:
                                              "-${controller.calculateAmount().toString()}")
                                      .then((value) {
                                    Get.back();
                                    controller.completeOrder();
                                  });
                                }
                              });
                              Get.back();
                            } else {
                              ShowToastDialog.showToast(
                                  "Wallet Amount Insufficient".tr);
                            }
                          } else if (controller.selectedPaymentMethod.value ==
                              controller.paymentModel.value.cash!.name) {
                            controller.completeCashOrder();
                            Get.back();
                          }
                        },
                      ),
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
}
