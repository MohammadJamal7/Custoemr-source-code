import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/ui/intercityOrders/intercity_inline_offer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_complete_order_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_driver_search_timer.dart';
import 'package:customer/ui/intercityOrders/intercity_payment_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:customer/utils/drawer_helper.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_screen/login_screen.dart';
import '../orders/order_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/banner_model.dart';
import 'package:customer/utils/ride_utils.dart';
import '../dashboard_screen.dart';
import 'package:customer/utils/timer_state_manager.dart';

class InterCityOrderScreen extends StatefulWidget {
  final bool showDrawer;
  final int initialTabIndex;

  const InterCityOrderScreen(
      {super.key, this.showDrawer = true, this.initialTabIndex = 0});

  @override
  State<InterCityOrderScreen> createState() => _InterCityOrderScreenState();
}

class _InterCityOrderScreenState extends State<InterCityOrderScreen> with TickerProviderStateMixin {
  _InterCityOrderScreenState();
  final PageController pageController = PageController();
  var bannerList = <OtherBannerModel>[];
  Timer? _timer;
  // Background watcher for expiring offers
  Timer? _offerExpiryTimer;
  StreamSubscription<QuerySnapshot>? _activeOrdersSub;
  // Cache of latest active intercity orders for offer expiry processing
  List<InterCityOrderModel> _latestActiveOrders = [];
  // Track last seen accepted drivers per order to detect add/remove deltas
  final Map<String, Set<String>> _lastAcceptedByOrder = {};
  // Track previously processed offer keys to reseed timers on first sight each tick
  Set<String> _previousOfferKeys = {};
  // Track when an offer key was first seen to provide a short grace window
  final Map<String, DateTime> _firstSeenAt = {};
  // Track which orders have their offers expanded (toggled open)
  final Set<String> _expandedOfferOrderIds = <String>{};
  

  // Drawer functionality
  RxInt selectedDrawerIndex = 3.obs; // Set to 3 since we're on OutStation Rides
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
    super.initState();
    getBanners();
    
    // Fix drawer links appearing disabled after ride cancellation
    DrawerHelper.ensureDrawerLinksEnabled();
    
    // Setup drawer enabled listener
    DrawerHelper.setupDrawerEnabledListener(widget, this);

