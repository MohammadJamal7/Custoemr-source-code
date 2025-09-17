// import 'dart:developer';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:customer/constant/constant.dart';
// import 'package:customer/constant/send_notification.dart';
// import 'package:customer/constant/show_toast_dialog.dart';
// import 'package:customer/controller/home_controller.dart';
// import 'package:customer/model/airport_model.dart';
// import 'package:customer/model/banner_model.dart';
// import 'package:customer/model/contact_model.dart';
// import 'package:customer/model/language_name.dart';
// import 'package:customer/model/order/location_lat_lng.dart';
// import 'package:customer/model/order/positions.dart';
// import 'package:customer/model/order_model.dart';
// import 'package:customer/model/service_model.dart';
// import 'package:customer/themes/app_colors.dart';
// import 'package:customer/themes/button_them.dart';
// import 'package:customer/themes/responsive.dart';
// import 'package:customer/themes/text_field_them.dart';
// import 'package:customer/utils/DarkThemeProvider.dart';
// import 'package:customer/utils/fire_store_utils.dart';
// import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
// import 'package:customer/widget/geoflutterfire/src/models/point.dart';
// import 'package:customer/widget/place_picker_osm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_dash/flutter_dash.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_google_maps_webservices/places.dart';
// import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
// import 'package:flutter_native_contact_picker/model/contact.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:super_tooltip/super_tooltip.dart';

// import '../../controller/dash_board_controller.dart';
// import '../../controller/interCity_controller.dart';
// import '../../model/zone_model.dart';
// import '../auth_screen/login_screen.dart';

// class HomeScreen extends StatelessWidget {
//   HomeScreen({super.key});

//   SuperTooltip? tooltip;
//   final Map<String, String> serviceTooltips = {
//     'تاكسي': 'إذاكنت بحاجة إلى سيارة كاملة عدد الركاب ٤ للتنقل داخل المدينة.',
//     'توك توك': 'تحجز كامل للتنقل داخل المدينة للمشاوير القريبة',
//     'رحلة خاصة داخلية':
//         'إذاكنت بحاجة إلى باص عدد الركاب 15 للتنقل داخل المدينة.',
//     'دراجة نارية': 'عدد الركاب ١ للتنقل داخل المدينة ولتجنب الإزدحامات.',
//   };

//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);

