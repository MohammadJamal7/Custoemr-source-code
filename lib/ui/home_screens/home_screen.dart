import 'dart:developer';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/language_name.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:customer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../../controller/dash_board_controller.dart';
import '../../controller/interCity_controller.dart';
import '../../model/zone_model.dart';
import '../auth_screen/login_screen.dart';
import '../on_boarding_screen.dart';
import 'ride_details_screen.dart';

// Modern shimmer placeholder for banners
class _BannerShimmerPlaceholder extends StatefulWidget {
  @override
  State<_BannerShimmerPlaceholder> createState() =>
      _BannerShimmerPlaceholderState();
}

class _BannerShimmerPlaceholderState extends State<_BannerShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final height = MediaQuery.of(context).size.height * 0.20;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPosition = _controller.value * (width + 120) - 60;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.10),
                AppColors.gray.withOpacity(0.18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: shimmerPosition,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  SuperTooltip? tooltip;
  HomeController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check location status when app becomes active
    if (state == AppLifecycleState.resumed && _controller != null) {
      print('🔄 App resumed - checking location status...');
      _controller!.refreshLocationStatus();
    }
  }

  final Map<String, String> serviceTooltips = {
    'تاكسي':
        ' إذا كنت بحاجة إلى سيارة عدد المقاعد من ٤ إلى ٧ مقعد للتنقل داخل المدينة والمدن القريبة',
    'توك توك': 'تحجز كامل للتنقل داخل المدينة للمشاوير القريبة',
    'باص':
        'إذا كنت بحاجة إلى باص عدد المقاعد من ١٥ إلى ٣٠ مقعد للتنقل داخل المدينة والمدن القريبة',
    'دراجة نارية': 'عدد الركاب ١ للتنقل داخل المدينة ولتجنب الإزدحامات.',
    'رحلة مجدولة':
        'للحجز المسبق ،إذا كنت تخطط للسفر أو مشوار في موعد وتاريخ معين داخل المدينة والمدن الأخرى',
    'الشحن والنقل':
        'اذا عندك عفش أو أثاث أوبضاعة وتحتاج تنقلة من مكان الى آخر داخل المدينة او خارجها',
    'مشتركة مع ركاب':
        ' اذا كنت لاتمانع ان يرافقك ركاب آخرون في الرحلة نظام الفرزات',
    'خدمة توصيل':
        'اذا كنت بحاجة الى خدمة توصيل طرد أو غرض بدراجة نارية أو بسيارة',
    'رحلة داخلية': 'اذا كنت بحاجة الى باص نوع تويوتا او أوربي وغيره',
  };

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<HomeController>(
        init: HomeController(),
        builder: (controller) {
          // Store controller reference for lifecycle callbacks
          _controller = controller;
          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.primary,
                body: controller.isLoading.value
                    ? Constant.loader()
                    : Column(
                        children: [
                          _buildBanner(context, controller),
                          // ✅ SIMPLIFIED LOCATION SECTION - Fixed overflow issues
                          Container(
                            height: Responsive.width(28,
                                context), // Increased height for better spacing
                            width: Responsive.width(100, context),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ✅ Title row with status
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        controller.userModel.value.fullName
                                                    ?.isNotEmpty ==
                                                true
                                            ? "Current Location".tr
                                            : "Guest".tr,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16, // Reduced font size
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // ✅ Compact status indicator - Using GetBuilder instead of Obx
                                    _buildLocationStatusIndicator(),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // ✅ Location content
                                InkWell(
                                  onTap: () {
                                    if (Constant.currentLocation == null &&
                                        !controller.isLocationLoading.value) {
                                      controller.requestLocationPermission();
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                          'assets/icons/ic_location.svg',
                                          width: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            _buildLocationContent(controller),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add more vertical space between location and next section
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.04),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.04,
                                      bottom:
                                          MediaQuery.of(context).size.height *
                                              0.02,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Service Type Selector
                                        Text("Choose Service Type".tr,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 0.5)),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.015),

                                        // Service Type Cards - Horizontal ListView
                                        SizedBox(
                                          height:
                                              Responsive.height(20, context),
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                controller.serviceList.length,
                                            itemBuilder: (context, index) {
                                              ServiceModel service =
                                                  controller.serviceList[index];

                                              return Obx(() {
                                                bool isSelected = controller
                                                        .selectedType
                                                        .value
                                                        .id ==
                                                    service.id;

                                                return InkWell(
                                                    onTap: () {
                                                      controller.selectedType
                                                          .value = service;
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 12),
                                                      width: Responsive.width(
                                                          30, context),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors
                                                                .darkModePrimary
                                                            : themeChange
                                                                    .getThem()
                                                                ? AppColors
                                                                    .darkContainerBackground
                                                                : const Color(
                                                                    0xFFF5F5F5),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          Radius.circular(16),
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.08),
                                                            blurRadius: 6,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Center(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                          const SizedBox(
                                                              height: 6),
                                                          // Service Icon
                                                          service.image !=
                                                                      null &&
                                                                  service.image!
                                                                      .isNotEmpty
                                                              ? CachedNetworkImage(
                                                                  imageUrl:
                                                                      service
                                                                          .image!,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  height: Responsive
                                                                      .height(
                                                                          10,
                                                                          context),
                                                                  width: Responsive
                                                                      .width(18,
                                                                          context),
                                                                  placeholder:
                                                                      (context,
                                                                              url) =>
                                                                          Icon(
                                                                    Icons
                                                                        .directions_car,
                                                                    color: isSelected
                                                                        ? Colors.white
                                                                        : themeChange.getThem()
                                                                            ? Colors.white
                                                                            : AppColors.primary,
                                                                    size: Responsive
                                                                        .width(
                                                                            10,
                                                                            context),
                                                                  ),
                                                                  errorWidget:
                                                                      (context,
                                                                              url,
                                                                              error) =>
                                                                          Icon(
                                                                    Icons
                                                                        .directions_car,
                                                                    color: isSelected
                                                                        ? Colors.white
                                                                        : themeChange.getThem()
                                                                            ? Colors.white
                                                                            : AppColors.primary,
                                                                    size: Responsive
                                                                        .width(
                                                                            10,
                                                                            context),
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  Icons
                                                                      .directions_car,
                                                                  color: isSelected
                                                                      ? Colors.white
                                                                      : themeChange.getThem()
                                                                          ? Colors.white
                                                                          : AppColors.primary,
                                                                  size: Responsive
                                                                      .width(10,
                                                                          context),
                                                                ),
                                                          const SizedBox(
                                                              height: 8),
                                                          // Service Title
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                            child: Text(
                                                              Constant
                                                                  .localizationTitle(
                                                                      service
                                                                          .title),
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: Responsive
                                                                    .width(3.5,
                                                                        context),
                                                                color: isSelected
                                                                    ? Colors.black
                                                                    : themeChange.getThem()
                                                                        ? Colors.white
                                                                        : Colors.black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                              ],
                                                            ),
                                                          ),
                                                          // Info icon with tooltip - only show when selected
                                                           if (serviceTooltips.containsKey(Constant.localizationTitle(service.title).trim()) && isSelected)
                                                             Positioned(
                                                               top: 4,
                                                               left: 10,
                                                               child: Builder(
                                                                 builder: (context) {
                                                                   final key = GlobalKey();
                                                                   return GestureDetector(
                                                                     key: key,
                                                                     onTap: () {
                                                                       String serviceName = Constant.localizationTitle(service.title);
                                                                       String? message = serviceTooltips[serviceName];
                                                                       if (message == null) return;
                                                                       showTooltip(context, message);
                                                                     },
                                                                     child: const Icon(
                                                                       Icons.info_outline,
                                                                       color: Colors.white,
                                                                       size: 18,
                                                                     ),
                                                                   );
                                                                 },
                                                               ),
                                                             ),
                                                        ],
                                                      ),
                                                    ));
                                              });
                                            },
                                          ),
                                        ),

                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.03), // Reduced from 0.03 to 0.015

                                        // Continue Button - REMOVED (will be moved to bottom)

                                        // New Label Above Pickup Location
                                        Text("Choose Pickup Location".tr,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 0.5)),

                                        // Pickup Location - Fixed label
                                        Text("Pickup Location".tr,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                                letterSpacing: 1,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)),

                                        controller.sourceLocationLAtLng.value
                                                    .latitude ==
                                                null
                                            ? InkWell(
                                                onTap: () async {
                                                  if (Constant
                                                          .selectedMapType ==
                                                      'osm') {
                                                    Get.to(() =>
                                                            const LocationPicker())
                                                        ?.then((value) async {
                                                      if (value != null) {
                                                        controller
                                                                .sourceLocationController
                                                                .value
                                                                .text =
                                                            value.displayName!;
                                                        controller
                                                                .sourceLocationLAtLng
                                                                .value =
                                                            LocationLatLng(
                                                                latitude:
                                                                    value.lat,
                                                                longitude:
                                                                    value.lon);
                                                        await controller
                                                            .calculateDurationAndDistance();
                                                        controller
                                                            .calculateAmount();
                                                      }
                                                    });
                                                  } else {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PlacePicker(
                                                          apiKey: Constant
                                                              .mapAPIKey,
                                                          autocompleteLanguage:
                                                              'ar',
                                                          onPlacePicked:
                                                              (result) async {
                                                            Get.back();
                                                            controller
                                                                .sourceLocationController
                                                                .value
                                                                .text = ((result
                                                                            .name
                                                                            ?.trim()
                                                                            .isNotEmpty ==
                                                                        true &&
                                                                    (result.formattedAddress
                                                                            ?.isNotEmpty ??
                                                                        false))
                                                                ? "${result.name!} - ${_shortAddress(result.formattedAddress!)}"
                                                                : (result.name
                                                                            ?.trim()
                                                                            .isNotEmpty ==
                                                                        true
                                                                    ? result
                                                                        .name!
                                                                    : (result.formattedAddress !=
                                                                            null
                                                                        ? _shortAddress(
                                                                            result.formattedAddress!)
                                                                        : "")));
                                                            controller
                                                                    .sourceLocationLAtLng
                                                                    .value =
                                                                LocationLatLng(
                                                                    latitude: result
                                                                        .geometry!
                                                                        .location
                                                                        .lat,
                                                                    longitude: result
                                                                        .geometry!
                                                                        .location
                                                                        .lng);
                                                            await controller
                                                                .calculateDurationAndDistance();
                                                            controller
                                                                .calculateAmount();
                                                          },
                                                          region: Constant.regionCode !=
                                                                      "all" &&
                                                                  Constant
                                                                      .regionCode
                                                                      .isNotEmpty
                                                              ? Constant
                                                                  .regionCode
                                                              : null,
                                                          // 🚀 PERFORMANCE: Use cached location instead of GPS
                                                          initialPosition: Constant.currentLocation !=
                                                                  null
                                                              ? LatLng(
                                                                  Constant
                                                                      .currentLocation!
                                                                      .latitude,
                                                                  Constant
                                                                      .currentLocation!
                                                                      .longitude)
                                                              : const LatLng(
                                                                  15.3694,
                                                                  44.1910), // Yemen center as fallback
                                                          // 🚀 PERFORMANCE: Disable slow location fetch
                                                          useCurrentLocation:
                                                              false,
                                                          autocompleteComponents:
                                                              Constant.regionCode !=
                                                                          "all" &&
                                                                      Constant
                                                                          .regionCode
                                                                          .isNotEmpty
                                                                  ? [
                                                                      Component(
                                                                          Component
                                                                              .country,
                                                                          Constant
                                                                              .regionCode)
                                                                    ]
                                                                  : [],
                                                          // ✅ ENABLE: Auto-detect address for initial position
                                                          selectInitialPosition:
                                                              true,
                                                          // ✅ ENABLE: Required for confirmation button
                                                          usePinPointingSearch:
                                                              true,
                                                          usePlaceDetailSearch:
                                                              true,
                                                          zoomGesturesEnabled:
                                                              true,
                                                          zoomControlsEnabled:
                                                              true,
                                                          resizeToAvoidBottomInset:
                                                              false, // only works in page mode, less flickery, remove if wrong offsets
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: TextFieldThem.buildTextFiled(
                                                    context,
                                                    hintText:
                                                        'Enter Your Current Location'
                                                            .tr,
                                                    controller: controller
                                                        .sourceLocationController
                                                        .value,
                                                    enable: false))
                                            : Row(
                                                children: [
                                                  Column(
                                                    children: [
                                                      SvgPicture.asset(
                                                          themeChange.getThem()
                                                              ? 'assets/icons/ic_source_dark.svg'
                                                              : 'assets/icons/ic_source.svg',
                                                          width: 18),
                                                      Dash(
                                                          direction:
                                                              Axis.vertical,
                                                          length:
                                                              Responsive.height(
                                                                  6, context),
                                                          dashLength: 12,
                                                          dashColor: AppColors
                                                              .dottedDivider),
                                                      SvgPicture.asset(
                                                          themeChange.getThem()
                                                              ? 'assets/icons/ic_destination_dark.svg'
                                                              : 'assets/icons/ic_destination.svg',
                                                          width: 20),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 18),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              if (Constant
                                                                      .selectedMapType ==
                                                                  'osm') {
                                                                Get.to(() =>
                                                                        const LocationPicker())
                                                                    ?.then(
                                                                        (value) async {
                                                                  if (value !=
                                                                      null) {
                                                                    controller
                                                                        .sourceLocationController
                                                                        .value
                                                                        .text = value.displayName!;
                                                                    controller.sourceLocationLAtLng.value = LocationLatLng(
                                                                        latitude:
                                                                            value
                                                                                .lat,
                                                                        longitude:
                                                                            value.lon);
                                                                    print(
                                                                        '✅ Source location set: ${value.displayName}');
                                                                    print(
                                                                        '✅ Source coordinates: ${value.lat}, ${value.lon}');
                                                                    // ✅ GetX will automatically update UI
                                                                    await controller
                                                                        .calculateDurationAndDistance();
                                                                    controller
                                                                        .calculateAmount();
                                                                  }
                                                                });
                                                              } else {
                                                                await Navigator
                                                                    .push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            PlacePicker(
                                                                      apiKey: Constant
                                                                          .mapAPIKey,
                                                                      autocompleteLanguage:
                                                                          'ar',
                                                                      onPlacePicked:
                                                                          (result) async {
                                                                        Get.back();
                                                                        controller
                                                                            .sourceLocationController
                                                                            .value
                                                                            .text = ((result.name?.trim().isNotEmpty == true &&
                                                                                (result.formattedAddress?.isNotEmpty ?? false))
                                                                            ? "${result.name!} - ${_shortAddress(result.formattedAddress!)}"
                                                                            : (result.name?.trim().isNotEmpty == true ? result.name! : (result.formattedAddress != null ? _shortAddress(result.formattedAddress!) : "")));
                                                                        controller.sourceLocationLAtLng.value = LocationLatLng(
                                                                            latitude:
                                                                                result.geometry!.location.lat,
                                                                            longitude: result.geometry!.location.lng);
                                                                        print(
                                                                            '✅ Source location set: ${result.formattedAddress}');
                                                                        print(
                                                                            '✅ Source coordinates: ${result.geometry!.location.lat}, ${result.geometry!.location.lng}');
                                                                        // ✅ GetX will automatically update UI
                                                                        await controller
                                                                            .calculateDurationAndDistance();
                                                                        controller
                                                                            .calculateAmount();
                                                                      },
                                                                      region: Constant.regionCode != "all" &&
                                                                              Constant.regionCode.isNotEmpty
                                                                          ? Constant.regionCode
                                                                          : null,
                                                                      // 🚀 PERFORMANCE: Use cached location instead of GPS
                                                                      initialPosition: Constant.currentLocation !=
                                                                              null
                                                                          ? LatLng(
                                                                              Constant
                                                                                  .currentLocation!.latitude,
                                                                              Constant
                                                                                  .currentLocation!.longitude)
                                                                          : const LatLng(
                                                                              15.3694,
                                                                              44.1910), // Yemen center as fallback
                                                                      // 🚀 PERFORMANCE: Disable slow location fetch
                                                                      useCurrentLocation:
                                                                          false,
                                                                      autocompleteComponents:
                                                                          Constant.regionCode != "all" && Constant.regionCode.isNotEmpty
                                                                              ? [
                                                                                  Component(Component.country, Constant.regionCode)
                                                                                ]
                                                                              : [],
                                                                      // ✅ ENABLE: Auto-detect address for initial position
                                                                      selectInitialPosition:
                                                                          true,
                                                                      // ✅ ENABLE: Required for confirmation button
                                                                      usePinPointingSearch:
                                                                          true,
                                                                      usePlaceDetailSearch:
                                                                          true,
                                                                      zoomGesturesEnabled:
                                                                          true,
                                                                      zoomControlsEnabled:
                                                                          true,
                                                                      resizeToAvoidBottomInset:
                                                                          false,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: TextFieldThem.buildTextFiled(
                                                                      context,
                                                                      hintText:
                                                                          'Enter Location'
                                                                              .tr,
                                                                      controller: controller
                                                                          .sourceLocationController
                                                                          .value,
                                                                      enable:
                                                                          false),
                                                                ),
                                                                const SizedBox(
                                                                    width: 10),
                                                                InkWell(
                                                                    onTap: () {
                                                                      ariPortDialog(
                                                                          context,
                                                                          controller,
                                                                          true);
                                                                    },
                                                                    child: const Icon(
                                                                        Icons
                                                                            .flight_takeoff))
                                                              ],
                                                            )),
                                                        // ✅ DESTINATION FIELD - Only show when source is set
                                                        if (controller
                                                            .sourceLocationController
                                                            .value
                                                            .text
                                                            .isNotEmpty) ...[
                                                          // ✅ Destination title
                                                          Text(
                                                            "Destination Location"
                                                                .tr,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                          ),
                                                          InkWell(
                                                              onTap: () async {
                                                                if (Constant
                                                                        .selectedMapType ==
                                                                    'osm') {
                                                                  Get.to(() =>
                                                                          const LocationPicker())
                                                                      ?.then(
                                                                          (value) async {
                                                                    if (value !=
                                                                        null) {
                                                                      controller
                                                                          .destinationLocationController
                                                                          .value
                                                                          .text = value.displayName!;
                                                                      controller.destinationLocationLAtLng.value = LocationLatLng(
                                                                          latitude: value
                                                                              .lat,
                                                                          longitude:
                                                                              value.lon);
                                                                      await controller
                                                                          .calculateDurationAndDistance();
                                                                      controller
                                                                          .calculateAmount();
                                                                    }
                                                                  });
                                                                } else {
                                                                  await Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              PlacePicker(
                                                                        apiKey:
                                                                            Constant.mapAPIKey,
                                                                        autocompleteLanguage:
                                                                            'ar',
                                                                        onPlacePicked:
                                                                            (result) async {
                                                                          Get.back();
                                                                          controller
                                                                              .destinationLocationController
                                                                              .value
                                                                              .text = ((result.name?.trim().isNotEmpty == true &&
                                                                                  (result.formattedAddress?.isNotEmpty ?? false))
                                                                              ? "${result.name!} - ${_shortAddress(result.formattedAddress!)}"
                                                                              : (result.name?.trim().isNotEmpty == true ? result.name! : (result.formattedAddress != null ? _shortAddress(result.formattedAddress!) : "")));
                                                                          controller.destinationLocationLAtLng.value = LocationLatLng(
                                                                              latitude: result.geometry!.location.lat,
                                                                              longitude: result.geometry!.location.lng);
                                                                          await controller
                                                                              .calculateDurationAndDistance();
                                                                          controller
                                                                              .calculateAmount();
                                                                        },
                                                                        region: Constant.regionCode != "all" &&
                                                                                Constant.regionCode.isNotEmpty
                                                                            ? Constant.regionCode
                                                                            : null,
                                                                        // 🚀 PERFORMANCE: Use cached location instead of GPS
                                                                        initialPosition: Constant.currentLocation !=
                                                                                null
                                                                            ? LatLng(Constant.currentLocation!.latitude,
                                                                                Constant.currentLocation!.longitude)
                                                                            : const LatLng(15.3694, 44.1910), // Yemen center as fallback
                                                                        // 🚀 PERFORMANCE: Disable slow location fetch
                                                                        useCurrentLocation:
                                                                            false,
                                                                        autocompleteComponents: Constant.regionCode != "all" && Constant.regionCode.isNotEmpty
                                                                            ? [
                                                                                Component(Component.country, Constant.regionCode)
                                                                              ]
                                                                            : [],
                                                                        // ✅ ENABLE: Auto-detect address for initial position
                                                                        selectInitialPosition:
                                                                            true,
                                                                        // ✅ ENABLE: Required for confirmation button
                                                                        usePinPointingSearch:
                                                                            true,
                                                                        usePlaceDetailSearch:
                                                                            true,
                                                                        zoomGesturesEnabled:
                                                                            true,
                                                                        zoomControlsEnabled:
                                                                            true,
                                                                        resizeToAvoidBottomInset:
                                                                            false,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: TextFieldThem.buildTextFiled(
                                                                        context,
                                                                        hintText:
                                                                            'Enter destination Location'
                                                                                .tr,
                                                                        controller: controller
                                                                            .destinationLocationController
                                                                            .value,
                                                                        enable:
                                                                            false),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          10),
                                                                  InkWell(
                                                                      onTap:
                                                                          () {
                                                                        ariPortDialog(
                                                                            context,
                                                                            controller,
                                                                            false);
                                                                      },
                                                                      child: const Icon(
                                                                          Icons
                                                                              .flight_takeoff))
                                                                ],
                                                              )),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        const SizedBox(height: 20),
                                        // Continue button - REMOVED (moved to top after service selection)

                                        // New Continue Button at bottom
                                        Center(
                                          child: ButtonThem.buildButton(
                                            context,
                                            title: "Continue".tr,
                                            btnHeight:
                                                Responsive.height(6, context),
                                            customColor:
                                                AppColors.darkModePrimary,
                                            customTextColor: Colors.black,
                                            onPress: () {
                                            // ✅ CRITICAL: Check if location is available first
                                            if (Constant.currentLocation ==
                                                null) {
                                              ShowToastDialog.showToast(
                                                  "Location is required to book rides. Please enable location services."
                                                      .tr);
                                              return;
                                            }

                                            // Validate service selection first
                                            if (controller
                                                    .selectedType.value.id ==
                                                null) {
                                              ShowToastDialog.showToast(
                                                  "Please select a service type first"
                                                      .tr);
                                              return;
                                            }

                                            // Validate locations
                                            if (controller
                                                .sourceLocationController
                                                .value
                                                .text
                                                .isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please select source location"
                                                      .tr);
                                            } else if (controller
                                                .destinationLocationController
                                                .value
                                                .text
                                                .isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please select destination location"
                                                      .tr);
                                            } else if (controller
                                                        .sourceLocationLAtLng
                                                        .value
                                                        .latitude ==
                                                    null ||
                                                controller.sourceLocationLAtLng
                                                        .value.longitude ==
                                                    null) {
                                              ShowToastDialog.showToast(
                                                  "Source location coordinates are missing. Please select a valid source location."
                                                      .tr);
                                            } else if (controller
                                                        .destinationLocationLAtLng
                                                        .value
                                                        .latitude ==
                                                    null ||
                                                controller
                                                        .destinationLocationLAtLng
                                                        .value
                                                        .longitude ==
                                                    null) {
                                              ShowToastDialog.showToast(
                                                  "Destination location coordinates are missing. Please select a valid destination location."
                                                      .tr);
                                            } else {
                                              // Navigate based on service type
                                              print(
                                                  '🚀 Continue button pressed');
                                              print(
                                                  '🔍 Selected service: ${controller.selectedType.value.title?.first.title}');
                                              print(
                                                  '🔍 Service ID: ${controller.selectedType.value.id}');
                                              print(
                                                  '🔍 Intercity type: ${controller.selectedType.value.intercityType}');
                                              print(
                                                  '🔍 Source location: ${controller.sourceLocationController.value.text}');
                                              print(
                                                  '🔍 Destination location: ${controller.destinationLocationController.value.text}');
                                              controller
                                                  .navigateBasedOnServiceType();
                                            }
                                          },
                                        ),
                                        ),

                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              // ✅ Loading overlay for location requests
              _buildLoadingOverlay(controller),
            ],
          );
        });
  }

  _buildSuggestedPrice(BuildContext context, HomeController controller) {
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
                    decoration: const BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
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
                                  style:
                                      GoogleFonts.poppins(color: Colors.black),
                                ),
                              )
                            : RichText(
                                //${"Your Price is".tr} ${Constant.amountShow(amount: controller.amount.value)}.
                                text: TextSpan(
                                  text:
                                      '${"Approx time".tr} ${Constant.getLocalizedTime(controller.duration.value)}. ${"Approx distance".tr} ${double.parse(controller.distance.value).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.getLocalizedDistanceUnit()}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
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

  paymentMethodDialog(BuildContext context, HomeController controller) {
    return showModalBottomSheet(
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
                                          controller
                                                  .selectedPaymentMethod.value =
                                              controller
                                                  .paymentModel.value.cash!.name
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
                                                        controller.paymentModel
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
                                                  width: 80,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: AppColors
                                                              .lightGray,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
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
                                                  value: controller.paymentModel
                                                      .value.cash!.name
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
                                                        controller.paymentModel
                                                            .value.cash!.name
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
                                          controller
                                                  .selectedPaymentMethod.value =
                                              controller.paymentModel.value
                                                  .wallet!.name
                                                  .toString();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            border: Border.all(
                                                color: controller
                                                            .selectedPaymentMethod
                                                            .value ==
                                                        controller.paymentModel
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
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 80,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.lightGray,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: SvgPicture.asset(
                                                      'assets/icons/ic_wallet.svg',
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Wallet".tr,
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
                                                  value: controller.paymentModel
                                                      .value.wallet!.name
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
                                                        controller.paymentModel
                                                            .value.wallet!.name
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
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Choose".tr,
                        onPress: () async {
                          Get.back();
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

  someOneTakingDialog(BuildContext context, HomeController controller) {
    return showModalBottomSheet(
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
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            controller.selectedTakingRide.value = ContactModel(
                                fullName: "Myself".tr, contactNumber: "");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                  color: controller.selectedTakingRide.value
                                              .fullName ==
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
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Myself".tr,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  Radio(
                                    value: "Myself".tr,
                                    groupValue: controller
                                        .selectedTakingRide.value.fullName,
                                    activeColor: themeChange.getThem()
                                        ? AppColors.darkModePrimary
                                        : AppColors.primary,
                                    onChanged: (value) {
                                      controller.selectedTakingRide.value =
                                          ContactModel(
                                              fullName: "Myself".tr,
                                              contactNumber: "");
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListView.builder(
                          itemCount: controller.contactList.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            ContactModel contactModel =
                                controller.contactList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: InkWell(
                                onTap: () {
                                  controller.selectedTakingRide.value =
                                      contactModel;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    border: Border.all(
                                        color: controller.selectedTakingRide
                                                    .value.fullName ==
                                                contactModel.fullName
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
                                          child: Icon(Icons.person,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            contactModel.fullName.toString(),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        Radio(
                                          value:
                                              contactModel.fullName.toString(),
                                          groupValue: controller
                                              .selectedTakingRide
                                              .value
                                              .fullName,
                                          activeColor: themeChange.getThem()
                                              ? AppColors.darkModePrimary
                                              : AppColors.primary,
                                          onChanged: (value) {
                                            controller.selectedTakingRide
                                                .value = contactModel;
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
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              final FlutterNativeContactPicker contactPicker =
                                  FlutterNativeContactPicker();
                              Contact? contact =
                                  await contactPicker.selectContact();
                              ContactModel contactModel = ContactModel();
                              contactModel.fullName = contact!.fullName ?? "";
                              contactModel.contactNumber =
                                  contact.selectedPhoneNumber;

                              if (!controller.contactList
                                  .contains(contactModel)) {
                                controller.contactList.add(contactModel);
                                controller.setContact();
                              }
                            } catch (e) {
                              rethrow;
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
                                const SizedBox(
                                  width: 10,
                                ),
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
                        const SizedBox(
                          height: 10,
                        ),
                        ButtonThem.buildButton(
                          context,
                          title:
                              "${"Book for ".tr} ${controller.selectedTakingRide.value.fullName}"
                                  .tr,
                          btnWidthRatio: 1,
                          customColor: AppColors.darkModePrimary,
                          customTextColor: Colors.black,
                          onPress: () async {
                            Get.back();
                          },
                        ),
                        const SizedBox(
                          height: 10,
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

  ariPortDialog(
      BuildContext context, HomeController controller, bool isSource) {
    // Reset airport list to ensure fresh loading each time
    Constant.airaPortList = null;
    
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);

          return StatefulBuilder(builder: (context1, setState) {
            // Always load airports fresh when dialog opens
            if (Constant.airaPortList == null) {
              // Reset to ensure fresh loading each time
              Constant.airaPortList = null;
              FireStoreUtils().getAirports().then((value) {
                if (value != null && value.isNotEmpty) {
                  Constant.airaPortList = value;
                } else {
                  // Set empty list to avoid showing loading indicator
                  Constant.airaPortList = [];
                  log("No airports found or empty list returned");
                }
                // Refresh the dialog state
                if (context1.mounted) {
                  setState(() {});
                }
              }).catchError((error) {
                // Set empty list to avoid showing loading indicator
                Constant.airaPortList = [];
                log("Error loading airports: $error");
                if (context1.mounted) {
                  setState(() {});
                  ShowToastDialog.showToast("Failed to load airports. Please try again.".tr);
                }
              });
            }
            
            return Container(
              constraints:
                  BoxConstraints(maxHeight: Responsive.height(90, context)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Do you want to travel for AirPort?".tr,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Choose a single AirPort".tr,
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Check if airport list is available
                      if (Constant.airaPortList == null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (Constant.airaPortList!.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.flight_takeoff, size: 50, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text(
                                  "No airports available for your location".tr,
                                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 300,
                          child: ListView.builder(
                            itemCount: Constant.airaPortList!.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                            AriPortModel airPortModel =
                                Constant.airaPortList![index];
                          return Obx(
                            () => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: InkWell(
                                onTap: () {
                                  controller.selectedAirPort.value =
                                      airPortModel;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    border: Border.all(
                                        color: controller
                                                    .selectedAirPort.value.id ==
                                                airPortModel.id
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
                                          child: Icon(Icons.airplanemode_active,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            airPortModel.airportName.toString(),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        Radio(
                                          value: airPortModel.id.toString(),
                                          groupValue: controller
                                              .selectedAirPort.value.id,
                                          activeColor: themeChange.getThem()
                                              ? AppColors.darkModePrimary
                                              : AppColors.primary,
                                          onChanged: (value) {
                                            controller.selectedAirPort.value =
                                                airPortModel;
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Book".tr,
                        onPress: () async {
                          // Check if airports are available
                          if (Constant.airaPortList == null || Constant.airaPortList!.isEmpty) {
                            ShowToastDialog.showToast(
                              "Airports are still loading. Please wait...".tr,
                            );
                            return;
                          }
                          
                          if (controller.selectedAirPort.value.id != null) {
                            if (isSource) {
                              controller.sourceLocationController.value.text =
                                  controller.selectedAirPort.value.airportName
                                      .toString();
                              controller.sourceLocationLAtLng.value =
                                  LocationLatLng(
                                      latitude: double.parse(controller
                                          .selectedAirPort.value.airportLat
                                          .toString()),
                                      longitude: double.parse(controller
                                          .selectedAirPort.value.airportLng
                                          .toString()));
                              controller.calculateAmount();
                            } else {
                              controller.destinationLocationController.value
                                      .text =
                                  controller.selectedAirPort.value.airportName
                                      .toString();
                              controller.destinationLocationLAtLng.value =
                                  LocationLatLng(
                                      latitude: double.parse(controller
                                          .selectedAirPort.value.airportLat
                                          .toString()),
                                      longitude: double.parse(controller
                                          .selectedAirPort.value.airportLng
                                          .toString()));
                              controller.calculateAmount();
                            }
                            Get.back();
                          } else {
                            ShowToastDialog.showToast(
                              "Please select one airport".tr,
                            );
                          }
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  showAlertDialog(BuildContext context) {
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

  Widget _buildBanner(BuildContext context, HomeController controller) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.20,
      color: Colors.black,
      child: Obx(() {
        if (controller.bannerList.isEmpty) {
          // Beautiful modern placeholder with soft gradient and shimmer
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: _BannerShimmerPlaceholder(),
            ),
          );
        }
        // Real banners
        return PageView.builder(
          padEnds: true,
          allowImplicitScrolling: true,
          itemCount: controller.bannerList.length,
          scrollDirection: Axis.horizontal,
          controller: controller.pageController,
          itemBuilder: (context, index) {
            try {
              BannerModel bannerModel = controller.bannerList[index];

              // ✅ Skip banners without valid image URLs
              if (bannerModel.image == null || bannerModel.image!.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                child: CachedNetworkImage(
                  imageUrl: bannerModel.image?.toString() ?? '',
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
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[300],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
              );
            } catch (e) {
              print('⚠️ Error building banner at index $index: $e');
              return const SizedBox.shrink();
            }
          },
        );
      }),
    );
  }

  void showTooltip(BuildContext context, String message) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);

    if (tooltip?.isOpen ?? false) return;

    tooltip = SuperTooltip(
      popupDirection: TooltipDirection.up,
      arrowTipDistance: 8.0,
      arrowBaseWidth: 20.0,
      arrowLength: 10.0,
      borderRadius: 12.0,
      hasShadow: true,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      content: Text(
        message,
        style: TextStyle(
            color: themeChange.getThem() ? Colors.black : Colors.white,
            fontSize: 13),
        textAlign: TextAlign.right,
      ),
      backgroundColor:
          themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
    );

    tooltip!.show(context);
  }

  /// ✅ Build location status indicator widget
  Widget _buildLocationStatusIndicator() {
    if (Constant.currentLocation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Required".tr,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Active".tr,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ✅ Build location content widget
  Widget _buildLocationContent(HomeController controller) {
    if (controller.isLocationLoading.value) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Getting location...".tr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (Constant.currentLocation == null) {
      return Text(
        "Location Required - Tap to grant permission".tr,
        style: GoogleFonts.poppins(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      _shortAddress(controller.currentLocation.value),
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// ✅ Build loading overlay widget
  Widget _buildLoadingOverlay(HomeController controller) {
    if (controller.isLocationLoading.value) {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// Helper to shorten the address
String _shortAddress(String address) {
  // Show the last 3 parts (e.g., 'Street, City, Country')
  final parts = address.split(',').map((e) => e.trim()).toList();
  if (parts.length >= 3) {
    return parts.sublist(parts.length - 3).join(', ');
  } else if (parts.length == 2) {
    return parts.join(', ');
  } else if (parts.isNotEmpty) {
    return parts.last;
  }
  return address;
}
