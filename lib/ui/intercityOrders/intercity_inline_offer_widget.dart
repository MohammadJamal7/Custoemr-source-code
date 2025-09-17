import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';

import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/timer_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer/utils/global_timer_service.dart';
import 'package:customer/ui/review/reviews_screen.dart';

// Ensure all required imports are present

// Inline offer widget for displaying intercity offers in the search page
class IntercityInlineOfferWidget extends StatefulWidget {
  final DriverUserModel driverModel;
  final InterCityOrderModel orderModel;
  final DriverIdAcceptReject offerData;
  final DarkThemeProvider themeChange;

  IntercityInlineOfferWidget({
    Key? key,
    required this.driverModel,
    required this.orderModel,
    required this.offerData,
    required this.themeChange,
  }) : super(key: key) {
    debugPrint('DEBUG: IntercityInlineOfferWidget constructor called');
    debugPrint('DEBUG: Driver ID: ${driverModel.id}');
    debugPrint('DEBUG: Order ID: ${orderModel.id}');
    debugPrint('DEBUG: Offer amount: ${offerData.offerAmount}');
  }

  @override
  State<IntercityInlineOfferWidget> createState() =>
      _IntercityInlineOfferWidgetState();
}

class _IntercityInlineOfferWidgetState extends State<IntercityInlineOfferWidget>
    with WidgetsBindingObserver {
  Timer? _timer;
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier<int>(300);
  final ValueNotifier<bool> _isExpiredNotifier = ValueNotifier<bool>(false);
  DateTime? _timerStartTime;
  static const int _offerDuration = 300; // 5 minutes (300 seconds)
  String get _timerKey =>
      'intercity_offer_${widget.orderModel.id}_${widget.driverModel.id}';
  GlobalTimerService get _timerService => GlobalTimerService.instance;
  String get _timerStorageKey => 'timer_start_${_timerKey}';

  // Helpers moved into State where they are used
  String _formatDate(String? input) {
    if (input == null || input.trim().isEmpty) return "--/--/----";
    final raw = input.trim();

    // First, try strict ISO or RFC-like strings
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      final yyyy = parsed.year.toString();
      return '$dd/$mm/$yyyy';
    }

    // Month name mapping
    int? _monthFromName(String s) {
      final m = s.toLowerCase();
      const names = {
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
      return names[m];
    }

    // Patterns with month names
    final norm =
        raw.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Case: Mon-YYYY-DD or Mon YYYY DD
    final reMonYmd = RegExp(r'^([A-Za-z]+)[\s\-_/]+(\d{4})[\s\-_/]+(\d{1,2})$');
    final mMonYmd = reMonYmd.firstMatch(norm);
    if (mMonYmd != null) {
      final mon = _monthFromName(mMonYmd.group(1)!);
      final y = mMonYmd.group(2)!;
      final d = mMonYmd.group(3)!;
      if (mon != null) {
        return '${d.padLeft(2, '0')}/${mon.toString().padLeft(2, '0')}/$y';
      }
    }

    // Case: DD-Mon-YYYY or DD Mon YYYY
    final reDMonY =
        RegExp(r'^(\d{1,2})[\s\-_/]+([A-Za-z]+)[\s\-_/]+(\d{2,4})$');
    final mDMonY = reDMonY.firstMatch(norm);
    if (mDMonY != null) {
      final d = mDMonY.group(1)!;
      final mon = _monthFromName(mDMonY.group(2)!);
      var y = mDMonY.group(3)!;
      if (y.length == 2) y = '20$y';
      if (mon != null) {
        return '${d.padLeft(2, '0')}/${mon.toString().padLeft(2, '0')}/$y';
      }
    }

    // Case: Mon DD YYYY
    final reMonDDY =
        RegExp(r'^([A-Za-z]+)[\s\-_/]+(\d{1,2})[\s\-_/]+(\d{2,4})$');
    final mMonDDY = reMonDDY.firstMatch(norm);
    if (mMonDDY != null) {
      final mon = _monthFromName(mMonDDY.group(1)!);
      final d = mMonDDY.group(2)!;
      var y = mMonDDY.group(3)!;
      if (y.length == 2) y = '20$y';
      if (mon != null) {
        return '${d.padLeft(2, '0')}/${mon.toString().padLeft(2, '0')}/$y';
      }
    }

    // yyyy-MM-dd or yyyy/MM/dd
    final reYMD = RegExp(r'^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$');
    final mYMD = reYMD.firstMatch(raw);
    if (mYMD != null) {
      final y = mYMD.group(1)!;
      final m = mYMD.group(2)!;
      final d = mYMD.group(3)!;
      return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$y';
    }

    // MM/dd/yyyy or M/d/yyyy
    final reMDY = RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$');
    final mMDY = reMDY.firstMatch(raw);
    if (mMDY != null) {
      // If we suspect it's already dd/MM/yyyy, detect ambiguous >12
      final a = int.tryParse(mMDY.group(1)!);
      final b = int.tryParse(mMDY.group(2)!);
      final y = mMDY.group(3)!;
      if (a != null && b != null) {
        if (a <= 12 && b <= 31) {
          // Treat as MM/dd/yyyy
          return '${b.toString().padLeft(2, '0')}/${a.toString().padLeft(2, '0')}/$y';
        } else {
          // Already in dd/MM/yyyy or invalid; normalize to dd/MM/yyyy
          return '${a.toString().padLeft(2, '0')}/${b.toString().padLeft(2, '0')}/$y';
        }
      }
    }

    // dd/MM/yyyy or d/M/yy etc.
    final reDMY = RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})$');
    final mDMY = reDMY.firstMatch(raw);
    if (mDMY != null) {
      var d = mDMY.group(1)!;
      var m = mDMY.group(2)!;
      var y = mDMY.group(3)!;
      if (y.length == 2) y = '20$y';
      return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$y';
    }

    // Fallback: return unchanged
    return raw;
  }

  String _localizedColorName(String? colorName) {
    final input = (colorName ?? '').trim();
    if (input.isEmpty) return '';
    final code = Constant.getLanguage().code ?? 'en';
    final lower = input.toLowerCase();

    const Map<String, String> enToAr = {
      'red': 'أحمر',
      'blue': 'أزرق',
      'green': 'أخضر',
      'black': 'أسود',
      'white': 'أبيض',
      'yellow': 'أصفر',
      'orange': 'برتقالي',
      'gray': 'رمادي',
      'grey': 'رمادي',
      'silver': 'فضي',
      'brown': 'بني',
      'purple': 'بنفسجي',
      'pink': 'وردي',
      'gold': 'ذهبي',
      'beige': 'بيج',
      'maroon': 'خمري',
      'navy': 'كحلي',
      'teal': 'تركوازي',
    };

    const Map<String, String> arToEn = {
      'أحمر': 'Red',
      'أزرق': 'Blue',
      'أخضر': 'Green',
      'أسود': 'Black',
      'أبيض': 'White',
      'أصفر': 'Yellow',
      'برتقالي': 'Orange',
      'رمادي': 'Gray',
      'فضي': 'Silver',
      'بني': 'Brown',
      'بنفسجي': 'Purple',
      'وردي': 'Pink',
      'ذهبي': 'Gold',
      'بيج': 'Beige',
      'خمري': 'Maroon',
      'كحلي': 'Navy',
      'تركوازي': 'Teal',
    };

    if (code == 'ar') {
      return enToAr[lower] ?? input; // keep Arabic as-is or unknown
    } else {
      return arToEn[input] ??
          (enToAr.containsKey(lower)
              ? lower[0].toUpperCase() + lower.substring(1)
              : input);
    }
  }

  String? _formatTo12Hour(String? time24) {
    if (time24 == null) return null;
    if (time24.contains('AM') || time24.contains('PM')) return time24;
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hours = int.parse(parts[0]);
      final minutes = parts[1];
      final period = hours >= 12 ? 'PM' : 'AM';
      hours = hours % 12;
      if (hours == 0) hours = 12;
      return '$hours:$minutes $period';
    } catch (_) {
      return time24;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use addPostFrameCallback to ensure the widget is fully built before starting timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize with default values immediately
      _remainingSecondsNotifier.value = _offerDuration;
      _isExpiredNotifier.value = false;
      _startTimer();

      // Then load the actual state asynchronously
      _loadTimerState();
    });
  }

  // Initialize timer with persistent storage
  Future<void> _loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedStartTime = prefs.getString(_timerStorageKey);

      if (storedStartTime != null) {
        // Restore existing timer
        _timerStartTime = DateTime.parse(storedStartTime);
        final remaining = _calculateRemainingSeconds();

        if (remaining <= 0) {
          // Timer already expired, auto-reject
          await _clearStoredTimer();
          _rejectOffer(autoReject: true);
          return;
        }

        _remainingSecondsNotifier.value = remaining;
      } else {
        // Start new timer
        _timerStartTime = DateTime.now();
        await prefs.setString(
            _timerStorageKey, _timerStartTime!.toIso8601String());
        _remainingSecondsNotifier.value = _offerDuration;
      }

      _startTimer();

      // Register with global timer service
      try {
        await TimerStateManager.clearTimerState(_timerKey);
        await _timerService.registerTimer(
          key: _timerKey,
          durationSeconds: _offerDuration,
          startTime: _timerStartTime!,
          restoreFromStorage: false,
        );
      } catch (e) {
        debugPrint('⚠️ Global timer registration failed: $e');
      }
    } catch (e) {
      debugPrint('Error loading timer state: $e');
    }
  }

  // Calculate remaining seconds based on elapsed time since start
  int _calculateRemainingSeconds() {
    if (_timerStartTime == null) return _offerDuration;
    final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
    final remaining = _offerDuration - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // Clear stored timer from SharedPreferences
  Future<void> _clearStoredTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerStorageKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when dependencies change
    // Use Future.microtask to avoid async in didChangeDependencies
    Future.microtask(() => _loadTimerState());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Calculate remaining time based on actual elapsed time
      final remaining = _calculateRemainingSeconds();

      // Update the ValueNotifier with calculated remaining time
      _remainingSecondsNotifier.value = remaining;

      // Check for expiration
      if (remaining <= 0) {
        timer.cancel();
        _clearStoredTimer();
        _isExpiredNotifier.value = true;
        _rejectOffer(autoReject: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app comes back from background, recalculate and update timer
      if (mounted && _timerStartTime != null && !_isExpiredNotifier.value) {
        final remaining = _calculateRemainingSeconds();
        _remainingSecondsNotifier.value = remaining;

        // If timer expired while in background, auto-reject
        if (remaining <= 0) {
          _isExpiredNotifier.value = true;
          _rejectOffer(autoReject: true);
        } else {
          _startTimer();
        }
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background, stop the timer
      _timer?.cancel();
    }
  }

  void _rejectOffer({bool autoReject = false}) async {
    if (_isExpiredNotifier.value) return; // Prevent multiple rejections

    _timer?.cancel();
    _isExpiredNotifier.value = true;

    try {
      // Clear stored timer from SharedPreferences
      await _clearStoredTimer();

      // Remove timer from GlobalTimerService
      await _timerService.removeTimer(_timerKey);

      // Remove driver from acceptedDriverId list and add to rejectedDriverId
      List<dynamic> acceptedDriverIds =
          List.from(widget.orderModel.acceptedDriverId ?? []);
      List<dynamic> rejectedDriverIds =
          List.from(widget.orderModel.rejectedDriverId ?? []);

      acceptedDriverIds.remove(widget.driverModel.id);
      if (!rejectedDriverIds.contains(widget.driverModel.id)) {
        rejectedDriverIds.add(widget.driverModel.id);
      }

      // Update Firestore
      await FireStoreUtils.updateIntercityOrder(widget.orderModel.id!, {
        'acceptedDriverId': acceptedDriverIds,
        'rejectedDriverId': rejectedDriverIds
      });

      // Also remove the per-driver accepted offer doc so the driver can re-apply
      await FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(widget.orderModel.id)
          .collection('acceptedDriver')
          .doc(widget.driverModel.id)
          .delete();

      // And remove any residual rejectedDriver sub-doc (if used by driver app)
      await FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(widget.orderModel.id)
          .collection('rejectedDriver')
          .doc(widget.driverModel.id)
          .delete()
          .catchError((_) {});

      // Show toast message
      final key = autoReject ? 'offerAutoRejectedToast' : 'offerRejectedToast';
      ShowToastDialog.showToast(key.tr);

      // Send notification to driver
      await SendNotification.sendOneNotification(
          token: widget.driverModel.fcmToken.toString(),
          title: 'Ride Canceled'.tr,
          body:
              'The passenger has canceled the ride. No action is required from your end.'
                  .tr,
          payload: {});
    } catch (e) {
      ShowToastDialog.showToast('Error rejecting offer: $e');
    }
  }

  void _handleAcceptOffer() async {
    if (_isExpiredNotifier.value) return; // Prevent accepting expired offers

    try {
      ShowToastDialog.showLoader('Please wait'.tr);

      // Clear stored timer from SharedPreferences
      await _clearStoredTimer();

      // Remove timer from GlobalTimerService
      await _timerService.removeTimer(_timerKey);

      // Check if driver is already busy with another trip
      bool activeOrder = await FireStoreUtils.currentDriverIntercityRideCheck(
          widget.driverModel.id.toString());
      if (activeOrder) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
          'Please select another driver. This driver is busy with another trip'
              .tr,
        );
        
        // Remove this driver's offer from the UI by rejecting it
        _rejectOffer(autoReject: true);
        return;
      }

      // Get the driver's offer amount
      final offerAmount = widget.offerData.offerAmount;

      // Update order with driver ID and final rate
      widget.orderModel.acceptedDriverId = [];
      widget.orderModel.driverId = widget.driverModel.id.toString();
      widget.orderModel.status = Constant.rideActive;
      widget.orderModel.finalRate = offerAmount;

      await FireStoreUtils.setInterCityOrder(widget.orderModel);

      // Send notification to driver
      await SendNotification.sendOneNotification(
          token: widget.driverModel.fcmToken.toString(),
          title: 'Ride Confirmed'.tr,
          body:
              'Your ride request has been accepted by the passenger. Please proceed to the pickup location.'
                  .tr,
          payload: {
            'orderId': widget.orderModel.id!,
            'type': 'intercity_order_accepted'
          });

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Offer accepted'.tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Error accepting offer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 0.5,
        ),
        boxShadow: widget.themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver profile section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: () {
                Get.to(
                  ReviewsScreen(
                    driverId: widget.driverModel.id ?? '',
                    driverName: widget.driverModel.fullName?.toString() ?? '',
                    orders: '0',
                  ),
                );
              },
              child: Row(
                children: [
                  // Driver image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.driverModel.profilePic ?? "",
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Constant.loader(),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/images/placeholder.jpg",
                        height: 48,
                        width: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverModel.fullName ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                Constant.calculateReview(
                                    reviewCount:
                                        (widget.driverModel.reviewsCount ??
                                                '0.0')
                                            .toString(),
                                    reviewSum:
                                        (widget.driverModel.reviewsSum ?? '0.0')
                                            .toString()),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // AC / Non-AC tag exactly like offers page (DriverView)
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: (widget.driverModel.vehicleInformation
                                                ?.is_AC !=
                                            null &&
                                        widget.driverModel.vehicleInformation
                                                ?.is_AC !=
                                            false)
                                    ? Row(
                                        children: const [
                                          Icon(Icons.ac_unit,
                                              size: 16, color: Colors.blue),
                                          SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              'مكيفة',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: const [
                                          Icon(Icons.not_interested_outlined,
                                              size: 16, color: Colors.red),
                                          SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              'بدون تكييف',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Offer amount (smaller to leave space for AC label)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.themeChange.getThem()
                          ? AppColors.darkModePrimary.withOpacity(0.08)
                          : AppColors.containerBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.themeChange.getThem()
                            ? AppColors.darkModePrimary.withOpacity(0.2)
                            : AppColors.containerBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      Constant.amountShow(
                          amount: widget.offerData.offerAmount ?? "0"),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: widget.themeChange.getThem()
                            ? AppColors.darkModePrimary
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Suggested Pickup Time + rules + passengers + notes (exactly like offers page)
          if (widget.offerData.suggestedDate != null ||
              widget.offerData.suggestedTime != null)
            Container(
              decoration: BoxDecoration(
                color: widget.themeChange.getThem()
                    ? AppColors.darkGray.withOpacity(0.5)
                    : AppColors.gray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Suggested Pickup Time".tr,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16,
                          color: widget.themeChange.getThem()
                              ? Colors.white70
                              : Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.offerData.suggestedDate ??
                            widget.orderModel.whenDates),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 16,
                          color: widget.themeChange.getThem()
                              ? Colors.white70
                              : Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        _formatTo12Hour(widget.offerData.suggestedTime) ??
                            "Original time".tr,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                  // Number of passengers
                  if ((widget.orderModel.numberOfPassenger ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_alt,
                            size: 16,
                            color: widget.themeChange.getThem()
                                ? Colors.white70
                                : Colors.black54),
                        const SizedBox(width: 6),
                        Text(widget.orderModel.numberOfPassenger.toString(),
                            style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  ],
                  // Notes
                  if ((widget.orderModel.comments ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 16,
                            color: widget.themeChange.getThem()
                                ? Colors.white70
                                : Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(widget.orderModel.comments!.trim(),
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                  // Driver rules inline
                  if ((widget.driverModel.vehicleInformation?.driverRules ?? [])
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...widget.driverModel.vehicleInformation!.driverRules!
                        .map((rule) {
                      final textColor = widget.themeChange.getThem()
                          ? Colors.white
                          : Colors.black;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: widget.themeChange.getThem()
                                    ? Colors.white
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Constant.localizationName(rule.name),
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Vehicle info section (exact as offers page)
          Container(
            decoration: BoxDecoration(
                color: widget.themeChange.getThem()
                    ? AppColors.darkGray
                    : AppColors.gray),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/ic_car.svg',
                          width: 18,
                          color: widget.themeChange.getThem()
                              ? Colors.white
                              : Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        Constant.localeVehicleType(
                            widget.driverModel.vehicleInformation!.vehicleType),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/ic_color.svg',
                          width: 18,
                          color: widget.themeChange.getThem()
                              ? Colors.white
                              : Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        _localizedColorName(widget
                            .driverModel.vehicleInformation!.vehicleColor),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Image.asset('assets/icons/ic_number.png',
                          width: 18,
                          color: widget.themeChange.getThem()
                              ? Colors.white
                              : Colors.black),
                      const SizedBox(width: 10),
                      Text(
                          widget.driverModel.vehicleInformation!.vehicleNumber
                              .toString(),
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600))
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Rules moved into Suggested Pickup Time section to match offers page

          // Action buttons (timer only inside Accept button)
          ValueListenableBuilder<bool>(
            valueListenable: _isExpiredNotifier,
            builder: (context, isExpired, _) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: widget.themeChange.getThem()
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 65,
                    child: Row(
                      children: [
                        Expanded(
                          child: ButtonThem.buildButton(
                            context,
                            title: 'Reject'.tr,
                            btnHeight: 45,
                            customColor: AppColors.darkModePrimary,
                            customTextColor: Colors.black,
                            onPress: isExpired
                                ? null
                                : () {
                                    try {
                                      if (!isExpired) _rejectOffer();
                                    } catch (e) {
                                      debugPrint('Error in reject offer: $e');
                                      ShowToastDialog.showToast(
                                          'Failed to reject offer. Please try again.');
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _remainingSecondsNotifier,
                            builder: (context, seconds, _) {
                              // Format the time as minutes:seconds
                              final minutes = (seconds / 60).floor();
                              final remainingSeconds = seconds % 60;
                              final timeDisplay =
                                  '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';

                              // Check if we're in the last 1 minute (60 seconds)
                              final isLastMinute = seconds <= 60;

                              return ButtonThem.buildButton(
                                context,
                                title: isExpired
                                    ? 'Expired'.tr
                                    : '${'Accept'.tr} ($timeDisplay)',
                                btnHeight: 45,
                                customColor: AppColors.darkModePrimary,
                                customTextColor:
                                    isLastMinute ? Colors.red : Colors.black,
                                btnWidthRatio: 0.8,
                                onPress: isExpired
                                    ? null
                                    : () {
                                        try {
                                          _timer?.cancel();
                                          _handleAcceptOffer();
                                        } catch (e) {
                                          debugPrint(
                                              'Error in accept offer: $e');
                                          ShowToastDialog.showToast(
                                              'Failed to accept offer. Please try again.');
                                          // Restart timer if accept fails
                                          _startTimer();
                                        }
                                      },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
