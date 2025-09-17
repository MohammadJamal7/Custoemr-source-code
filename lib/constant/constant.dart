// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/ChatVideoContainer.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/language_description.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/language_name.dart';
import 'package:customer/model/language_privacy_policy.dart';
import 'package:customer/model/language_terms_condition.dart';
import 'package:customer/model/language_title.dart';
import 'package:customer/model/map_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Constant {
  static const String phoneLoginType = "phone";
  static const String googleLoginType = "google";
  static const String appleLoginType = "apple";
  static String mapAPIKey = "AIzaSyB6M2CwWg_-UV-OgNawX_0Vl5U21VH23GU";
  static String senderId = '328097407117';
  static String jsonNotificationFileURL =
      'https://firebasestorage.googleapis.com/v0/b/wdni-518ff.firebasestorage.app/o/wdni-518ff-firebase-adminsdk-f6229-ab36f0c229.json?alt=media&token=8e49b58e-152d-432a-a255-44ee4603ec9e';
  static String radius = "10";
  static String interCityRadius = "50";
  static String distanceType = "";

  // Function to get localized distance unit
  static String getLocalizedDistanceUnit() {
    if (getLanguage().code == "ar") {
      return "كم";
    } else if (getLanguage().code == "fr") {
      return "km";
    } else {
      return distanceType.isEmpty ? "km" : distanceType;
    }
  }

  // Function to get localized time unit
  static String getLocalizedTimeUnit() {
    if (getLanguage().code == "ar") {
      return "دقيقة";
    } else if (getLanguage().code == "fr") {
      return "min";
    } else {
      return "mins";
    }
  }

  // Function to extract time and return with localized unit
  static String getLocalizedTime(String durationText) {
    try {
      log('🕐 Parsing duration: "$durationText"');

      // Handle empty or null input
      if (durationText.isEmpty) {
        return '0 ${getLocalizedTimeUnit()}';
      }

      int totalMinutes = 0;

      // Extract hours (look for patterns like "1 hour", "2 hours", "1h", "2 hrs")
      RegExp hoursRegex =
          RegExp(r'(\d+)\s*(hour|hours|hr|hrs|h)\b', caseSensitive: false);
      Match? hoursMatch = hoursRegex.firstMatch(durationText);
      if (hoursMatch != null) {
        int hours = int.parse(hoursMatch.group(1)!);
        totalMinutes += hours * 60;
        log('🕐 Found hours: $hours');
      }

      // Extract minutes (look for patterns like "30 min", "45 mins", "30m", "5 minutes")
      RegExp minutesRegex = RegExp(r'(\d+)\s*(min|mins|minute|minutes|m)\b',
          caseSensitive: false);
      Match? minutesMatch = minutesRegex.firstMatch(durationText);
      if (minutesMatch != null) {
        int minutes = int.parse(minutesMatch.group(1)!);
        totalMinutes += minutes;
        log('🕐 Found minutes: $minutes');
      }

      // If no hours or minutes found, try to extract just a number (assume it's minutes)
      if (totalMinutes == 0) {
        RegExp numberRegex = RegExp(r'(\d+)');
        Match? numberMatch = numberRegex.firstMatch(durationText);
        if (numberMatch != null) {
          totalMinutes = int.parse(numberMatch.group(1)!);
          log('🕐 Found raw number as minutes: $totalMinutes');
        }
      }

      log('🕐 Total minutes calculated: $totalMinutes');

      // Format the result based on language
      if (getLanguage().code == "ar") {
        if (totalMinutes >= 60) {
          int hours = totalMinutes ~/ 60;
          int remainingMinutes = totalMinutes % 60;
          if (remainingMinutes > 0) {
            return '$hours ساعة $remainingMinutes دقيقة';
          } else {
            return '$hours ساعة';
          }
        } else {
          return '$totalMinutes دقيقة';
        }
      } else if (getLanguage().code == "fr") {
        if (totalMinutes >= 60) {
          int hours = totalMinutes ~/ 60;
          int remainingMinutes = totalMinutes % 60;
          if (remainingMinutes > 0) {
            return '${hours}h ${remainingMinutes}min';
          } else {
            return '${hours}h';
          }
        } else {
          return '${totalMinutes}min';
        }
      } else {
        // English
        if (totalMinutes >= 60) {
          int hours = totalMinutes ~/ 60;
          int remainingMinutes = totalMinutes % 60;
          if (remainingMinutes > 0) {
            return '$hours hr $remainingMinutes min';
          } else {
            return '$hours hr';
          }
        } else {
          return '$totalMinutes min';
        }
      }
    } catch (e) {
      log('❌ Error parsing duration "$durationText": $e');
      return durationText; // Return original if parsing fails
    }
  }

  static CurrencyModel? currencyModel;
  static AdminCommission? adminCommission;
  static String? referralAmount = "0";
  static String? cityLocation;
  static String? supportURL = "";
  static String? phone = "";
  static const commissionSubscriptionID = "J0RwvxCWhZzQQD7Kc2Ll";
  static const selectIntercityItem = "0";

  static List<LanguageTermsCondition> termsAndConditions = [];
  static List<LanguagePrivacyPolicy> privacyPolicy = [];
  static String appVersion = "";

  static String mapType = "google";
  static String selectedMapType = 'osm';
  static String driverLocationUpdate = "10";
  static String regionCode = "";
  static String regionCountry = "";
  static int totalHoldingCharges = 0;

  static const String ridePlaced = "Ride Placed";
  static const String rideActive = "Ride Active";
  static const String rideInProgress = "Ride InProgress";
  static const String rideComplete = "Ride Completed";
  static const String rideCanceled = "Ride Canceled";
  static const String rideHold = "Ride Hold";
  static const String rideHoldAccepted = "Ride Hold Accepted";

  static const globalUrl = "https://wdni.net/admin/";
  static const userPlaceHolder =
      "https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115";

  static Position? currentLocation;
  static String? country;
  static String? city;
  static List<TaxModel>? taxList;
  static List<AriPortModel>? airaPortList;
  static bool isGuestUser = false;

  static Widget loader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.darkModePrimary),
    );
  }

  static String localizationName(List<LanguageName>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .name!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .name!;
    } else {
      return name.firstWhere((element) => element.type == "en").name.toString();
    }
  }

  static String localizationDescription(List<LanguageDescription>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .description!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .description!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .description
          .toString();
    }
  }

  static String localeVehicleType(List<LanguageName>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .name!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .name!;
    } else {
      return name.firstWhere((element) => element.type == "en").name.toString();
    }
  }

  static String localizationTitle(List<LanguageTitle>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .title!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .title!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .title
          .toString();
    }
  }

  static String localizationPrivacyPolicy(List<LanguagePrivacyPolicy>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .privacyPolicy!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .privacyPolicy!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .privacyPolicy
          .toString();
    }
  }

  static String localizationTermsCondition(List<LanguageTermsCondition>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .termsAndConditions!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .termsAndConditions!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .termsAndConditions
          .toString();
    }
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  static bool? validateEmail(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value ?? '')) {
      return false;
    } else {
      return true;
    }
  }

  static bool isPointInPolygon(LatLng point, List<GeoPoint> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      int next = (i + 1) % polygon.length;
      if (polygon[i].latitude <= point.latitude &&
              polygon[next].latitude > point.latitude ||
          polygon[i].latitude > point.latitude &&
              polygon[next].latitude <= point.latitude) {
        double edgeLong = polygon[next].longitude - polygon[i].longitude;
        double edgeLat = polygon[next].latitude - polygon[i].latitude;
        double interpol = (point.latitude - polygon[i].latitude) / edgeLat;
        if (point.longitude < polygon[i].longitude + interpol * edgeLong) {
          crossings++;
        }
      }
    }
    print("=====isPointInPolygon=${(crossings % 2 != 0)}");
    return (crossings % 2 != 0);
  }

  static Future<MapModel?> getDurationDistance(
      LatLng departureLatLong, LatLng destinationLatLong) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';

      // Get current time for departure_time (important for traffic-aware estimates)
      int currentTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build comprehensive API request with all necessary parameters
      String requestUrl = '$url?'
          'units=metric&'
          'origins=${departureLatLong.latitude},${departureLatLong.longitude}&'
          'destinations=${destinationLatLong.latitude},${destinationLatLong.longitude}&'
          'mode=driving&'
          'traffic_model=best_guess&'
          'departure_time=$currentTimeSeconds&'
          'avoid=tolls&'
          'key=${Constant.mapAPIKey}';

      log('🚗 Distance Matrix API Request: $requestUrl');

      http.Response restaurantToCustomerTime =
          await http.get(Uri.parse(requestUrl));

      log('🚗 Distance Matrix API Response: ${restaurantToCustomerTime.body}');

      if (restaurantToCustomerTime.statusCode != 200) {
        log('❌ API Error: Status Code ${restaurantToCustomerTime.statusCode}');
        ShowToastDialog.showToast('Network error occurred');
        return null;
      }

      MapModel mapModel =
          MapModel.fromJson(jsonDecode(restaurantToCustomerTime.body));

      if (mapModel.status == 'OK' &&
          mapModel.rows != null &&
          mapModel.rows!.isNotEmpty &&
          mapModel.rows!.first.elements != null &&
          mapModel.rows!.first.elements!.isNotEmpty &&
          mapModel.rows!.first.elements!.first.status == "OK") {
        // Additional validation for duration and distance
        final element = mapModel.rows!.first.elements!.first;
        if (element.duration?.value != null &&
            element.distance?.value != null) {
          log('✅ Valid response - Duration: ${element.duration!.text}, Distance: ${element.distance!.text}');
          return mapModel;
        } else {
          log('❌ Invalid response - Missing duration or distance data');
          ShowToastDialog.showToast('Unable to calculate route');
          return null;
        }
      } else {
        String errorMsg = mapModel.errorMessage ?? 'Route calculation failed';
        log('❌ API Response Error: $errorMsg');
        ShowToastDialog.showToast(errorMsg);
        return null;
      }
    } catch (e) {
      log('❌ Exception in getDurationDistance: $e');
      ShowToastDialog.showToast('Error calculating route');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getDurationOsmDistance(
      LatLng departureLatLong, LatLng destinationLatLong) async {
    String url = 'http://router.project-osrm.org/route/v1/driving';
    String coordinates =
        '${departureLatLong.longitude},${departureLatLong.latitude};${destinationLatLong.longitude},${destinationLatLong.latitude}';

    http.Response response = await http
        .get(Uri.parse('$url/$coordinates?overview=false&steps=false'));

    log(response.body.toString());

    return jsonDecode(response.body);
  }

  static double amountCalculate(String amount, String distance) {
    double finalAmount = 0.0;
    log("------->");
    log(amount);
    log(distance);
    finalAmount = double.parse(amount) * double.parse(distance);
    return finalAmount;
  }

  static String getUuid() {
    return const Uuid().v4();
  }

  String formatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd-MM-yyyy hh:mm aa'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  static String dateAndTimeFormatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd MMM yyyy hh:mm aa'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  static String dateFormatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd MMM yyyy'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  double calculateTax({String? amount, TaxModel? taxModel}) {
    double taxAmount = 0.0;
    if (taxModel != null && taxModel.enable == true) {
      if (taxModel.type == "fix") {
        taxAmount = double.parse(taxModel.tax.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(taxModel.tax!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static double getAmountShow({required String? amount}) {
    amount = (amount == null || amount.isEmpty) ? "0.0" : amount;
    double parseAmount;
    try {
      parseAmount = double.parse(amount);
    } catch (e) {
      parseAmount = 0.0;
    }
    return parseAmount;
  }

  static String amountShow({required String? amount}) {
    amount = (amount == null || amount.isEmpty) ? "0.0" : amount;
    double parseAmount;
    try {
      parseAmount = double.parse(amount);
    } catch (e) {
      parseAmount = 0.0;
    }
    final int decimalDigits = Constant.currencyModel!.decimalDigits ?? 0;

    // Choose currency label based on app language
    // - Arabic: use localized symbol (e.g., "ريال")
    // - Non-Arabic: use currency code (e.g., "SAR") to avoid Arabic label in English/French
    final String? langCode = getLanguage().code;
    final String label = (langCode == 'ar')
        ? (Constant.currencyModel!.symbol?.toString() ?? '')
        : (Constant.currencyModel!.code?.toString() ?? Constant.currencyModel!.symbol?.toString() ?? '');

    if (Constant.currencyModel!.symbolAtRight == true) {
      return "${parseAmount.toStringAsFixed(decimalDigits)} $label";
    } else {
      return "$label ${parseAmount.toStringAsFixed(decimalDigits)}";
    }
  }

  static double calculateOrderAdminCommission(
      {String? amount, AdminCommission? adminCommission}) {
    double taxAmount = 0.0;
    if (adminCommission != null) {
      if (adminCommission.type == "fix") {
        taxAmount = double.parse(adminCommission.amount.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(adminCommission.amount!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static String calculateReview(
      {required String? reviewCount, required String? reviewSum}) {
    if (reviewCount == "0.0" && reviewSum == "0.0") {
      return "0.0";
    }
    return (double.parse(reviewSum.toString()) /
            double.parse(reviewCount.toString()))
        .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
  }

  static bool IsNegative(double number) {
    return number < 0;
  }

  static LanguageModel getLanguage() {
    final String user = Preferences.getString(Preferences.languageCodeKey);
    Map<String, dynamic> userMap = jsonDecode(user);
    return LanguageModel.fromJson(userMap);
  }

  static String getReferralCode() {
    var rng = math.Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  bool hasValidUrl(String value) {
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    return true;
  }

  static Future<String> uploadUserImageToFireStorage(
      File image, String filePath, String fileName) async {
    Reference upload =
        FirebaseStorage.instance.ref().child('$filePath/$fileName');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...'.tr);
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('/chat/images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
        mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  Future<ChatVideoContainer?> uploadChatVideoToFireStorage(File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef =
          FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      final Uint8List? thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        throw Exception("Failed to generate thumbnail.");
      }

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef =
          FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(
          videoUrl: Url(
              url: videoUrl.toString(),
              mime: metaData.contentType ?? 'video',
              videoThumbnail: thumbnailUrl),
          thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('/thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
}