//     return GetX<HomeController>(
//         init: HomeController(),
//         builder: (controller) {
//           return Scaffold(
//             backgroundColor: AppColors.primary,
//             body: controller.isLoading.value
//                 ? Constant.loader()
//                 : Column(
//                     children: [
//                       _buildBanner(context, controller),
//                       SizedBox(
//                         height: Responsive.width(22, context),
//                         width: Responsive.width(100, context),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 controller.userModel.value.fullName
//                                             ?.isNotEmpty ==
//                                         true
//                                     ? "Current Location".tr
//                                     : "Guest",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 18,
//                                   letterSpacing: 1,
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 4,
//                               ),
//                               Row(
//                                 children: [
//                                   SvgPicture.asset(
//                                       'assets/icons/ic_location.svg',
//                                       width: 16),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   Expanded(
//                                       child: Text(
//                                           controller.currentLocation.value,
//                                           style: GoogleFonts.poppins(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.w400))),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Container(
//                           decoration: BoxDecoration(
//                               color: Theme.of(context).colorScheme.background,
//                               borderRadius: const BorderRadius.only(
//                                   topLeft: Radius.circular(25),
//                                   topRight: Radius.circular(25))),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10),
//                             child: SingleChildScrollView(
//                               child: Padding(
//                                 padding: const EdgeInsets.only(top: 10),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text("Where you want to go?".tr,
//                                         style: GoogleFonts.poppins(
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 18,
//                                             letterSpacing: 1)),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     controller.sourceLocationLAtLng.value
//                                                 .latitude ==
//                                             null
//                                         ? InkWell(
//                                             onTap: () async {
//                                               if (Constant.selectedMapType ==
//                                                   'osm') {
//                                                 Get.to(() =>
//                                                         const LocationPicker())
//                                                     ?.then((value) async {
//                                                   if (value != null) {
//                                                     controller
//                                                         .sourceLocationController
//                                                         .value
//                                                         .text = value.displayName!;
//                                                     controller
//                                                             .sourceLocationLAtLng
//                                                             .value =
//                                                         LocationLatLng(
//                                                             latitude: value.lat,
//                                                             longitude:
//                                                                 value.lon);
//                                                     await controller
//                                                         .calculateDurationAndDistance();
//                                                     controller
//                                                         .calculateAmount();
//                                                   }
//                                                 });
//                                               } else {
//                                                 await Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (context) =>
//                                                         PlacePicker(
//                                                       apiKey:
//                                                           Constant.mapAPIKey,
//                                                       onPlacePicked:
//                                                           (result) async {
//                                                         Get.back();
//                                                         controller
//                                                                 .sourceLocationController
//                                                                 .value
//                                                                 .text =
//                                                             result
//                                                                 .formattedAddress
//                                                                 .toString();
//                                                         controller
//                                                                 .sourceLocationLAtLng
//                                                                 .value =
//                                                             LocationLatLng(
//                                                                 latitude: result
//                                                                     .geometry!
//                                                                     .location
//                                                                     .lat,
//                                                                 longitude: result
//                                                                     .geometry!
//                                                                     .location
//                                                                     .lng);
//                                                         await controller
//                                                             .calculateDurationAndDistance();
//                                                         controller
//                                                             .calculateAmount();
//                                                       },
//                                                       region:
//                                                           Constant.regionCode !=
//                                                                       "all" &&
//                                                                   Constant
//                                                                       .regionCode
//                                                                       .isNotEmpty
//                                                               ? Constant
//                                                                   .regionCode
//                                                               : null,
//                                                       initialPosition:
//                                                           const LatLng(
//                                                               -33.8567844,
//                                                               151.213108),
//                                                       useCurrentLocation: true,
//                                                       autocompleteComponents:
//                                                           Constant.regionCode !=
//                                                                       "all" &&
//                                                                   Constant
//                                                                       .regionCode
//                                                                       .isNotEmpty
//                                                               ? [
//                                                                   Component(
//                                                                       Component
//                                                                           .country,
//                                                                       Constant
//                                                                           .regionCode)
//                                                                 ]
//                                                               : [],
//                                                       // Add this line
//                                                       selectInitialPosition:
//                                                           true,
//                                                       usePinPointingSearch:
//                                                           true,
//                                                       usePlaceDetailSearch:
//                                                           true,
//                                                       zoomGesturesEnabled: true,
//                                                       zoomControlsEnabled: true,
//                                                       resizeToAvoidBottomInset:
//                                                           false, // only works in page mode, less flickery, remove if wrong offsets
//                                                     ),
//                                                   ),
//                                                 );
//                                               }
//                                             },
//                                             child: TextFieldThem.buildTextFiled(
//                                                 context,
//                                                 hintText:
//                                                     'Enter Your Current Location'
//                                                         .tr,
//                                                 controller: controller
//                                                     .sourceLocationController
//                                                     .value,
//                                                 enable: false))
//                                         : Row(
//                                             children: [
//                                               Column(
//                                                 children: [
//                                                   SvgPicture.asset(
//                                                       themeChange.getThem()
//                                                           ? 'assets/icons/ic_source_dark.svg'
//                                                           : 'assets/icons/ic_source.svg',
//                                                       width: 18),
//                                                   Dash(
//                                                       direction: Axis.vertical,
//                                                       length: Responsive.height(
//                                                           6, context),
//                                                       dashLength: 12,
//                                                       dashColor: AppColors
//                                                           .dottedDivider),
//                                                   SvgPicture.asset(
//                                                       themeChange.getThem()
//                                                           ? 'assets/icons/ic_destination_dark.svg'
//                                                           : 'assets/icons/ic_destination.svg',
//                                                       width: 20),
//                                                 ],
//                                               ),
//                                               const SizedBox(
//                                                 width: 18,
//                                               ),
//                                               Expanded(
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     InkWell(
//                                                         onTap: () async {
//                                                           print(
//                                                               "::::::::::33::::::::::::");
//                                                           if (Constant
//                                                                   .selectedMapType ==
//                                                               'osm') {
//                                                             Get.to(() =>
//                                                                     const LocationPicker())
//                                                                 ?.then(
//                                                                     (value) async {
//                                                               if (value !=
//                                                                   null) {
//                                                                 controller
//                                                                         .sourceLocationController
//                                                                         .value
//                                                                         .text =
//                                                                     value
//                                                                         .displayName!;
//                                                                 controller
//                                                                         .sourceLocationLAtLng
//                                                                         .value =
//                                                                     LocationLatLng(
//                                                                         latitude:
//                                                                             value
//                                                                                 .lat,
//                                                                         longitude:
//                                                                             value.lon);
//                                                                 await controller
//                                                                     .calculateDurationAndDistance();
//                                                                 controller
//                                                                     .calculateAmount();
//                                                               }
//                                                             });
//                                                           } else {
//                                                             await Navigator
//                                                                 .push(
//                                                               context,
//                                                               MaterialPageRoute(
//                                                                 builder:
//                                                                     (context) =>
//                                                                         PlacePicker(
//                                                                   apiKey: Constant
//                                                                       .mapAPIKey,
//                                                                   onPlacePicked:
//                                                                       (result) async {
//                                                                     Get.back();
//                                                                     controller
//                                                                             .sourceLocationController
//                                                                             .value
//                                                                             .text =
//                                                                         result
//                                                                             .formattedAddress
//                                                                             .toString();
//                                                                     controller.sourceLocationLAtLng.value = LocationLatLng(
//                                                                         latitude: result
//                                                                             .geometry!
//                                                                             .location
//                                                                             .lat,
//                                                                         longitude: result
//                                                                             .geometry!
//                                                                             .location
//                                                                             .lng);
//                                                                     await controller
//                                                                         .calculateDurationAndDistance();
//                                                                     controller
//                                                                         .calculateAmount();
//                                                                   },
//                                                                   region: Constant.regionCode !=
//                                                                               "all" &&
//                                                                           Constant
//                                                                               .regionCode
//                                                                               .isNotEmpty
//                                                                       ? Constant
//                                                                           .regionCode
//                                                                       : null,
//                                                                   initialPosition:
//                                                                       const LatLng(
//                                                                           -33.8567844,
//                                                                           151.213108),
//                                                                   useCurrentLocation:
//                                                                       true,
//                                                                   autocompleteComponents: Constant.regionCode !=
//                                                                               "all" &&
//                                                                           Constant
//                                                                               .regionCode
//                                                                               .isNotEmpty
//                                                                       ? [
//                                                                           Component(
//                                                                               Component.country,
//                                                                               Constant.regionCode)
//                                                                         ]
//                                                                       : [],
//                                                                   selectInitialPosition:
//                                                                       true,
//                                                                   usePinPointingSearch:
//                                                                       true,
//                                                                   usePlaceDetailSearch:
//                                                                       true,
//                                                                   zoomGesturesEnabled:
//                                                                       true,
//                                                                   zoomControlsEnabled:
//                                                                       true,
//                                                                   resizeToAvoidBottomInset:
//                                                                       false, // only works in page mode, less flickery, remove if wrong offsets
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           }
//                                                         },
//                                                         child: Row(
//                                                           children: [
//                                                             Expanded(
//                                                               child: TextFieldThem.buildTextFiled(
//                                                                   context,
//                                                                   hintText:
//                                                                       'Enter Location'
//                                                                           .tr,
//                                                                   controller:
//                                                                       controller
//                                                                           .sourceLocationController
//                                                                           .value,
//                                                                   enable:
//                                                                       false),
//                                                             ),
//                                                             const SizedBox(
//                                                               width: 10,
//                                                             ),
//                                                             InkWell(
//                                                                 onTap: () {
//                                                                   ariPortDialog(
//                                                                       context,
//                                                                       controller,
//                                                                       true);
//                                                                 },
//                                                                 child: const Icon(
//                                                                     Icons
//                                                                         .flight_takeoff))
//                                                           ],
//                                                         )),
//                                                     SizedBox(
//                                                         height:
//                                                             Responsive.height(
//                                                                 1, context)),
//                                                     InkWell(
//                                                         onTap: () async {
//                                                           print(
//                                                               "::::::::::11::::::::::::");
//                                                           if (Constant
//                                                                   .selectedMapType ==
//                                                               'osm') {
//                                                             Get.to(() =>
//                                                                     const LocationPicker())
//                                                                 ?.then(
//                                                                     (value) async {
//                                                               if (value !=
//                                                                   null) {
//                                                                 controller
//                                                                         .destinationLocationController
//                                                                         .value
//                                                                         .text =
//                                                                     value
//                                                                         .displayName!;
//                                                                 controller
//                                                                         .destinationLocationLAtLng
//                                                                         .value =
//                                                                     LocationLatLng(
//                                                                         latitude:
//                                                                             value
//                                                                                 .lat,
//                                                                         longitude:
//                                                                             value.lon);
//                                                                 await controller
//                                                                     .calculateDurationAndDistance();
//                                                                 controller
//                                                                     .calculateAmount();
//                                                               }
//                                                             });
//                                                           } else {
//                                                             await Navigator
//                                                                 .push(
//                                                               context,
//                                                               MaterialPageRoute(
//                                                                 builder:
//                                                                     (context) =>
//                                                                         PlacePicker(
//                                                                   apiKey: Constant
//                                                                       .mapAPIKey,
//                                                                   onPlacePicked:
//                                                                       (result) async {
//                                                                     Get.back();
//                                                                     controller
//                                                                             .destinationLocationController
//                                                                             .value
//                                                                             .text =
//                                                                         result
//                                                                             .formattedAddress
//                                                                             .toString();
//                                                                     controller.destinationLocationLAtLng.value = LocationLatLng(
//                                                                         latitude: result
//                                                                             .geometry!
//                                                                             .location
//                                                                             .lat,
//                                                                         longitude: result
//                                                                             .geometry!
//                                                                             .location
//                                                                             .lng);
//                                                                     await controller
//                                                                         .calculateDurationAndDistance();
//                                                                     controller
//                                                                         .calculateAmount();
//                                                                   },
//                                                                   region: Constant.regionCode !=
//                                                                               "all" &&
//                                                                           Constant
//                                                                               .regionCode
//                                                                               .isNotEmpty
//                                                                       ? Constant
//                                                                           .regionCode
//                                                                       : null,
//                                                                   initialPosition:
//                                                                       const LatLng(
//                                                                           -33.8567844,
//                                                                           151.213108),
//                                                                   useCurrentLocation:
//                                                                       true,
//                                                                   autocompleteComponents: Constant.regionCode !=
//                                                                               "all" &&
//                                                                           Constant
//                                                                               .regionCode
//                                                                               .isNotEmpty
//                                                                       ? [
//                                                                           Component(
//                                                                               Component.country,
//                                                                               Constant.regionCode)
//                                                                         ]
//                                                                       : [],
//                                                                   selectInitialPosition:
//                                                                       true,
//                                                                   usePinPointingSearch:
//                                                                       true,
//                                                                   usePlaceDetailSearch:
//                                                                       true,
//                                                                   zoomGesturesEnabled:
//                                                                       true,
//                                                                   zoomControlsEnabled:
//                                                                       true,
//                                                                   resizeToAvoidBottomInset:
//                                                                       false, // only works in page mode, less flickery, remove if wrong offsets
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           }
//                                                         },
//                                                         child: Row(
//                                                           children: [
//                                                             Expanded(
//                                                               child: TextFieldThem.buildTextFiled(
//                                                                   context,
//                                                                   hintText:
//                                                                       'Enter destination Location'
//                                                                           .tr,
//                                                                   controller:
//                                                                       controller
//                                                                           .destinationLocationController
//                                                                           .value,
//                                                                   enable:
//                                                                       false),
//                                                             ),
//                                                             const SizedBox(
//                                                               width: 10,
//                                                             ),
//                                                             InkWell(
//                                                                 onTap: () {
//                                                                   ariPortDialog(
//                                                                       context,
//                                                                       controller,
//                                                                       false);
//                                                                 },
//                                                                 child: const Icon(
//                                                                     Icons
//                                                                         .flight_takeoff))
//                                                           ],
//                                                         )),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                     const SizedBox(
//                                       height: 20,
//                                     ),
//                                     Text("Select Vehicle".tr,
//                                         style: GoogleFonts.poppins(
//                                             fontWeight: FontWeight.w500,
//                                             letterSpacing: 1)),
//                                     const SizedBox(
//                                       height: 05,
//                                     ),
//                                     SizedBox(
//                                       height: Responsive.height(18, context),
//                                       child: ListView.builder(
//                                         itemCount:
//                                             controller.serviceList.length,
//                                         scrollDirection: Axis.horizontal,
//                                         shrinkWrap: true,
//                                         itemBuilder: (context, index) {
//                                           ServiceModel serviceModel =
//                                               controller.serviceList[index];
//                                           print(
//                                               'NAME SERVICE -> ${Constant.localizationTitle(serviceModel.title).trim()}');
//                                           return Obx(
//                                             () => InkWell(
//                                               onTap: () {
//                                                 // select city service
//                                                 controller.selectedType.value =
//                                                     serviceModel;
//                                                 // select intercity service
//                                                 if (serviceModel
//                                                         .intercityType ==
//                                                     true) {
//                                                   final interCityController =
//                                                       Get.put(
//                                                           InterCityController());
//                                                   interCityController
//                                                       .selectIntercityFromService(
//                                                           Constant
//                                                               .localizationTitle(
//                                                                   serviceModel
//                                                                       .title));
//                                                   Get.find<
//                                                           DashBoardController>()
//                                                       .onSelectItem(1);
//                                                   return;
//                                                 }
//                                                 if (Constant.selectedMapType ==
//                                                     'osm') {
//                                                   controller
//                                                       .calculateOsmAmount();
//                                                 } else {
//                                                   controller.calculateAmount();
//                                                 }
//                                               },
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.all(6.0),
//                                                 child: Container(
//                                                   width: Responsive.width(
//                                                       28, context),
//                                                   decoration: BoxDecoration(
//                                                       color: controller
//                                                                   .selectedType
//                                                                   .value ==
//                                                               serviceModel
//                                                           ? themeChange
//                                                                   .getThem()
//                                                               ? AppColors
//                                                                   .darkModePrimary
//                                                               : AppColors
//                                                                   .primary
//                                                           : themeChange
//                                                                   .getThem()
//                                                               ? AppColors
//                                                                   .darkService
//                                                               : controller
//                                                                       .colors[
//                                                                   index %
//                                                                       controller
//                                                                           .colors
//                                                                           .length],
//                                                       borderRadius:
//                                                           const BorderRadius
//                                                               .all(
//                                                         Radius.circular(20),
//                                                       )),
//                                                   child: Stack(
//                                                     children: [
//                                                       Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .center,
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           Center(
//                                                             child: Container(
//                                                               decoration:
//                                                                   BoxDecoration(
//                                                                 color: Theme.of(
//                                                                         context)
//                                                                     .colorScheme
//                                                                     .background,
//                                                                 borderRadius:
//                                                                     const BorderRadius
//                                                                         .all(
//                                                                         Radius.circular(
//                                                                             20)),
//                                                               ),
//                                                               child: Padding(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(
//                                                                         8.0),
//                                                                 child:
//                                                                     CachedNetworkImage(
//                                                                   imageUrl:
//                                                                       serviceModel
//                                                                           .image
//                                                                           .toString(),
//                                                                   fit: BoxFit
//                                                                       .contain,
//                                                                   height: Responsive
//                                                                       .height(8,
//                                                                           context),
//                                                                   width: Responsive
//                                                                       .width(18,
//                                                                           context),
//                                                                   placeholder: (context,
//                                                                           url) =>
//                                                                       Constant
//                                                                           .loader(),
//                                                                   errorWidget: (context,
//                                                                           url,
//                                                                           error) =>
//                                                                       Image.network(
//                                                                           Constant
//                                                                               .userPlaceHolder),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                               height: 10),
//                                                           Text(
//                                                             Constant
//                                                                 .localizationTitle(
//                                                                     serviceModel
//                                                                         .title),
//                                                             style: GoogleFonts
//                                                                 .poppins(
//                                                               color: controller
//                                                                           .selectedType
//                                                                           .value ==
//                                                                       serviceModel
//                                                                   ? themeChange
//                                                                           .getThem()
//                                                                       ? Colors
//                                                                           .black
//                                                                       : Colors
//                                                                           .white
//                                                                   : themeChange
//                                                                           .getThem()
//                                                                       ? Colors
//                                                                           .white
//                                                                       : Colors
//                                                                           .black,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                       if (serviceTooltips.containsKey(
//                                                               Constant.localizationTitle(
//                                                                       serviceModel
//                                                                           .title)
//                                                                   .trim()) &&
//                                                           controller
//                                                                   .selectedType
//                                                                   .value
//                                                                   .id ==
//                                                               serviceModel.id)
//                                                         Positioned(
//                                                           top: 5,
//                                                           left: 10,
//                                                           child: Builder(
//                                                             builder: (context) {
//                                                               final key =
//                                                                   GlobalKey();

//                                                               return GestureDetector(
//                                                                 key: key,
//                                                                 onTap: () {
//                                                                   final title =
//                                                                       Constant.localizationTitle(
//                                                                           serviceModel
//                                                                               .title);
//                                                                   final message =
//                                                                       serviceTooltips[
//                                                                           title];
//                                                                   if (message ==
//                                                                       null)
//                                                                     return;
//                                                                   showTooltip(
//                                                                       context,
//                                                                       message);
//                                                                 },
//                                                                 child:
//                                                                     const Icon(
//                                                                   Icons
//                                                                       .info_outline,
//                                                                   color: Colors
//                                                                       .white,
//                                                                   size: 18,
//                                                                 ),
//                                                               );
//                                                             },
//                                                           ),
//                                                         ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                     _buildSuggestedPrice(context, controller),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     Visibility(
//                                       visible: controller
//                                               .selectedType.value.offerRate ==
//                                           true,
//                                       child: TextFieldThem
//                                           .buildTextFiledWithPrefixIcon(context,
//                                               hintText:
//                                                   "Enter your offer rate".tr,
//                                               controller: controller
//                                                   .offerYourRateController
//                                                   .value,
//                                               inputFormatters: <TextInputFormatter>[
//                                                 FilteringTextInputFormatter
//                                                     .allow(RegExp(r'[0-9*]')),
//                                               ],
//                                               prefix: Padding(
//                                                 padding: const EdgeInsets.only(
//                                                     right: 10),
//                                                 child: Text(Constant
//                                                     .currencyModel!.symbol
//                                                     .toString()),
//                                               ),
//                                               keyBoardType:
//                                                   TextInputType.number),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     InkWell(
//                                       onTap: () {
//                                         someOneTakingDialog(
//                                             context, controller);
//                                       },
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius: const BorderRadius.all(
//                                               Radius.circular(4)),
//                                           border: Border.all(
//                                               color: AppColors.textFieldBorder,
//                                               width: 1),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 10, vertical: 12),
//                                           child: Row(
//                                             children: [
//                                               const Icon(Icons.person),
//                                               const SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Expanded(
//                                                   child: Text(
//                                                 controller.selectedTakingRide
//                                                             .value.fullName ==
//                                                         "Myself"
//                                                     ? "Myself".tr
//                                                     : controller
//                                                         .selectedTakingRide
//                                                         .value
//                                                         .fullName
//                                                         .toString(),
//                                                 style: GoogleFonts.poppins(),
//                                               )),
//                                               const Icon(Icons
//                                                   .arrow_drop_down_outlined)
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     InkWell(
//                                       onTap: () {
//                                         paymentMethodDialog(
//                                             context, controller);
//                                       },
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius: const BorderRadius.all(
//                                               Radius.circular(4)),
//                                           border: Border.all(
//                                               color: AppColors.textFieldBorder,
//                                               width: 1),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 10, vertical: 12),
//                                           child: Row(
//                                             children: [
//                                               SvgPicture.asset(
//                                                 'assets/icons/ic_payment.svg',
//                                                 width: 26,
//                                               ),
//                                               const SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Expanded(
//                                                   child: Text(
//                                                 controller.selectedPaymentMethod
//                                                         .value.isNotEmpty
//                                                     ? (controller
//                                                                 .selectedPaymentMethod
//                                                                 .value ==
//                                                             "Cash"
//                                                         ? "Cash".tr
//                                                         : "Wallet".tr)
//                                                     : "Select Payment type".tr,
//                                                 style: GoogleFonts.poppins(),
//                                               )),
//                                               const Icon(Icons
//                                                   .arrow_drop_down_outlined)
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                     ButtonThem.buildButton(
//                                       context,
//                                       title: "Book Ride".tr,
//                                       btnWidthRatio:
//                                           Responsive.width(100, context),
//                                       onPress: () async {
//                                         // double suggestPrice =
//                                         //     Constant.getAmountShow(
//                                         //         amount:
//                                         //             controller.amount.value);
//                                         double offerRate = double.parse(
//                                             controller.offerYourRateController
//                                                     .value.text.isEmpty
//                                                 ? '0.0'
//                                                 : controller
//                                                     .offerYourRateController
//                                                     .value
//                                                     .text);
//                                         // double acceptPrice = suggestPrice / 2;
//                                         if (controller
//                                                 .userModel.value.isActive ==
//                                             false) {
//                                           showDialog(
//                                               barrierDismissible: false,
//                                               context: context,
//                                               builder: (con) {
//                                                 return AlertDialog(
//                                                   content: Text(
//                                                       "This account is not active please contact administrator"
//                                                           .tr),
//                                                   actions: [
//                                                     TextButton(
//                                                         onPressed: () {
//                                                           Get.offAll(
//                                                               LoginScreen());
//                                                         },
//                                                         child: Text("OK".tr))
//                                                   ],
//                                                 );
//                                               });
//                                         } else {
//                                           bool isPaymentNotCompleted =
//                                               await FireStoreUtils
//                                                   .paymentStatusCheck();
//                                           bool isCurrentRide =
//                                               await FireStoreUtils
//                                                   .currentCheckRideCheck();
//                                           if (controller.selectedPaymentMethod
//                                               .value.isEmpty) {
//                                             ShowToastDialog.showToast(
//                                                 "Please select Payment Method"
//                                                     .tr);
//                                           } else if (controller
//                                               .sourceLocationController
//                                               .value
//                                               .text
//                                               .isEmpty) {
//                                             ShowToastDialog.showToast(
//                                                 "Please select source location"
//                                                     .tr);
//                                           } else if (controller
//                                               .destinationLocationController
//                                               .value
//                                               .text
//                                               .isEmpty) {
//                                             ShowToastDialog.showToast(
//                                                 "Please select destination location"
//                                                     .tr);
//                                           } else if (double.parse(
//                                                   controller.distance.value) <=
//                                               2) {
//                                             ShowToastDialog.showToast(
//                                                 "Please select more than two location"
//                                                     .tr);
//                                           } else if (controller.selectedType
//                                                       .value.offerRate ==
//                                                   true &&
//                                               controller.offerYourRateController
//                                                   .value.text.isEmpty) {
//                                             ShowToastDialog.showToast(
//                                                 "Please Enter offer rate".tr);
//                                           } else if (isPaymentNotCompleted) {
//                                             showAlertDialog(context);
//                                             // showDialog(context: context, builder: (BuildContext context) => warningDailog());
//                                           } else if (isCurrentRide) {
//                                             ShowToastDialog.showToast(
//                                                 "Please Complete Your Current Ride"
//                                                     .tr);
//                                             // showDialog(context: context, builder: (BuildContext context) => warningDailog());
//                                           } else if (offerRate < 1000) {
//                                             ShowToastDialog.showToast(
//                                                 "priceOffer".tr);
//                                           } else {
//                                             // ShowToastDialog.showLoader("Please wait");
//                                             OrderModel orderModel =
//                                                 OrderModel();

//                                             orderModel.id = Constant.getUuid();
//                                             orderModel.userId =
//                                                 FireStoreUtils.getCurrentUid();
//                                             orderModel.sourceLocationName =
//                                                 controller
//                                                     .sourceLocationController
//                                                     .value
//                                                     .text;
//                                             orderModel.destinationLocationName =
//                                                 controller
//                                                     .destinationLocationController
//                                                     .value
//                                                     .text;
//                                             orderModel.sourceLocationLAtLng =
//                                                 controller
//                                                     .sourceLocationLAtLng.value;
//                                             orderModel
//                                                     .destinationLocationLAtLng =
//                                                 controller
//                                                     .destinationLocationLAtLng
//                                                     .value;
//                                             orderModel.distance =
//                                                 controller.distance.value;
//                                             orderModel.distanceType =
//                                                 Constant.distanceType;
//                                             orderModel.offerRate = controller
//                                                         .selectedType
//                                                         .value
//                                                         .offerRate ==
//                                                     true
//                                                 ? controller
//                                                     .offerYourRateController
//                                                     .value
//                                                     .text
//                                                 : controller.amount.value;
//                                             orderModel.serviceId = controller
//                                                 .selectedType.value.id;
//                                             GeoFirePoint position =
//                                                 Geoflutterfire().point(
//                                                     latitude: controller
//                                                         .sourceLocationLAtLng
//                                                         .value
//                                                         .latitude!,
//                                                     longitude: controller
//                                                         .sourceLocationLAtLng
//                                                         .value
//                                                         .longitude!);

//                                             orderModel.position = Positions(
//                                                 geoPoint: position.geoPoint,
//                                                 geohash: position.hash);
//                                             orderModel.createdDate =
//                                                 Timestamp.now();
//                                             orderModel.status =
//                                                 Constant.ridePlaced;
//                                             orderModel.paymentType = controller
//                                                 .selectedPaymentMethod.value;
//                                             orderModel.paymentStatus = false;
//                                             orderModel.service =
//                                                 controller.selectedType.value;
//                                             orderModel.adminCommission =
//                                                 controller
//                                                             .selectedType
//                                                             .value
//                                                             .adminCommission!
//                                                             .isEnabled ==
//                                                         false
//                                                     ? controller.selectedType
//                                                         .value.adminCommission!
//                                                     : Constant.adminCommission;
//                                             orderModel.otp =
//                                                 Constant.getReferralCode();

//                                             orderModel.duration =
//                                                 controller.duration.value;

//                                             orderModel.taxList =
//                                                 Constant.taxList;
//                                             if (controller.selectedTakingRide
//                                                     .value.fullName !=
//                                                 "Myself") {
//                                               orderModel.someOneElse =
//                                                   controller
//                                                       .selectedTakingRide.value;
//                                             }

//                                             List<ZoneModel> foundZones = [];
//                                             for (int i = 0;
//                                                 i < controller.zoneList.length;
//                                                 i++) {
//                                               if (Constant.isPointInPolygon(
//                                                   LatLng(
//                                                       double.parse(controller
//                                                           .sourceLocationLAtLng
//                                                           .value
//                                                           .latitude
//                                                           .toString()),
//                                                       double.parse(controller
//                                                           .sourceLocationLAtLng
//                                                           .value
//                                                           .longitude
//                                                           .toString())),
//                                                   controller
//                                                       .zoneList[i].area!)) {
//                                                 log("---- zone found in index: ${i}");
//                                                 log("---- zone found in : ${controller.zoneList[i].id}");
//                                                 foundZones.add(
//                                                     controller.zoneList[i]);
//                                               }
//                                             }
//                                             if (foundZones.isNotEmpty) {
//                                               controller.selectedZone.value =
//                                                   controller.zoneList[0];
//                                               orderModel.zoneId = controller
//                                                   .selectedZone.value.id;
//                                               orderModel.zoneIds = foundZones
//                                                   .map((e) => e.id)
//                                                   .toList();
//                                               orderModel.zone =
//                                                   controller.selectedZone.value;
//                                               orderModel.zones = foundZones;
//                                               orderModel.duration =
//                                                   controller.duration.value;
//                                               FireStoreUtils()
//                                                   .sendOrderData(orderModel)
//                                                   .listen((event) {
//                                                 event.forEach((element) async {
//                                                   log("FCM TOKEN LIST ${element.fcmToken}");
//                                                   if (element.fcmToken !=
//                                                       null) {
//                                                     log("FCM TOKEN LIST ${element.fcmToken}");
//                                                     log("FCM TOKEN LIST ${element.fullName}");
//                                                     Map<String, dynamic>
//                                                         playLoad =
//                                                         <String, dynamic>{
//                                                       "type": "city_order",
//                                                       "orderId": orderModel.id
//                                                     };
//                                                     await SendNotification
//                                                         .sendOneNotification(
//                                                             token:
//                                                                 element
//                                                                     .fcmToken
//                                                                     .toString(),
//                                                             title:
//                                                                 'New Ride Available'
//                                                                     .tr,
//                                                             body:
//                                                                 'A customer has placed an ride near your location.'
//                                                                     .tr,
//                                                             payload: playLoad);
//                                                   }
//                                                 });
//                                                 FireStoreUtils().closeStream();
//                                               });
//                                               log("----- order zone ids: ${orderModel.toJson()["zoneIds"]}");
//                                               log("----- order zones: ${orderModel.toJson()["zones"]}");
//                                               await FireStoreUtils.setOrder(
//                                                       orderModel)
//                                                   .then((value) {
//                                                 ShowToastDialog.showToast(
//                                                     "Ride Placed successfully"
//                                                         .tr);
//                                                 log("Navigate");
//                                                 controller.dashboardController
//                                                     .selectedDrawerIndex(2);
//                                                 ShowToastDialog.closeLoader();
//                                               });
//                                             } else {
//                                               ShowToastDialog.showToast(
//                                                   "Services are currently unavailable on the selected location. Please reach out to the administrator for assistance."
//                                                       .tr,
//                                                   position:
//                                                       EasyLoadingToastPosition
//                                                           .center);
//                                             }
//                                           }
//                                         }
//                                       },
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//           );
//         });
//   }

//   _buildSuggestedPrice(BuildContext context, HomeController controller) {
//     return Obx(
//       () => controller.sourceLocationLAtLng.value.latitude != null &&
//               controller.destinationLocationLAtLng.value.latitude != null &&
//               controller.amount.value.isNotEmpty
//           ? Column(
//               children: [
//                 const SizedBox(
//                   height: 10,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
//                   ),
//                   child: Container(
//                     width: Responsive.width(100, context),
//                     decoration: const BoxDecoration(
//                       color: AppColors.gray,
//                       borderRadius: BorderRadius.all(Radius.circular(10)),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 10,
//                       ),
//                       child: Center(
//                         child: controller.selectedType.value.offerRate == true
//                             ? RichText(
//                                 text: TextSpan(
//                                   text:
//                                       '${"Approx time".tr} ${controller.duration.value}. ${"Approx distance".tr} ${double.parse(controller.distance.value).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.distanceType}'
//                                           .tr,
//                                   style:
//                                       GoogleFonts.poppins(color: Colors.black),
//                                 ),
//                               )
//                             : RichText(
//                                 //${"Your Price is".tr} ${Constant.amountShow(amount: controller.amount.value)}.
//                                 text: TextSpan(
//                                   text:
//                                       '${"Approx time".tr} ${controller.duration.value}. ${"Approx distance".tr} ${double.parse(controller.distance.value).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.distanceType}'
//                                           .tr,
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : Container(),
//     );
//   }

//   paymentMethodDialog(BuildContext context, HomeController controller) {
//     return showModalBottomSheet(
//         backgroundColor: Theme.of(context).colorScheme.background,
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(15), topLeft: Radius.circular(15))),
//         context: context,
//         isScrollControlled: true,
//         isDismissible: false,
//         builder: (context1) {
//           final themeChange = Provider.of<DarkThemeProvider>(context1);

//           return FractionallySizedBox(
//             heightFactor: 0.9,
//             child: StatefulBuilder(builder: (context1, setState) {
//               return Obx(
//                 () => Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10.0, vertical: 10),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Row(
//                           children: [
//                             InkWell(
//                                 onTap: () {
//                                   Get.back();
//                                 },
//                                 child: const Icon(Icons.arrow_back_ios)),
//                             Expanded(
//                                 child: Center(
//                                     child: Text(
//                               "Select Payment Method".tr,
//                             ))),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(
//                             children: [
//                               Visibility(
//                                 visible: controller
//                                         .paymentModel.value.cash!.enable ==
//                                     true,
//                                 child: Obx(
//                                   () => Column(
//                                     children: [
//                                       const SizedBox(
//                                         height: 10,
//                                       ),
//                                       InkWell(
//                                         onTap: () {
//                                           controller
//                                                   .selectedPaymentMethod.value =
//                                               controller
//                                                   .paymentModel.value.cash!.name
//                                                   .toString();
//                                         },
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             borderRadius:
//                                                 const BorderRadius.all(
//                                                     Radius.circular(10)),
//                                             border: Border.all(
//                                                 color: controller
//                                                             .selectedPaymentMethod
//                                                             .value ==
//                                                         controller.paymentModel
//                                                             .value.cash!.name
//                                                             .toString()
//                                                     ? themeChange.getThem()
//                                                         ? AppColors
//                                                             .darkModePrimary
//                                                         : AppColors.primary
//                                                     : AppColors.textFieldBorder,
//                                                 width: 1),
//                                           ),
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 horizontal: 10, vertical: 10),
//                                             child: Row(
//                                               children: [
//                                                 Container(
//                                                   height: 40,
//                                                   width: 80,
//                                                   decoration:
//                                                       const BoxDecoration(
//                                                           color: AppColors
//                                                               .lightGray,
//                                                           borderRadius:
//                                                               BorderRadius.all(
//                                                                   Radius
//                                                                       .circular(
//                                                                           5))),
//                                                   child: const Padding(
//                                                     padding:
//                                                         EdgeInsets.all(8.0),
//                                                     child: Icon(Icons.money,
//                                                         color: Colors.black),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(
//                                                   width: 10,
//                                                 ),
//                                                 Expanded(
//                                                   child: Text(
//                                                     controller
//                                                                 .paymentModel
//                                                                 .value
//                                                                 .cash!
//                                                                 .name
//                                                                 .toString() ==
//                                                             "Cash"
//                                                         ? "Cash".tr
//                                                         : "Wallet".tr,
//                                                     style:
//                                                         GoogleFonts.poppins(),
//                                                   ),
//                                                 ),
//                                                 Radio(
//                                                   value: controller.paymentModel
//                                                       .value.cash!.name
//                                                       .toString(),
//                                                   groupValue: controller
//                                                       .selectedPaymentMethod
//                                                       .value,
//                                                   activeColor:
//                                                       themeChange.getThem()
//                                                           ? AppColors
//                                                               .darkModePrimary
//                                                           : AppColors.primary,
//                                                   onChanged: (value) {
//                                                     controller
//                                                             .selectedPaymentMethod
//                                                             .value =
//                                                         controller.paymentModel
//                                                             .value.cash!.name
//                                                             .toString();
//                                                   },
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Visibility(
//                                 visible: controller
//                                         .paymentModel.value.wallet!.enable ==
//                                     true,
//                                 child: Obx(
//                                   () => Column(
//                                     children: [
//                                       const SizedBox(
//                                         height: 10,
//                                       ),
//                                       InkWell(
//                                         onTap: () {
//                                           controller
//                                                   .selectedPaymentMethod.value =
//                                               controller.paymentModel.value
//                                                   .wallet!.name
//                                                   .toString();
//                                         },
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             borderRadius:
//                                                 const BorderRadius.all(
//                                               Radius.circular(10),
//                                             ),
//                                             border: Border.all(
//                                                 color: controller
//                                                             .selectedPaymentMethod
//                                                             .value ==
//                                                         controller.paymentModel
//                                                             .value.wallet!.name
//                                                             .toString()
//                                                     ? themeChange.getThem()
//                                                         ? AppColors
//                                                             .darkModePrimary
//                                                         : AppColors.primary
//                                                     : AppColors.textFieldBorder,
//                                                 width: 1),
//                                           ),
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 10,
//                                               vertical: 10,
//                                             ),
//                                             child: Row(
//                                               children: [
//                                                 Container(
//                                                   height: 40,
//                                                   width: 80,
//                                                   decoration:
//                                                       const BoxDecoration(
//                                                     color: AppColors.lightGray,
//                                                     borderRadius:
//                                                         BorderRadius.all(
//                                                       Radius.circular(5),
//                                                     ),
//                                                   ),
//                                                   child: Padding(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             8.0),
//                                                     child: SvgPicture.asset(
//                                                       'assets/icons/ic_wallet.svg',
//                                                       color: AppColors.primary,
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(
//                                                   width: 10,
//                                                 ),
//                                                 Expanded(
//                                                   child: Text(
//                                                     "Wallet".tr,
//                                                     style:
//                                                         GoogleFonts.poppins(),
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                     "(${Constant.amountShow(amount: controller.userModel.value.walletAmount.toString())})",
//                                                     style: GoogleFonts.poppins(
//                                                         color: themeChange
//                                                                 .getThem()
//                                                             ? AppColors
//                                                                 .darkModePrimary
//                                                             : AppColors
//                                                                 .primary)),
//                                                 Radio(
//                                                   value: controller.paymentModel
//                                                       .value.wallet!.name
//                                                       .toString(),
//                                                   groupValue: controller
//                                                       .selectedPaymentMethod
//                                                       .value,
//                                                   activeColor:
//                                                       themeChange.getThem()
//                                                           ? AppColors
//                                                               .darkModePrimary
//                                                           : AppColors.primary,
//                                                   onChanged: (value) {
//                                                     controller
//                                                             .selectedPaymentMethod
//                                                             .value =
//                                                         controller.paymentModel
//                                                             .value.wallet!.name
//                                                             .toString();
//                                                   },
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       ButtonThem.buildButton(
//                         context,
//                         title: "Choose".tr,
//                         onPress: () async {
//                           Get.back();
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           );
//         });
//   }

//   someOneTakingDialog(BuildContext context, HomeController controller) {
//     return showModalBottomSheet(
//         backgroundColor: Theme.of(context).colorScheme.background,
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(15), topLeft: Radius.circular(15))),
//         context: context,
//         isScrollControlled: true,
//         isDismissible: false,
//         builder: (context1) {
//           final themeChange = Provider.of<DarkThemeProvider>(context1);
//           return StatefulBuilder(builder: (context1, setState) {
//             return Obx(
//               () => Container(
//                 constraints:
//                     BoxConstraints(maxHeight: Responsive.height(90, context)),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10.0, vertical: 10),
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Someone else taking this ride?".tr,
//                           style: GoogleFonts.poppins(
//                               fontSize: 16, fontWeight: FontWeight.w600),
//                         ),
//                         Text(
//                           "Choose a contact and share a code to conform that ride."
//                               .tr,
//                           style: GoogleFonts.poppins(),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         InkWell(
//                           onTap: () {
//                             controller.selectedTakingRide.value = ContactModel(
//                                 fullName: "Myself".tr, contactNumber: "");
//                           },
//                           child: Container(
//                             decoration: BoxDecoration(
//                               borderRadius:
//                                   const BorderRadius.all(Radius.circular(10)),
//                               border: Border.all(
//                                   color: controller.selectedTakingRide.value
//                                               .fullName ==
//                                           "Myself".tr
//                                       ? themeChange.getThem()
//                                           ? AppColors.darkModePrimary
//                                           : AppColors.primary
//                                       : AppColors.textFieldBorder,
//                                   width: 1),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 10),
//                               child: Row(
//                                 children: [
//                                   const Padding(
//                                     padding: EdgeInsets.all(8.0),
//                                     child:
//                                         Icon(Icons.person, color: Colors.black),
//                                   ),
//                                   const SizedBox(
//                                     width: 10,
//                                   ),
//                                   Expanded(
//                                     child: Text(
//                                       "Myself".tr,
//                                       style: GoogleFonts.poppins(),
//                                     ),
//                                   ),
//                                   Radio(
//                                     value: "Myself".tr,
//                                     groupValue: controller
//                                         .selectedTakingRide.value.fullName,
//                                     activeColor: themeChange.getThem()
//                                         ? AppColors.darkModePrimary
//                                         : AppColors.primary,
//                                     onChanged: (value) {
//                                       controller.selectedTakingRide.value =
//                                           ContactModel(
//                                               fullName: "Myself".tr,
//                                               contactNumber: "");
//                                     },
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         ListView.builder(
//                           itemCount: controller.contactList.length,
//                           shrinkWrap: true,
//                           itemBuilder: (context, index) {
//                             ContactModel contactModel =
//                                 controller.contactList[index];
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 5),
//                               child: InkWell(
//                                 onTap: () {
//                                   controller.selectedTakingRide.value =
//                                       contactModel;
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: const BorderRadius.all(
//                                         Radius.circular(10)),
//                                     border: Border.all(
//                                         color: controller.selectedTakingRide
//                                                     .value.fullName ==
//                                                 contactModel.fullName
//                                             ? themeChange.getThem()
//                                                 ? AppColors.darkModePrimary
//                                                 : AppColors.primary
//                                             : AppColors.textFieldBorder,
//                                         width: 1),
//                                   ),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10, vertical: 10),
//                                     child: Row(
//                                       children: [
//                                         const Padding(
//                                           padding: EdgeInsets.all(8.0),
//                                           child: Icon(Icons.person,
//                                               color: Colors.black),
//                                         ),
//                                         const SizedBox(
//                                           width: 10,
//                                         ),
//                                         Expanded(
//                                           child: Text(
//                                             contactModel.fullName.toString(),
//                                             style: GoogleFonts.poppins(),
//                                           ),
//                                         ),
//                                         Radio(
//                                           value:
//                                               contactModel.fullName.toString(),
//                                           groupValue: controller
//                                               .selectedTakingRide
//                                               .value
//                                               .fullName,
//                                           activeColor: themeChange.getThem()
//                                               ? AppColors.darkModePrimary
//                                               : AppColors.primary,
//                                           onChanged: (value) {
//                                             controller.selectedTakingRide
//                                                 .value = contactModel;
//                                           },
//                                         )
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         InkWell(
//                           onTap: () async {
//                             try {
//                               final FlutterNativeContactPicker contactPicker =
//                                   FlutterNativeContactPicker();
//                               Contact? contact =
//                                   await contactPicker.selectContact();
//                               ContactModel contactModel = ContactModel();
//                               contactModel.fullName = contact!.fullName ?? "";
//                               contactModel.contactNumber =
//                                   contact.selectedPhoneNumber;

//                               if (!controller.contactList
//                                   .contains(contactModel)) {
//                                 controller.contactList.add(contactModel);
//                                 controller.setContact();
//                               }
//                             } catch (e) {
//                               rethrow;
//                             }
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 10, vertical: 10),
//                             child: Row(
//                               children: [
//                                 const Padding(
//                                   padding: EdgeInsets.all(8.0),
//                                   child:
//                                       Icon(Icons.contacts, color: Colors.black),
//                                 ),
//                                 const SizedBox(
//                                   width: 10,
//                                 ),
//                                 Expanded(
//                                   child: Text(
//                                     "Choose another contact".tr,
//                                     style: GoogleFonts.poppins(),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         ButtonThem.buildButton(
//                           context,
//                           title:
//                               "${"Book for ".tr} ${controller.selectedTakingRide.value.fullName}"
//                                   .tr,
//                           onPress: () async {
//                             Get.back();
//                           },
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           });
//         });
//   }

//   ariPortDialog(
//       BuildContext context, HomeController controller, bool isSource) {
//     return showModalBottomSheet(
//         backgroundColor: Theme.of(context).colorScheme.background,
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(15), topLeft: Radius.circular(15))),
//         context: context,
//         isScrollControlled: true,
//         isDismissible: true,
//         builder: (context1) {
//           final themeChange = Provider.of<DarkThemeProvider>(context1);

