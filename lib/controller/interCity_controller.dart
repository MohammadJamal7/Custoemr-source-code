import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/freight_vehicle.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../model/service_model.dart';
import '../model/user_model.dart';

class InterCityController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());
  
  // Timer state for offer accept button
  final ValueNotifier<Map<String, int>> offerTimers = ValueNotifier<Map<String, int>>({});
  
  // Start or get a timer for a specific driver
  int getOfferRemainingTime(String driverId) {
    if (!offerTimers.value.containsKey(driverId)) {
      offerTimers.value[driverId] = 10; // Start with 10 seconds
    }
    return offerTimers.value[driverId] ?? 10;
  }
  
  // Update timer for a specific driver
  void updateOfferTimer(String driverId, int newValue) {
    final updatedTimers = Map<String, int>.from(offerTimers.value);
    updatedTimers[driverId] = newValue;
    offerTimers.value = updatedTimers;
  }
  
  // Remove timer for a specific driver
  void removeOfferTimer(String driverId) {
    final updatedTimers = Map<String, int>.from(offerTimers.value);
    updatedTimers.remove(driverId);
    offerTimers.value = updatedTimers;
  }

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;

  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  Rx<TextEditingController> parcelWeight = TextEditingController().obs;
  Rx<TextEditingController> parcelDimension = TextEditingController().obs;

  Rx<TextEditingController> noOfPassengers = TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> commentsController = TextEditingController().obs;

  RxList<IntercityServiceModel> intercityService =
      <IntercityServiceModel>[].obs;
  RxList<FreightVehicle> frightVehicleList = <FreightVehicle>[].obs;
  Rx<IntercityServiceModel> selectedInterCityType = IntercityServiceModel().obs;
  Rx<FreightVehicle> selectedFreightVehicle = FreightVehicle().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<ScrollController> scrollController = ScrollController().obs;
  RxList zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;

  Rx<bool> loaderNeeded = false.obs;

  DateTime? dateAndTime;

  RxList<XFile> images = <XFile>[].obs;

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  @override
  void onInit() {
    // TODO: implement onInit
    getPaymentData();
    getUser();
    getIntercityService();
    super.onInit();
  }

  @override
  void onClose() {
    // ✅ Clear all data when leaving InterCity screen
    clearInterCityData();
    super.onClose();
  }

  /// ✅ Clear all InterCity data when user leaves the screen
  void clearInterCityData() {
    print('🧹 Clearing InterCity data...');

    // Clear location data
    sourceLocationController.value.clear();
    destinationLocationController.value.clear();
    sourceLocationLAtLng.value = LocationLatLng();
    destinationLocationLAtLng.value = LocationLatLng();

    // Clear city data
    sourceCityController.value.clear();
    destinationCityController.value.clear();

    // Clear parcel data
    parcelWeight.value.clear();
    parcelDimension.value.clear();

    // Clear passenger data
    noOfPassengers.value.clear();
    offerYourRateController.value.clear();
    whenController.value.clear();
    commentsController.value.clear();

    // Clear selected services
    selectedInterCityType.value = IntercityServiceModel();
    selectedFreightVehicle.value = FreightVehicle();
    selectedZone.value = ZoneModel();

    // Clear images
    images.clear();

    // Reset date and time
    dateAndTime = null;

    print('✅ InterCity data cleared successfully');
  }

  void getUser() async {
    String? uid = FireStoreUtils.getCurrentUid();
    UserModel? value = await FireStoreUtils.getUserProfile(uid);
    if (value != null) {
      userModel.value = value;
    } else {
      print("⚠️ لم يتم العثور على بيانات المستخدم في Firestore.");
    }
  }

  RxBool isLoading = true.obs;

  void selectIntercityFromService(String type) {
    log("Type: $type");

    // ✅ CRITICAL FIX: Ensure originalServiceId is set for all services
    for (var service in intercityService) {
      if (service.originalServiceId == null || service.originalServiceId!.isEmpty) {
        service.originalServiceId = service.id;
        log("⚠️ Service ${service.id} missing originalServiceId - set to service ID as fallback");
      }
    }

    // First try to find by service title (for backward compatibility)
    switch (type) {
      case "Parcel":
        if (intercityService.length > 1) {
          selectedInterCityType.value = intercityService[1];
          return;
        }
        break;
      case "خدمة توصيل":
        if (intercityService.length > 1) {
          selectedInterCityType.value = intercityService[1];
          return;
        }
        break;
      case "private trip":
        if (intercityService.length > 3) {
          selectedInterCityType.value = intercityService[3];
          return;
        }
        break;
      case "رحلة خاصة":
        if (intercityService.length > 3) {
          selectedInterCityType.value = intercityService[3];
          return;
        }
        break;
      case "Shared ride":
        if (intercityService.isNotEmpty) {
          selectedInterCityType.value = intercityService[0];
          return;
        }
        break;
      case "رحلة مشتركة":
        if (intercityService.isNotEmpty) {
          selectedInterCityType.value = intercityService[0];
          return;
        }
        break;
      case "Freight":
        if (intercityService.length > 2) {
          selectedInterCityType.value = intercityService[2];
          return;
        }
        break;
      case "الشحن والنقل":
        if (intercityService.length > 2) {
          selectedInterCityType.value = intercityService[2];
          return;
        }
        break;
    }

    // If not found by title, try to find by matching the service type
    // This is more flexible and will work with any service type
    for (var service in intercityService) {
      // Check by service name
      if (service.name?.first.name == type ||
          service.name?.first.name?.contains(type) == true) {
        selectedInterCityType.value = service;
        log("✅ Service matched by name and selected: ${service.name?.first.name}");
        return;
      }

      // Check by service ID (if type is actually an ID)
      if (service.id == type) {
        selectedInterCityType.value = service;
        log("✅ Service matched by ID and selected: ${service.name?.first.name}");
        return;
      }
    }

    // If still not found, select the first available service as fallback
    if (intercityService.isNotEmpty) {
      selectedInterCityType.value = intercityService.first;
      log("⚠️ Service not found, using first available: ${intercityService.first.name?.first.name}");
    }

    // ✅ CRITICAL FIX: Ensure originalServiceId is set for selected service
    if (selectedInterCityType.value.originalServiceId == null || 
        selectedInterCityType.value.originalServiceId!.isEmpty) {
      selectedInterCityType.value.originalServiceId = selectedInterCityType.value.id;
      log("⚠️ Selected service missing originalServiceId - set to service ID as fallback");
    }

    // ✅ CRITICAL FIX: Trigger calculation after service selection
    _triggerCalculationAfterServiceSelection();
  }

  // Overloaded method to select service by ID for more precise matching
  void selectIntercityFromServiceById(String serviceId) {
    log("Service ID: $serviceId");

    // If services are not loaded yet, store the ID to set later
    if (intercityService.isEmpty) {
      log("⏳ Services not loaded yet, will set later: $serviceId");
      // We'll need to set this after services are loaded
      return;
    }

    for (var service in intercityService) {
      // ✅ CRITICAL FIX: Ensure originalServiceId is set
      if (service.originalServiceId == null || service.originalServiceId!.isEmpty) {
        service.originalServiceId = service.id;
        log("⚠️ Service ${service.id} missing originalServiceId - set to service ID as fallback");
      }
      
      if (service.id == serviceId) {
        selectedInterCityType.value = service;
        log("✅ Service matched by ID and selected: ${service.name?.first.name}");
        // ✅ CRITICAL FIX: Trigger calculation after service selection
        _triggerCalculationAfterServiceSelection();
        return;
      }
    }

    // If not found by ID, fallback to first available service
    if (intercityService.isNotEmpty) {
      selectedInterCityType.value = intercityService.first;
      // ✅ CRITICAL FIX: Ensure originalServiceId is set for selected service
      if (selectedInterCityType.value.originalServiceId == null || 
          selectedInterCityType.value.originalServiceId!.isEmpty) {
        selectedInterCityType.value.originalServiceId = selectedInterCityType.value.id;
        log("⚠️ Selected service missing originalServiceId - set to service ID as fallback");
      }
      log("⚠️ Service ID not found, using first available: ${intercityService.first.name?.first.name}");
      // ✅ CRITICAL FIX: Trigger calculation after service selection
      _triggerCalculationAfterServiceSelection();
    }
  }

  // Method to set service after services are loaded
  void setSelectedServiceAfterLoad(String serviceId) {
    log("🔄 Setting service after load: $serviceId");

    // Wait a bit for services to load, then try to set
    Future.delayed(Duration(milliseconds: 500), () {
      if (intercityService.isNotEmpty) {
        log("🔍 Looking for service ID: $serviceId");
        log("📋 Available InterCity service IDs:");
        for (var service in intercityService) {
          log("  - ${service.id} (${service.name?.first.name}) - originalServiceId: ${service.originalServiceId}");
        }

        bool serviceFound = false;
        for (var service in intercityService) {
          // ✅ CRITICAL FIX: Ensure originalServiceId is set
          if (service.originalServiceId == null || service.originalServiceId!.isEmpty) {
            service.originalServiceId = service.id;
            log("⚠️ Service ${service.id} missing originalServiceId - set to service ID as fallback");
          }
          
          // Check by service ID
          if (service.id == serviceId) {
            selectedInterCityType.value = service;
            log("✅ Service matched by ID: ${service.name?.first.name}");
            serviceFound = true;
            break;
          }

          // Check by originalServiceId (this might be the key!)
          if (service.originalServiceId == serviceId) {
            selectedInterCityType.value = service;
            log("✅ Service matched by originalServiceId: ${service.name?.first.name}");
            serviceFound = true;
            break;
          }
        }

        if (!serviceFound) {
          log("⚠️ Service not found after load: $serviceId");
          log("💡 This might be a city service with intercityType=true, not an actual InterCity service");
          
          // ✅ CRITICAL FIX: If service not found, set default and ensure originalServiceId
          if (intercityService.isNotEmpty) {
            selectedInterCityType.value = intercityService.first;
            if (selectedInterCityType.value.originalServiceId == null || 
                selectedInterCityType.value.originalServiceId!.isEmpty) {
              selectedInterCityType.value.originalServiceId = selectedInterCityType.value.id;
              log("⚠️ Selected service missing originalServiceId - set to service ID as fallback");
            }
            log("⚠️ Using default service: ${selectedInterCityType.value.name?.first.name}");
          }
        }

        // ✅ CRITICAL FIX: Trigger calculation after service is set
        _triggerCalculationAfterServiceSelection();
      } else {
        log("⏳ Services still not loaded, retrying...");
        // Retry once more
        Future.delayed(Duration(milliseconds: 1000), () {
          setSelectedServiceAfterLoad(serviceId);
        });
      }
    });
  }

  // Method to refresh services every time the page loads
  refreshServices() async {
    log("🔄 Refreshing intercity services...");
    isLoading.value = true;
    await getIntercityService();
  }

  getIntercityService() async {
    await FireStoreUtils.getIntercityService().then((value) {
      intercityService.value = value;
      if (intercityService.isNotEmpty) {
        // Only set default if no service is currently selected
        if (selectedInterCityType.value.id == null ||
            selectedInterCityType.value.id!.isEmpty) {
          selectedInterCityType.value = intercityService.first;
          log("🔄 Set default service: ${intercityService.first.name?.first.name}");
        } else {
          log("✅ Keeping existing selected service: ${selectedInterCityType.value.name?.first.name}");
        }
        
        // ✅ CRITICAL FIX: Ensure originalServiceId is set for all services
        for (int i = 0; i < intercityService.length; i++) {
          var service = intercityService[i];
          if (service.originalServiceId == null || service.originalServiceId!.isEmpty) {
            // If originalServiceId is missing, use the service's own ID as fallback
            service.originalServiceId = service.id;
            log("⚠️ Service ${service.id} missing originalServiceId - set to service ID as fallback");
          }
        }

        // Debug: Log all available services
        log("📋 Available InterCity services:");
        for (int i = 0; i < intercityService.length; i++) {
          var service = intercityService[i];
          log("  $i: ID=${service.id}, Name=${service.name?.first.name}, originalServiceId=${service.originalServiceId}");
        }
      }
    });
    await FireStoreUtils.getFreightVehicle().then((value) {
      frightVehicleList.value = value;
      // if (frightVehicleList.isNotEmpty) {
      //   selectedFreightVehicle.value = frightVehicleList.first;
      // }
    });
    isLoading.value = false;
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString selectedPaymentMethod = "".obs;

  getPaymentData() async {
    try {
      await FireStoreUtils().getZone().then((value) {
        if (value != null) {
          zoneList.value = value;
        }
      });
      await FireStoreUtils().getPayment().then((value) {
        if (value != null) {
          paymentModel.value = value;
          // Set cash as default payment method if it's enabled
          if (paymentModel.value.cash != null &&
              paymentModel.value.cash!.enable == true) {
            selectedPaymentMethod.value =
                paymentModel.value.cash!.name.toString();
            print(
                "✅ InterCity: Cash payment set as default: ${selectedPaymentMethod.value}");
          } else {
            print("⚠️ InterCity: Cash payment not available or disabled");
            // Set cash as default anyway if no payment method is selected
            if (selectedPaymentMethod.value.isEmpty) {
              selectedPaymentMethod.value = "Cash";
              print("✅ InterCity: Cash payment set as fallback default");
            }
          }
        } else {
          // If payment data is null, set cash as default
          if (selectedPaymentMethod.value.isEmpty) {
            selectedPaymentMethod.value = "Cash";
            print(
                "✅ InterCity: Cash payment set as fallback default (no payment data)");
          }
        }
      });
    } catch (e) {
      ShowToastDialog.showToast("Payment Error: ${e.toString()}");
      // Set cash as default even if there's an error
      if (selectedPaymentMethod.value.isEmpty) {
        selectedPaymentMethod.value = "Cash";
        print(
            "✅ InterCity: Cash payment set as fallback default (error occurred)");
      }
    }
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;

  calculateOsmAmount() async {
    print(
        "${sourceLocationLAtLng.value.latitude}::: duration sourceLocationLAtLng :::${sourceLocationLAtLng.value.longitude}");
    print(
        "${destinationLocationLAtLng.value.latitude}::: duration destinationLocationLAtLng :::${destinationLocationLAtLng.value.longitude}");
    if (selectedInterCityType.value.id == "Kn2VEnPI3ikF58uK8YqY") {
      if (selectedFreightVehicle.value.id == null) {
        amount.value = "0.0";
        offerYourRateController.value.text = "";
      } else {
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
              duration.value = '$hours hours $minutes minutes';

              if (Constant.distanceType == "Km") {
                distance.value =
                    (value['routes'].first['distance'] / 1000).toString();
                amount.value = Constant.amountCalculate(
                        selectedFreightVehicle.value.kmCharge.toString(),
                        distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
                offerYourRateController.value.text = "";

                // Constant.amountCalculate(
                //     selectedFreightVehicle.value.kmCharge.toString(),
                //     distance.value)
                // .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              } else {
                distance.value =
                    (value['routes'].first['distance'] / 1609.34).toString();
                amount.value = Constant.amountCalculate(
                        selectedFreightVehicle.value.kmCharge.toString(),
                        distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
                offerYourRateController.value.text = "";

                // Constant.amountCalculate(
                //         selectedFreightVehicle.value.kmCharge.toString(),
                //         distance.value)
                //     .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              }
            }
          });
        }
      }
    } else {
      amount.value = "0.0";
      offerYourRateController.value.text = "";
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
            duration.value = '$hours hours $minutes minutes';
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
              amount.value = Constant.amountCalculate(
                      selectedInterCityType.value.kmCharge.toString(),
                      distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              offerYourRateController.value.text = "";

              // Constant.amountCalculate(
              //     selectedInterCityType.value.kmCharge.toString(),
              //     distance.value)
              // .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
              amount.value = Constant.amountCalculate(
                      selectedInterCityType.value.kmCharge.toString(),
                      distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              offerYourRateController.value.text = "";

              // Constant.amountCalculate(
              //     selectedInterCityType.value.kmCharge.toString(),
              //     distance.value)
              // .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            }
          }
        });
      }
    }
  }

  calculateAmount() async {
    if (selectedInterCityType.value.id == "Kn2VEnPI3ikF58uK8YqY") {
      if (selectedFreightVehicle.value.id == null) {
        amount.value = "0.0";
        offerYourRateController.value.text = "";
      } else {
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
              print("duration  :: 11 :: ${duration.value}");
              if (Constant.distanceType == "Km") {
                distance.value = (value
                            .rows!.first.elements!.first.distance!.value!
                            .toInt() /
                        1000)
                    .toString();
                amount.value = Constant.amountCalculate(
                        selectedFreightVehicle.value.kmCharge.toString(),
                        distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
                offerYourRateController.value.text = "";
                // Constant.amountCalculate(
                //         selectedFreightVehicle.value.kmCharge.toString(),
                //         distance.value)
                //     .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              } else {
                distance.value = (value
                            .rows!.first.elements!.first.distance!.value!
                            .toInt() /
                        1609.34)
                    .toString();
                amount.value = Constant.amountCalculate(
                        selectedFreightVehicle.value.kmCharge.toString(),
                        distance.value)
                    .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
                offerYourRateController.value.text = "";
                // Constant.amountCalculate(
                //         selectedFreightVehicle.value.kmCharge.toString(),
                //         distance.value)
                //     .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              }
            }
          });
        }
      }
    } else {
      amount.value = "0.0";
      offerYourRateController.value.text = "";
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
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1000)
                      .toString();
              amount.value = Constant.amountCalculate(
                      selectedInterCityType.value.kmCharge.toString(),
                      distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              offerYourRateController.value.text = "";
              // Constant.amountCalculate(
              //         selectedInterCityType.value.kmCharge.toString(),
              //         distance.value)
              //     .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            } else {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1609.34)
                      .toString();
              amount.value = Constant.amountCalculate(
                      selectedInterCityType.value.kmCharge.toString(),
                      distance.value)
                  .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
              offerYourRateController.value.text = "";
              // Constant.amountCalculate(
              //         selectedInterCityType.value.kmCharge.toString(),
              //         distance.value)
              //     .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
            }
          }
        });
      }
    }
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself".tr, contactNumber: "").obs;

  setContact() {
    print(jsonEncode(contactList));
    Preferences.setString(
        Preferences.contactList,
        json.encode(contactList
            .map<Map<String, dynamic>>((music) => music.toJson())
            .toList()));
    getContact();
  }

  getContact() {
    String contactListJson = Preferences.getString(Preferences.contactList);

    if (contactListJson.isNotEmpty) {
      print("---->");
      contactList.clear();
      contactList.value = (json.decode(contactListJson) as List<dynamic>)
          .map<ContactModel>((item) => ContactModel.fromJson(item))
          .toList();
    }
  }

  /// ✅ CRITICAL FIX: Trigger calculation after service selection from home page
  void _triggerCalculationAfterServiceSelection() {
    // Only trigger calculation if we have both pickup and drop-off locations
    if (sourceLocationLAtLng.value.latitude != null &&
        sourceLocationLAtLng.value.longitude != null &&
        destinationLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.longitude != null) {
      log("🔄 Triggering calculation after service selection");
      log("📍 Source: ${sourceLocationLAtLng.value.latitude}, ${sourceLocationLAtLng.value.longitude}");
      log("📍 Destination: ${destinationLocationLAtLng.value.latitude}, ${destinationLocationLAtLng.value.longitude}");
      log("🚗 Selected Service: ${selectedInterCityType.value.name?.first.name}");

      // Use a small delay to ensure the UI is ready
      Future.delayed(Duration(milliseconds: 300), () {
        if (Constant.selectedMapType == 'google') {
          calculateAmount();
        } else {
          calculateOsmAmount();
        }
      });
    } else {
    
    }
  }
}
