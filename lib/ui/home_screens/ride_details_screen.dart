import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:provider/provider.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/language_name.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/home_screens/home_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../dashboard_screen.dart';
import 'dart:typed_data';

class RideDetailsScreen extends StatelessWidget {
  final HomeController controller;
  const RideDetailsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final srcLat = controller.sourceLocationLAtLng.value.latitude;
    final srcLng = controller.sourceLocationLAtLng.value.longitude;
    final dstLat = controller.destinationLocationLAtLng.value.latitude;
    final dstLng = controller.destinationLocationLAtLng.value.longitude;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Ride Details'.tr,
            style:
                GoogleFonts.poppins(fontSize: Responsive.height(2.2, context))),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map at the top, fixed height, always interactive
          if (srcLat != null &&
              srcLng != null &&
              dstLat != null &&
              dstLng != null)
            SizedBox(
              height: Responsive.height(32, context), // ~220-260px
              width: double.infinity,
              child: RouteMapWidget(
                source: LatLng(srcLat, srcLng),
                destination: LatLng(dstLat, dstLng),
                showRoute: true,
              ),
            ),
          // Scrollable content below the map
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(3, context),
                vertical: Responsive.height(2, context),
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Service Display
                  Container(
                    padding: EdgeInsets.all(Responsive.width(3, context)),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppColors.darkService
                          : Colors
                              .white, // ✅ White background for seamless vehicle images
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                            0.3), // ✅ Slightly stronger border for definition
                        width:
                            1.5, // ✅ Slightly thicker border for better contrast
                      ),
                      // ✅ Add subtle shadow for depth and definition
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: Responsive.width(12, context),
                          height: Responsive.width(12, context),
                          decoration: BoxDecoration(
                            // ✅ Removed redundant white background - card is already white
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl:
                                  controller.selectedType.value.image ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                                size: Responsive.width(6, context),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                                size: Responsive.width(6, context),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.width(3, context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selected Service".tr,
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.height(1.6, context),
                                  color: AppColors
                                      .darkModePrimary, // ✅ App's green color
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: Responsive.height(0.5, context)),
                              Text(
                                Constant.localizationTitle(
                                    controller.selectedType.value.title),
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.height(2, context),
                                  fontWeight: FontWeight.w600,
                                  // Force proper contrast: white text on dark, black on light
                                  color: themeChange.getThem()
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: AppColors.darkModePrimary,
                          size: Responsive.width(5, context),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Responsive.height(2, context)),

                  // Removed service type selector - now handled on home screen
                  _buildSuggestedPrice(context, controller),
                  SizedBox(height: Responsive.height(1.5, context)),
                  Visibility(
                    visible: controller.selectedType.value.offerRate == true,
                    child: TextFieldThem.buildTextFiledWithPrefixIcon(
                      context,
                      hintText: "Enter your offer rate".tr,
                      controller: controller.offerYourRateController.value,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9*]')),
                      ],
                      prefix: Padding(
                        padding: EdgeInsets.only(
                            right: Responsive.width(2, context)),
                        child: Text(Constant.currencyModel!.symbol.toString()),
                      ),
                      keyBoardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(height: Responsive.height(1.5, context)),
                  InkWell(
                    onTap: () {
                      controller.someOneTakingDialog(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        border: Border.all(
                            color: AppColors.textFieldBorder, width: 1),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.width(2, context),
                          vertical: Responsive.height(1.2, context),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            SizedBox(width: Responsive.width(2, context)),
                            Expanded(
                              child: Obx(() {
                                final name = controller
                                    .selectedTakingRide.value.fullName;
                                final displayName = (name == null ||
                                        name.isEmpty ||
                                        name == "Myself".tr)
                                    ? "Myself".tr
                                    : name;
                                return Text(
                                  displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                        Responsive.height(1.8, context),
                                  ),
                                );
                              }),
                            ),
                            const Icon(Icons.arrow_drop_down_outlined)
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.height(1.5, context)),
                  InkWell(
                    onTap: () {
                      controller.paymentMethodDialog(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        border: Border.all(
                            color: AppColors.textFieldBorder, width: 1),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.width(2, context),
                          vertical: Responsive.height(1.2, context),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/icons/ic_payment.svg',
                                width: Responsive.width(6, context)),
                            SizedBox(width: Responsive.width(2, context)),
                            Expanded(
                              child: Obx(() => Text(
                                    controller.selectedPaymentMethod.value
                                            .isNotEmpty
                                        ? (controller.selectedPaymentMethod
                                                    .value ==
                                                "Cash"
                                            ? "Cash".tr
                                            : "Wallet".tr)
                                        : "Select Payment type".tr,
                                    style: GoogleFonts.poppins(
                                        fontSize:
                                            Responsive.height(1.8, context)),
                                  )),
                            ),
                            const Icon(Icons.arrow_drop_down_outlined)
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.height(2, context)),
                  ButtonThem.buildButton(
                    context,
                    title: "Book Ride".tr,
                    btnWidthRatio: Responsive.width(100, context),
                    customColor: AppColors.darkModePrimary,
                    customTextColor: Colors.black, // Black text in all modes
                    onPress: () async {
                      await _bookRide(context, controller);
                    },
                  ),
                  SizedBox(height: Responsive.height(2, context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrice(BuildContext context, HomeController controller) {
    final themeChange =
        Provider.of<DarkThemeProvider>(context); // ✅ Get theme provider
    return Obx(
      () => controller.sourceLocationLAtLng.value.latitude != null &&
              controller.destinationLocationLAtLng.value.latitude != null &&
              controller.amount.value.isNotEmpty
          ? Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Container(
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                      // ✅ Adaptive background for light/dark mode
                      color: themeChange.getThem()
                          ? AppColors
                              .darkService // Dark mode: use dark service color
                          : AppColors.gray, // Light mode: keep original gray
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      // ✅ Add subtle border for better definition
                      border: Border.all(
                        color: themeChange.getThem()
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Center(
                        child: controller.selectedType.value.offerRate == true
                            ? RichText(
                                text: TextSpan(
                                  text:
                                      '${"Approx time".tr} ${Constant.getLocalizedTime(controller.duration.value)}. ${"Approx distance".tr} ${double.parse(controller.distance.value).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.getLocalizedDistanceUnit()}',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              )
                            : RichText(
                                text: TextSpan(
                                  text:
                                      '${"Approx time".tr} ${Constant.getLocalizedTime(controller.duration.value)}. ${"Approx distance".tr} ${double.parse(controller.distance.value).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.getLocalizedDistanceUnit()}',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(),
    );
  }

  Future<void> _bookRide(
      BuildContext context, HomeController controller) async {
    double offerRate = double.parse(
        controller.offerYourRateController.value.text.isEmpty
            ? '0.0'
            : controller.offerYourRateController.value.text);

    // ✅ GUEST CHECK: Prevent guests from booking rides
    if (controller.userModel.value.fullName?.isEmpty == true ||
        controller.userModel.value.fullName == null) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  "Login Required".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "To book a ride, you need to login to your account first.".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please login or create an account to continue.".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Cancel".tr,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.offAll(() => const LoginScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  "Login Now".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    if (controller.userModel.value.isActive == false) {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (con) {
            return AlertDialog(
              content: Text(
                  "This account is not active please contact administrator".tr),
              actions: [
                TextButton(
                    onPressed: () {
                      Get.offAll(LoginScreen());
                    },
                    child: Text("OK".tr))
              ],
            );
          });
    } else {
      bool isPaymentNotCompleted = await FireStoreUtils.paymentStatusCheck();
      bool isCurrentRide = await FireStoreUtils.currentCheckRideCheck();
      if (controller.selectedPaymentMethod.value.isEmpty) {
        ShowToastDialog.showToast("Please select Payment Method".tr);
      } else if (controller.sourceLocationController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please select source location".tr);
      } else if (controller.destinationLocationController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please select destination location".tr);
      } else if (controller.sourceLocationLAtLng.value.latitude == null ||
          controller.sourceLocationLAtLng.value.longitude == null) {
        ShowToastDialog.showToast(
            "Source location coordinates are missing. Please select a valid source location."
                .tr);
      } else if (controller.destinationLocationLAtLng.value.latitude == null ||
          controller.destinationLocationLAtLng.value.longitude == null) {
        ShowToastDialog.showToast(
            "Destination location coordinates are missing. Please select a valid destination location."
                .tr);
      } else if (double.parse(controller.distance.value) <= 2) {
        ShowToastDialog.showToast("Please select more than two location".tr);
      } else if (controller.selectedType.value.offerRate == true &&
          controller.offerYourRateController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please Enter offer rate".tr);
      } else if (isPaymentNotCompleted) {
        controller.showAlertDialog(context);
      } else if (isCurrentRide) {
        ShowToastDialog.showToast("Please Complete Your Current Ride".tr);
      } else if (offerRate < 1000) {
        ShowToastDialog.showToast("priceOffer".tr);
      } else {
        OrderModel orderModel = OrderModel();
        orderModel.id = Constant.getUuid();
        orderModel.userId = FireStoreUtils.getCurrentUid();
        orderModel.sourceLocationName =
            controller.sourceLocationController.value.text;
        orderModel.destinationLocationName =
            controller.destinationLocationController.value.text;
        orderModel.sourceLocationLAtLng = controller.sourceLocationLAtLng.value;
        orderModel.destinationLocationLAtLng =
            controller.destinationLocationLAtLng.value;
        orderModel.distance = controller.distance.value;
        orderModel.distanceType = Constant.distanceType;
        orderModel.offerRate = controller.selectedType.value.offerRate == true
            ? controller.offerYourRateController.value.text
            : controller.amount.value;
        orderModel.serviceId = controller.selectedType.value.id;
        GeoFirePoint position = Geoflutterfire().point(
            latitude: controller.sourceLocationLAtLng.value.latitude!,
            longitude: controller.sourceLocationLAtLng.value.longitude!);
        orderModel.position =
            Positions(geoPoint: position.geoPoint, geohash: position.hash);
        orderModel.createdDate = Timestamp.now();
        orderModel.status = Constant.ridePlaced;
        orderModel.paymentType = controller.selectedPaymentMethod.value;
        orderModel.paymentStatus = false;
        orderModel.service = controller.selectedType.value;
        orderModel.adminCommission =
            controller.selectedType.value.adminCommission!.isEnabled == false
                ? controller.selectedType.value.adminCommission!
                : Constant.adminCommission;
        orderModel.otp = Constant.getReferralCode();
        orderModel.duration = controller.duration.value;
        orderModel.taxList = Constant.taxList;
        if (controller.selectedTakingRide.value.fullName != "Myself") {
          orderModel.someOneElse = controller.selectedTakingRide.value;
        }
        List<ZoneModel> foundZones = [];
        for (int i = 0; i < controller.zoneList.length; i++) {
          if (Constant.isPointInPolygon(
              LatLng(
                  double.parse(controller.sourceLocationLAtLng.value.latitude
                      .toString()),
                  double.parse(controller.sourceLocationLAtLng.value.longitude
                      .toString())),
              controller.zoneList[i].area!)) {
            foundZones.add(controller.zoneList[i]);
          }
        }
        if (foundZones.isNotEmpty) {
          controller.selectedZone.value = controller.zoneList[0];
          orderModel.zoneId = controller.selectedZone.value.id;
          orderModel.zoneIds = foundZones.map((e) => e.id).toList();
          orderModel.zone = controller.selectedZone.value;
          orderModel.zones = foundZones;
          orderModel.duration = controller.duration.value;
          FireStoreUtils().sendOrderData(orderModel).listen((event) {
            event.forEach((element) async {
              if (element.fcmToken != null) {
                Map<String, dynamic> playLoad = <String, dynamic>{
                  "type": "city_order",
                  "orderId": orderModel.id
                };
                await SendNotification.sendOneNotification(
                    token: element.fcmToken.toString(),
                    title: 'New Ride Available'.tr,
                    body:
                        'A customer has placed an ride near your location.'.tr,
                    payload: playLoad);
              }
            });
            FireStoreUtils().closeStream();
          });
          await FireStoreUtils.setOrder(orderModel).then((value) {
            ShowToastDialog.showToast("Ride Placed successfully".tr);
            Get.offAll(const DashBoardScreen());
          });
        } else {
          ShowToastDialog.showToast(
              "Services are currently unavailable on the selected location. Please reach out to the administrator for assistance."
                  .tr,
              position: EasyLoadingToastPosition.center);
        }
      }
    }
  }
}

class RouteMapWidget extends StatefulWidget {
  final LatLng source;
  final LatLng? destination;
  final bool showRoute;
  // New for live tracking
  final LatLng? driverLocation;
  final double? carRotation;
  final bool showLiveTracking;
  const RouteMapWidget({
    super.key,
    required this.source,
    this.destination,
    this.showRoute = false,
    this.driverLocation,
    this.carRotation,
    this.showLiveTracking = false,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _departureIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    if (widget.showLiveTracking && widget.driverLocation != null) {
      _initLiveTracking();
    } else if (widget.showRoute && widget.destination != null) {
      _initRouteMap();
    } else {
      // No driver yet - show pickup location with animated marker
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
      _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear),
      );

      // Initialize pickup marker asynchronously
      _initPickupMarker();
    }
  }

  Future<void> _initPickupMarker() async {
    try {
      // Load the same pickup icon as live tracking
      final Uint8List departure =
          await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      _departureIcon = BitmapDescriptor.fromBytes(departure);
    } catch (e) {
      _departureIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    if (mounted) {
      setState(() {
        // Add pickup marker with animation using the same icon as live tracking
        _markers = {
          Marker(
            markerId: const MarkerId('Pickup'),
            position: widget.source,
            icon: _departureIcon!,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndex: 1,
          ),
        };
        _loading = false;
      });
    }
  }

  Future<void> _initLiveTracking() async {
    try {
      // Load the exact same assets as LiveTrackingController
      final Uint8List departure =
          await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      final Uint8List destination =
          await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);
      final Uint8List driver =
          await Constant().getBytesFromAsset('assets/images/ic_cab.png', 50);

      _departureIcon = BitmapDescriptor.fromBytes(departure);
      _destinationIcon = BitmapDescriptor.fromBytes(destination);
      _carIcon = BitmapDescriptor.fromBytes(driver);
    } catch (e) {
      _departureIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _destinationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _carIcon = BitmapDescriptor.defaultMarker;
    }

    // Progressive markers based on ride status
    print(
        '🎯 Marker Debug: showLiveTracking=${widget.showLiveTracking}, driverLocation=${widget.driverLocation}, destination=${widget.destination}');

    _markers = {
      // Always include pickup marker using the same icon as live tracking
      Marker(
        markerId: const MarkerId('Pickup'),
        position: widget.source,
        icon: _departureIcon!,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
      ),
      // Include drop-off marker using the same icon as live tracking
      if (widget.showLiveTracking && widget.destination != null)
        Marker(
          markerId: const MarkerId('Dropoff'),
          position: widget.destination!,
          icon: _destinationIcon!,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 1,
        ),
      // Include driver marker if available (keep car icon for driver)
      if (widget.driverLocation != null)
        Marker(
          markerId: const MarkerId('Driver'),
          position: widget.driverLocation!,
          icon: _carIcon!,
          rotation: widget.carRotation ?? 0.0,
        ),
    };

    print('🎯 Markers created: ${_markers.length} markers');
    for (var marker in _markers) {
      print('  - ${marker.markerId.value}: ${marker.position}');
    }

    // Fetch route for live tracking
    print(
        '🎯 Route Fetch Check: showLiveTracking=${widget.showLiveTracking}, driverLocation=${widget.driverLocation != null}, destination=${widget.destination != null}');
    if (widget.showLiveTracking &&
        widget.driverLocation != null &&
        widget.destination != null) {
      print('🎯 Fetching route...');
      await _fetchLiveRoute();
    } else {
      print('🎯 Route fetch skipped - conditions not met');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchLiveRoute() async {
    try {
      if (!mounted ||
          widget.driverLocation == null ||
          widget.destination == null) return;

      final apiKey = Constant.mapAPIKey;
      final origin =
          '${widget.driverLocation!.latitude},${widget.driverLocation!.longitude}';
      final destination =
          '${widget.destination!.latitude},${widget.destination!.longitude}';

      print(
          '🔍 Fetching route: origin=$origin, destination=$destination, showLiveTracking=${widget.showLiveTracking}');
      print(
          '🎯 RouteMapWidget Debug: source=${widget.source}, destination=${widget.destination}, driverLocation=${widget.driverLocation}');
      print(
          '📍 Route Details: from driver (${widget.driverLocation!.latitude}, ${widget.driverLocation!.longitude}) to destination (${widget.destination!.latitude}, ${widget.destination!.longitude})');

      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey&mode=driving';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylineCoords = _decodePolyline(points);
          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('poly'),
                  points: polylineCoords,
                  consumeTapEvents: true,
                  startCap: Cap.roundCap,
                  width: 4,
                  color: Colors.black,
                ),
              };
            });
            print(
                '🎯 Route drawn successfully with ${polylineCoords.length} points');
          }
          // Position camera to show driver and destination
          await Future.delayed(const Duration(milliseconds: 300));
          if (widget.showLiveTracking && widget.destination != null) {
            // Ride Active: position camera to show driver and dropoff
            _updateCameraLocation(widget.driverLocation!, widget.destination!);
          } else if (widget.destination != null &&
              widget.driverLocation != null) {
            // Driver accepted but ride not started: position camera to show driver and pickup
            _updateCameraLocation(widget.driverLocation!, widget.destination!);
          }
        }
      }
    } catch (e) {
      print('Live route fetch error: $e');
    }
  }

  Future<void> _updateCameraLocation(LatLng source, LatLng destination) async {
    if (_mapController == null || !mounted) return;

    try {
      // Calculate bounds to include both driver location and destination
      LatLngBounds bounds;

      if (source.latitude > destination.latitude &&
          source.longitude > destination.longitude) {
        bounds = LatLngBounds(southwest: destination, northeast: source);
      } else if (source.longitude > destination.longitude) {
        bounds = LatLngBounds(
            southwest: LatLng(source.latitude, destination.longitude),
            northeast: LatLng(destination.latitude, source.longitude));
      } else if (source.latitude > destination.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(destination.latitude, source.longitude),
            northeast: LatLng(source.latitude, destination.longitude));
      } else {
        bounds = LatLngBounds(southwest: source, northeast: destination);
      }

      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
      await _checkCameraLocation(cameraUpdate, _mapController!);
    } catch (e) {
      print('Camera location update error: $e');
    }
  }

  Future<void> _checkCameraLocation(
      CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    try {
      if (!mounted) return;

      mapController.animateCamera(cameraUpdate);
      LatLngBounds l1 = await mapController.getVisibleRegion();
      LatLngBounds l2 = await mapController.getVisibleRegion();

      if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
        if (mounted) {
          return _checkCameraLocation(cameraUpdate, mapController);
        }
      }
    } catch (e) {
      print('Camera location check error: $e');
    }
  }

  @override
  void dispose() {
    try {
      // Cancel any ongoing operations
      if (!widget.showRoute && !widget.showLiveTracking) {
        _animationController.dispose();
      }

      // Properly dispose map controller with delay
      if (_mapController != null) {
        // Add a small delay to ensure all operations are complete
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            if (_mapController != null) {
              _mapController!.dispose();
              _mapController = null;
            }
          } catch (e) {
            print('Delayed map controller disposal error: $e');
          }
        });
      }

      // Clear markers and polylines
      _markers.clear();
      _polylines.clear();
    } catch (e) {
      print('Map controller disposal error: $e');
    }
    super.dispose();
  }

  Future<void> _initRouteMap() async {
    try {
      // Load the same assets as live tracking
      final Uint8List departure =
          await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      final Uint8List destination =
          await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);

      _departureIcon = BitmapDescriptor.fromBytes(departure);
      _destinationIcon = BitmapDescriptor.fromBytes(destination);
    } catch (e) {
      _departureIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _destinationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    // Add pickup and drop-off markers using the same icons as live tracking
    _markers = {
      Marker(
        markerId: const MarkerId('source'),
        position: widget.source,
        icon: _departureIcon!,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!,
        icon: _destinationIcon!,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
      ),
    };
    // Fetch route polyline
    await _fetchRoute();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchRoute() async {
    try {
      if (!mounted || widget.destination == null) return;

      final apiKey = Constant.mapAPIKey;
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.source.latitude},${widget.source.longitude}&destination=${widget.destination!.latitude},${widget.destination!.longitude}&key=$apiKey&mode=driving';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylineCoords = _decodePolyline(points);
          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.black,
                  width: 4,
                  points: polylineCoords,
                ),
              };
            });
          }
          // Fit camera to route
          await Future.delayed(const Duration(milliseconds: 300));
          _fitCameraToRoute(polylineCoords);
        }
      }
    } catch (e) {
      print('Route fetch error: $e');
    }
  }

  void _fitCameraToRoute(List<LatLng> routePoints) async {
    if (_mapController == null || routePoints.isEmpty || !mounted) return;

    try {
      // Calculate bounds to include both driver location and destination
      final driverLocation = widget.driverLocation ?? widget.source;
      final destination = widget.destination ?? widget.source;

      // Calculate distance between source and destination to determine appropriate padding
      final distance = _calculateDistance(driverLocation, destination);
      print('🗺️ Route distance: ${distance.toStringAsFixed(2)} km');

      // Smart padding calculation based on route distance
      double padding;
      if (distance > 500) {
        // Very long routes (500+ km) - like Irbid to Aqaba - minimal padding to show both points
        padding = 10;
      } else if (distance > 300) {
        // Long routes (300-500 km)
        padding = 15;
      } else if (distance > 200) {
        // Medium-long routes (200-300 km)
        padding = 25;
      } else if (distance > 100) {
        // Medium routes (100-200 km)
        padding = 40;
      } else if (distance > 50) {
        // Short-medium routes (50-100 km)
        padding = 50;
      } else {
        // Short routes (< 50 km)
        padding = 80;
      }

      // Use the existing _calculateOptimalBounds method but with route points included
      List<LatLng> allPoints = [driverLocation, destination];
      allPoints.addAll(routePoints);

      LatLngBounds bounds = _calculateOptimalBounds(allPoints);

      // Add extra margin to bounds for better visibility of long routes
      if (distance > 100) {
        final latRange = bounds.northeast.latitude - bounds.southwest.latitude;
        final lngRange =
            bounds.northeast.longitude - bounds.southwest.longitude;

        // Larger margin for very long routes to ensure both points are clearly visible
        double marginPercent;
        if (distance > 500) {
          marginPercent =
              0.15; // 15% margin for very long routes like Irbid to Aqaba
        } else if (distance > 300) {
          marginPercent = 0.12; // 12% margin for long routes
        } else {
          marginPercent = 0.1; // 10% margin for medium routes
        }

        final latMargin = latRange * marginPercent;
        final lngMargin = lngRange * marginPercent;

        bounds = LatLngBounds(
          southwest: LatLng(
            bounds.southwest.latitude - latMargin,
            bounds.southwest.longitude - lngMargin,
          ),
          northeast: LatLng(
            bounds.northeast.latitude + latMargin,
            bounds.northeast.longitude + lngMargin,
          ),
        );
      }

      print('🗺️ Applying bounds with padding: $padding');
      print('🗺️ SW: ${bounds.southwest}, NE: ${bounds.northeast}');

      if (_mapController != null && mounted) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
        // Double animation workaround for Google Maps Flutter
        await Future.delayed(const Duration(milliseconds: 350));
        if (_mapController != null && mounted) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, padding),
          );
        }
      }
    } catch (e) {
      print('Map camera animation error: $e');
      // Enhanced fallback with smart zoom based on distance
      if (_mapController != null && mounted) {
        try {
          final fallbackLocation = widget.driverLocation ?? widget.source;
          final distance = _calculateDistance(
              widget.source, widget.destination ?? widget.source);

          // Smart fallback zoom based on distance
          double fallbackZoom;
          if (distance > 500) {
            fallbackZoom = 4; // Very wide country level
          } else if (distance > 300) {
            fallbackZoom = 5; // Wide country level
          } else if (distance > 200) {
            fallbackZoom = 6; // Regional level
          } else if (distance > 100) {
            fallbackZoom = 8; // Large city level
          } else if (distance > 50) {
            fallbackZoom = 10; // City level
          } else {
            fallbackZoom = 13; // District level
          }

          print(
              '🗺️ Using fallback zoom: $fallbackZoom for distance: ${distance.toStringAsFixed(2)} km');

          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(fallbackLocation, fallbackZoom),
          );
        } catch (fallbackError) {
          print('Map fallback animation error: $fallbackError');
        }
      }
    }
  }

  // Helper method to calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper method to get smart initial camera position based on route distance
  CameraPosition _getSmartInitialCameraPosition(LatLng point1, LatLng point2) {
    final distance = _calculateDistance(point1, point2);

    // Calculate center point
    final centerLat = (point1.latitude + point2.latitude) / 2;
    final centerLng = (point1.longitude + point2.longitude) / 2;

    // Smart zoom based on distance
    double zoom;
    if (distance > 500) {
      zoom = 4; // Very wide country level - for routes like Irbid to Aqaba
    } else if (distance > 300) {
      zoom = 5; // Wide country level
    } else if (distance > 200) {
      zoom = 6; // Regional level
    } else if (distance > 100) {
      zoom = 8; // Large city level
    } else if (distance > 50) {
      zoom = 10; // City level
    } else if (distance > 10) {
      zoom = 12; // District level
    } else {
      zoom = 14; // Neighborhood level
    }

    print(
        '🗺️ Smart initial camera: distance=${distance.toStringAsFixed(2)}km, zoom=$zoom');

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }

  LatLngBounds _calculateOptimalBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    if (widget.showLiveTracking && widget.driverLocation != null) {
      try {
        // Calculate initial bounds to show both driver and destination
        final driverLocation = widget.driverLocation!;
        final destination = widget.destination ?? widget.source;

        LatLngBounds initialBounds;
        if (driverLocation.latitude > destination.latitude &&
            driverLocation.longitude > destination.longitude) {
          initialBounds =
              LatLngBounds(southwest: destination, northeast: driverLocation);
        } else if (driverLocation.longitude > destination.longitude) {
          initialBounds = LatLngBounds(
              southwest: LatLng(driverLocation.latitude, destination.longitude),
              northeast:
                  LatLng(destination.latitude, driverLocation.longitude));
        } else if (driverLocation.latitude > destination.latitude) {
          initialBounds = LatLngBounds(
              southwest: LatLng(destination.latitude, driverLocation.longitude),
              northeast:
                  LatLng(driverLocation.latitude, destination.longitude));
        } else {
          initialBounds =
              LatLngBounds(southwest: driverLocation, northeast: destination);
        }

        return GoogleMap(
          initialCameraPosition:
              _getSmartInitialCameraPosition(driverLocation, destination),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            try {
              if (mounted) {
                _mapController = controller;
              }
            } catch (e) {
              print('Map controller creation error: $e');
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.terrain,
          zoomControlsEnabled: true,
          padding: const EdgeInsets.only(top: 22.0),
          mapToolbarEnabled: true,
          liteModeEnabled: false,
          compassEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer()),
          },
        );
      } catch (e) {
        print('GoogleMap widget error: $e');
        return Container(
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
    if (widget.showRoute && widget.destination != null) {
      // Show route with both markers and polyline
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _getSmartInitialCameraPosition(
                widget.driverLocation ?? widget.source,
                widget.destination!,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                try {
                  if (mounted) {
                    _mapController = controller;
                  }
                } catch (e) {
                  print('Map controller creation error (route): $e');
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: false,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              mapType: MapType.normal,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()),
              },
            ),
            // Custom Zoom Controls for Route Map
            Positioned(
              bottom: 18,
              right: 18,
              child: Column(
                children: [
                  // Zoom In Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        try {
                          if (_mapController != null && mounted) {
                            await _mapController!.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          }
                        } catch (e) {
                          print('Zoom in error: $e');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.darkModePrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Zoom Out Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        try {
                          if (_mapController != null && mounted) {
                            await _mapController!.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          }
                        } catch (e) {
                          print('Zoom out error: $e');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.remove,
                          color: AppColors.darkModePrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Show animated pickup spot and recenter button
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.source,
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                try {
                  if (mounted) {
                    _mapController = controller;
                  }
                } catch (e) {
                  print('Map controller creation error (animated): $e');
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: false,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              mapType: MapType.normal,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()),
              },
            ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          final delay = i * 0.33;
                          double t = (_pulseAnimation.value + delay) % 1.0;
                          return CustomPaint(
                            painter: _PulsePainter(
                              value: t,
                              color: AppColors.darkModePrimary
                                  .withOpacity(0.25 - i * 0.07),
                            ),
                            child: SizedBox(width: 160, height: 160),
                          );
                        }),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.darkModePrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.darkModePrimary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Custom Zoom Controls
            Positioned(
              bottom: 80,
              right: 18,
              child: Column(
                children: [
                  // Zoom In Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        try {
                          if (_mapController != null && mounted) {
                            await _mapController!.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          }
                        } catch (e) {
                          print('Zoom in error: $e');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.darkModePrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Zoom Out Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        try {
                          if (_mapController != null && mounted) {
                            await _mapController!.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          }
                        } catch (e) {
                          print('Zoom out error: $e');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.remove,
                          color: AppColors.darkModePrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    try {
                      if (_mapController != null && mounted) {
                        // Show both driver location and destination
                        final driverLocation =
                            widget.driverLocation ?? widget.source;
                        final destination = widget.destination ?? widget.source;

                        LatLngBounds bounds;
                        if (driverLocation.latitude > destination.latitude &&
                            driverLocation.longitude > destination.longitude) {
                          bounds = LatLngBounds(
                              southwest: destination,
                              northeast: driverLocation);
                        } else if (driverLocation.longitude >
                            destination.longitude) {
                          bounds = LatLngBounds(
                              southwest: LatLng(driverLocation.latitude,
                                  destination.longitude),
                              northeast: LatLng(destination.latitude,
                                  driverLocation.longitude));
                        } else if (driverLocation.latitude >
                            destination.latitude) {
                          bounds = LatLngBounds(
                              southwest: LatLng(destination.latitude,
                                  driverLocation.longitude),
                              northeast: LatLng(driverLocation.latitude,
                                  destination.longitude));
                        } else {
                          bounds = LatLngBounds(
                              southwest: driverLocation,
                              northeast: destination);
                        }

                        await _mapController!.animateCamera(
                          CameraUpdate.newLatLngBounds(bounds, 50),
                        );
                      }
                    } catch (e) {
                      print('Map recenter error: $e');
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: AppColors.darkModePrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class RouteMapWidgetSimple extends StatefulWidget {
  final LatLng source;
  const RouteMapWidgetSimple({super.key, required this.source});

  @override
  State<RouteMapWidgetSimple> createState() => _RouteMapWidgetSimpleState();
}

class _RouteMapWidgetSimpleState extends State<RouteMapWidgetSimple>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _loading = false;
  }

  @override
  void dispose() {
    try {
      _animationController.dispose();

      // Properly dispose map controller with delay
      if (_mapController != null) {
        // Add a small delay to ensure all operations are complete
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            if (_mapController != null) {
              _mapController!.dispose();
              _mapController = null;
            }
          } catch (e) {
            print('Delayed simple map controller disposal error: $e');
          }
        });
      }
    } catch (e) {
      print('Simple map controller disposal error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }
    // Show animated pickup spot and recenter button
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.source,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              try {
                if (mounted) {
                  _mapController = controller;
                }
              } catch (e) {
                print('Map controller creation error (simple): $e');
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            liteModeEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            mapType: MapType.normal,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
            },
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (i) {
                        final delay = i * 0.33;
                        double t = (_pulseAnimation.value + delay) % 1.0;
                        return CustomPaint(
                          painter: _PulsePainter(
                            value: t,
                            color: AppColors.darkModePrimary
                                .withOpacity(0.25 - i * 0.07),
                          ),
                          child: SizedBox(width: 160, height: 160),
                        );
                      }),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.darkModePrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.darkModePrimary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Custom Zoom Controls
          Positioned(
            bottom: 80,
            right: 18,
            child: Column(
              children: [
                // Zoom In Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      try {
                        if (_mapController != null && mounted) {
                          await _mapController!.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        }
                      } catch (e) {
                        print('Zoom in error: $e');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.darkModePrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Zoom Out Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      try {
                        if (_mapController != null && mounted) {
                          await _mapController!.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        }
                      } catch (e) {
                        print('Zoom out error: $e');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.remove,
                        color: AppColors.darkModePrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 18,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () async {
                  try {
                    if (_mapController != null && mounted) {
                      await _mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: widget.source, zoom: 16),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Map recenter error (simple): $e');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.darkModePrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to overlay the animated pulse and blue spot at the pickup location
class MapOverlayPulse extends StatelessWidget {
  final GoogleMapController? mapController;
  final LatLng target;
  final Animation<double> animation;
  const MapOverlayPulse(
      {super.key,
      required this.mapController,
      required this.target,
      required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (mapController == null) return SizedBox.shrink();
        return FutureBuilder<ScreenCoordinate>(
          future: mapController!.getScreenCoordinate(target),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox.shrink();
            final coord = snapshot.data!;
            // Convert map coordinates to overlay position
            final left = coord.x.toDouble() - 80; // Center the pulse
            final top = coord.y.toDouble() - 80;
            return Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final delay = i * 0.33;
                      double t = (animation.value + delay) % 1.0;
                      return CustomPaint(
                        painter: _PulsePainter(
                          value: t,
                          color: AppColors.darkModePrimary
                              .withOpacity(0.25 - i * 0.07),
                        ),
                        child: SizedBox(width: 160, height: 160),
                      );
                    }),
                    // Green spot
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.darkModePrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkModePrimary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Custom painter for the pulsing effect
class _PulsePainter extends CustomPainter {
  final double value;
  final Color color;
  _PulsePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 40.0 * value + 20.0;
    final opacity = (1.0 - value).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