//           return StatefulBuilder(builder: (context1, setState) {
//             return Container(
//               constraints:
//                   BoxConstraints(maxHeight: Responsive.height(90, context)),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Do you want to travel for AirPort?".tr,
//                         style: GoogleFonts.poppins(
//                             fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       Text(
//                         "Choose a single AirPort".tr,
//                         style: GoogleFonts.poppins(),
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       ListView.builder(
//                         itemCount: Constant.airaPortList!.length,
//                         shrinkWrap: true,
//                         itemBuilder: (context, index) {
//                           AriPortModel airPortModel =
//                               Constant.airaPortList![index];
//                           return Obx(
//                             () => Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 5),
//                               child: InkWell(
//                                 onTap: () {
//                                   controller.selectedAirPort.value =
//                                       airPortModel;
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: const BorderRadius.all(
//                                         Radius.circular(10)),
//                                     border: Border.all(
//                                         color: controller
//                                                     .selectedAirPort.value.id ==
//                                                 airPortModel.id
//                                             ? themeChange.getThem()
//                                                 ? AppColors.darkModePrimary
//                                                 : AppColors.primary
//                                             : AppColors.textFieldBorder,
//                                         width: 1),
//                                   ),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10, vertical: 10),
//                                     child: Row(
//                                       children: [
//                                         const Padding(
//                                           padding: EdgeInsets.all(8.0),
//                                           child: Icon(Icons.airplanemode_active,
//                                               color: Colors.black),
//                                         ),
//                                         const SizedBox(
//                                           width: 10,
//                                         ),
//                                         Expanded(
//                                           child: Text(
//                                             airPortModel.airportName.toString(),
//                                             style: GoogleFonts.poppins(),
//                                           ),
//                                         ),
//                                         Radio(
//                                           value: airPortModel.id.toString(),
//                                           groupValue: controller
//                                               .selectedAirPort.value.id,
//                                           activeColor: themeChange.getThem()
//                                               ? AppColors.darkModePrimary
//                                               : AppColors.primary,
//                                           onChanged: (value) {
//                                             controller.selectedAirPort.value =
//                                                 airPortModel;
//                                           },
//                                         )
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                       ButtonThem.buildButton(
//                         context,
//                         title: "Book".tr,
//                         onPress: () async {
//                           if (controller.selectedAirPort.value.id != null) {
//                             if (isSource) {
//                               controller.sourceLocationController.value.text =
//                                   controller.selectedAirPort.value.airportName
//                                       .toString();
//                               controller.sourceLocationLAtLng.value =
//                                   LocationLatLng(
//                                       latitude: double.parse(controller
//                                           .selectedAirPort.value.airportLat
//                                           .toString()),
//                                       longitude: double.parse(controller
//                                           .selectedAirPort.value.airportLng
//                                           .toString()));
//                               controller.calculateAmount();
//                             } else {
//                               controller.destinationLocationController.value
//                                       .text =
//                                   controller.selectedAirPort.value.airportName
//                                       .toString();
//                               controller.destinationLocationLAtLng.value =
//                                   LocationLatLng(
//                                       latitude: double.parse(controller
//                                           .selectedAirPort.value.airportLat
//                                           .toString()),
//                                       longitude: double.parse(controller
//                                           .selectedAirPort.value.airportLng
//                                           .toString()));
//                               controller.calculateAmount();
//                             }
//                             Get.back();
//                           } else {
//                             ShowToastDialog.showToast(
//                               "Please select one airport".tr,
//                             );
//                           }
//                         },
//                       ),
//                       const SizedBox(
//                         height: 10,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           });
//         });
//   }

//   showAlertDialog(BuildContext context) {
//     // set up the button
//     Widget okButton = TextButton(
//       child: Text("OK".tr),
//       onPressed: () {
//         Get.back();
//       },
//     );

//     // set up the AlertDialog
//     AlertDialog alert = AlertDialog(
//       title: Text("Warning".tr),
//       content: Text(
//         "You are not able book new ride please complete previous ride payment"
//             .tr,
//       ),
//       actions: [
//         okButton,
//       ],
//     );
//     // show the dialog
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return alert;
//       },
//     );
//   }

//   Widget _buildBanner(BuildContext context, HomeController controller) {
//     return Visibility(
//       visible: controller.bannerList.isNotEmpty,
//       child: Container(
//           height: MediaQuery.of(context).size.height * 0.25,
//           color: Colors.black,
//           child: PageView.builder(
//               padEnds: true,
//               allowImplicitScrolling: true,
//               itemCount: controller.bannerList.length,
//               scrollDirection: Axis.horizontal,
//               controller: controller.pageController,
//               itemBuilder: (context, index) {
//                 BannerModel bannerModel = controller.bannerList[index];
//                 return Padding(
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
//                   child: CachedNetworkImage(
//                     imageUrl: bannerModel.image.toString(),
//                     imageBuilder: (context, imageProvider) => Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         image: DecorationImage(
//                             image: imageProvider, fit: BoxFit.cover),
//                       ),
//                     ),
//                     color: Colors.black.withOpacity(0.5),
//                     placeholder: (context, url) =>
//                         const Center(child: CircularProgressIndicator()),
//                     fit: BoxFit.cover,
//                   ),
//                 );
//               })),
//     );
//   }

//   void showTooltip(BuildContext context, String message) {
//     final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);

//     if (tooltip?.isOpen ?? false) return;

//     tooltip = SuperTooltip(
//       popupDirection: TooltipDirection.up,
//       arrowTipDistance: 8.0,
//       arrowBaseWidth: 20.0,
//       arrowLength: 10.0,
//       borderRadius: 12.0,
//       hasShadow: true,
//       touchThroughAreaShape: ClipAreaShape.rectangle,
//       content: Text(
//         message,
//         style: TextStyle(
//             color: themeChange.getThem() ? Colors.black : Colors.white,
//             fontSize: 13),
//         textAlign: TextAlign.right,
//       ),
//       backgroundColor:
//           themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
//     );

//     tooltip!.show(context);
//   }
// }
