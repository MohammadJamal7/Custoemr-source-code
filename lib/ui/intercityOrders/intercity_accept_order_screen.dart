import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/intercity_accept_order_controller.dart';
import 'package:customer/controller/intercity_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/global_timer_service.dart';
import 'package:customer/utils/timer_state_manager.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterCityAcceptOrderScreen extends StatelessWidget {
  const InterCityAcceptOrderScreen({super.key});

  // Convert 24-hour format to 12-hour format
  static String? formatTo12Hour(String? time24) {
    if (time24 == null) return null;

    // Check if the time is already in correct format
    if (time24.contains('AM') || time24.contains('PM')) {
      return time24;
    }

    try {
      // Extract hours and minutes
      final parts = time24.split(':');
      if (parts.length < 2) return time24;

      int hours = int.parse(parts[0]);
      final minutes = parts[1];

      // Determine AM/PM
      final period = hours >= 12 ? 'PM' : 'AM';

      // Convert hours to 12-hour format
      hours = hours % 12;
      if (hours == 0) hours = 12;

      return '$hours:$minutes $period';
    } catch (e) {
      // If parsing fails, return the original string
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    // Initialize InterCityController if it doesn't exist
    if (!Get.isRegistered<InterCityController>()) {
      Get.put(InterCityController());
    }

    return GetBuilder<InterCityAcceptOrderController>(
        init: InterCityAcceptOrderController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: Text("OutStation ride details".tr),
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  )),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.width(8, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkGray
                            : AppColors.gray,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection(CollectionName.ordersIntercity)
                              .doc(controller.orderModel.value.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Something went wrong'.tr));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Constant.loader();
                            }

                            InterCityOrderModel orderModel =
                                InterCityOrderModel.fromJson(
                                    snapshot.data!.data()!);
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              orderModel.status.toString().tr,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Text(
                                            orderModel.status ==
                                                    Constant.ridePlaced
                                                ? Constant.amountShow(
                                                    amount: orderModel.offerRate
                                                        .toString())
                                                : Constant.amountShow(
                                                    amount: orderModel
                                                                .finalRate ==
                                                            null
                                                        ? "0.0"
                                                        : orderModel.finalRate
                                                            .toString()),
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold),
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
                                        destinationLocation: orderModel
                                            .destinationLocationName
                                            .toString(),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBorder
                                                : Colors.white,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10))),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 14),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Text("OTP".tr,
                                                          style: GoogleFonts
                                                              .poppins()),
                                                      Text(
                                                          " : ${orderModel.otp}",
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                    Constant().formatTimestamp(
                                                        orderModel.createdDate),
                                                    style:
                                                        GoogleFonts.poppins()),
                                              ],
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      ButtonThem.buildButton(
                                        context,
                                        title: "Cancel".tr,
                                        btnHeight: 44,
                                        onPress: () async {
                                          List<dynamic> acceptDriverId = [];

                                          orderModel.status =
                                              Constant.rideCanceled;
                                          orderModel.acceptedDriverId =
                                              acceptDriverId;
                                          await FireStoreUtils
                                                  .setInterCityOrder(orderModel)
                                              .then((value) {
                                            Get.back();
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child:
                                      (orderModel.acceptedDriverId == null ||
                                              orderModel
                                                  .acceptedDriverId!.isEmpty)
                                          ? Center(
                                              child: Text("No driver Found".tr),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              itemCount: orderModel
                                                  .acceptedDriverId!.length,
                                              itemBuilder: (context, index) {
                                                return FutureBuilder<
                                                        DriverUserModel?>(
                                                    future: FireStoreUtils
                                                        .getDriver(orderModel
                                                                .acceptedDriverId![
                                                            index]),
                                                    builder:
                                                        (context, snapshot) {
                                                      switch (snapshot
                                                          .connectionState) {
                                                        case ConnectionState
                                                              .waiting:
                                                          return Constant
                                                              .loader();
                                                        case ConnectionState
                                                              .done:
                                                          if (snapshot
                                                              .hasError) {
                                                            return Text(snapshot
                                                                .error
                                                                .toString());
                                                          } else {
                                                            DriverUserModel
                                                                driverModel =
                                                                snapshot.data!;
                                                            return FutureBuilder<
                                                                    DriverIdAcceptReject?>(
                                                                future: FireStoreUtils.getInterCItyAcceptedOrders(
                                                                    orderModel
                                                                        .id
                                                                        .toString(),
                                                                    driverModel
                                                                        .id
                                                                        .toString()),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  switch (snapshot
                                                                      .connectionState) {
                                                                    case ConnectionState
                                                                          .waiting:
                                                                      return Constant
                                                                          .loader();
                                                                    case ConnectionState
                                                                          .done:
                                                                      if (snapshot
                                                                          .hasError) {
                                                                        return Text(snapshot
                                                                            .error
                                                                            .toString());
                                                                      } else {
                                                                        // Add null safety check
                                                                        DriverIdAcceptReject?
                                                                            driverIdAcceptReject =
                                                                            snapshot.data;

                                                                        // If data is null, show appropriate message
                                                                        if (driverIdAcceptReject ==
                                                                            null) {
                                                                          return Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                            child:
                                                                                Container(
                                                                              decoration: BoxDecoration(
                                                                                color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                                                                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                                                                border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(15.0),
                                                                                child: Center(child: Text("Driver offer details not available".tr)),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                        // Wrap in a StatefulWidget for timer functionality
                                                                        return _OfferListItemWidget(
                                                                          context:
                                                                              context,
                                                                          themeChange:
                                                                              themeChange,
                                                                          controller:
                                                                              controller,
                                                                          driverModel:
                                                                              driverModel,
                                                                          orderModel: controller
                                                                              .orderModel
                                                                              .value,
                                                                          driverIdAcceptReject:
                                                                              driverIdAcceptReject,
                                                                          formatTimeCallback:
                                                                              formatTo12Hour,
                                                                        );
                                                                      }
                                                                    default:
                                                                      return Text(
                                                                          'Error'
                                                                              .tr);
                                                                  }
                                                                });
                                                          }
                                                        default:
                                                          return Text(
                                                              'Error'.tr);
                                                      }
                                                    });
                                              },
                                            ),
                                )
                              ],
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
}

class _OfferListItemWidget extends StatefulWidget {
  final BuildContext context;
  final DarkThemeProvider themeChange;
  final InterCityAcceptOrderController controller;
  final DriverUserModel driverModel;
  final InterCityOrderModel orderModel;
  final DriverIdAcceptReject driverIdAcceptReject;
  final Function(String?) formatTimeCallback;

  const _OfferListItemWidget({
    required this.context,
    required this.themeChange,
    required this.controller,
    required this.driverModel,
    required this.orderModel,
    required this.driverIdAcceptReject,
    required this.formatTimeCallback,
  });

  @override
  State<_OfferListItemWidget> createState() => _OfferListItemWidgetState();
}

class _OfferListItemWidgetState extends State<_OfferListItemWidget>
    with WidgetsBindingObserver {
  late InterCityController _controller;
  late String _driverId;
  static const int _offerDuration = 300; // seconds (5 minutes)
  // Use the same key format as global watcher to share/reset state consistently
  String get _timerKey =>
      'intercity_offer_${widget.orderModel.id}_${widget.driverModel.id}';

  // Use GlobalTimerService for timer management
  GlobalTimerService get _timerService => GlobalTimerService.instance;

  // StreamSubscription for timer expiration events
  StreamSubscription<String>? _timerExpirySubscription;

  // Formats a date string to dd/MM/yyyy if possible; otherwise returns original or a fallback
  String _formatDate(String? input) {
    if (input == null || input.trim().isEmpty) return "Original date".tr;
    final raw = input.trim();
    // Try ISO-like formats first (e.g., 2025-09-10)
    DateTime? dt = DateTime.tryParse(raw);
    if (dt != null) {
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      return '$dd/$mm/$yyyy';
    }
    // Try numeric with separators (e.g., 10/9/2025 or 9-10-25)
    final regNum = RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})$');
    final mNum = regNum.firstMatch(raw);
    if (mNum != null) {
      String d = mNum.group(1)!;
      String mo = mNum.group(2)!;
      String y = mNum.group(3)!;
      if (y.length == 2) y = '20$y';
      return '${d.padLeft(2, '0')}/${mo.padLeft(2, '0')}/$y';
    }
    // Try month-name formats (English): 'September 10, 2025', 'Sep 10 2025', '10 September 2025', '10 Sep 2025'
    final months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    // Pattern A: MonthName D{1,2},? Y{4}
    final regA =
        RegExp(r'^(?<mon>[A-Za-z]+)\s+(?<d>\d{1,2})(?:,)?\s+(?<y>\d{4})$');
    final mA = regA.firstMatch(raw);
    if (mA != null) {
      final monStr = mA.namedGroup('mon')!.toLowerCase();
      final d = mA.namedGroup('d')!;
      final y = mA.namedGroup('y')!;
      final mo = months[monStr];
      if (mo != null) {
        return '${d.padLeft(2, '0')}/${mo.toString().padLeft(2, '0')}/$y';
      }
    }
    // Pattern B: D{1,2} MonthName Y{4}
    final regB = RegExp(r'^(?<d>\d{1,2})\s+(?<mon>[A-Za-z]+)\s+(?<y>\d{4})$');
    final mB = regB.firstMatch(raw);
    if (mB != null) {
      final monStr = mB.namedGroup('mon')!.toLowerCase();
      final d = mB.namedGroup('d')!;
      final y = mB.namedGroup('y')!;
      final mo = months[monStr];
      if (mo != null) {
        return '${d.padLeft(2, '0')}/${mo.toString().padLeft(2, '0')}/$y';
      }
    }
    // Pattern C: mon-yyyy-dd (e.g., aug-2025-22)
    final regC =
        RegExp(r'^(?<mon>[A-Za-z]+)[\-\s](?<y>\d{4})[\-\s](?<d>\d{1,2})$');
    final mC = regC.firstMatch(raw.toLowerCase());
    if (mC != null) {
      final monStr = mC.namedGroup('mon')!;
      final y = mC.namedGroup('y')!;
      final d = mC.namedGroup('d')!;
      final mo = months[monStr];
      if (mo != null) {
        return '${d.padLeft(2, '0')}/${mo.toString().padLeft(2, '0')}/$y';
      }
    }
    // Pattern D: yyyy-mon-dd (e.g., 2025-aug-22)
    final regD =
        RegExp(r'^(?<y>\d{4})[\-\s](?<mon>[A-Za-z]+)[\-\s](?<d>\d{1,2})$');
    final mD = regD.firstMatch(raw.toLowerCase());
    if (mD != null) {
      final monStr = mD.namedGroup('mon')!;
      final y = mD.namedGroup('y')!;
      final d = mD.namedGroup('d')!;
      final mo = months[monStr];
      if (mo != null) {
        return '${d.padLeft(2, '0')}/${mo.toString().padLeft(2, '0')}/$y';
      }
    }
    // Pattern E: dd-mon-yyyy (e.g., 22-aug-2025)
    final regE =
        RegExp(r'^(?<d>\d{1,2})[\-\s](?<mon>[A-Za-z]+)[\-\s](?<y>\d{4})$');
    final mE = regE.firstMatch(raw.toLowerCase());
    if (mE != null) {
      final monStr = mE.namedGroup('mon')!;
      final y = mE.namedGroup('y')!;
      final d = mE.namedGroup('d')!;
      final mo = months[monStr];
      if (mo != null) {
        return '${d.padLeft(2, '0')}/${mo.toString().padLeft(2, '0')}/$y';
      }
    }
    // Fallback: return as is
    return raw;
  }

  // Initialize ValueNotifier immediately to avoid LateInitializationError
  late final ValueNotifier<int> _remainingSeconds;

  // Local timer for UI updates
  Timer? _countdownTimer;

  // Store the start time for persistent timer calculation
  late final DateTime _timerStartTime;

  // SharedPreferences key for storing timer start time
  String get _timerStorageKey => 'timer_start_${_timerKey}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
    _driverId = widget.driverIdAcceptReject.driverId ?? "";

    // Initialize the ValueNotifier first
    _remainingSeconds = ValueNotifier<int>(_offerDuration);

    // Initialize timer with persistence
    _initializeTimerWithPersistence();

    // Listen for timer expiration events
    _timerExpirySubscription = _timerService.onTimerExpired.listen((key) {
      if (key == _timerKey && mounted) {
        _rejectOffer(auto: true);
      }
    });
  }

  void _initializeController() {
    // Always put a new controller to ensure it exists
    // Get.put will return the existing instance if it's already registered
    _controller = Get.put(InterCityController());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cancel all timers
    _timerExpirySubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app comes back from background, recalculate and update timer
      if (mounted) {
        final remaining = _calculateRemainingSeconds();
        _remainingSeconds.value = remaining;

        // If timer expired while in background, auto-reject
        if (remaining <= 0) {
          _rejectOffer(auto: true);
        }
      }
    }
  }

  // Initialize timer with persistent storage
  Future<void> _initializeTimerWithPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    final storedStartTime = prefs.getString(_timerStorageKey);

    if (storedStartTime != null) {
      // Restore existing timer
      _timerStartTime = DateTime.parse(storedStartTime);
      final remaining = _calculateRemainingSeconds();

      if (remaining <= 0) {
        // Timer already expired, auto-reject
        await _clearStoredTimer();
        _rejectOffer(auto: true);
        return;
      }

      _remainingSeconds.value = remaining;
    } else {
      // Start new timer
      _timerStartTime = DateTime.now();
      await prefs.setString(
          _timerStorageKey, _timerStartTime.toIso8601String());
      _remainingSeconds.value = _offerDuration;
    }

    _startPeriodicTimer();
  }

  // Calculate remaining seconds based on elapsed time since start
  int _calculateRemainingSeconds() {
    final elapsed = DateTime.now().difference(_timerStartTime).inSeconds;
    final remaining = _offerDuration - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // Clear stored timer from SharedPreferences
  Future<void> _clearStoredTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerStorageKey);
  }

  Future<void> _startPeriodicTimer() async {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    // Register with global timer service for consistency with other app features
    try {
      await TimerStateManager.clearTimerState(_timerKey);
      await _timerService.registerTimer(
        key: _timerKey,
        durationSeconds: _offerDuration,
        startTime: _timerStartTime,
        restoreFromStorage: false,
      );
    } catch (e) {
      print('⚠️ Global timer registration failed: $e');
      // Continue with local timer only
    }

    // Use DateTime-based calculation for persistent timing
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Calculate remaining time based on actual elapsed time
      final remaining = _calculateRemainingSeconds();

      // Update the ValueNotifier with calculated remaining time
      _remainingSeconds.value = remaining;

      // Check for expiration
      if (remaining <= 0) {
        timer.cancel();
        _clearStoredTimer();
        _rejectOffer(auto: true);
      }
    });
  }

  // These methods are no longer needed as GlobalTimerService handles timer calculations and ticking

  dynamic _rejectOffer({bool auto = false}) async {
    // Clear stored timer from SharedPreferences
    await _clearStoredTimer();

    // Remove timer from GlobalTimerService
    await _timerService.removeTimer(_timerKey);

    // Remove timer from controller
    _controller.removeOfferTimer(_driverId);

    // Remove this driver from the accepted drivers list
    List<dynamic> acceptedDriverId = [];
    if (widget.orderModel.acceptedDriverId != null) {
      acceptedDriverId = widget.orderModel.acceptedDriverId!;
    }

    acceptedDriverId.remove(widget.driverIdAcceptReject.driverId);

    // Also ensure the driver is NOT in rejectedDriverId (so they can re-apply)
    List<dynamic> rejectedDriverId = [];
    if (widget.orderModel.rejectedDriverId != null) {
      rejectedDriverId = widget.orderModel.rejectedDriverId!;
    }
    rejectedDriverId.remove(_driverId);

    await FireStoreUtils.fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(widget.orderModel.id)
        .update({
      "acceptedDriverId": acceptedDriverId,
      "rejectedDriverId": rejectedDriverId,
    });

    // Also remove the per-driver accepted offer doc so the driver can re-apply
    await FireStoreUtils.fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(widget.orderModel.id)
        .collection("acceptedDriver")
        .doc(_driverId)
        .delete();

    // And remove any residual rejectedDriver sub-doc (if used by driver app)
    await FireStoreUtils.fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(widget.orderModel.id)
        .collection("rejectedDriver")
        .doc(_driverId)
        .delete()
        .catchError((_) {});

    final key = auto ? 'offerAutoRejectedToast' : 'offerRejectedToast';
    ShowToastDialog.showToast(key.tr);
    widget.controller.update();

    await SendNotification.sendOneNotification(
        token: widget.driverModel.fcmToken.toString(),
        title: 'Ride Canceled'.tr,
        body:
            'The passenger has canceled the ride. No action is required from your end.'
                .tr,
        payload: {});

    return null;
  }

  dynamic _acceptOffer() async {
    // Clear stored timer from SharedPreferences
    await _clearStoredTimer();

    // Remove timer from GlobalTimerService
    await _timerService.removeTimer(_timerKey);

    // Remove timer from controller
    _controller.removeOfferTimer(_driverId);

    bool activeOrder = await FireStoreUtils.currentDriverIntercityRideCheck(
        widget.driverModel.id.toString());
    if (activeOrder) {
      ShowToastDialog.showToast(
        "Please select another driver. This driver is busy with another trip"
            .tr,
      );
    } else {
      widget.orderModel.acceptedDriverId = [];
      widget.orderModel.driverId =
          widget.driverIdAcceptReject.driverId.toString();
      widget.orderModel.status = Constant.rideActive;
      widget.orderModel.finalRate = widget.driverIdAcceptReject.offerAmount;

      await SendNotification.sendOneNotification(
          token: widget.driverModel.fcmToken.toString(),
          title: 'Ride Confirmed'.tr,
          body:
              'Your ride request has been accepted by the passenger. Please proceed to the pickup location.'
                  .tr,
          payload: {});

      await FireStoreUtils.setInterCityOrder(widget.orderModel);
      Get.back();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: widget.themeChange.getThem()
              ? AppColors.darkContainerBackground
              : AppColors.containerBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
              color: widget.themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 0.5),
          boxShadow: widget.themeChange.getThem()
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 5,
                    offset: const Offset(0, 4), // changes position of shadow
                  ),
                ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DriverView(
                    driverId: widget.driverModel.id.toString(),
                    amount:
                        widget.driverIdAcceptReject.offerAmount?.toString() ??
                            "0",
                    name: widget.driverModel.fullName,
                  ),
                  const SizedBox(height: 10),
                  // Display suggested date and time
                  if (widget.driverIdAcceptReject.suggestedDate != null ||
                      widget.driverIdAcceptReject.suggestedTime != null)
                    Container(
                      decoration: BoxDecoration(
                        color: widget.themeChange.getThem()
                            ? AppColors.darkGray.withOpacity(0.5)
                            : AppColors.gray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Suggested Pickup Time".tr,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: widget.themeChange.getThem()
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(
                                    widget.driverIdAcceptReject.suggestedDate ??
                                        widget.orderModel.whenDates),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: widget.themeChange.getThem()
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.formatTimeCallback(widget
                                        .driverIdAcceptReject.suggestedTime) ??
                                    "Original time".tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          // Inline driver rules under date/time
                          if ((widget.driverModel.vehicleInformation
                                      ?.driverRules ??
                                  [])
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...widget
                                .driverModel.vehicleInformation!.driverRules!
                                .map((rule) {
                              final textColor = widget.themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // White square bullet
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(
                                          top: 6, right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    // Rule text
                                    Expanded(
                                      child: Text(
                                        Constant.localizationName(rule.name),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          // Number of passengers
                          if ((widget.orderModel.numberOfPassenger ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_alt,
                                  size: 16,
                                  color: widget.themeChange.getThem()
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.orderModel.numberOfPassenger
                                      .toString(),
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          // Notes (comments)
                          if ((widget.orderModel.comments ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 16,
                                  color: widget.themeChange.getThem()
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.orderModel.comments!.trim(),
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                  color: widget.themeChange.getThem()
                      ? AppColors.darkGray
                      : AppColors.gray),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_car.svg',
                            width: 18,
                            color: widget.themeChange.getThem()
                                ? Colors.white
                                : Colors.black,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            Constant.localizationName(widget
                                .driverModel.vehicleInformation!.vehicleType),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_color.svg',
                            width: 18,
                            color: widget.themeChange.getThem()
                                ? Colors.white
                                : Colors.black,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            widget.driverModel.vehicleInformation!.vehicleColor
                                .toString(),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/ic_number.png',
                            width: 18,
                            color: widget.themeChange.getThem()
                                ? Colors.white
                                : Colors.black,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            widget.driverModel.vehicleInformation!.vehicleNumber
                                .toString(),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ],
                  )),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonThem.buildBorderButton(
                      context,
                      title: "Reject".tr,
                      btnHeight: 45,
                      iconVisibility: false,
                      onPress: () {
                        _rejectOffer(auto: false);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _remainingSeconds,
                      builder: (context, seconds, _) {
                        // Format the time as minutes:seconds
                        final minutes = (seconds / 60).floor();
                        final remainingSeconds = seconds % 60;
                        final timeDisplay =
                            "${minutes}:${remainingSeconds.toString().padLeft(2, '0')}";

                        // Check if we're in the last 1 minute (60 seconds)
                        final isLastMinute = seconds <= 60;

                        return ButtonThem.buildButton(
                          context,
                          btnHeight: 40,
                          title: "${'Accept'.tr} ($timeDisplay)",
                          customColor: AppColors
                              .darkModePrimary, // Green color from system
                          customTextColor: isLastMinute
                              ? Colors.red
                              : Colors.black, // Red text in last 1 minute
                          btnWidthRatio: 0.8,
                          onPress: () => _acceptOffer(),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
