import 'dart:async';
import 'dart:developer';
import '../../utils/timer_state_manager.dart';
import '../../utils/global_timer_service.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/configs/color_config.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/home_screens/ride_details_screen.dart';
import 'package:customer/widget/live_map_widget.dart';
import 'package:customer/ui/hold_timer/hold_timer_screen.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/ui/orders/inline_offer_widget.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/banner_model.dart';
import '../../utils/ride_utils.dart';
import '../auth_screen/login_screen.dart';
import '../dashboard_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderScreen extends StatefulWidget {
  final bool showDrawer;
  final int initialTabIndex;

  const OrderScreen(
      {super.key, this.showDrawer = true, this.initialTabIndex = 0});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final PageController pageController = PageController();
  var bannerList = <OtherBannerModel>[];
  Timer? _timer;
  final Map<String, Widget> _mapWidgetCache = {};
  Timer? _cacheCleanupTimer;
  DateTime? _lastMapCreation;
  // Background watcher for auto-expiring offers
  bool _offerSweepScheduled = false;
  Timer? _offerExpiryTimer;
  StreamSubscription<QuerySnapshot>? _activeOrdersSub;
  // Cache of latest active orders for offer expiry processing
  List<OrderModel> _latestActiveOrders = [];
  // Track last seen accepted drivers per order to detect changes
  final Map<String?, Set<String>> _lastAcceptedByOrder = {};

  // Track which order IDs have their offers expanded/visible
  final Set<String> _expandedOrderIds = {};

  // Drawer functionality
  RxInt selectedDrawerIndex = 2.obs; // Set to 2 since we're on Rides
  RxList<dynamic> drawerItems = [
    {'title': 'City'.tr, 'icon': "assets/icons/ic_city.svg"},
    {'title': 'OutStation'.tr, 'icon': "assets/icons/ic_intercity.svg"},
    {'title': 'Rides'.tr, 'icon': "assets/icons/ic_order.svg"},
    {'title': 'OutStation Rides'.tr, 'icon': "assets/icons/ic_order.svg"},
    {'title': 'My Wallet'.tr, 'icon': "assets/icons/ic_wallet.svg"},
    {'title': 'Settings'.tr, 'icon': "assets/icons/ic_settings.svg"},
    {'title': 'Referral a friends'.tr, 'icon': "assets/icons/ic_referral.svg"},
    {'title': 'Inbox'.tr, 'icon': "assets/icons/ic_inbox.svg"},
    {'title': 'Profile'.tr, 'icon': "assets/icons/ic_profile.svg"},
    {'title': 'Contact us'.tr, 'icon': "assets/icons/ic_contact_us.svg"},
    {'title': 'FAQs'.tr, 'icon': "assets/icons/ic_faq.svg"},
    {'title': 'Log out'.tr, 'icon': "assets/icons/ic_logout.svg"},
  ].obs;

  @override
  void initState() {
    getBanners();
    super.initState();

    // Clear any previously expanded orders
    _expandedOrderIds.clear();

    // Start background watcher to auto-expire offers
    _startOfferExpiryWatcher();
  }

  void startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      try {
        if (pageController.hasClients && bannerList.isNotEmpty && mounted) {
          // Check if pageController is still valid and has only one attached PageView
          if (!pageController.hasClients ||
              pageController.positions.length != 1) return;

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
        print('Banner auto-scroll error: $e');
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    try {
      _timer?.cancel();
      _cacheCleanupTimer?.cancel();
      _offerExpiryTimer?.cancel();
      _activeOrdersSub?.cancel();
      _mapWidgetCache.clear();
      _lastMapCreation = null;
      if (pageController.hasClients) {
        pageController.dispose();
      }
    } catch (e) {
      print('OrderScreen dispose error: $e');
    }
    super.dispose();
  }

  void getBanners() async {
    await FireStoreUtils.getBannerOrder().then((value) {
      if (mounted) {
        setState(() {
          bannerList = value;
        });
        startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      drawer: widget.showDrawer ? buildAppDrawer(context) : null,
      appBar: widget.showDrawer
          ? AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: Builder(
                builder: (context) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(CollectionName.orders)
                        .where("userId",
                            isEqualTo: FireStoreUtils.getCurrentUid())
                        .where("status", whereIn: [
                          Constant.ridePlaced,
                          Constant.rideInProgress,
                          Constant.rideActive,
                          Constant.rideHoldAccepted,
                          Constant.rideHold,
                        ])
                        .where("paymentStatus", isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Show drawer icon only when there are no active rides
                      bool shouldShowDrawer = true;

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        // Hide drawer when there are any active rides
                        shouldShowDrawer = false;

                        print(
                            '🔍 Drawer Icon Debug: hasActiveRides=true, shouldShowDrawer=$shouldShowDrawer, activeRidesCount=${snapshot.data!.docs.length}');
                      }

                      return shouldShowDrawer
                          ? InkWell(
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 10, right: 20, top: 20, bottom: 20),
                                child: SvgPicture.asset(
                                    'assets/icons/ic_humber.svg'),
                              ),
                            )
                          : const SizedBox.shrink(); // Hide drawer icon
                    },
                  );
                },
              ),
              title: Text(
                "Rides".tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          if (widget.showDrawer)
            Container(
              height: Responsive.width(10, context),
              width: Responsive.width(100, context),
              color: AppColors.primary,
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DefaultTabController(
                    length: 3,
                    initialIndex: widget.initialTabIndex,
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
                            physics:
                                const ClampingScrollPhysics(), // Prevent interference with PageView
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

                                  // Add a small delay to prevent rapid rebuilds
                                  if (snapshot.connectionState ==
                                      ConnectionState.active) {
                                    // Ensure we have stable data before rebuilding
                                    if (snapshot.data == null) {
                                      return Constant.loader();
                                    }
                                  }

                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child:
                                              Text("No active rides found".tr),
                                        )
                                      : SingleChildScrollView(
                                          key: ValueKey(
                                              'active_rides_${snapshot.data!.docs.length}'),
                                          child: Column(
                                            children: List.generate(
                                              snapshot.data!.docs.length,
                                              (index) {
                                                OrderModel orderModel =
                                                    OrderModel.fromJson(snapshot
                                                            .data!.docs[index]
                                                            .data()
                                                        as Map<String,
                                                            dynamic>);

                                                // Auto-expand orders that have offers
                                                if (orderModel.status == Constant.ridePlaced && 
                                                    orderModel.acceptedDriverId != null && 
                                                    orderModel.acceptedDriverId!.isNotEmpty &&
                                                    orderModel.id != null) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    if (!_expandedOrderIds.contains(orderModel.id!)) {
                                                      setState(() {
                                                        _expandedOrderIds.add(orderModel.id!);
                                                      });
                                                    }
                                                  });
                                                }

                                                Widget? mapWidget;
                                                final srcLat = orderModel
                                                    .sourceLocationLAtLng
                                                    ?.latitude;
                                                final srcLng = orderModel
                                                    .sourceLocationLAtLng
                                                    ?.longitude;
                                                final dstLat = orderModel
                                                    .destinationLocationLAtLng
                                                    ?.latitude;
                                                final dstLng = orderModel
                                                    .destinationLocationLAtLng
                                                    ?.longitude;

                                                // Progressive map logic based on ride status
                                                bool hasDriver =
                                                    orderModel.driverId !=
                                                            null &&
                                                        orderModel.driverId!
                                                            .isNotEmpty;
                                                bool isRideActive =
                                                    orderModel.status ==
                                                        Constant.rideActive;
                                                bool isRideInProgress =
                                                    orderModel.status ==
                                                        Constant.rideInProgress;

                                                // Check if driver has actually picked up the passenger
                                                // If ride is active but driver hasn't reached pickup yet, treat as in progress
                                                bool driverHasPickedUp = false;
                                                if (isRideActive && hasDriver) {
                                                  // You might need to add a field to track if pickup is completed
                                                  // For now, we'll assume if status is rideActive, driver has picked up
                                                  driverHasPickedUp = true;
                                                }

                                                print(
                                                    '🔍 Ride Status Analysis: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, driverHasPickedUp=$driverHasPickedUp');

                                                print(
                                                    '🔍 Order Debug: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, hasDriver=$hasDriver');
                                                bool isDriverAccepted =
                                                    orderModel.status ==
                                                            Constant
                                                                .ridePlaced &&
                                                        hasDriver;

                                                if (srcLat == null ||
                                                    srcLng == null) {
                                                  print(
                                                      '🔍 Error: Source coordinates missing for order ${orderModel.id}');
                                                  return SizedBox(
                                                    height: Responsive.height(
                                                        28, context),
                                                    child: Center(
                                                        child: Text(
                                                            'Invalid source location'
                                                                .tr)),
                                                  );
                                                }

                                                if (isRideActive &&
                                                    (dstLat == null ||
                                                        dstLng == null)) {
                                                  print(
                                                      '🔍 Error: Destination coordinates missing for order ${orderModel.id} in rideActive');
                                                  return SizedBox(
                                                    height: Responsive.height(
                                                        28, context),
                                                    child: Center(
                                                        child: Text(
                                                            'Invalid destination location'
                                                                .tr)),
                                                  );
                                                }

                                                print(
                                                    '🔍 Order Debug: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, hasDriver=$hasDriver, srcLat=$srcLat, srcLng=$srcLng, dstLat=$dstLat, dstLng=$dstLng, driverId=${orderModel.driverId}');
                                                print(
                                                    '📍 Pickup Location: LatLng($srcLat, $srcLng)');
                                                print(
                                                    '📍 Dropoff Location: LatLng($dstLat, $dstLng)');

                                                if (hasDriver) {
                                                  // Use a FutureBuilder to fetch driver location and rotation
                                                  mapWidget = FutureBuilder<
                                                      DriverUserModel?>(
                                                    future: FireStoreUtils
                                                        .getDriver(orderModel
                                                            .driverId!),
                                                    builder: (context,
                                                        driverSnapshot) {
                                                      if (driverSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return SizedBox(
                                                          height:
                                                              Responsive.height(
                                                                  28, context),
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        );
                                                      }
                                                      if (!driverSnapshot
                                                              .hasData ||
                                                          driverSnapshot.data ==
                                                              null ||
                                                          driverSnapshot
                                                              .hasError) {
                                                        // fallback to pickup location map
                                                        return SizedBox(
                                                          height:
                                                              Responsive.height(
                                                                  28, context),
                                                          width:
                                                              double.infinity,
                                                          child:
                                                              _createCachedMapWidget(
                                                            cacheKey:
                                                                'no_driver_${orderModel.id}',
                                                            source: LatLng(
                                                                srcLat, srcLng),
                                                            showRoute: false,
                                                          ),
                                                        );
                                                      }
                                                      final driver =
                                                          driverSnapshot.data!;
                                                      final driverLoc =
                                                          driver.location;
                                                      print(
                                                          '🚗 Driver Location: LatLng(${driverLoc?.latitude}, ${driverLoc?.longitude})');
                                                      if (driverLoc == null) {
                                                        // fallback to pickup location map
                                                        return SizedBox(
                                                          height:
                                                              Responsive.height(
                                                                  28, context),
                                                          width:
                                                              double.infinity,
                                                          child:
                                                              _createCachedMapWidget(
                                                            cacheKey:
                                                                'pickup_fallback_${orderModel.id}',
                                                            source: LatLng(
                                                                srcLat, srcLng),
                                                            showRoute: false,
                                                          ),
                                                        );
                                                      }
                                                      // Determine if driver should go to pickup or dropoff
                                                      bool shouldGoToPickup =
                                                          isRideActive; // Driver accepted, heading to pickup
                                                      bool shouldGoToDropoff =
                                                          isRideInProgress; // Ride started, heading to dropoff

                                                      final calculatedDestination =
                                                          shouldGoToPickup
                                                              ? LatLng(srcLat,
                                                                  srcLng) // Route to pickup
                                                              : (shouldGoToDropoff &&
                                                                      dstLat !=
                                                                          null &&
                                                                      dstLng !=
                                                                          null
                                                                  ? LatLng(
                                                                      dstLat,
                                                                      dstLng) // Route to dropoff
                                                                  : null);

                                                      print(
                                                          '🎯 Route Decision: shouldGoToPickup=$shouldGoToPickup, shouldGoToDropoff=$shouldGoToDropoff');

                                                      print(
                                                          '🔍 RouteMapWidget Debug: isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, isDriverAccepted=$isDriverAccepted');
                                                      print(
                                                          '🎯 Calculated Destination: $calculatedDestination');
                                                      print(
                                                          '📍 Expected Route: ${shouldGoToPickup ? "Driver → Pickup" : "Driver → Dropoff"}');
                                                      return SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                28, context),
                                                        child:
                                                            _createCachedMapWidget(
                                                          cacheKey:
                                                              'live_tracking_${orderModel.id}',
                                                          source: LatLng(
                                                              srcLat, srcLng),
                                                          destination:
                                                              calculatedDestination,
                                                          driverLocation: LatLng(
                                                              driverLoc
                                                                  .latitude!,
                                                              driverLoc
                                                                  .longitude!),
                                                          driverId: orderModel
                                                              .driverId,
                                                          carRotation:
                                                              driver.rotation ??
                                                                  0.0,
                                                          showLiveTracking:
                                                              isRideActive ||
                                                                  isRideInProgress,
                                                          showRoute:
                                                              isDriverAccepted ||
                                                                  isRideInProgress ||
                                                                  isRideActive,
                                                          isRideActive:
                                                              isRideActive,
                                                          isRideInProgress:
                                                              isRideInProgress,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  // No driver yet - show pickup location with animated marker
                                                  mapWidget = Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 10),
                                                    child: SizedBox(
                                                      height: Responsive.height(
                                                          28, context),
                                                      width: double.infinity,
                                                      child:
                                                          _createCachedMapWidget(
                                                        cacheKey:
                                                            'no_driver_${orderModel.id}',
                                                        source: LatLng(
                                                            srcLat, srcLng),
                                                        showRoute: false,
                                                        showLiveTracking: false,
                                                      ),
                                                    ),
                                                  );
                                                }

                                                // Seed timers and sweep expirations in background (once per build)
                                                _scheduleOfferPersistenceTasks(
                                                    snapshot.data!.docs
                                                        .map((d) =>
                                                            OrderModel.fromJson(
                                                                d.data() as Map<
                                                                    String,
                                                                    dynamic>))
                                                        .toList());

                                                return Column(
                                                  children: [
                                                    mapWidget, // Map always at the top
                                                    InkWell(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Container(
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
                                                                    .all(Radius
                                                                        .circular(
                                                                            10)),
                                                            border: Border.all(
                                                                color: themeChange
                                                                        .getThem()
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
                                                                          color: Colors
                                                                              .black
                                                                              .withOpacity(0.10),
                                                                          blurRadius:
                                                                              5,
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
                                                                        orderModel.status ==
                                                                            Constant.rideActive
                                                                    ? const SizedBox()
                                                                    : Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              orderModel.status.toString().tr,
                                                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            orderModel.status == Constant.ridePlaced
                                                                                ? Constant.amountShow(amount: (orderModel.offerRate == null || orderModel.offerRate.toString() == 'null' || orderModel.offerRate.toString().isEmpty) ? '0.0' : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))
                                                                                : Constant.amountShow(amount: (orderModel.finalRate == null || orderModel.finalRate.toString() == 'null' || orderModel.finalRate.toString().isEmpty) ? '0.0' : double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
                                                                            style:
                                                                                GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                orderModel.status ==
                                                                            Constant
                                                                                .rideComplete ||
                                                                        orderModel.status ==
                                                                            Constant.rideActive
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
                                                                          amount: orderModel.status == Constant.ridePlaced
                                                                              ? (orderModel.offerRate == null || orderModel.offerRate.toString() == 'null' || orderModel.offerRate.toString().isEmpty ? '0.0' : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))
                                                                              : (orderModel.finalRate == null || orderModel.finalRate.toString() == 'null' || orderModel.finalRate.toString().isEmpty ? '0.0' : double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
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
                                                                                ? AppColors.darkGray
                                                                                : AppColors.gray,
                                                                            borderRadius: const BorderRadius.all(Radius.circular(10))),
                                                                        child: Padding(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                                            child: Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                                                    holdingMinuteCharge: orderModel
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
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          10),
                                                                  child:
                                                                      Container(
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
                                                                              child: orderModel.status == Constant.rideInProgress || orderModel.status == Constant.ridePlaced || orderModel.status == Constant.rideComplete
                                                                                  ? Text(orderModel.status.toString().tr)
                                                                                  : Row(
                                                                                      children: [
                                                                                        Text("OTP".tr, style: GoogleFonts.poppins()),
                                                                                        Text(" : ${orderModel.otp}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                                      ],
                                                                                    ),
                                                                            ),
                                                                            Text(Constant().formatTimestamp(orderModel.createdDate),
                                                                                style: GoogleFonts.poppins(fontSize: 12)),
                                                                          ],
                                                                        )),
                                                                  ),
                                                                ),
                                                                Visibility(
                                                                  visible: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .ridePlaced,
                                                                  child: StreamBuilder<
                                                                      DocumentSnapshot>(
                                                                    stream: FirebaseFirestore
                                                                        .instance
                                                                        .collection(CollectionName
                                                                            .orders)
                                                                        .doc(orderModel
                                                                            .id)
                                                                        .snapshots(),
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      if (!snapshot
                                                                          .hasData) {
                                                                        return const SizedBox
                                                                            .shrink();
                                                                      }

                                                                      final data = snapshot
                                                                              .data!
                                                                              .data()
                                                                          as Map<
                                                                              String,
                                                                              dynamic>?;
                                                                      if (data ==
                                                                          null)
                                                                        return const SizedBox
                                                                            .shrink();

                                                                      // Get the current list of accepted drivers
                                                                      final acceptedDriverIds =
                                                                          data['acceptedDriverId'] as List<dynamic>? ??
                                                                              [];

                                                                      // Process any expired timers for this order using GlobalTimerService
                                                                      // This ensures the counter is accurate even if the background timer hasn't run yet
                                                                      Future.microtask(
                                                                          () async {
                                                                        final timerService =
                                                                            GlobalTimerService.instance;
                                                                        final toRemove =
                                                                            <String>[];

                                                                        for (final d
                                                                            in List<String>.from(acceptedDriverIds.map((e) =>
                                                                                e.toString()))) {
                                                                          final key =
                                                                              'offer_${orderModel.id}_${d}';

                                                                          // Register timer if not already active
                                                                          if (!timerService
                                                                              .isTimerActive(key)) {
                                                                            await timerService.registerTimer(
                                                                              key: key,
                                                                              durationSeconds: 60,
                                                                              restoreFromStorage: true,
                                                                            );
                                                                          }

                                                                          // Check if timer has expired
                                                                          final remaining =
                                                                              timerService.getRemainingSeconds(key);
                                                                          if (remaining <=
                                                                              0) {
                                                                            toRemove.add(d);
                                                                            await timerService.removeTimer(key);
                                                                          }
                                                                        }

                                                                        // If any timers have expired, update Firestore
                                                                        if (toRemove
                                                                            .isNotEmpty) {
                                                                          final updatedAccepted =
                                                                              List<dynamic>.from(acceptedDriverIds);
                                                                          updatedAccepted.removeWhere((e) =>
                                                                              toRemove.contains(e.toString()));

                                                                          final updatedRejected =
                                                                              List<dynamic>.from(data['rejectedDriverId'] ?? []);
                                                                          for (final id
                                                                              in toRemove) {
                                                                            if (!updatedRejected.contains(id)) {
                                                                              updatedRejected.add(id);
                                                                            }
                                                                          }

                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection(CollectionName
                                                                                  .orders)
                                                                              .doc(orderModel
                                                                                  .id)
                                                                              .update({
                                                                            'acceptedDriverId':
                                                                                updatedAccepted,
                                                                            'rejectedDriverId':
                                                                                updatedRejected
                                                                          });
                                                                        }
                                                                      });

                                                                      final count =
                                                                          acceptedDriverIds
                                                                              .length;

                                                                      // Show offers count button if any
                                                                      return count >
                                                                              0
                                                                          ? InkWell(
                                                                              onTap: () {
                                                                                // Toggle the visibility of offers for this order
                                                                                setState(() {
                                                                                  // Make sure orderModel.id is not null before using it
                                                                                  final orderId = orderModel.id ?? '';
                                                                                  if (!_expandedOrderIds.contains(orderId)) {
                                                                                    _expandedOrderIds.add(orderId);
                                                                                  } else {
                                                                                    _expandedOrderIds.remove(orderId);
                                                                                  }
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                                decoration: BoxDecoration(
                                                                                  color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.1) : AppColors.containerBackground,
                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                  border: Border.all(
                                                                                    color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.3) : AppColors.containerBorder,
                                                                                  ),
                                                                                ),
                                                                                child: Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Text(
                                                                                      count == 1 ? 'offer_received'.tr.replaceAll('{count}', count.toString()) : 'offers_received'.tr.replaceAll('{count}', count.toString()),
                                                                                      style: GoogleFonts.poppins(
                                                                                        fontWeight: FontWeight.w500,
                                                                                        color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(width: 4),
                                                                                    Icon(
                                                                                      _expandedOrderIds.contains(orderModel.id ?? '') ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                                                      color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                                                                                      size: 18,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            )
                                                                          : const SizedBox
                                                                              .shrink();
                                                                    },
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 10),
                                                                // Show offers inline if any exist and this order is expanded
                                                                Visibility(
                                                                  visible: orderModel
                                                                              .status ==
                                                                          Constant
                                                                              .ridePlaced &&
                                                                      _expandedOrderIds.contains(orderModel
                                                                              .id ??
                                                                          '') &&
                                                                      _expandedOrderIds
                                                                          .isNotEmpty,
                                                                  child: StreamBuilder<
                                                                      DocumentSnapshot>(
                                                                    key: ValueKey(
                                                                        'order-stream-${orderModel.id}-${DateTime.now().millisecondsSinceEpoch}'),
                                                                    stream: FirebaseFirestore
                                                                        .instance
                                                                        .collection(CollectionName
                                                                            .orders)
                                                                        .doc(orderModel
                                                                            .id)
                                                                        .snapshots(),
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      if (!snapshot
                                                                          .hasData) {
                                                                        return const SizedBox
                                                                            .shrink();
                                                                      }

                                                                      final data = snapshot
                                                                              .data!
                                                                              .data()
                                                                          as Map<
                                                                              String,
                                                                              dynamic>?;
                                                                      if (data ==
                                                                          null)
                                                                        return const SizedBox
                                                                            .shrink();

                                                                      final acceptedDriverIds =
                                                                          data['acceptedDriverId'] as List<dynamic>? ??
                                                                              [];

                                                                      if (acceptedDriverIds
                                                                          .isEmpty) {
                                                                        return const SizedBox
                                                                            .shrink();
                                                                      }

                                                                      return Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  'available_offers'.tr,
                                                                                  style: GoogleFonts.poppins(
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontSize: 16,
                                                                                  ),
                                                                                ),
                                                                                // Add refresh button
                                                                                InkWell(
                                                                                  onTap: () {
                                                                                    // Force rebuild by setting state
                                                                                    setState(() {
                                                                                      // This will trigger a rebuild of the offers list
                                                                                    });
                                                                                  },
                                                                                  child: Container(
                                                                                    padding: const EdgeInsets.all(6),
                                                                                    decoration: BoxDecoration(
                                                                                      color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.1) : AppColors.containerBackground,
                                                                                      borderRadius: BorderRadius.circular(20),
                                                                                      border: Border.all(
                                                                                        color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.3) : AppColors.containerBorder,
                                                                                      ),
                                                                                    ),
                                                                                    child: Icon(
                                                                                      Icons.refresh,
                                                                                      color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                                                                                      size: 18,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          ListView
                                                                              .builder(
                                                                            shrinkWrap:
                                                                                true,
                                                                            physics:
                                                                                const NeverScrollableScrollPhysics(),
                                                                            key:
                                                                                ValueKey('offers-list-${acceptedDriverIds.length}-${DateTime.now().millisecondsSinceEpoch}'),
                                                                            itemCount:
                                                                                acceptedDriverIds.length,
                                                                            itemBuilder:
                                                                                (context, index) {
                                                                              final driverId = acceptedDriverIds[index].toString();
                                                                              return FutureBuilder<DriverUserModel?>(
                                                                                future: FireStoreUtils.getDriver(driverId),
                                                                                builder: (context, driverSnapshot) {
                                                                                  if (driverSnapshot.connectionState == ConnectionState.waiting) {
                                                                                    return Container(
                                                                                      height: 80,
                                                                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                                                      child: Constant.loader(),
                                                                                    );
                                                                                  }

                                                                                  if (!driverSnapshot.hasData || driverSnapshot.data == null) {
                                                                                    return const SizedBox.shrink();
                                                                                  }

                                                                                  final driverModel = driverSnapshot.data!;
                                                                                  // Use a unique key for each FutureBuilder to force rebuild when data changes
                                                                                  return FutureBuilder<DriverIdAcceptReject?>(
                                                                                    key: ValueKey('offer-${orderModel.id}-${driverId}'),
                                                                                    future: FireStoreUtils.getAcceptedOrders(orderModel.id.toString(), driverId),
                                                                                    builder: (context, offerSnapshot) {
                                                                                      print('Offer snapshot state: ${offerSnapshot.connectionState}');
                                                                                      print('Offer snapshot hasData: ${offerSnapshot.hasData}');
                                                                                      print('Offer snapshot data: ${offerSnapshot.data}');

                                                                                      // Always show a loader while waiting to prevent white squares
                                                                                      if (offerSnapshot.connectionState == ConnectionState.waiting) {
                                                                                        return Container(
                                                                                          height: 120,
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                                                          decoration: BoxDecoration(
                                                                                            color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                                                                                            borderRadius: BorderRadius.circular(10),
                                                                                            border: Border.all(
                                                                                              color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
                                                                                              width: 0.5,
                                                                                            ),
                                                                                          ),
                                                                                          child: Center(child: Constant.loader()),
                                                                                        );
                                                                                      }

                                                                                      if (offerSnapshot.hasError) {
                                                                                        print('Offer snapshot error: ${offerSnapshot.error}');
                                                                                        return Container(
                                                                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                                                          padding: const EdgeInsets.all(16),
                                                                                          decoration: BoxDecoration(
                                                                                            color: Colors.red.shade50,
                                                                                            borderRadius: BorderRadius.circular(8),
                                                                                          ),
                                                                                          child: Text('Error loading offer: ${offerSnapshot.error}'),
                                                                                        );
                                                                                      }

                                                                                      // Handle offer data - only create fallback if truly no data exists
                                                                                      if (!offerSnapshot.hasData || offerSnapshot.data == null) {
                                                                                        print('No offer data available for driver: $driverId, skipping display');
                                                                                         // Return empty container when no offer data exists
                                                                                         return const SizedBox.shrink();
                                                                                      }
                                                                                      
                                                                                      final offerData = offerSnapshot.data!;
                                                                                      print('Displaying offer for driver: ${driverModel.fullName}, amount: ${offerData.offerAmount}');

                                                                                      // Use a key for the InlineOfferWidget to force rebuild
                                                                                      return InlineOfferWidget(
                                                                                        key: ValueKey('inline-offer-${driverId}-${offerData.offerAmount}'),
                                                                                        driverModel: driverModel,
                                                                                        orderModel: orderModel,
                                                                                        offerData: offerData,
                                                                                        themeChange: themeChange,
                                                                                      );
                                                                                    },
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 16),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                // loader
                                                                Visibility(
                                                                  visible: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .ridePlaced,
                                                                  child:
                                                                      _DriverSearchTimer(
                                                                    orderModel:
                                                                        orderModel,
                                                                    onCancel:
                                                                        () async {
                                                                      try {
                                                                        // Update order status to canceled
                                                                        orderModel.status =
                                                                            Constant.rideCanceled;
                                                                        orderModel.updateDate =
                                                                            Timestamp.now();
                                                                        await FireStoreUtils.setOrder(
                                                                            orderModel);
                                                                        ShowToastDialog.showToast(
                                                                            'rideCancelledToast'.tr);
                                                                      } catch (e) {
                                                                        ShowToastDialog.showToast(
                                                                            'rideCancelFailedToast'.tr);
                                                                      }
                                                                    },
                                                                    onContinue:
                                                                        () {
                                                                      // No-op: timer widget will reset itself
                                                                      // Searching continues while status is Ride Placed
                                                                    },
                                                                  ),
                                                                ),
                                                                Visibility(
                                                                    visible: orderModel.status == Constant.rideActive ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideInProgress ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideHold ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideHoldAccepted,
                                                                    child: ButtonThem
                                                                        .buildButton(
                                                                      context,
                                                                      title: "SOS"
                                                                          .tr,
                                                                      btnHeight:
                                                                          44,
                                                                      customColor:
                                                                          Colors
                                                                              .red,
                                                                      customTextColor:
                                                                          Colors
                                                                              .white,
                                                                      onPress:
                                                                          () async {
                                                                        await FireStoreUtils.getSOS(orderModel.id.toString())
                                                                            .then((value) {
                                                                          if (value !=
                                                                              null) {
                                                                            ShowToastDialog.showToast("Your request is".tr);
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
                                                                            FireStoreUtils.setSOS(sosModel);
                                                                          }
                                                                        });
                                                                      },
                                                                    )),
                                                                const SizedBox(
                                                                    height: 10),
                                                                Visibility(
                                                                    visible: orderModel.status == Constant.rideActive ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideInProgress ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideHold ||
                                                                        orderModel.status ==
                                                                            Constant.rideHoldAccepted,
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              UserModel? customer = await FireStoreUtils.getUserProfile(orderModel.userId.toString());
                                                                              DriverUserModel? driver = await FireStoreUtils.getDriver(orderModel.driverId.toString());

                                                                              Get.to(ChatScreens(
                                                                                driverId: driver!.id,
                                                                                customerId: customer!.id,
                                                                                customerName: customer.fullName,
                                                                                customerProfileImage: customer.profilePic,
                                                                                driverName: driver.fullName,
                                                                                driverProfileImage: driver.profilePic,
                                                                                orderId: orderModel.id,
                                                                                token: driver.fcmToken,
                                                                              ));
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              height: 44,
                                                                              decoration: BoxDecoration(color: AppColors.darkModePrimary, borderRadius: BorderRadius.circular(5)),
                                                                              child: Icon(Icons.chat, color: Colors.black),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              if (orderModel.status == Constant.rideActive) {
                                                                                DriverUserModel? driver = await FireStoreUtils.getDriver(orderModel.driverId.toString());
                                                                                Constant.makePhoneCall("${driver!.countryCode}${driver.phoneNumber}");
                                                                              } else {
                                                                                String phone = await FireStoreUtils.getEmergencyPhoneNumber();
                                                                                Constant.makePhoneCall(phone);
                                                                              }
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              height: 44,
                                                                              decoration: BoxDecoration(color: AppColors.darkModePrimary, borderRadius: BorderRadius.circular(5)),
                                                                              child: Icon(Icons.call, color: Colors.black),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              // Navigate to LiveTrackingScreen with order data
                                                                              Get.to(
                                                                                const LiveTrackingScreen(),
                                                                                arguments: {
                                                                                  "orderModel": orderModel,
                                                                                  "type": "orderModel",
                                                                                },
                                                                              );
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              height: 44,
                                                                              decoration: BoxDecoration(color: AppColors.darkModePrimary, borderRadius: BorderRadius.circular(5)),
                                                                              child: Icon(Icons.map, color: Colors.black),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )),
                                                                const SizedBox(
                                                                    height: 10),
                                                                Visibility(
                                                                    visible: orderModel.status == Constant.rideInProgress ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideHold ||
                                                                        orderModel.status ==
                                                                            Constant
                                                                                .rideHoldAccepted,
                                                                    child: ButtonThem
                                                                        .buildButton(
                                                                      context,
                                                                      title:
                                                                          "whatsapp"
                                                                              .tr,
                                                                      btnHeight:
                                                                          44,
                                                                      onPress:
                                                                          () async {
                                                                        var phone =
                                                                            await FireStoreUtils.getWhatsAppNumber();
                                                                        String
                                                                            message =
                                                                            "wdniWhatsapp".tr;
                                                                        final Uri
                                                                            whatsappUrl =
                                                                            Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
                                                                        try {
                                                                          await launchUrl(
                                                                            whatsappUrl,
                                                                            mode:
                                                                                LaunchMode.externalApplication,
                                                                          );
                                                                        } catch (e) {
                                                                          log("Error: ${e.toString()}");
                                                                          ShowToastDialog.showToast(
                                                                              "Could not launch".tr);
                                                                        }
                                                                      },
                                                                    )),
                                                                orderModel.status ==
                                                                        Constant
                                                                            .rideInProgress
                                                                    ? const SizedBox(
                                                                        height:
                                                                            10,
                                                                      )
                                                                    : SizedBox
                                                                        .shrink(),
                                                                Visibility(
                                                                    visible: orderModel.status ==
                                                                            Constant
                                                                                .rideComplete &&
                                                                        (orderModel.paymentStatus ==
                                                                                null ||
                                                                            orderModel.paymentStatus ==
                                                                                false),
                                                                    child: ButtonThem
                                                                        .buildButton(
                                                                      context,
                                                                      title: "Pay"
                                                                          .tr,
                                                                      btnHeight:
                                                                          44,
                                                                      onPress:
                                                                          () async {
                                                                        Get.to(
                                                                            const PaymentOrderScreen(),
                                                                            arguments: {
                                                                              "orderModel": orderModel,
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
                                                                        "Cancel"
                                                                            .tr,
                                                                    color: Colors
                                                                        .red,
                                                                    btnHeight:
                                                                        44,
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
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
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
                                                                ? (orderModel.offerRate == null ||
                                                                        orderModel.offerRate.toString() ==
                                                                            'null' ||
                                                                        orderModel
                                                                            .offerRate
                                                                            .toString()
                                                                            .isEmpty
                                                                    ? '0.0'
                                                                    : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant
                                                                        .currencyModel!
                                                                        .decimalDigits!))
                                                                : (orderModel.finalRate == null ||
                                                                        orderModel.finalRate.toString() ==
                                                                            'null' ||
                                                                        orderModel
                                                                            .finalRate
                                                                            .toString()
                                                                            .isEmpty
                                                                    ? '0.0'
                                                                    : double.parse(orderModel.finalRate.toString())
                                                                        .toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
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
                                                                      amount: (orderModel.offerRate == null ||
                                                                              orderModel.offerRate.toString() == 'null' ||
                                                                              orderModel.offerRate.toString().isEmpty
                                                                          ? '0.0'
                                                                          : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))),
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
                        ),
                        // Banner section at the bottom
                        _buildBanner(context),
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

  // Schedule seeding of timers and sweeping expired offers without blocking build.
  void _scheduleOfferPersistenceTasks(List<OrderModel> orders) {
    if (_offerSweepScheduled) return;
    _offerSweepScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _seedOfferTimers(orders);
        // No need to sweep here as the background watcher handles it
      } catch (e) {
        log('Offer persistence tasks error: $e');
      } finally {
        _offerSweepScheduled = false;
      }
    });
  }

  // Start watching for offer expiry
  void _startOfferExpiryWatcher() {
    // Listen for active orders
    _activeOrdersSub = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status',
            whereIn: [Constant.ridePlaced, Constant.rideInProgress])
        .snapshots()
        .listen((snap) {
          _latestActiveOrders =
              snap.docs.map((d) => OrderModel.fromJson(d.data())).toList();

          // Process offers immediately when data changes
          _processOfferExpiryTick();
        });

    // Periodic tick to seed/expire offers
    _offerExpiryTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _processOfferExpiryTick();
    });
  }

  // Process offer expiry tick for normal orders
  Future<void> _processOfferExpiryTick() async {
    if (_latestActiveOrders.isEmpty) return;

    // Get the GlobalTimerService instance
    final timerService = GlobalTimerService.instance;

    for (final order in List<OrderModel>.from(_latestActiveOrders)) {
      final orderId = order.id;
      final drivers = order.acceptedDriverId ?? [];
      if (orderId == null || drivers.isEmpty) continue;

      print('Processing normal order $orderId with ${drivers.length} drivers');

      // Track changes in accepted drivers
      final prev = _lastAcceptedByOrder[orderId] ?? <String>{};
      final curr = Set<String>.from(
          (order.acceptedDriverId ?? const <dynamic>[])
              .map((e) => e.toString()));

      final added = curr.difference(prev);
      final removed = prev.difference(curr);

      // For drivers newly added to acceptedDriverId, register their timers with GlobalTimerService
      for (final d in added) {
        final key = 'offer_${orderId}_${d}';
        if (!timerService.isTimerActive(key)) {
          print(
              'New driver $d added - registering timer with GlobalTimerService');
          await timerService.registerTimer(
            key: key,
            durationSeconds: 60,
            startTime: DateTime.now(),
            restoreFromStorage: false,
          );
        }
      }

      // For drivers removed from acceptedDriverId, remove their timers from GlobalTimerService
      for (final d in removed) {
        final key = 'offer_${orderId}_${d}';
        print('Driver $d removed - removing timer from GlobalTimerService');
        await timerService.removeTimer(key);
      }

      // Update our tracking map
      _lastAcceptedByOrder[orderId] = curr;

      // Work on a copy to track removals
      final toRemove = <String>[];

      // Process all drivers in the accepted list regardless of UI visibility
      for (final d in List<String>.from(drivers.map((e) => e.toString()))) {
        final key = 'offer_${orderId}_${d}';

        // Register timer if not already active
        if (!timerService.isTimerActive(key)) {
          print('Registering new timer for driver $d with 13 second duration');
          await timerService.registerTimer(
            key: key,
            durationSeconds: 60,
            startTime: DateTime.now(),
            restoreFromStorage: false,
          );
          continue;
        }

        // Get remaining seconds from GlobalTimerService
        final remaining = timerService.getRemainingSeconds(key);
        print('Driver $d timer: 13s total, ${remaining}s remaining');

        // If timer has expired, add to removal list
        if (remaining <= 0) {
          print('Expiring offer for driver $d');
          toRemove.add(d);
          await timerService.removeTimer(key);
        }
      }

      // Update Firestore if any timers have expired
      if (toRemove.isNotEmpty) {
        final updatedAccepted =
            List<dynamic>.from(order.acceptedDriverId ?? []);
        updatedAccepted.removeWhere((e) => toRemove.contains(e.toString()));

        final updatedRejected =
            List<dynamic>.from(order.rejectedDriverId ?? []);
        for (final id in toRemove) {
          if (!updatedRejected.contains(id)) {
            updatedRejected.add(id);
          }
          // Delete the driver's document from acceptedDriver subcollection
          await FirebaseFirestore.instance
              .collection(CollectionName.orders)
              .doc(orderId)
              .collection("acceptedDriver")
              .doc(id)
              .delete();
        }

        try {
          await FirebaseFirestore.instance
              .collection(CollectionName.orders)
              .doc(orderId)
              .update({
            'acceptedDriverId': updatedAccepted,
            'rejectedDriverId': updatedRejected
          });
        } catch (e) {
          log('Failed to update order $orderId during offer expiry: $e');
        }
      }
    }
  }

  // Persist a start time for any newly-seen offers so they expire consistently.
  Future<void> _seedOfferTimers(List<OrderModel> orders) async {
    final futures = <Future<void>>[];
    for (final o in orders) {
      if (o.status != Constant.ridePlaced) continue;
      final list = o.acceptedDriverId ?? const <dynamic>[];
      if (list.isEmpty) continue;
      for (final dynamicId in list) {
        final driverId = dynamicId?.toString();
        if (driverId == null || driverId.isEmpty) continue;
        final key = 'offer_${o.id}_$driverId';
        futures.add(() async {
          final state = await TimerStateManager.getTimerState(key);
          if (state == null || state.startTime == null) {
            await TimerStateManager.saveTimerState(
              orderId: key,
              startTime: DateTime.now(),
              isRunning: true,
              phaseDuration: 13,
            );
          }
        }());
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Widget _buildBanner(BuildContext context) {
    return Visibility(
      visible: bannerList.isNotEmpty,
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
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

  // Create cached map widget to prevent rapid creation/destruction
  Widget _createCachedMapWidget({
    required String cacheKey,
    required LatLng source,
    LatLng? destination,
    LatLng? driverLocation,
    String? driverId,
    double? carRotation,
    bool showLiveTracking = false,
    bool showRoute = false,
    bool isRideActive = false,
    bool isRideInProgress = false,
  }) {
    try {
      // For live tracking maps with driver ID, we don't want to cache them
      // as they need to update in real-time with driver location changes
      if (showLiveTracking && driverId != null && driverId.isNotEmpty) {
        return LiveMapWidget(
          source: source,
          destination: destination,
          driverId: driverId,
          showRoute: showRoute,
          isRideActive: isRideActive,
          isRideInProgress: isRideInProgress,
        );
      }

      // For static maps or maps without driver ID, use caching
      if (_mapWidgetCache.containsKey(cacheKey)) {
        return _mapWidgetCache[cacheKey]!;
      }

      // Add a small delay to ensure Google Maps is ready
      if (!mounted) {
        return Container(
          height: Responsive.height(28, context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: const Center(
            child: Text('Map loading...'),
          ),
        );
      }

      // Add unique identifier to prevent platform view conflicts
      final uniqueKey = '${cacheKey}_${DateTime.now().millisecondsSinceEpoch}';

      // Prevent rapid platform view creation
      final now = DateTime.now();
      if (_lastMapCreation != null &&
          now.difference(_lastMapCreation!).inMilliseconds < 500) {
        return Container(
          height: Responsive.height(28, context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: const Center(
            child: Text('Map loading...'),
          ),
        );
      }
      _lastMapCreation = now;

      final mapWidget = RouteMapWidget(
        source: source,
        destination: destination,
        driverLocation: driverLocation,
        carRotation: carRotation,
        showLiveTracking: showLiveTracking,
        showRoute: showRoute,
        key: ValueKey(uniqueKey),
      );

      _mapWidgetCache[cacheKey] = mapWidget;

      // Cleanup cache after 5 seconds to prevent memory leaks
      _cacheCleanupTimer?.cancel();
      _cacheCleanupTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _mapWidgetCache.clear();
        }
      });

      return mapWidget;
    } catch (e) {
      print('Map widget creation error: $e');
      return Container(
        height: Responsive.height(28, context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Text('Map temporarily unavailable'),
        ),
      );
    }
  }

  // Calculate distance between two points in kilometers
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLng = (lng2 - lng1) * (math.pi / 180);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Drawer navigation method
  void onSelectDrawerItem(int index) async {
    if (index == 11) {
      // Logout
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
      // Navigate to appropriate screen
      switch (index) {
        case 0:
          Get.offAll(const DashBoardScreen());
          break;
        case 1:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 1;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 2:
          // Already on rides screen
          break;
        case 3:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 3;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 4:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 4;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 5:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 5;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 6:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 6;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 7:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 7;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 8:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 8;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 9:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 9;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
        case 10:
          Get.offAll(const DashBoardScreen());
          // ✅ CRITICAL FIX: Safely access DashBoardController
          try {
            Get.find<DashBoardController>().selectedDrawerIndex.value = 10;
          } catch (e) {
            print(
                'DashBoardController not found, will be created by DashBoardScreen');
          }
          break;
      }
    }
    Get.back(); // Close drawer
  }

  // Build drawer widget
  Widget buildAppDrawer(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    var drawerOptions = <Widget>[];

    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(
        InkWell(
          onTap: () {
            onSelectDrawerItem(i);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: i == selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    d['icon'],
                    width: 20,
                    color: i == selectedDrawerIndex.value
                        ? themeChange.getThem()
                            ? Colors.black
                            : Colors.white
                        : themeChange.getThem()
                            ? Colors.white
                            : AppColors.drawerIcon,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    d['title'],
                    style: GoogleFonts.poppins(
                      color: i == selectedDrawerIndex.value
                          ? themeChange.getThem()
                              ? Colors.black
                              : Colors.white
                          : themeChange.getThem()
                              ? Colors.white
                              : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: FutureBuilder<UserModel?>(
              future: FireStoreUtils.getUserProfile(
                FireStoreUtils.getCurrentUid(),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Constant.loader();
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Icon(Icons.account_circle, size: 36);
                } else {
                  final userModel = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            height: Responsive.width(20, context),
                            width: Responsive.width(20, context),
                            imageUrl: userModel.profilePic ??
                                Constant.userPlaceHolder,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(),
                            errorWidget: (context, url, error) =>
                                Image.network(Constant.userPlaceHolder),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            userModel.fullName.toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            userModel.email.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
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
}

class _DriverSearchTimer extends StatefulWidget {
  final OrderModel orderModel;
  final Future<void> Function() onCancel;
  final VoidCallback onContinue;

  const _DriverSearchTimer({
    required this.orderModel,
    required this.onCancel,
    required this.onContinue,
  });

  @override
  State<_DriverSearchTimer> createState() => _DriverSearchTimerState();
}

class _DriverSearchTimerState extends State<_DriverSearchTimer>
    with WidgetsBindingObserver {
  static const int phaseDuration = 60; // seconds per minute
  int secondsRemaining = phaseDuration;
  Timer? _timer;
  bool _isRunning = false; // controls whether the minute countdown is active
  DateTime? _cycleStartAt; // wall-clock start of the current minute cycle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(
        '🏁 DriverSearchTimer: initState called for order ${widget.orderModel.id}');
    _initializeTimerState();
  }

  Future<void> _initializeTimerState() async {
    // Load saved timer state from persistent storage
    final timerState =
        await TimerStateManager.getTimerState(widget.orderModel.id);

    if (timerState != null && mounted) {
      setState(() {
        _isRunning = timerState.isRunning;
        _cycleStartAt = timerState.startTime;

        if (_isRunning && _cycleStartAt != null) {
          // Calculate remaining time based on saved start time
          secondsRemaining = TimerStateManager.calculateRemainingSeconds(
              _cycleStartAt!, timerState.phaseDuration);

          // If time already expired while app was closed, trigger minute end
          if (secondsRemaining <= 0) {
            // Use Future.microtask to avoid calling setState during build
            Future.microtask(() => _onMinuteEnded());
            secondsRemaining = 0;
          } else {
            // Start the timer with the remaining time
            _timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (!mounted) {
                t.cancel();
                return;
              }

              final elapsed =
                  DateTime.now().difference(_cycleStartAt!).inSeconds;
              final remaining = phaseDuration - elapsed;

              if (remaining <= 0) {
                t.cancel();
                _onMinuteEnded();
              } else {
                setState(() => secondsRemaining = remaining);
              }
            });
          }
        }
      });
    } else {
      // No saved state, start fresh
      _startMinute();
    }
  }

  @override
  void dispose() async {
    print(
        '💀 DriverSearchTimer: dispose called for order ${widget.orderModel.id}');
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Clean up any stored dialog expiry time
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dialog_expiry_${widget.orderModel.id}');
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Check timer state when app resumes
    if (state == AppLifecycleState.resumed) {
      // Check if there's an active dialog that should have expired
      final prefs = await SharedPreferences.getInstance();
      final expiryTimeStr =
          prefs.getString('dialog_expiry_${widget.orderModel.id}');

      if (expiryTimeStr != null) {
        final expiryTime = DateTime.parse(expiryTimeStr);
        if (DateTime.now().isAfter(expiryTime)) {
          // Dialog should have expired while app was in background
          await prefs.remove('dialog_expiry_${widget.orderModel.id}');

          // Force close any open dialog
          try {
            Navigator.of(context, rootNavigator: true).pop(false);
          } catch (_) {}

          // Cancel the ride since dialog timed out
          await _onCancel();
          return;
        }
      }

      // Normal timer check
      if (_isRunning && _cycleStartAt != null) {
        // Recompute remaining based on wall clock
        final elapsed = DateTime.now().difference(_cycleStartAt!).inSeconds;
        final remaining = phaseDuration - elapsed;
        if (remaining <= 0) {
          _timer?.cancel();
          _onMinuteEnded();
        } else {
          setState(() => secondsRemaining = remaining);
          // Create a fresh timer that continues from current remaining time
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) {
              t.cancel();
              return;
            }

            final currentElapsed =
                DateTime.now().difference(_cycleStartAt!).inSeconds;
            final currentRemaining = phaseDuration - currentElapsed;

            if (currentRemaining <= 0) {
              t.cancel();
              _onMinuteEnded();
            } else {
              setState(() => secondsRemaining = currentRemaining);
            }
          });
        }
      }
    }
    // Add this workaround to wake up timers after background (fixes Android unresponsiveness)
    if (state == AppLifecycleState.resumed) {
      Future(() => null).then((value) => null);
    }
  }

  void _startMinute() {
    if (!mounted) return;
    print('🔄 _startMinute: Starting initial minute');
    _startFreshTimer();
  }

  void _startFreshTimer() {
    print('🔄 _startFreshTimer: Starting fresh timer');
    if (!mounted) {
      print('❌ _startFreshTimer: Widget not mounted, aborting');
      return;
    }

    // Cancel any existing timer first
    _timer?.cancel();
    _timer = null;
    print('🛑 _startFreshTimer: Cancelled old timer');

    // Force a complete reset - set fresh start time
    final now = DateTime.now();
    print('⏰ _startFreshTimer: Fresh start time: $now');

    // Update state with completely fresh values
    setState(() {
      secondsRemaining = phaseDuration;
      _isRunning = true;
      _cycleStartAt = now;
    });
    print(
        '✅ _startFreshTimer: State updated - secondsRemaining: $secondsRemaining, _isRunning: $_isRunning');

    // Start completely fresh timer with immediate first tick
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        print('❌ Timer tick: Widget not mounted, cancelling timer');
        t.cancel();
        return;
      }

      // Always calculate from the exact start time we set
      final elapsed = DateTime.now().difference(now).inSeconds;
      final remaining = phaseDuration - elapsed;

      print(
          '⏱️ Timer tick: elapsed=${elapsed}s, remaining=${remaining}s, current_display=${secondsRemaining}s');

      if (remaining <= 0) {
        print('⏰ Timer tick: Time expired, ending minute');
        t.cancel();
        if (mounted) {
          _onMinuteEnded();
        }
      } else {
        if (mounted && remaining != secondsRemaining) {
          setState(() => secondsRemaining = remaining);
          print('🔄 Timer tick: Updated UI to ${remaining}s');
        }
      }
    });

    print('🚀 _startFreshTimer: Timer started successfully');

    // Save timer state in background without blocking
    _saveTimerStateAsync(now);
  }

  String _format(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onMinuteEnded() async {
    print('⏰ _onMinuteEnded: Minute ended, showing continue dialog');
    if (!mounted) return;

    // Cancel any existing timer
    _timer?.cancel();

    setState(() {
      _isRunning = false; // pause while prompting
    });

    // Persist paused state
    await TimerStateManager.saveTimerState(
      orderId: widget.orderModel.id,
      startTime: null,
      isRunning: false,
      phaseDuration: phaseDuration,
    );

    // Ask user if they want to continue searching for another minute
    final bool? decision = await _showContinueDialog();
    print('🔄 _onMinuteEnded: Dialog result: $decision');

    // CRITICAL: Check mounted immediately after dialog closes
    if (!mounted) {
      print('❌ _onMinuteEnded: Widget not mounted after dialog, aborting');
      return;
    }

    if (decision == true) {
      // CRITICAL: Notify parent FIRST before any async operations
      // This ensures the parent knows we're continuing before any potential disposal
      print('📱 _onMinuteEnded: Notifying parent about continuation');
      widget.onContinue();

      // Start a fresh timer directly here instead of calling _onContinue
      // which might get interrupted by disposal
      _startFreshTimer();
    } else if (decision == false || decision == null) {
      // Explicit No or dialog timeout -> cancel
      await _onCancel();
    }
  }

  Future<bool?> _showContinueDialog() async {
    // Auto-timeout after 20 seconds: if no response, close dialog with false (cancel)
    bool poppedByTimer = false;

    // Store the dialog expiry time in SharedPreferences
    final dialogExpiryTime = DateTime.now().add(const Duration(seconds: 20));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dialog_expiry_${widget.orderModel.id}',
        dialogExpiryTime.toIso8601String());

    // Create a background-aware timer that will check if dialog should be dismissed
    // This will work even when the app is in the background
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (poppedByTimer) {
        timer.cancel();
        return;
      }

      // Check if we've reached or passed the expiry time
      final now = DateTime.now();
      if (now.isAfter(dialogExpiryTime)) {
        timer.cancel();

        // Clean up the stored expiry time
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dialog_expiry_${widget.orderModel.id}');

        if (!poppedByTimer && mounted) {
          poppedByTimer = true;
          try {
            // Force close dialog with root navigator
            Navigator.of(context, rootNavigator: true).pop(false);
          } catch (e) {
            // If root navigator fails, try local navigator
            try {
              Navigator.of(context).pop(false);
            } catch (_) {
              // If both navigators fail, call onCancel directly
              _onCancel();
            }
          }
        }
      }
    });

    // Show the dialog with a timeout
    bool? result;
    try {
      result = await showDialog<bool?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          // Prevent back button from dismissing without handling
          onWillPop: () async => false,
          child: AlertDialog(
            content: Text(
              'continueSearchingMessage'.tr,
            ),
            actions: [
              Directionality(
                textDirection:
                    TextDirection.ltr, // Force No(left) and Yes(right)
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Clean up expiry time when user explicitly responds
                        prefs.remove('dialog_expiry_${widget.orderModel.id}');
                        Navigator.of(ctx).pop(false);
                      },
                      child: Text('No'.tr),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // Clean up expiry time when user explicitly responds
                        prefs.remove('dialog_expiry_${widget.orderModel.id}');
                        Navigator.of(ctx).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ColorConfig.appThemeColor, // Green background
                        foregroundColor: Colors.black, // Black text
                      ),
                      child: Text('Yes'.tr),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Dialog may have been dismissed by the system
      result = false;
    }

    // Cancel the timer if it's still active
    if (timer.isActive) timer.cancel();

    // Clean up expiry time if it still exists
    try {
      await prefs.remove('dialog_expiry_${widget.orderModel.id}');
    } catch (_) {}

    return result; // null => timeout; true => continue; false => cancel
  }

  // This method is now only used during initialization
  Future<void> _onContinue() async {
    print('🔄 _onContinue: Starting timer continuation...');
    if (!mounted) {
      print('❌ _onContinue: Widget not mounted, aborting');
      return;
    }

    // Notify parent FIRST before any async operations
    // This ensures the parent knows we're continuing before any potential disposal
    print('📱 _onContinue: Notifying parent about continuation');
    widget.onContinue();

    // Start a fresh timer
    _startFreshTimer();
  }

  // Save timer state asynchronously without blocking the UI
  Future<void> _saveTimerStateAsync(DateTime startTime) async {
    if (!mounted) return;

    try {
      await TimerStateManager.clearTimerState(widget.orderModel.id);
      if (!mounted) return;

      await TimerStateManager.saveTimerState(
        orderId: widget.orderModel.id,
        startTime: startTime,
        isRunning: true,
        phaseDuration: phaseDuration,
      );
      print('💾 Timer state saved to persistence');
    } catch (e) {
      print('❌ Error saving timer state: $e');
    }
  }

  Future<void> _onCancel() async {
    _timer?.cancel();

    // Clear persisted timer state on cancel
    await TimerStateManager.clearTimerState(widget.orderModel.id);

    await widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print(
        '🎨 DriverSearchTimer: build() called - secondsRemaining: $secondsRemaining, _isRunning: $_isRunning');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fast moving line under the offers button (indeterminate)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: null, // indeterminate animation
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: AppColors.darkModePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRunning ? 'searchingDrivers'.tr : 'stillSearchingDrivers'.tr,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: 1 - (secondsRemaining / phaseDuration),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: AppColors.darkModePrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _format(secondsRemaining),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: secondsRemaining <= 10 ? Colors.red : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