    // Start background watcher to auto-expire offers
    _startOfferExpiryWatcher();
  }

  // Cache helpers
  void _upsertActiveOrderInCache(InterCityOrderModel order) {
    final idx = _latestActiveOrders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      _latestActiveOrders[idx] = order;
    } else {
      _latestActiveOrders.add(order);
    }
  }

  void _startOfferExpiryWatcher() {
    // Listen to active 'ridePlaced' intercity orders for this user
    _activeOrdersSub = FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status', isEqualTo: Constant.ridePlaced)
        .where('paymentStatus', isEqualTo: false)
        .snapshots()
        .listen((snap) async {
      _latestActiveOrders = snap.docs
          .map((d) => InterCityOrderModel.fromJson(d.data()))
          .toList();

      // Delta tracking: clear/reseed timers for added/removed drivers per order
      for (final order in _latestActiveOrders) {
        final orderId = order.id;
        if (orderId == null) continue;

        final prev = _lastAcceptedByOrder[orderId] ?? <String>{};
        final curr = Set<String>.from(
            (order.acceptedDriverId ?? const <dynamic>[])
                .map((e) => e.toString()));

        final added = curr.difference(prev);
        final removed = prev.difference(curr);

        // For drivers newly added to acceptedDriverId, reset their timers to full duration
        // but only if they don't already have a valid timer
        for (final d in added) {
          final key = 'intercity_offer_${orderId}_${d}';
          // Check if timer already exists before clearing/reseeding
          final existingState = await TimerStateManager.getTimerState(key);
          final remaining = existingState?.startTime != null ? 
              TimerStateManager.calculateRemainingSeconds(existingState!.startTime!, existingState.phaseDuration) : -1;
          
          // Only reseed if no timer exists or timer is expired
          if (existingState == null || existingState.startTime == null || remaining <= 0) {
            print('Driver $d newly added - seeding fresh 13s timer');
            await TimerStateManager.clearTimerState(key);
            await TimerStateManager.saveTimerState(
              orderId: key,
              startTime: DateTime.now(),
              isRunning: true,
              phaseDuration: 300,
            );
          } else {
            print('Driver $d newly added but has valid timer with ${remaining}s remaining - keeping it');
          }
        }

        // For drivers removed from acceptedDriverId, clear any lingering timer state
        for (final d in removed) {
          final key = 'intercity_offer_${orderId}_${d}';
          print('Driver $d removed - clearing timer state');
          await TimerStateManager.clearTimerState(key);
        }

        _lastAcceptedByOrder[orderId] = curr;
      }
    });

    // Periodic tick to seed/expire offers
    _offerExpiryTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _processOfferExpiryTick();
    });
  }

  Future<void> _processOfferExpiryTick() async {
    if (_latestActiveOrders.isEmpty) return;
    // Track keys seen during this tick to detect first-time sightings
    final currentKeys = <String>{};
    for (final order in List<InterCityOrderModel>.from(_latestActiveOrders)) {
      final orderId = order.id;
      final drivers = order.acceptedDriverId ?? [];
      if (orderId == null || drivers.isEmpty) continue;

      print('Processing intercity order $orderId with ${drivers.length} drivers');
      
      // Work on a copy to track removals
      final toRemove = <String>[];

      for (final d in List<String>.from(drivers.map((e) => e.toString()))) {
        final key = 'intercity_offer_${orderId}_${d}';
        currentKeys.add(key);
        
        // Only track first seen time if not already tracked
        _firstSeenAt.putIfAbsent(key, () => DateTime.now());

        // Reseed guard: if this key wasn't processed in previous tick, only seed if no timer exists
        if (!_previousOfferKeys.contains(key)) {
          // Check if timer already exists before reseeding
          final existingState = await TimerStateManager.getTimerState(key);
          if (existingState == null || existingState.startTime == null) {
            // Only seed if no valid timer exists
            await TimerStateManager.saveTimerState(
              orderId: key,
              startTime: DateTime.now(),
              isRunning: true,
              phaseDuration: 300,
            );
            print('New key $key - seeded fresh timer');
          } else {
            print('New key $key - using existing timer with ${TimerStateManager.calculateRemainingSeconds(existingState.startTime!, existingState.phaseDuration)}s remaining');
          }
          continue;
        }

        final state = await TimerStateManager.getTimerState(key);
        if (state == null || state.startTime == null) {
          // Seed start time for new offer not yet seen on offers page
          print('Seeding new timer for driver $d with 13 second duration');
          await TimerStateManager.saveTimerState(
            orderId: key,
            startTime: DateTime.now(),
            isRunning: true,
            phaseDuration: 300,
          );
          continue;
        }

        final remaining = TimerStateManager.calculateRemainingSeconds(
          state.startTime!,
          state.phaseDuration,
        );
        print('Driver $d timer: ${state.phaseDuration}s total, ${DateTime.now().difference(state.startTime!).inSeconds}s elapsed, ${remaining}s remaining');
        
        if (remaining <= 0) {
          // Grace period: if this key was first seen very recently, skip removal this tick
          final seenAt = _firstSeenAt[key] ?? DateTime.now();
          final sinceFirstSeen = DateTime.now().difference(seenAt).inMilliseconds;
          if (sinceFirstSeen < 2000) {
            print('Skipping immediate removal for key=$key (grace ${sinceFirstSeen}ms)');
            continue;
          }
          toRemove.add(d);
          await TimerStateManager.clearTimerState(key);
        }
      }

      if (toRemove.isNotEmpty) {
        final updatedAccepted = List<dynamic>.from(order.acceptedDriverId ?? []);
        updatedAccepted.removeWhere((e) => toRemove.contains(e.toString()));
        
        // Also remove from rejectedDriverId to allow drivers to reapply after timeout
        final updatedRejected = List<dynamic>.from(order.rejectedDriverId ?? []);
        updatedRejected.removeWhere((e) => toRemove.contains(e.toString()));
        
        try {
          final updateData = {
            'acceptedDriverId': updatedAccepted,
            'rejectedDriverId': updatedRejected
          };
          
          // Ensure zoneIds is set if it's missing but zoneId exists
          if ((order.zoneIds == null || order.zoneIds!.isEmpty) && order.zoneId != null) {
            print('Adding missing zoneIds array with zoneId: ${order.zoneId}');
            updateData['zoneIds'] = [order.zoneId];
          }
          
          await FirebaseFirestore.instance
              .collection(CollectionName.ordersIntercity)
              .doc(orderId)
              .update(updateData);
        } catch (_) {}
      }
    }
    // Remember keys seen in this tick
    _previousOfferKeys = currentKeys;
  }

  void startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      try {
        if (mounted && pageController.hasClients && bannerList.isNotEmpty) {
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
        print('InterCity banner auto-scroll error: $e');
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _offerExpiryTimer?.cancel();
    _activeOrdersSub?.cancel();
    pageController.dispose();
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
                        .collection(CollectionName.ordersIntercity)
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
                            '🔍 Intercity Drawer Icon Debug: hasActiveRides=true, shouldShowDrawer=$shouldShowDrawer, activeRidesCount=${snapshot.data!.docs.length}');
                      }

                      return shouldShowDrawer
                          ? InkWell(
                              onTap: () {
                                // Fix drawer links appearing disabled
                                DrawerHelper.resetGuestModeAndRebuild(context);
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
                "OutStation Rides".tr,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            height: widget.showDrawer ? Responsive.width(8, context) : 0,
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
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection(CollectionName.ordersIntercity)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status", whereIn: [
                                      Constant.ridePlaced,
                                      Constant.rideInProgress,
                                      Constant.rideComplete,
                                      Constant.rideActive
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
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/icons/ic_no_rides.svg',
                                                height: 100,
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                'No active rides found'.tr,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            InterCityOrderModel orderModel =
                                                InterCityOrderModel.fromJson(
                                                    snapshot.data!.docs[index]
                                                            .data()
                                                        as Map<String,
                                                            dynamic>);
                                            // Update cache for background expiry
                                            _upsertActiveOrderInCache(orderModel);
                                            return Column(
                                                children: [
                                              InkWell(
                                                  onTap: () {
                                                    if (Constant.mapType ==
                                                        "inappmap") {
                                                      if (orderModel.status ==
                                                              Constant
                                                                  .rideActive ||
                                                          orderModel.status ==
                                                              Constant
                                                                  .rideInProgress) {
                                                        Get.to(
                                                            const LiveTrackingScreen(),
                                                            arguments: {
                                                              "interCityOrderModel":
                                                                  orderModel,
                                                              "type":
                                                                  "interCityOrderModel",
                                                            });
                                                      }
                                                    } else {
                                                      Utils.redirectMap(
                                                          latitude: orderModel
                                                              .destinationLocationLAtLng!
                                                              .latitude!,
                                                          longLatitude: orderModel
                                                              .destinationLocationLAtLng!
                                                              .longitude!,
                                                          name: orderModel
                                                              .destinationLocationName
                                                              .toString());
                                                    }
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
                                                                .all(10.0),
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
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.30),
                                                                      borderRadius: const BorderRadius
                                                                          .all(
                                                                          Radius.circular(
                                                                              5))),
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            4),
                                                                    child: Text(orderModel.paymentType.toString() ==
                                                                            "Wallet"
                                                                        ? "Wallet"
                                                                            .tr
                                                                        : "Cash"
                                                                            .tr),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  decoration: BoxDecoration(
                                                                      color: AppColors
                                                                          .primary
                                                                          .withOpacity(
                                                                              0.30),
                                                                      borderRadius: const BorderRadius
                                                                          .all(
                                                                          Radius.circular(
                                                                              5))),
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                          10.0,
                                                                        vertical:
                                                                            4),
                                                                    child: Text(Constant.localizationName(orderModel
                                                                            .intercityService!
                                                                            .name)
                                                                        .tr),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            // Show an "offers available" toggle button and conditionally render offers
                                                            Visibility(
                                                              visible: orderModel.status == Constant.ridePlaced,
                                                              child: StreamBuilder<DocumentSnapshot>(
                                                                key: ValueKey('intercity-order-stream-${orderModel.id}-${DateTime.now().millisecondsSinceEpoch}'),
                                                                stream: FirebaseFirestore.instance
                                                                    .collection(CollectionName.ordersIntercity)
                                                                    .doc(orderModel.id)
                                                                    .snapshots(),
                                                                builder: (context, snapshot) {
                                                                  if (!snapshot.hasData) {
                                                                    return const SizedBox.shrink();
                                                                  }
                                                                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                                                                  if (data == null) return const SizedBox.shrink();
                                                                  final acceptedDriverIds = data['acceptedDriverId'] as List<dynamic>? ?? [];
                                                                  final count = acceptedDriverIds.length;
                                                                  if (count == 0) {
                                                                    return const SizedBox.shrink();
                                                                  }

                                                                  final orderId = orderModel.id?.toString() ?? '';
                                                                  final isExpanded = _expandedOfferOrderIds.contains(orderId);

                                                                  return Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      // Toggle button mirroring normal orders UX
                                                                      InkWell(
                                                                        onTap: () {
                                                                          setState(() {
                                                                            if (isExpanded) {
                                                                              _expandedOfferOrderIds.remove(orderId);
                                                                            } else {
                                                                              _expandedOfferOrderIds.add(orderId);
                                                                            }
                                                                          });
                                                                        },
                                                                        child: Container(
                                                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                                          decoration: BoxDecoration(
                                                                            color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.1) : AppColors.containerBackground,
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            border: Border.all(
                                                                              color: themeChange.getThem() ? AppColors.darkModePrimary.withOpacity(0.3) : AppColors.containerBorder,
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Text(
                                                                                    count == 1
                                                                                        ? 'offer_received'.tr.replaceAll('{count}', count.toString())
                                                                                        : 'offers_received'.tr.replaceAll('{count}', count.toString()),
                                                                                    style: GoogleFonts.poppins(
                                                                                      fontWeight: FontWeight.w500,
                                                                                      color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                                                                                      fontSize: 14,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(width: 4),
                                                                                  Icon(
                                                                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                                                    color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                                                                                    size: 18,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              // Keep right side empty to mirror spacing
                                                                              const SizedBox.shrink(),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      // Offers list only when expanded
                                                                      if (isExpanded) ...[
                                                                        Padding(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                          child: Row(
                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                'available_offers'.tr,
                                                                                style: GoogleFonts.poppins(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontSize: 16,
                                                                                ),
                                                                              ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    // trigger rebuild
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
                                                                        ListView.builder(
                                                                          shrinkWrap: true,
                                                                          physics: const NeverScrollableScrollPhysics(),
                                                                          key: ValueKey('intercity-offers-list-${acceptedDriverIds.length}-${DateTime.now().millisecondsSinceEpoch}'),
                                                                          itemCount: acceptedDriverIds.length,
                                                                          itemBuilder: (context, index) {
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
                                                                                return FutureBuilder<DriverIdAcceptReject?>(
                                                                                  key: ValueKey('intercity-offer-${driverId}-${DateTime.now().millisecondsSinceEpoch}'),
                                                                                  future: FireStoreUtils.getInterCItyAcceptedOrders(orderModel.id ?? '', driverId),
                                                                                  builder: (context, offerSnapshot) {
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
                                                                                    if (!offerSnapshot.hasData || offerSnapshot.data == null) {
                                                                                      return Container(
                                                                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                                                        padding: const EdgeInsets.all(16),
                                                                                        decoration: BoxDecoration(
                                                                                          color: Colors.orange.shade50,
                                                                                          borderRadius: BorderRadius.circular(8),
                                                                                        ),
                                                                                        child: Text('No offer data for ${driverModel.fullName}'),
                                                                                      );
                                                                                    }
                                                                                    final offerData = offerSnapshot.data!;
                                                                                    return IntercityInlineOfferWidget(
                                                                                      key: ValueKey('intercity-inline-offer-${driverId}-${offerData.offerAmount}'),
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
                                                                      ],
                                                                      const SizedBox(height: 8),
                                                                    ],
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(height: 10),
                                                            // Text(orderModel.id.toString()),
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

                                                            // Spacer below offers toggle
                                                            const SizedBox(height: 10),
                                                            // loader
                                                            Visibility(
                                                              visible: orderModel
                                                                      .status ==
                                                                  Constant
                                                                      .ridePlaced,
                                                              child: DriverSearchTimer(
                                                                orderModel: orderModel,
                                                                onCancel: () async {
                                                                  try {
                                                                    ShowToastDialog.showLoader('Please wait');
                                                                    // Update order status to canceled
                                                                    orderModel.status = Constant.rideCanceled;
                                                                    orderModel.updateDate = Timestamp.now();
                                                                    await FireStoreUtils.setInterCityOrder(orderModel);
                                                                    ShowToastDialog.closeLoader();
                                                                    ShowToastDialog.showToast('rideCancelledToast'.tr);
                                                                  } catch (e) {
                                                                    ShowToastDialog.closeLoader();
                                                                    ShowToastDialog.showToast('rideCancelFailedToast'.tr);
                                                                  }
                                                                },
                                                                onContinue: () {
                                                                  // Continue searching - timer will reset automatically
                                                                },
                                                              ),
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
                                                            const SizedBox(
                                                                height: 5),
                                                            Visibility(
                                                                visible: orderModel
                                                                        .status !=
                                                                    Constant
                                                                        .ridePlaced,
                                                                child: Column(
                                                                  children: [
                                                                    Row(
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
                                                                              color: AppColors.darkModePrimary,
                                                                              borderRadius: BorderRadius.circular(5)),
                                                                          child: Icon(
                                                                              Icons.chat,
                                                                              color: Colors.black),
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
                                                                              color: AppColors.darkModePrimary,
                                                                              borderRadius: BorderRadius.circular(5)),
                                                                          child: Icon(
                                                                              Icons.call,
                                                                              color: Colors.black),
                                                                        ),
                                                                      ),
                                                                    )
                                                                      ],
                                                                    ),
                                                                  ],
                                                                )),
                                                            const SizedBox(
                                                                height: 5),
                                                            Visibility(
                                                                visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideInProgress,
                                                                child: ButtonThem
                                                                    .buildButton(
                                                                  context,
                                                                  title:
                                                                      "SOS".tr,
                                                                  btnHeight: 44,
                                                                  customColor:
                                                                      Colors.red,
                                                                  customTextColor:
                                                                      Colors.white,
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
                                                                            "intercity";
                                                                        FireStoreUtils.setSOS(
                                                                            sosModel);
                                                                      }
                                                                    });
                                                                  },
                                                                )),
                                                            const SizedBox(
                                                                height: 2),
                                                            Visibility(
                                                              visible: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .rideActive ||
                                                                  orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .rideInProgress,
                                                              child: ButtonThem
                                                                  .buildButton(
                                                                context,
                                                                title:
                                                                    "View Map"
                                                                        .tr,
                                                                btnHeight: 44,
                                                                onPress:
                                                                    () async {
                                                                  if (Constant
                                                                          .mapType ==
                                                                      "inappmap") {
                                                                    if (orderModel.status ==
                                                                            Constant
                                                                                .rideActive ||
                                                                        orderModel.status ==
                                                                            Constant.rideInProgress) {
                                                                      Get.to(
                                                                          const LiveTrackingScreen(),
                                                                          arguments: {
                                                                            "interCityOrderModel":
                                                                                orderModel,
                                                                            "type":
                                                                                "interCityOrderModel",
                                                                          });
                                                                    }
                                                                  } else {
                                                                    Utils.redirectMap(
                                                                        latitude: orderModel
                                                                            .destinationLocationLAtLng!
                                                                            .latitude!,
                                                                        longLatitude: orderModel
                                                                            .destinationLocationLAtLng!
                                                                            .longitude!,
                                                                        name: orderModel
                                                                            .destinationLocationName
                                                                            .toString());
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 5),
                                                            Visibility(
                                                              visible: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .rideComplete &&
                                                                  (orderModel.paymentStatus ==
                                                                          null ||
                                                                      orderModel
                                                                              .paymentStatus ==
                                                                          false),
                                                              child: ButtonThem
                                                                  .buildButton(
                                                                context,
                                                                title: "Pay".tr,
                                                                btnHeight: 44,
                                                                onPress:
                                                                    () async {
                                                                  Get.to(
                                                                      const InterCityPaymentOrderScreen(),
                                                                      arguments: {
                                                                        "orderModel":
                                                                            orderModel,
                                                                      });
                                                                  // paymentMethodDialog(context, controller, orderModel);
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 5),
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
                                                                color:
                                                                    Colors.red,
                                                                title:
                                                                    "Cancel".tr,
                                                                btnHeight: 44,
                                                                onPress: () {
                                                                  RideUtils().showCancelationBottomsheet(
                                                                      context,
                                                                      interCityOrderModel:
                                                                          orderModel);
                                                                },
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
                                          });
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection(CollectionName.ordersIntercity)
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
                                              "No completed rides Found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            InterCityOrderModel orderModel =
                                                InterCityOrderModel.fromJson(
                                                    snapshot.data!.docs[index]
                                                            .data()
                                                        as Map<String,
                                                            dynamic>);
                                            //log(orderModel.status.toString());

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
                                                      if (orderModel.status ==
                                                              Constant
                                                                  .rideComplete &&
                                                          orderModel
                                                                  .paymentStatus ==
                                                              true) {
                                                        Get.to(
                                                            const IntercityCompleteOrderScreen(),
                                                            arguments: {
                                                              "orderModel":
                                                                  orderModel,
                                                            });
                                                      }
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              15.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(orderModel.status
                                                              .toString()
                                                              .tr),
                                                          DriverView(
                                                              driverId: orderModel
                                                                  .driverId
                                                                  .toString(),
                                                              amount: orderModel
                                                                          .status ==
                                                                      Constant
                                                                          .ridePlaced
                                                                  ? double.parse(orderModel.offerRate.toString())
                                                                      .toStringAsFixed(Constant
                                                                          .currencyModel!
                                                                          .decimalDigits!)
                                                                  : double.parse(orderModel
                                                                          .finalRate
                                                                          .toString())
                                                                      .toStringAsFixed(Constant
                                                                          .currencyModel!
                                                                          .decimalDigits!)),
                                                          const Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        4),
                                                            child: Divider(
                                                              thickness: 1,
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .grey
                                                                        .withOpacity(
                                                                            0.30),
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(5))),
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(orderModel
                                                                      .paymentType
                                                                      .toString()
                                                                      .tr),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                    color: AppColors
                                                                        .primary
                                                                        .withOpacity(
                                                                            0.30),
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(5))),
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4),
                                                                  child: Text(Constant.localizationName(
                                                                      orderModel
                                                                          .intercityService!
                                                                          .name)),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
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
                                                            height: 10,
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
                                                                            10))),
                                                            child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        10),
                                                                child: Center(
                                                                  child: Row(
                                                                    children: [
                                                                      Expanded(
                                                                          child: Text(
                                                                              orderModel.status.toString().tr,
                                                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                                                                      Text(
                                                                          Constant().formatTimestamp(orderModel
                                                                              .createdDate),
                                                                          style:
                                                                              GoogleFonts.poppins()),
                                                                    ],
                                                                  ),
                                                                )),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Visibility(
                                                            visible: orderModel
                                                                    .status ==
                                                                Constant
                                                                    .rideComplete,
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: ButtonThem
                                                                      .buildButton(
                                                                    context,
                                                                    title:
                                                                        "Review"
                                                                            .tr,
                                                                    btnHeight:
                                                                        44,
                                                                    onPress:
                                                                        () async {
                                                                      Get.to(
                                                                          const ReviewScreen(),
                                                                          arguments: {
                                                                            "type":
                                                                                "interCityOrderModel",
                                                                            "interCityOrderModel":
                                                                                orderModel,
                                                                          });
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
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
                                    .collection(CollectionName.ordersIntercity)
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
                                              "No completed rides Found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            InterCityOrderModel orderModel =
                                                InterCityOrderModel.fromJson(
                                                    snapshot.data!.docs[index]
                                                            .data()
                                                        as Map<String,
                                                            dynamic>);
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
                                                      Row(
                                                        children: [
                                                          Container(
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.30),
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
                                                                          4),
                                                              child: Text(
                                                                  orderModel
                                                                      .paymentType
                                                                      .toString()
                                                                      .tr),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                                color: AppColors
                                                                    .primary
                                                                    .withOpacity(
                                                                        0.30),
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
                                                                          4),
                                                              child: Text(Constant
                                                                  .localizationName(
                                                                      orderModel
                                                                          .intercityService!
                                                                          .name)),
                                                            ),
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
    if (bannerList.isEmpty) return const SizedBox.shrink();
    
    return Container(
     height: MediaQuery.of(context).size.height * 0.20,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildBannerCarousel(),
    );
  }

  Widget _buildBannerCarousel() {
    if (bannerList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: PageView.builder(
          itemCount: bannerList.length,
          scrollDirection: Axis.horizontal,
          controller: pageController,
          itemBuilder: (context, index) {
            final bannerModel = bannerList[index];
            return InkWell(
              onTap: () {
                // Banner tap action can be implemented here if needed
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CachedNetworkImage(
                  imageUrl: bannerModel.image.toString(),
                  fit: BoxFit.fill,
                  width: MediaQuery.of(context).size.width,
                  placeholder: (context, url) => Constant.loader(),
                  errorWidget: (context, url, error) => Image.network(
                    Constant.userPlaceHolder,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  // Build drawer widget with the same implementation as dashboard_screen.dart
  Widget buildAppDrawer(BuildContext context) {
    // Fix drawer links appearing disabled after ride cancellation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        DrawerHelper.resetGuestModeAndRebuild(context);
      }
    });
    
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final dashboardController = Get.put(DashBoardController());
    
    // Set the selected drawer index to match the current screen (OutStation Rides)
    dashboardController.selectedDrawerIndex.value = 3;
    
    var drawerOptions = <Widget>[];
    for (var i = 0; i < dashboardController.drawerItems.length; i++) {
      var d = dashboardController.drawerItems[i];
      
      // Define which items should be disabled for guest users
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
                // Set the selected drawer index first
                dashboardController.selectedDrawerIndex.value = i;
                
                // Close drawer first
                Navigator.pop(context);
                
                // Handle logout separately
                if (i == 11) { // Logout
                  FirebaseAuth.instance.signOut();
                  Get.offAll(() => const LoginScreen());
                } else {
                  // Navigate through the DashboardScreen to ensure app bar appears
                  Get.offAll(() => const DashBoardScreen());
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                color: i == dashboardController.selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : isGuestDisabled
                        ? Colors.grey.withOpacity(0.08)
                        : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SvgPicture.asset(
                  d.icon,
                  width: 20,
                  color: i == dashboardController.selectedDrawerIndex.value
                      ? themeChange.getThem()
                          ? Colors.black
                          : Colors.white
                      : isGuestDisabled
                          ? Colors.grey.withOpacity(0.4)
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
                      color: i == dashboardController.selectedDrawerIndex.value
                          ? themeChange.getThem()
                              ? Colors.black
                              : Colors.white
                          : isGuestDisabled
                              ? Colors.grey.withOpacity(0.6)
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

  // Build drawer header with user profile
  Widget _buildDrawerHeader(BuildContext context) {
    // Handle guest users
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
              "مستخدم ضيف", // Force Arabic for guest user
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

    // Handle logged-in users
    final currentUid = FireStoreUtils.getCurrentUid();
    if (currentUid.isEmpty) {
      // Fallback for non-logged-in users
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
          UserModel userModel = snapshot.data!;
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
                        userModel.profilePic ?? Constant.userPlaceHolder,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Constant.loader(),
                    errorWidget: (context, url, error) =>
                        Image.network(Constant.userPlaceHolder),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(userModel.fullName.toString(),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    userModel.email.toString(),
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
  
  // Drawer navigation method
  void onSelectDrawerItem(int index) async {
    // Fix drawer links appearing disabled - ensure we're not in guest mode
    DrawerHelper.ensureDrawerLinksEnabled();
    if (!mounted) return;
    Navigator.pop(context);
    
    if (index == 11) {
      // Logout
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
      return;
    }
    
    selectedDrawerIndex.value = index;
    // Navigate to appropriate screen
    switch (index) {
      case 0:
        // Initialize DashBoardController before navigation
        Get.put(DashBoardController());
        Get.offAll(const DashBoardScreen());
        break;
      case 1:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 1;
        Get.offAll(const DashBoardScreen());
        break;
      case 2:
        Get.offAll(const OrderScreen(showDrawer: true));
        break;
      case 3:
        // Already on intercity orders screen, just close drawer
        break;
      case 4:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 4;
        Get.offAll(const DashBoardScreen());
        break;
      case 5:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 5;
        Get.offAll(const DashBoardScreen());
        break;
      case 6:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 6;
        Get.offAll(const DashBoardScreen());
        break;
      case 7:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 7;
        Get.offAll(const DashBoardScreen());
        break;
      case 8:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 8;
        Get.offAll(const DashBoardScreen());
        break;
      case 9:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 9;
        Get.offAll(const DashBoardScreen());
        break;
      case 10:
        // Initialize DashBoardController before navigation
        var dashController = Get.put(DashBoardController());
        dashController.selectedDrawerIndex.value = 10;
        Get.offAll(const DashBoardScreen());
        break;
      }
    }
  }
