import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'intercityOrders/intercity_order_screen.dart';
import 'orders/order_screen.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  Stream<bool> mergedOrdersStream() {
    final controller = StreamController<bool>();

    final userId = FireStoreUtils.getCurrentUid();

    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).snapshots();

    final intercityOrdersStream = FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).snapshots();

    StreamSubscription? ordersSub;
    StreamSubscription? intercitySub;

    void checkAndAdd(
        QuerySnapshot ordersSnapshot, QuerySnapshot intercitySnapshot) {
      final hasAnyOrder =
          ordersSnapshot.docs.isNotEmpty || intercitySnapshot.docs.isNotEmpty;
      log("Merged Stream => orders: ${ordersSnapshot.docs.length}, intercity: ${intercitySnapshot.docs.length}");
      controller.add(hasAnyOrder);
    }

    QuerySnapshot? lastOrdersSnapshot;
    QuerySnapshot? lastIntercitySnapshot;

    ordersSub = ordersStream.listen((ordersSnapshot) {
      lastOrdersSnapshot = ordersSnapshot;
      if (lastIntercitySnapshot != null) {
        checkAndAdd(ordersSnapshot, lastIntercitySnapshot!);
      }
    });

    intercitySub = intercityOrdersStream.listen((intercitySnapshot) {
      lastIntercitySnapshot = intercitySnapshot;
      if (lastOrdersSnapshot != null) {
        checkAndAdd(lastOrdersSnapshot!, intercitySnapshot);
      }
    });

    controller.onCancel = () {
      ordersSub?.cancel();
      intercitySub?.cancel();
    };

    return controller.stream;
  }

  late final Stream<bool> _ordersStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _ordersStream = mergedOrdersStream().asBroadcastStream();
    checkActiveOrdersAndNavigate();
  }

  void checkActiveOrdersAndNavigate() async {
    final userId = FireStoreUtils.getCurrentUid();

    final cityOrderSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).get();

    final intercityOrderSnap = await FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).get();

    final hasOrders = cityOrderSnap.docs.isNotEmpty;
    final hasIntercityOrders = intercityOrderSnap.docs.isNotEmpty;
    if (hasOrders) {
      Get.offAll(const OrderScreen(showDrawer: true, initialTabIndex: 0));
    } else if (hasIntercityOrders) {
      Get.offAll(const InterCityOrderScreen());
    }
  }

  // ✅ CRITICAL FIX: Create DashBoardController HERE when dashboard is actually displayed
  final controller = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        drawerEnableOpenDragGesture: false,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: controller.selectedDrawerIndex.value != 0 &&
                  controller.selectedDrawerIndex.value != 6
              ? Text(
                  controller.drawerItems[controller.selectedDrawerIndex.value]
                      .title.tr,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                )
              : const Text(""),
          leading: StreamBuilder<bool>(
            stream: _ordersStream,
            builder: (context, snapshot) {
              if (snapshot.data == false) {
                return Builder(builder: (context) {
                  return InkWell(
                    onTap: () {
                      final scaffoldState = Scaffold.maybeOf(context);
                      final drawer = scaffoldState?.widget.drawer;
                      if (drawer != null && drawer is! SizedBox) {
                        scaffoldState?.openDrawer();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 20, top: 20, bottom: 20),
                      child: SvgPicture.asset('assets/icons/ic_humber.svg'),
                    ),
                  );
                });
              } else {
                return SizedBox();
              }
            },
          ),
          actions: [
            controller.selectedDrawerIndex.value == 0
                ? FutureBuilder<UserModel?>(
                    future: FireStoreUtils.getUserProfile(
                        FireStoreUtils.getCurrentUid()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Constant.loader();
                      } else if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return Icon(Icons.account_circle, size: 36);
                      } else {
                        UserModel driverModel = snapshot.data!;
                        return InkWell(
                          onTap: () {
                            controller.selectedDrawerIndex(8);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              width: 40, // Fixed width
                              height:
                                  50, // Fixed height - same as width for perfect circle
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: driverModel.profilePic ??
                                      Constant.userPlaceHolder,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Constant.loader(),
                                  errorWidget: (context, url, error) =>
                                      Image.network(Constant.userPlaceHolder),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  )
                : controller.selectedDrawerIndex.value == 4
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          overlayColor: WidgetStatePropertyAll(Colors.black),
                          onTap: () async {
                            String message =
                                "السلام عليكم, عندى استفسار بخصوص المحفظة فى تطبيق الراكب";
                            final Uri url = Uri.parse(
                                "https://wa.me/${Constant.phone.toString()}?text=${Uri.encodeComponent(message)}");
                            if (!await launchUrl(url)) {
                              throw Exception(
                                  'Could not launch ${Constant.supportURL.toString()}'
                                      .tr);
                            }
                          },
                          child: SvgPicture.asset('assets/icons/ic_support.svg',
                              width: 24),
                        ),
                      )
                    : Container(),
          ],
        ),
        drawer: StreamBuilder<bool>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return buildAppDrawer(context, controller);
            return snapshot.data!
                ? SizedBox()
                : buildAppDrawer(context, controller);
          },
        ),
        body: WillPopScope(
            onWillPop: controller.onWillPop,
            child: Column(
              children: [
                // _buildBanner(context, controller),
                Expanded(
                  child: controller.getDrawerItemWidget(
                    controller.selectedDrawerIndex.value,
                  ),
                )
              ],
            )),
      ),
    );
  }

  buildAppDrawer(BuildContext context, DashBoardController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    RxList<DrawerItem> drawerItems = [
      DrawerItem('City', "assets/icons/ic_city.svg"),
      DrawerItem('OutStation', "assets/icons/ic_intercity.svg"),
      DrawerItem('Rides', "assets/icons/ic_order.svg"),
      DrawerItem('OutStation Rides', "assets/icons/ic_order.svg"),
      DrawerItem('My Wallet', "assets/icons/ic_wallet.svg"),
      DrawerItem('Settings', "assets/icons/ic_settings.svg"),
      DrawerItem('Referral a friends', "assets/icons/ic_referral.svg"),
      DrawerItem('Inbox', "assets/icons/ic_inbox.svg"),
      DrawerItem('Profile', "assets/icons/ic_profile.svg"),
      DrawerItem('Contact us', "assets/icons/ic_contact_us.svg"),
      DrawerItem('FAQs', "assets/icons/ic_faq.svg"),
      DrawerItem('Log out', "assets/icons/ic_logout.svg"),
    ].obs;
    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];

      // ✅ Define which items should be disabled for guest users
      bool isGuestDisabled = Constant.isGuestUser &&
          [
            'OutStation',
            'Rides',
            'OutStation Rides',
            'My Wallet',
            'Settings',
            'Referral a friends',
            'Inbox',
            'Profile',
          ].contains(d.title);

      drawerOptions.add(InkWell(
        onTap: isGuestDisabled
            ? null
            : () {
                controller.onSelectItem(i);
              },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                color: i == controller.selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : isGuestDisabled
                        ? Colors.grey.withOpacity(
                            0.08) // ✅ Very light disabled background for better readability
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
                      : isGuestDisabled
                          ? Colors.grey.withOpacity(
                              0.4) // ✅ Subtle disabled icon color for better visibility
                          : themeChange.getThem()
                              ? Colors.white
                              : AppColors.drawerIcon,
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  d.title.tr,
                  style: GoogleFonts.poppins(
                      color: i == controller.selectedDrawerIndex.value
                          ? themeChange.getThem()
                              ? Colors.black
                              : Colors.white
                          : isGuestDisabled
                              ? Colors.grey.withOpacity(
                                  0.6) // ✅ Better disabled text color for readability
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
            child: _buildDrawerHeader(context),
          ),
          Column(children: drawerOptions),
        ],
      ),
    );
  }

  /// ✅ CRITICAL FIX: Build drawer header with proper guest user support
  Widget _buildDrawerHeader(BuildContext context) {
    // ✅ Handle guest users
    if (Constant.isGuestUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.network(
              Constant.userPlaceHolder,
              height: Responsive.width(20, context),
              width: Responsive.width(20, context),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "مستخدم ضيف", // ✅ Force Arabic for guest user
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "guest@wdni.net",
              style: GoogleFonts.poppins(),
            ),
          )
        ],
      );
    }

    // ✅ Handle logged-in users
    final currentUid = FireStoreUtils.getCurrentUid();
    if (currentUid.isEmpty) {
      // ✅ Fallback for non-logged-in users
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle, size: 60),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Please Login".tr,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getUserProfile(currentUid),
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
                    imageUrl:
                        driverModel.profilePic ?? Constant.userPlaceHolder,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Constant.loader(),
                    errorWidget: (context, url, error) =>
                        Image.network(Constant.userPlaceHolder),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(driverModel.fullName.toString(),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
    );
  }
}
