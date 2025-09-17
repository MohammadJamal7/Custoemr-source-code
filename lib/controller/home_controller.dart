import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/widgets.dart';

import 'package:customer/constant/constant.dart';
import 'package:customer/utils/utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'interCity_controller.dart';
import '../ui/home_screens/ride_details_screen.dart';
import '../ui/interCity/interCity_screen.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxBool isLocationLoading = false.obs; // ✅ Add location loading state
  Timer? _locationDebounceTimer; // ✅ Add debounce timer
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxBool isAcSelected = false.obs;
  RxDouble extraDistance = 0.0.obs;

  // Colors array for service cards (matching InterCity controller)
  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);
  RxList bannerList = <BannerModel>[].obs;
  Timer? bannerTimer;
  Timer? _locationStatusTimer;

  String? startNightTime;
  String? endNightTime;
  DateTime startNightTimeString = DateTime.now();
  DateTime endNightTimeString = DateTime.now();

  @override
  void onInit() {
    // TODO: implement onInit
    print('🚀 HomeController.onInit() called - starting initialization...');
    Get.put(InterCityController());
    final stopwatch = Stopwatch()..start();

    print('🎯 HomeController: Starting non-blocking initialization...');

    // Observe app lifecycle to refresh location on resume
    WidgetsBinding.instance.addObserver(this);

    // ✅ NON-BLOCKING APPROACH: Load essential data first, location later
    Future.wait<void>([
      getServiceType(),
      getPaymentData(),
    ]).then((_) {
      isLoading.value = false;
      print(
          'HomeController: Essential data loaded in ${stopwatch.elapsedMilliseconds}ms');

      // ✅ Lazy-load non-essential data
      getBannerHome();
      getContact();

      // ✅ Try to get location in background (non-blocking)
      _tryGetLocationInBackground();

      // ✅ Check location status when page loads
      checkLocationStatus();

      // ✅ Start periodic location status check (every 30 seconds)
      _startPeriodicLocationCheck();
    }).catchError((error) {
      print('❌ HomeController: Error in Future.wait: $error');
      isLoading.value = false;
    });
    super.onInit();
  }

  @override
  void onClose() {
    bannerTimer?.cancel();
    _locationDebounceTimer?.cancel(); // ✅ Cancel location debounce timer
    _locationStatusTimer?.cancel(); // ✅ Cancel location status timer
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App returned to foreground: refresh location quickly
      refreshLocationStatus();
    }
  }

  /// ✅ START PERIODIC LOCATION CHECK: Check location status every 30 seconds
  void _startPeriodicLocationCheck() {
    _locationStatusTimer?.cancel(); // Cancel existing timer
    _locationStatusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 Periodic location status check...');
      checkLocationStatus();
    });
  }

  /// 🇾🇪 SET YEMEN LOCATION: Set user location to Yemen for testing
  void setYemenLocation() {
    // Yemen coordinates (Sana'a)
    Constant.currentLocation = Position(
      latitude: 15.3694,
      longitude: 44.1910,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    
    print('🇾🇪 Location set to Yemen: ${Constant.currentLocation!.latitude}, ${Constant.currentLocation!.longitude}');
    
    // Process location data to update UI
    _processLocationDataInBackground();
    update();
    
    // Show confirmation toast
    ShowToastDialog.showToast('Location set to Yemen for testing');
  }

  /// ✅ NON-BLOCKING: Try to get location in background without blocking UI
  Future<void> _tryGetLocationInBackground() async {
    try {
      print('🔄 Trying to get location in background...');

      // ✅ Quick check without blocking dialogs
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print(
            '⚠️ Location services disabled - will show prompt when user interacts');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print(
            '⚠️ Location permission not granted - will show prompt when user interacts');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            '⚠️ Location permission permanently denied - will show settings prompt when user interacts');
        return;
      }

      // ✅ If we have permission, first try last known position for instant UI
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        try {
          final Position? lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            Constant.currentLocation = lastKnown;
            print(
                '✅ Using last known location: ${lastKnown.latitude}, ${lastKnown.longitude}');
            // Show something immediately
            _processLocationDataInBackground();
            update();
          }
        } catch (e) {
          print('ℹ️ No last known location available: $e');
        }

        // ✅ Then try to refresh with a current position (slightly longer timeout on cold start)
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy:
                LocationAccuracy.medium, // Lower accuracy for speed
            forceAndroidLocationManager: false,
            timeLimit: const Duration(seconds: 10), // Slightly longer on init
          );

          Constant.currentLocation = position;
          print(
              '✅ Fresh location obtained: ${position.latitude}, ${position.longitude}');
          _processLocationDataInBackground();
          update();
          print('✅ Background location obtained successfully');
        } catch (e) {
          print('⚠️ Could not refresh current position quickly: $e');
        }
      }
    } catch (e) {
      print(
          '⚠️ Background location failed: $e - will show prompt when user interacts');
    }
  }

  /// ✅ CHECK LOCATION STATUS: Check if location is available without getting position
  Future<void> checkLocationStatus() async {
    try {
      print('🔍 Checking location status...');

      // Track if we need to force a fresh location
      bool needsFreshLocation = false;

      // ✅ Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        // Always clear current location if services are disabled
        Constant.currentLocation = null;
        update();
        return;
      } else {
        // Location services are enabled, we should get a fresh location
        needsFreshLocation = true;
      }

      // ✅ Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Location permission not granted');
        // Always clear current location if permission is denied
        Constant.currentLocation = null;
        update();
        return;
      }

      // ✅ If we have permission, always try to get a fresh location first
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Always attempt to get current position first
        try {
          print('📍 Getting fresh location...');
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            forceAndroidLocationManager: false,
            timeLimit: const Duration(seconds: 5), // Short timeout
          );

          // Always update with fresh position when available
          Constant.currentLocation = position;
          print(
              '✅ Fresh location obtained: ${position.latitude}, ${position.longitude}');
          _processLocationDataInBackground();
          update();
          return; // Exit early since we have fresh location
        } catch (e) {
          print('⚠️ Quick current position fetch failed: $e');

          // Only fall back to last known if we couldn't get fresh location
          // AND we don't already have a current location
          if (Constant.currentLocation == null) {
            print('📍 Falling back to last known location...');
            try {
              final Position? lastKnown =
                  await Geolocator.getLastKnownPosition();
              if (lastKnown != null) {
                Constant.currentLocation = lastKnown;
                print(
                    '✅ Last known position used: ${lastKnown.latitude}, ${lastKnown.longitude}');
                _processLocationDataInBackground();
                update();
              }
            } catch (e) {
              print('ℹ️ No last known location available: $e');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Location status check failed: $e');
      // Clear current location on error
      Constant.currentLocation = null;
      update();
    }
  }

  /// ✅ REFRESH LOCATION STATUS: Call this when screen becomes active
  Future<void> refreshLocationStatus() async {
    print('Refreshing location status...');
    await checkLocationStatus();
  }

  /// PAYMENT METHOD DIALOG: Show payment method selection
  void paymentMethodDialog(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                            ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Visibility(
                                visible:
                                    paymentModel.value.cash!.enable == true,
                                child: Obx(
                                  () => Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () {
                                          selectedPaymentMethod.value =
                                              paymentModel.value.cash!.name
                                                  .toString();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10)),
                                            border: Border.all(
                                                color: selectedPaymentMethod
                                                            .value ==
                                                        paymentModel
                                                            .value.cash!.name
                                                            .toString()
                                                    ? themeChange.getThem()
                                                        ? AppColors
                                                            .darkModePrimary
                                                        : AppColors.primary
                                                    : AppColors.textFieldBorder,
                                                width: 1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 60,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.lightGray,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(5)),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/ic_payment.svg',
                                                      width: 22,
                                                      height: 22,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Cash".tr,
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                ),
                                                Radio(
                                                  value: paymentModel
                                                      .value.cash!.name
                                                      .toString(),
                                                  groupValue:
                                                      selectedPaymentMethod
                                                          .value,
                                                  activeColor:
                                                      themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary,
                                                  onChanged: (value) {
                                                    selectedPaymentMethod
                                                            .value =
                                                        value.toString();
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
                                visible:
                                    paymentModel.value.wallet!.enable == true,
                                child: Obx(
                                  () => Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () {
                                          selectedPaymentMethod.value =
                                              paymentModel.value.wallet!.name
                                                  .toString();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10)),
                                            border: Border.all(
                                                color: selectedPaymentMethod
                                                            .value ==
                                                        paymentModel
                                                            .value.wallet!.name
                                                            .toString()
                                                    ? themeChange.getThem()
                                                        ? AppColors
                                                            .darkModePrimary
                                                        : AppColors.primary
                                                    : AppColors.textFieldBorder,
                                                width: 1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 60,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.lightGray,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(5)),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/ic_wallet.svg',
                                                      width: 22,
                                                      height: 22,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Wallet".tr,
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                ),
                                                Text(
                                                  "(${Constant.amountShow(amount: userModel.value.walletAmount.toString())})",
                                                  style: GoogleFonts.poppins(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary),
                                                ),
                                                Radio(
                                                  value: paymentModel
                                                      .value.wallet!.name
                                                      .toString(),
                                                  groupValue:
                                                      selectedPaymentMethod
                                                          .value,
                                                  activeColor:
                                                      themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary,
                                                  onChanged: (value) {
                                                    selectedPaymentMethod
                                                            .value =
                                                        value.toString();
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
                      ButtonThem.buildButton(
                        context1,
                        title: "Confirm".tr,
                        btnWidthRatio: Responsive.width(100, context1),
                        onPress: () {
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  /// ✅ SOMEONE TAKING DIALOG: Show contact selection for ride
  void someOneTakingDialog(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);
          return StatefulBuilder(builder: (context1, setState) {
            return Obx(
              () => Container(
                constraints:
                    BoxConstraints(maxHeight: Responsive.height(90, context)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Someone else taking this ride?".tr,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Choose a contact and share a code to conform that ride."
                              .tr,
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            selectedTakingRide.value = ContactModel(
                                fullName: "Myself".tr, contactNumber: "");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                  color: selectedTakingRide.value.fullName ==
                                          "Myself".tr
                                      ? themeChange.getThem()
                                          ? AppColors.darkModePrimary
                                          : AppColors.primary
                                      : AppColors.textFieldBorder,
                                  width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child:
                                        Icon(Icons.person, color: Colors.black),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Myself".tr,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  Radio(
                                    value: "Myself".tr,
                                    groupValue:
                                        selectedTakingRide.value.fullName,
                                    activeColor: themeChange.getThem()
                                        ? AppColors.darkModePrimary
                                        : AppColors.primary,
                                    onChanged: (value) {
                                      selectedTakingRide.value = ContactModel(
                                          fullName: "Myself".tr,
                                          contactNumber: "");
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Contact list
                        ListView.builder(
                          itemCount: contactList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final contactModel = contactList[index];
                            final isSelected =
                                (selectedTakingRide.value.fullName ?? "") ==
                                    (contactModel.fullName ?? "");
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: InkWell(
                                onTap: () {
                                  selectedTakingRide.value = contactModel;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    border: Border.all(
                                        color: isSelected
                                            ? (themeChange.getThem()
                                                ? AppColors.darkModePrimary
                                                : AppColors.primary)
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.person,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            (contactModel.fullName ?? ""),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        Radio(
                                          value: (contactModel.fullName ?? ""),
                                          groupValue: (selectedTakingRide
                                                  .value.fullName ??
                                              ""),
                                          activeColor: themeChange.getThem()
                                              ? AppColors.darkModePrimary
                                              : AppColors.primary,
                                          onChanged: (value) {
                                            selectedTakingRide.value =
                                                contactModel;
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        // Choose another contact
                        InkWell(
                          onTap: () async {
                            try {
                              final FlutterNativeContactPicker contactPicker =
                                  FlutterNativeContactPicker();
                              final Contact? contact =
                                  await contactPicker.selectContact();
                              if (contact == null) return;
                              final contactModel = ContactModel(
                                fullName: contact.fullName ?? "",
                                contactNumber: contact.selectedPhoneNumber,
                              );
                              final exists = contactList.any((c) =>
                                  (c.fullName ?? "") ==
                                  (contactModel.fullName ?? ""));
                              if (!exists) {
                                contactList.add(contactModel);
                              }
                              selectedTakingRide.value = contactModel;
                            } catch (e) {
                              // picker cancelled or failed
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child:
                                      Icon(Icons.contacts, color: Colors.black),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Choose another contact".tr,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ButtonThem.buildButton(
                          context1,
                          title: "Confirm".tr,
                          btnWidthRatio: 1,
                          customColor: AppColors.darkModePrimary,
                          customTextColor: Colors.black,
                          onPress: () {
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          });
        });
  }

  /// ✅ SHOW ALERT DIALOG: Show payment warning dialog
  void showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr),
      onPressed: () {
        Get.back();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Warning".tr),
      content: Text(
        "You are not able book new ride please complete previous ride payment"
            .tr,
      ),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// ✅ USER-INITIATED: Force location permission when user taps location area
  Future<void> requestLocationPermission() async {
    print('🎯 User initiated location request...');

    // ✅ Prevent multiple simultaneous requests
    if (isLocationLoading.value) {
      print('⚠️ Location request already in progress');
      return;
    }

    // ✅ Immediately perform location request (no debounce for user-initiated)
    await _performLocationRequest();
  }

  /// ✅ DIRECT NATIVE DIALOG: Perform the location request with direct native dialog
  Future<void> _performLocationRequest() async {
    // ✅ Set loading state
    isLocationLoading.value = true;
    update(); // ✅ Update UI for GetBuilder

    try {
      print('🏁 Direct native permission request...');

      // ✅ STEP 1: Always clear any existing location data first
      // This ensures we don't use stale data if the user disabled and re-enabled location
      Constant.currentLocation = null;
      update();

      // ✅ STEP 2: Ensure location services are enabled using native Android dialog
      final loc.Location location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        print(
            'ℹ️ Location services disabled. Requesting to enable via native dialog...');
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('❌ User did not enable location services');
          ShowToastDialog.showToast(
              "Location services are required to continue. Please enable them."
                  .tr);
          return;
        }
        print('✅ Location services enabled');
      }

      // ✅ STEP 3: Request app permission (While-in-use)
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print('❌ Location permission denied by user');
        ShowToastDialog.showToast(
            "Location permission is required to book rides. Please grant location permission."
                .tr);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        ShowToastDialog.showToast(
            "Location permission is permanently denied. Please enable location permission in app settings."
                .tr);
        // Show settings dialog for permanently denied permission
        _showLocationSettingsDialog();
        return;
      }

      // ✅ STEP 4: Always get a fresh current position
      // Never use last known position for explicit user requests
      print('📍 Getting fresh current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false,
        timeLimit: const Duration(seconds: 15),
      );

      Constant.currentLocation = position;
      print(
          '✅ Fresh location obtained successfully! ${position.latitude}, ${position.longitude}');

      // ✅ Process location data in background to avoid blocking UI
      _processLocationDataInBackground();
      update(); // ✅ Update UI for GetBuilder
    } catch (e) {
      print('❌ Location request failed: $e');
      ShowToastDialog.showToast(
          "Unable to get your location. Please check your location settings and try again."
              .tr);
      _showLocationErrorDialog();
    } finally {
      // ✅ Clear loading state
      isLocationLoading.value = false;
      update(); // ✅ Update UI for GetBuilder
    }
  }

  /// ✅ NON-BLOCKING: Show dialog to enable location services
  void _showLocationServicesDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("Location Services Required".tr),
        content: Text(
            "This app requires location services to function. Please enable location services in your device settings."
                .tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            child: Text("Open Settings".tr),
          ),
        ],
      ),
      barrierDismissible: true, // Allow user to dismiss
    );
  }

  /// ✅ NON-BLOCKING: Show dialog to grant location permission
  void _showLocationPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("Location Permission Required".tr),
        content: Text(
            "This app needs location permission to find nearby drivers and calculate ride costs. Please grant location permission."
                .tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              // ✅ Show native Android location permission dialog
              await _requestNativeLocationPermission();
            },
            child: Text("Grant Permission".tr),
          ),
        ],
      ),
      barrierDismissible: true, // Allow user to dismiss
    );
  }

  /// ✅ Request native Android location permission dialog
  Future<void> _requestNativeLocationPermission() async {
    try {
      print('📍 Requesting native location permission...');
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('✅ Location permission granted');
        // ✅ Permission granted, now get location
        await requestLocationPermission();
      } else {
        print('❌ Location permission denied');
        ShowToastDialog.showToast(
            "Location permission is required to book rides. Please grant location permission."
                .tr);
      }
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      ShowToastDialog.showToast(
          "Error requesting location permission. Please try again.".tr);
    }
  }

  /// ✅ NON-BLOCKING: Show dialog to enable location in app settings
  void _showLocationSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("Location Permission Required".tr),
        content: Text(
            "Location permission is permanently denied. Please enable location permission in app settings."
                .tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Geolocator.openAppSettings();
            },
            child: Text("Open Settings".tr),
          ),
        ],
      ),
      barrierDismissible: true, // Allow user to dismiss
    );
  }

  /// ✅ NON-BLOCKING: Show dialog for location errors
  void _showLocationErrorDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("Location Error".tr),
        content: Text(
            "Unable to get your location. Please check your location settings and try again."
                .tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              // Retry location
              await requestLocationPermission();
            },
            child: Text("Try Again".tr),
          ),
        ],
      ),
      barrierDismissible: true, // Allow user to dismiss
    );
  }

  /// ✅ EXPERT METHOD: Process location data after permission granted
  Future<void> _processLocationData() async {
    if (Constant.currentLocation == null) {
      print('⚠️ Warning: currentLocation is null after permission granted');
      return;
    }

    try {
      if (Constant.selectedMapType == 'google') {
        List<Placemark> placeMarks = await placemarkFromCoordinates(
          Constant.currentLocation!.latitude,
          Constant.currentLocation!.longitude,
        );
        Constant.country = placeMarks.first.country;
        Constant.city = placeMarks.first.locality;
        currentLocation.value =
            "${placeMarks.first.name}, ${placeMarks.first.subLocality}, ${placeMarks.first.locality}, ${placeMarks.first.administrativeArea}, ${placeMarks.first.postalCode}, ${placeMarks.first.country}";
        print('🏠 Address resolved (Google): ${currentLocation.value}');
      } else {
        Place place = await Nominatim.reverseSearch(
          lat: Constant.currentLocation!.latitude,
          lon: Constant.currentLocation!.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
          language: 'ar',
        );
        currentLocation.value = place.displayName.toString();
        Constant.country = place.address?['country'] ?? '';
        Constant.city = place.address?['city'] ?? '';
        print('🏠 Address resolved (OSM): ${currentLocation.value}');
      }
    } catch (e) {
      print('⚠️ Address resolution failed: $e');
      currentLocation.value =
          "Location obtained (${Constant.currentLocation!.latitude.toStringAsFixed(4)}, ${Constant.currentLocation!.longitude.toStringAsFixed(4)})";
    }
  }

  /// ✅ BACKGROUND: Process location data without blocking UI
  Future<void> _processLocationDataInBackground() async {
    try {
      await _processLocationData();
      update(); // ✅ Update UI for GetBuilder
    } catch (e) {
      print('⚠️ Error processing location data: $e');
    }
  }

  Future<void> getBannerHome() async {
    try {
      await FireStoreUtils.getBanner().then((value) {
        bannerList.value = value;
      });
      startAutoScroll();
    } catch (e) {
      ShowToastDialog.showToast("Banner Error: ${e.toString()}");
    }
  }

  void startAutoScroll() {
    bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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
        print('Home banner auto-scroll error: $e');
        bannerTimer?.cancel();
      }
    });
  }

  getServiceType() async {
    await FireStoreUtils.getAllServices().then((value) {
      serviceList.value = value;
      if (serviceList.isNotEmpty) {
        selectedType.value = serviceList.first;
      }
    });

    // Fetch tax list and airports - airports don't require location
    await FireStoreUtils().getTaxList().then((value) {
      if (value != null) {
        Constant.taxList = value;
      }
    });

    log("Start AirPort");
    await FireStoreUtils().getAirports().then((value) {
      if (value != null) {
        Constant.airaPortList = value;
        log("Airports loaded: ${value.length} airports");
      } else {
        log("No airports loaded");
      }
    }).catchError((error) {
      log("Error loading airports in controller: $error");
    });

    // ✅ CRITICAL FIX: User profile and FCM token update with guest user support
    try {
      String token = await NotificationService.getToken();
      String? uid = FireStoreUtils.getCurrentUid();

      // ✅ Skip user profile operations for guest users
      if (uid.isEmpty || uid == "Guest" || Constant.isGuestUser) {
        print(
            "HomeController: Skipping user profile operations for guest user");
        return;
      }

      UserModel? value = await FireStoreUtils.getUserProfile(uid);
      if (value != null) {
        userModel.value = value;
        userModel.value.fcmToken = token;
        await FireStoreUtils.updateUser(userModel.value);
      } else {
        print("⚠️ لم يتم العثور على بيانات المستخدم في Firestore.");
      }
    } catch (e) {
      print("HomeController: Error updating user profile: $e");
    }

    isLoading.value = false;
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;
  RxString acCharge = "".obs;
  RxString nonAcCharge = "".obs;
  RxString basicFare = "".obs;
  RxString basicFareCharge = "".obs;
  RxString nightCharge = "".obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble totalNightFare = 0.0.obs;
  RxBool isAcNonAc = false.obs;
  DateTime currentTime = DateTime.now();
  DateTime currentDate = DateTime.now();

  double convertToMinutes(String duration) {
    double durationValue = 0.0;

    try {
      final RegExp hoursRegex = RegExp(r"(\d+)\s*hour");
      final RegExp minutesRegex = RegExp(r"(\d+)\s*min");

      final Match? hoursMatch = hoursRegex.firstMatch(duration);
      if (hoursMatch != null) {
        int hours = int.parse(hoursMatch.group(1)!.trim());
        durationValue += hours * 60;
      }

      final Match? minutesMatch = minutesRegex.firstMatch(duration);
      if (minutesMatch != null) {
        int minutes = int.parse(minutesMatch.group(1)!.trim());
        durationValue += minutes;
      }
    } catch (e) {
      print("Exception: $e");
      throw FormatException("Invalid duration format: $duration");
    }

    return durationValue;
  }

  calculateDurationAndDistance() async {
    if (Constant.selectedMapType == 'osm') {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait".tr);
        await Constant.getDurationOsmDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != {} && value.isNotEmpty) {
            int hours = value['routes'].first['duration'] ~/ 3600;
            int minutes =
                ((value['routes'].first['duration'] % 3600) / 60).round();
            duration.value = '$hours ساعة $minutes دقيقة '.trim();
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
            }
          }
          update();
        });
      }
      ShowToastDialog.closeLoader();
    } else {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait".tr);
        await Constant.getDurationDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != null) {
            duration.value =
                value.rows!.first.elements!.first.duration!.text.toString();
            print("🚗 Raw Google Maps duration text: '${duration.value}'");
            print(
                "🚗 Duration value in seconds: ${value.rows!.first.elements!.first.duration!.value}");
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1000)
                      .toString();
            } else {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1609.34)
                      .toString();
            }
          }
          update();
        });
        ShowToastDialog.closeLoader();
      }
    }
  }

  calculateAmount() async {
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      await Constant.getDurationDistance(
              LatLng(sourceLocationLAtLng.value.latitude!,
                  sourceLocationLAtLng.value.longitude!),
              LatLng(destinationLocationLAtLng.value.latitude!,
                  destinationLocationLAtLng.value.longitude!))
          .then((value) {
        if (value != null) {
          duration.value =
              value.rows!.first.elements!.first.duration!.text.toString();
          print("duration :: 00 :: ${duration.value}");
          if (Constant.distanceType == "Km") {
            distance.value =
                (value.rows!.first.elements!.first.distance!.value!.toInt() /
                        1000)
                    .toString();
            amount.value = Constant.amountCalculate(
                    selectedType.value.kmCharge.toString(), distance.value)
                .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          } else {
            distance.value =
                (value.rows!.first.elements!.first.distance!.value!.toInt() /
                        1609.34)
                    .toString();
            amount.value = Constant.amountCalculate(
                    selectedType.value.kmCharge.toString(), distance.value)
                .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          }
        }
      });
    }
  }

  calculateOsmAmount() async {
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      await Constant.getDurationOsmDistance(
              LatLng(sourceLocationLAtLng.value.latitude!,
                  sourceLocationLAtLng.value.longitude!),
              LatLng(destinationLocationLAtLng.value.latitude!,
                  destinationLocationLAtLng.value.longitude!))
          .then((value) {
        if (value != {} && value.isNotEmpty) {
          int hours = value['routes'].first['duration'] ~/ 3600;
          int minutes =
              ((value['routes'].first['duration'] % 3600) / 60).round();
          duration.value = '$hours ساعة $minutes دقيقة ';
          if (Constant.distanceType == "Km") {
            distance.value =
                (value['routes'].first['distance'] / 1000).toString();
            amount.value = Constant.amountCalculate(
                    selectedType.value.kmCharge.toString(), distance.value)
                .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          } else {
            distance.value =
                (value['routes'].first['distance'] / 1609.34).toString();
            amount.value = Constant.amountCalculate(
                    selectedType.value.kmCharge.toString(), distance.value)
                .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          }
        }
      });
    }
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString selectedPaymentMethod = "".obs;

  RxList airPortList = <AriPortModel>[].obs;

  getPaymentData() async {
    try {
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;
          // Set cash as default payment method if it's enabled
          if (paymentModel.value.cash != null &&
              paymentModel.value.cash!.enable == true) {
            selectedPaymentMethod.value =
                paymentModel.value.cash!.name.toString();
            print(
                "✅ Cash payment set as default: ${selectedPaymentMethod.value}");
          } else {
            print("⚠️ Cash payment not available or disabled");
            // Set cash as default anyway if no payment method is selected
            if (selectedPaymentMethod.value.isEmpty) {
              selectedPaymentMethod.value = "Cash";
              print("✅ Cash payment set as fallback default");
            }
          }
        } else {
          // If payment data is null, set cash as default
          if (selectedPaymentMethod.value.isEmpty) {
            selectedPaymentMethod.value = "Cash";
            print("✅ Cash payment set as fallback default (no payment data)");
          }
        }
      });

      await FireStoreUtils().getZone().then((value) {
        if (value != null) {
          zoneList.value = value;
        }
      });
    } catch (e) {
      ShowToastDialog.showToast("Payment Error: ${e.toString()}");
      // Set cash as default even if there's an error
      if (selectedPaymentMethod.value.isEmpty) {
        selectedPaymentMethod.value = "Cash";
        print("✅ Cash payment set as fallback default (error occurred)");
      }
    }
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself".tr, contactNumber: "").obs;
  Rx<AriPortModel> selectedAirPort = AriPortModel().obs;

  setContact() {
    print(jsonEncode(contactList));
    Preferences.setString(
        Preferences.contactList,
        json.encode(contactList
            .map<Map<String, dynamic>>((music) => music.toJson())
            .toList()));
    getContact();
  }

  Future<void> getContact() async {
    try {
      String contactListJson = Preferences.getString(Preferences.contactList);

      if (contactListJson.isNotEmpty) {
        print("---->");
        contactList.clear();
        contactList.value = (json.decode(contactListJson) as List<dynamic>)
            .map<ContactModel>((item) => ContactModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      ShowToastDialog.showToast("Contact Error: ${e.toString()}");
    }
  }

  // Method to handle navigation based on service type
  void navigateBasedOnServiceType() {
    if (selectedType.value.intercityType == true) {
      // For intercity services, navigate to InterCity page and pass the selected service
      InterCityController interCityController = Get.find<InterCityController>();

      // ✅ Clear any existing data first
      interCityController.clearInterCityData();

      // Pass the pickup/dropoff data from home screen to intercity screen
      interCityController.sourceLocationController.value.text =
          sourceLocationController.value.text;
      interCityController.sourceLocationLAtLng.value =
          sourceLocationLAtLng.value;
      interCityController.destinationLocationController.value.text =
          destinationLocationController.value.text;
      interCityController.destinationLocationLAtLng.value =
          destinationLocationLAtLng.value;

      // Set the selected service type - use ID for more precise matching
      String serviceTitle = selectedType.value.title?.first.title ?? "";
      String serviceId = selectedType.value.id ?? "";
      print(
          "🚀 Passing service to InterCity - Title: $serviceTitle, ID: $serviceId");
      print(
          "🔍 Service details - intercityType: ${selectedType.value.intercityType}");
      print(
          "🔍 Service details - title: ${selectedType.value.title?.first.title}");
      print("🔍 Service details - id: ${selectedType.value.id}");

      // Use the new method that handles timing better
      if (serviceId.isNotEmpty) {
        interCityController.setSelectedServiceAfterLoad(serviceId);
      } else {
        // Fallback to title-based selection
        interCityController.selectIntercityFromService(serviceTitle);
      }

      Get.to(() => const InterCityScreen());
    } else {
      // For city services, navigate to ride details screen
      Get.to(() => RideDetailsScreen(controller: this));
    }
  }
}
