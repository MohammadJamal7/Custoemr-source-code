import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_rules_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/timer_state_manager.dart';
// Removed unused import
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer/ui/review/reviews_screen.dart';

// Inline offer widget for displaying offers in the search page
class InlineOfferWidget extends StatefulWidget {
  final DriverUserModel driverModel;
  final OrderModel orderModel;
  final DriverIdAcceptReject offerData;
  final DarkThemeProvider themeChange;

  const InlineOfferWidget({
    super.key,
    required this.driverModel,
    required this.orderModel,
    required this.offerData,
    required this.themeChange,
  });

  @override
  State<InlineOfferWidget> createState() => _InlineOfferWidgetState();
}

class _InlineOfferWidgetState extends State<InlineOfferWidget>
    with WidgetsBindingObserver {
  Timer? _timer;
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier<int>(60);
  final ValueNotifier<bool> _isExpiredNotifier = ValueNotifier<bool>(false);
  DateTime? _timerStartTime;
  static const int offerDuration = 60;
  String get _timerKey =>
      'offer_${widget.orderModel.id}_${widget.driverModel.id}';

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
      return enToAr[lower] ?? input;
    } else {
      return arToEn[input] ??
          (enToAr.containsKey(lower)
              ? lower[0].toUpperCase() + lower.substring(1)
              : input);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize timer for all offers
    // Use post-frame callback to ensure widget is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeTimer();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when dependencies change
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _remainingSecondsNotifier.dispose();
    _isExpiredNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    final timerState = await TimerStateManager.getTimerState(_timerKey);

    if (timerState != null && timerState.startTime != null) {
      _timerStartTime = timerState.startTime;
      final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      final remaining = offerDuration - elapsed;

      if (remaining > 0) {
        _remainingSecondsNotifier.value = remaining;
        _startTimer();
      } else {
        _remainingSecondsNotifier.value = 0;
        _isExpiredNotifier.value = true;
        _rejectOffer();
      }
    } else {
      _timerStartTime = DateTime.now();
      await TimerStateManager.saveTimerState(
        orderId: _timerKey,
        startTime: _timerStartTime,
        isRunning: true,
        phaseDuration: offerDuration,
      );
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_timerStartTime!).inSeconds;
      final remaining = offerDuration - elapsed;

      if (remaining > 0) {
        _remainingSecondsNotifier.value = remaining;
      } else {
        _timer?.cancel();
        _remainingSecondsNotifier.value = 0;
        _isExpiredNotifier.value = true;
        _rejectOffer();
      }
    });
  }

  void _rejectOffer() {
    _timer?.cancel();
    _isExpiredNotifier.value = true;
    TimerStateManager.clearTimerState(_timerKey);
    _processRejectOffer();
  }

  Future<void> _processRejectOffer() async {
    try {
      List<dynamic> rejectDriverId = widget.orderModel.rejectedDriverId ?? [];
      rejectDriverId.add(widget.driverModel.id);

      List<dynamic> acceptDriverId = widget.orderModel.acceptedDriverId ?? [];
      acceptDriverId.remove(widget.driverModel.id);

      widget.orderModel.rejectedDriverId = rejectDriverId;
      widget.orderModel.acceptedDriverId = acceptDriverId;

      await SendNotification.sendOneNotification(
        token: widget.driverModel.fcmToken.toString(),
        title: 'Ride Canceled'.tr,
        body:
            'The passenger has canceled the ride. No action is required from your end.'
                .tr,
        payload: {},
      );

      await FireStoreUtils.setOrder(widget.orderModel);

      if (mounted) {
        ShowToastDialog.showToast('Offer expired automatically'.tr);
      }
    } catch (e) {
      print('Error rejecting offer: $e');
    }
  }

  void _handleAcceptOffer() {
    _isExpiredNotifier.value = true;
    _processAcceptOffer();
  }

  Future<void> _processAcceptOffer() async {
    try {
      bool activeOrder = await FireStoreUtils.currentDriverRideCheck(
          widget.driverModel.id.toString());
      if (activeOrder) {
        ShowToastDialog.showToast(
          "Please select another driver. This driver is busy with another trip"
              .tr,
        );
      } else {
        widget.orderModel.acceptedDriverId = [];
        widget.orderModel.driverId = widget.driverModel.id.toString();
        widget.orderModel.status = Constant.rideActive;
        widget.orderModel.finalRate = widget.offerData.offerAmount;

        await FireStoreUtils.setOrder(widget.orderModel);
        await SendNotification.sendOneNotification(
          token: widget.driverModel.fcmToken.toString(),
          title: 'Ride Confirmed'.tr,
          body:
              'Your ride request has been accepted by the passenger. Please proceed to the pickup location.'
                  .tr,
          payload: {},
        );

        if (mounted) {
          ShowToastDialog.showToast('Offer accepted successfully'.tr);
        }
      }
    } catch (e) {
      print('Error accepting offer: $e');
      ShowToastDialog.showToast('Error accepting offer'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isExpiredNotifier,
      builder: (context, isExpired, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.themeChange.getThem()
                  ? AppColors.darkContainerBackground
                  : AppColors.containerBackground,
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
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
                        offset: const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      Get.to(
                        ReviewsScreen(
                          driverId: widget.driverModel.id ?? '',
                          driverName:
                              widget.driverModel.fullName?.toString() ?? '',
                          orders: '0',
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            imageUrl: widget.driverModel.profilePic.toString(),
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.driverModel.fullName.toString(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    () {
                                      final double sum = double.tryParse(widget
                                                  .driverModel.reviewsSum
                                                  ?.toString() ??
                                              "0") ??
                                          0.0;
                                      final double count = double.tryParse(
                                              widget.driverModel.reviewsCount
                                                      ?.toString() ??
                                                  "0") ??
                                          0.0;
                                      if (count > 0) {
                                        return (sum / count).toStringAsFixed(1);
                                      }
                                      return "0.0";
                                    }(),
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  // AC/Non-AC indicator near rating
                                  const SizedBox(width: 12),
                                  if (widget.driverModel.vehicleInformation
                                          ?.is_AC ==
                                      true) ...[
                                    const Icon(
                                      Icons.ac_unit,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'مكيفة',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.not_interested_outlined,
                                      size: 16,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'بدون',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[300],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  const Spacer(),
                                  // Display the actual offer amount
                                  Text(
                                    Constant.amountShow(
                                        amount: widget.offerData.offerAmount
                                            .toString()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: widget.themeChange.getThem()
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                          const SizedBox(width: 10),
                          Text(
                            widget.driverModel.vehicleInformation != null
                                ? Constant.localeVehicleType(widget.driverModel
                                    .vehicleInformation!.vehicleType)
                                : "Vehicle",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
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
                          const SizedBox(width: 10),
                          Text(
                            widget.driverModel.vehicleInformation != null
                                ? _localizedColorName(widget.driverModel
                                    .vehicleInformation!.vehicleColor)
                                : "Color",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: widget.themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black,
                            ),
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
                          const SizedBox(width: 10),
                          Text(
                            widget.driverModel.vehicleInformation != null
                                ? widget.driverModel.vehicleInformation!
                                    .vehicleNumber
                                    .toString()
                                : "Number",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                      // Removed AC/Non-AC indicator here to avoid duplication; it is now shown near the rating.
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                (widget.driverModel.vehicleInformation?.driverRules != null)
                    ? SizedBox(
                        height: widget.driverModel.vehicleInformation!
                                .driverRules!.length *
                            40.0,
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: widget.driverModel.vehicleInformation!
                              .driverRules!.length,
                          itemBuilder: (context, index) {
                            DriverRulesModel driverRules = widget.driverModel
                                .vehicleInformation!.driverRules![index];
                            return Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: driverRules.image.toString(),
                                    fit: BoxFit.fill,
                                    color: widget.themeChange.getThem()
                                        ? Colors.white
                                        : Colors.black,
                                    height: Responsive.width(4, context),
                                    width: Responsive.width(4, context),
                                    placeholder: (context, url) =>
                                        Constant.loader(),
                                    errorWidget: (context, url, error) =>
                                        Image.network(
                                      Constant.userPlaceHolder,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      Constant.localizationName(
                                        driverRules.name,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 10),
                _buildOfferButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfferButtons() {
    return Container(
      height: 65,
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isExpiredNotifier,
        builder: (context, isExpired, _) {
          return Row(
            children: [
              Expanded(
                child: ButtonThem.buildButton(
                  context,
                  title: 'Reject'.tr,
                  btnHeight: 45,
                  customColor: AppColors.darkModePrimary,
                  customTextColor: Colors.black,
                  onPress: isExpired
                      ? () {
                          return true;
                        }
                      : () {
                          if (!isExpired) _rejectOffer();
                          return true;
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _remainingSecondsNotifier,
                  builder: (context, seconds, _) {
                    // Change text color to red when timer reaches last 10 seconds
                    final bool isLastMinute = seconds <= 10 && seconds > 0;

                    return ButtonThem.buildButton(
                      context,
                      title: isExpired
                          ? 'Expired'.tr
                          : '${'Accept'.tr} (${seconds}s)',
                      btnHeight: 45,
                      customColor: AppColors.darkModePrimary,
                      customTextColor: isLastMinute ? Colors.red : Colors.black,
                      onPress: isExpired
                          ? () {
                              return true;
                            }
                          : () {
                              _timer?.cancel();
                              _handleAcceptOffer();
                              return true;
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
