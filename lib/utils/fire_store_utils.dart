import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/faq_model.dart';
import 'package:customer/model/freight_vehicle.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/language_title.dart';
import 'package:customer/model/language_privacy_policy.dart';
import 'package:customer/model/language_terms_condition.dart';
import 'package:customer/model/on_boarding_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/referral_model.dart';
import 'package:customer/model/review_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../model/cancellation_reason_model.dart';
import '../model/driver_document_model.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  // API key for Firestore security rules
  static const String _apiKey =
      "mysecretapikeyisthisonethatshouldbetooscrectandhardtobedetected";

  // Utility method to add API key to any data map
  static Map<String, dynamic> _addApiKey(Map<String, dynamic> data) {
    return {...data, '_apiKey': _apiKey};
  }

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static Query getReviewsQuery(String driverId) {
    return fireStore
        .collection(CollectionName.reviewDriver)
        .where("driverId", isEqualTo: driverId)
        .orderBy('date', descending: true);
  }

  static Future<bool> currentDriverRideCheck(String driverId) async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: driverId)
        .where("status",
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .get()
        .then((value) {
          ShowToastDialog.closeLoader();
          print(value.size);
          if (value.size >= 1) {
            isFirst = true;
          } else {
            isFirst = false;
          }
        });
    return isFirst;
  }

  static Future<bool> currentDriverIntercityRideCheck(String driverId) async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('driverId', isEqualTo: driverId)
        .where("status",
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .get()
        .then((value) {
          ShowToastDialog.closeLoader();
          print(value.size);
          if (value.size >= 1) {
            isFirst = true;
          } else {
            isFirst = false;
          }
        });
    return isFirst;
  }

  static Future<bool> hasChargeWalletPending() async {
    try {
      final currentUid = getCurrentUid();
      if (currentUid.isEmpty || currentUid == "Guest") {
        return false; // ✅ Guest users don't have wallet charges
      }

      final querySnapshot = await fireStore
          .collection(CollectionName.chargeWallet)
          .where('userID', isEqualTo: currentUid)
          .where('state', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log('Error checking pending wallet charge: $e');
      return false;
    }
  }

  static Future<bool> viewWallet() async {
    bool wallet = false;
    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get();
      wallet = querySnapshot["wallet"];
      return wallet;
    } catch (e) {
      log('Error checking pending wallet charge: $e');
      return wallet;
    }
  }

  static Future<void> setChargeTransaction(File image, double amount) async {
    String imageURL = "";
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      imageURL = await Constant.uploadUserImageToFireStorage(
        image,
        "chargeWallet",
        image.path.split('/').last,
      );
      await fireStore
          .collection(CollectionName.walletTransaction)
          .add(_addApiKey({
            "state": "pending",
            "amount": amount.toString(),
            "createdDate": Timestamp.now(),
            "userId": FirebaseAuth.instance.currentUser!.uid,
            "paymentMethod": "wallet",
            "note": "Add to wallet",
            "orderType": "wallet",
            "transactionId": "",
          }))
          .then((value) async {
        await fireStore
            .collection(CollectionName.walletTransaction)
            .doc(value.id)
            .update(_addApiKey({
              "id": value.id,
            }));
        await fireStore.collection(CollectionName.chargeWallet).add(_addApiKey({
              "image": imageURL,
              "type": "Customer",
              "state": "pending",
              "amount": amount,
              "time": Timestamp.now(),
              "userID": getCurrentUid(),
              "walletTransaction": value.id
            }));
      });
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("chargeWalletUploaded".tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
    }
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver(
      {required String id}) async {
    DriverDocumentModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(id)
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> currentCheckRideCheck() async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;

    try {
      final currentUid = FireStoreUtils.getCurrentUid();
      if (currentUid.isEmpty || currentUid == "Guest") {
        ShowToastDialog.closeLoader();
        return false; // ✅ Guest users don't have active rides
      }

      await fireStore
          .collection(CollectionName.orders)
          .where('userId', isEqualTo: currentUid)
          .where("status", whereIn: [
            Constant.rideInProgress,
            Constant.rideActive,
            Constant.ridePlaced
          ])
          .get()
          .then((value) {
            ShowToastDialog.closeLoader();
            print(value.size);
            if (value.size >= 1) {
              isFirst = true;
            } else {
              isFirst = false;
            }
          });
    } catch (e) {
      ShowToastDialog.closeLoader();
      log('Error checking current ride: $e');
      return false;
    }

    return isFirst;
  }

  static Future<String> getStoreVersion() async {
    try {
      DocumentSnapshot versionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get();

      return Platform.isAndroid
          ? versionDoc['versionAndroid']
          : versionDoc['versionIOS'];
    } catch (e) {
      return "";
    }
  }

  getSettings() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("globalKey")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.mapAPIKey = value.data()!["googleMapKey"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("notification_setting")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL =
              value.data()!['serviceJson'].toString();
        }
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("globalValue")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"];
        Constant.radius = value.data()!["radius"];
        Constant.mapType = value.data()!["mapType"];
        Constant.selectedMapType = value.data()!["selectedMapType"];
        Constant.driverLocationUpdate = value.data()!["driverLocationUpdate"];
        Constant.regionCode = value.data()!["regionCode"] ?? "";
        Constant.regionCountry = value.data()!["regionCountry"] ?? "";
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("global")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data()!["privacyPolicy"] != null) {
          Constant.privacyPolicy = <LanguagePrivacyPolicy>[];
          value.data()!["privacyPolicy"].forEach((v) {
            Constant.privacyPolicy.add(LanguagePrivacyPolicy.fromJson(v));
          });
        }

        if (value.data()!["termsAndConditions"] != null) {
          Constant.termsAndConditions = <LanguageTermsCondition>[];
          value.data()!["termsAndConditions"].forEach((v) {
            Constant.termsAndConditions.add(LanguageTermsCondition.fromJson(v));
          });
        }

        Constant.appVersion = value.data()!["appVersion"];
      }
    });

    fireStore
        .collection(CollectionName.settings)
        .doc("adminCommission")
        .snapshots()
        .listen((value) {
      if (value.data() != null) {
        AdminCommission adminCommission =
            AdminCommission.fromJson(value.data()!);
        if (adminCommission.isEnabled == true) {
          Constant.adminCommission = adminCommission;
        }
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("referral")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
        Constant.phone = value.data()!["emergencyPhoneNumber"];
      }
    });
  }

  // static String getCurrentUid() {
  //   return FirebaseAuth.instance.currentUser!.uid;
  // }
  static String getCurrentUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (Constant.isGuestUser) {
        return "Guest";
      }
      // ✅ CRITICAL FIX: Don't throw exception, return empty string for better error handling
      print("Warning: User is not logged in and not a guest user");
      return "";
    }
    return user.uid;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet".tr,
                  transactionId: orderModel.id,
                  userId: referralModel!.referralBy.toString(),
                  orderType: "city",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<bool> getIntercityFirstOrderOrNOt(
      InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  Stream<List<DriverUserModel>> sendIntercityOrderData(
      InterCityOrderModel orderModel, String originalServiceId) async* {
    getNearestOrderRequestController ??=
        StreamController<List<DriverUserModel>>.broadcast();
    List<DriverUserModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: originalServiceId)
        .where('zoneIds', arrayContainsAny: orderModel.zoneIds)
        .where('isOnline', isEqualTo: true);
    GeoFirePoint center = Geoflutterfire().point(
        latitude: orderModel.sourceLocationLAtLng!.latitude ?? 0.0,
        longitude: orderModel.sourceLocationLAtLng!.longitude ?? 0.0);

    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.interCityRadius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      if (getNearestOrderRequestController != null) {
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          DriverUserModel orderModel = DriverUserModel.fromJson(data);
          ordersList.add(orderModel);
        }

        if (!getNearestOrderRequestController!.isClosed) {
          getNearestOrderRequestController!.sink.add(ordersList);
        }
        closeStream();
      }
    });
    yield* getNearestOrderRequestController!.stream;
  }

  static Future updateIntercityReferralAmount(
      InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              print(userDocument.data());
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet".tr,
                  transactionId: orderModel.id,
                  userId: orderModel.driverId.toString(),
                  orderType: "intercity",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      ShowToastDialog.showToast("Error Get: ${error.toString()}");
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<DriverUserModel?> getDriver(String uuid) async {
    DriverUserModel? driverUserModel;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        driverUserModel = DriverUserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverUserModel = null;
    });
    return driverUserModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(_addApiKey(userModel.toJson()))
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      ShowToastDialog.showToast("Error Update: ${error.toString()}");
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<String> getEmergencyPhoneNumber() async {
    String phone = "";
    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) async {
      if (value.data() != null) {
        phone = value.data()!["emergencyPhoneNumber"];
      }
      return phone;
    });
    return phone;
  }

  static Future<String> getWhatsAppNumber() async {
    String phone = "";
    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.data() != null) {
        phone = value.data()!["whatsappNumber"];
      }
      return phone;
    });
    return phone;
  }

  static Future<bool> updateDriver(DriverUserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(userModel.id)
        .set(_addApiKey(userModel.toJson()))
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool?> rejectRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("rejectedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(_addApiKey(driverIdAcceptReject.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool> checkUserInCollection(
      String uid, String collectionName) async {
    try {
      DocumentSnapshot doc =
          await fireStore.collection(collectionName).doc(uid).get();
      return doc.exists;
    } catch (e) {
      log("checkUserInCollection error: $e");
      return false;
    }
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;

    await fireStore.collection(CollectionName.users).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      },
    ).catchError((error) {
      log("Failed to update user: $error");
      isExit = false;
    });
    return isExit;
  }

  static Future<List<CancellationReasonModel>> getCancellationReasons() async {
    List<CancellationReasonModel> freightVehicle = [];
    await fireStore
        .collection(CollectionName.cancellationReasons)
        .where("enable", isEqualTo: true)
        .where("forDriver", isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        CancellationReasonModel documentModel =
            CancellationReasonModel.fromJson(element.data());
        freightVehicle.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return freightVehicle;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  // static Future<List<BannerModel>> getBanner() async {
  //   List<BannerModel> bannerList = [];
  //   await fireStore
  //       .collection(CollectionName.banner)
  //       .where('enable', isEqualTo: true)
  //       .where('isDeleted', isEqualTo: false)
  //       .orderBy('position', descending: false)
  //       .get()
  //       .then((value) {
  //     for (var element in value.docs) {
  //       BannerModel documentModel = BannerModel.fromJson(element.data());
  //       bannerList.add(documentModel);
  //     }
  //   }).catchError((error) {
  //     log(error.toString());
  //   });
  //   return bannerList;
  // }

  static Future<List<OtherBannerModel>> getBannerOrder() async {
    List<OtherBannerModel> bannerList = [];
    await fireStore
        .collection(CollectionName.ads)
        .where("from_date", isLessThanOrEqualTo: DateTime.now())
        .where("expiry_date", isGreaterThan: DateTime.now())
        .get()
        .then((value) {
      for (var element in value.docs) {
        OtherBannerModel documentModel =
            OtherBannerModel.fromJson(element.data());
        bannerList.add(documentModel);
      }
    }).catchError((error) {
      log("❌ Banner Error: ${error.toString()}");
    });
    return bannerList;
  }

  static Future<List<BannerModel>> getBanner() async {
    List<BannerModel> bannerList = [];
    String userType = 'customer';

    await fireStore
        .collection(CollectionName.banner)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .where('forWho', whereIn: ['customer', 'both'])
        .get()
        .then((value) {
          for (var element in value.docs) {
            BannerModel documentModel = BannerModel.fromJson(element.data());
            bannerList.add(documentModel);
          }

          bannerList.sort((a, b) {
            int aPos = userType == 'customer'
                ? (a.positionCustomer ?? 0)
                : (a.positionDriver ?? 0);
            int bPos = userType == 'customer'
                ? (b.positionCustomer ?? 0)
                : (b.positionDriver ?? 0);
            return aPos.compareTo(bPos);
          });

          print("✅ تم جلب وترتيب البانرات: ${bannerList.length}");
        })
        .catchError((error) {
          log("❌ Banner Error: ${error.toString()}");
        });

    return bannerList;
  }

  static Future<List<IntercityServiceModel>> getIntercityService() async {
    List<IntercityServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.intercityService)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        IntercityServiceModel documentModel =
            IntercityServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  // Method to fetch both services and intercity services combined
  static Future<List<ServiceModel>> getAllServices() async {
    List<ServiceModel> allServices = [];

    // Fetch regular services
    List<ServiceModel> regularServices = await getService();
    allServices.addAll(regularServices);

    // Fetch intercity services and convert to ServiceModel
    List<IntercityServiceModel> intercityServices = await getIntercityService();

    // Convert IntercityServiceModel to ServiceModel
    for (IntercityServiceModel intercityService in intercityServices) {
      ServiceModel convertedService = ServiceModel(
        image: intercityService.image,
        enable: intercityService.enable,
        offerRate: intercityService.offerRate,
        id: intercityService.id,
        // Convert LanguageName to LanguageTitle
        title: intercityService.name
            ?.map((languageName) => LanguageTitle(
                  title: languageName.name,
                  type: languageName.type,
                ))
            .toList(),
        // Set default values for fields not present in IntercityServiceModel
        acCharge: "0",
        nonAcCharge: "0",
        basicFare: "0",
        kmCharge: intercityService.kmCharge ?? "0",
        perMinuteCharge: "0",
        intercityType: true, // Mark as intercity type
        isAcNonAc: false,
        adminCommission: intercityService.adminCommission,
      );
      allServices.add(convertedService);
    }

    return allServices;
  }

  static Future<List<FreightVehicle>> getFreightVehicle() async {
    List<FreightVehicle> freightVehicle = [];
    await fireStore
        .collection(CollectionName.freightVehicle)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        FreightVehicle documentModel = FreightVehicle.fromJson(element.data());
        freightVehicle.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return freightVehicle;
  }

  static Future<bool> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .set(_addApiKey(orderModel.toJson()))
        .then((value) {
      log("New Order: ${orderModel.id}");
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  StreamController<List<DriverUserModel>>? getNearestOrderRequestController;

  Stream<List<DriverUserModel>> sendOrderData(OrderModel orderModel) async* {
    getNearestOrderRequestController ??=
        StreamController<List<DriverUserModel>>.broadcast();

    List<DriverUserModel> ordersList = [];

    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneIds', arrayContainsAny: orderModel.zoneIds)
        .where('isOnline', isEqualTo: true);

    GeoFirePoint center = Geoflutterfire().point(
        latitude: orderModel.sourceLocationLAtLng!.latitude ?? 0.0,
        longitude: orderModel.sourceLocationLAtLng!.longitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      if (getNearestOrderRequestController != null) {
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;

          DriverUserModel orderModel = DriverUserModel.fromJson(data);

          ordersList.add(orderModel);
        }

        if (!getNearestOrderRequestController!.isClosed) {
          getNearestOrderRequestController!.sink.add(ordersList);
        }
        closeStream();
      }
    });
    yield* getNearestOrderRequestController!.stream;
  }

  Future<List<DriverUserModel>> sendOrderDataFuture(
      OrderModel orderModel) async {
    List<DriverUserModel> ordersList = [];

    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneIds', arrayContains: orderModel.zoneId)
        .where('isOnline', isEqualTo: true);

    GeoFirePoint center = Geoflutterfire().point(
      latitude: orderModel.sourceLocationLAtLng!.latitude ?? 0.0,
      longitude: orderModel.sourceLocationLAtLng!.longitude ?? 0.0,
    );

    // Fetching documents using GeoFlutterFire's `within` function.
    List<DocumentSnapshot> documentList = await Geoflutterfire()
        .collection(collectionRef: query)
        .within(
          center: center,
          radius: double.parse(Constant.radius),
          field: 'position',
          strictMode: true,
        )
        .first; // Get the first batch of documents.

    for (var document in documentList) {
      final data = document.data() as Map<String, dynamic>;
      DriverUserModel orderModel = DriverUserModel.fromJson(data);
      ordersList.add(orderModel);
    }

    return ordersList;
  }

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController == null;
      getNearestOrderRequestController!.close();
    }
  }

  static Future<bool> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .set(_addApiKey(orderModel.toJson()))
        .then((value) {
      isAdded = true;
      log(orderModel.id.toString());
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<OrderModel?> getOrderById(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) async {
      if (value.exists) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      orderModel = null;
    });
    return orderModel;
  }

  static Future<int> getOrderCountForDriver(String driverID) async {
    int ordersCount = 0;
    int intercityOrdersCount = 0;

    final ordersSnapshot = await fireStore
        .collection(CollectionName.orders)
        .where("driverId", isEqualTo: driverID)
        .get();
    ordersCount = ordersSnapshot.docs.length;

    final intercitySnapshot = await fireStore
        .collection(CollectionName.ordersIntercity)
        .where("driverId", isEqualTo: driverID)
        .get();
    intercityOrdersCount = intercitySnapshot.docs.length;

    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(driverID)
        .update(_addApiKey({
          "totalRides": (ordersCount + intercityOrdersCount),
        }));

    return (ordersCount + intercityOrdersCount);
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore
        .collection(CollectionName.settings)
        .doc("payment")
        .get()
        .then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];

    await fireStore
        .collection(CollectionName.tax)
        .where('country', isEqualTo: Constant.country)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        TaxModel taxModel = TaxModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  Future<List<CouponModel>?> getCoupon() async {
    List<CouponModel> couponModel = [];

    await fireStore
        .collection(CollectionName.coupon)
        .where('enable', isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .where('validity', isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
      for (var element in value.docs) {
        CouponModel taxModel = CouponModel.fromJson(element.data());
        couponModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return couponModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewDriver)
        .doc(reviewModel.id)
        .set(_addApiKey(reviewModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewDriver)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        WalletTransactionModel taxModel =
            WalletTransactionModel.fromJson(element.data());
        if (element["note"] == "Charge Wallet") {
          taxModel.transactionId = element.id;
          taxModel.state = await getStatusForChargeWallet(element.id);
        }
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<String> getStatusForChargeWallet(String walletID) async {
    String status = "";
    var data = await fireStore
        .collection(CollectionName.chargeWallet)
        .where("walletTransaction", isEqualTo: walletID)
        .get();
    if (data.docs.isNotEmpty) {
      status = data.docs.first['state'];
    } else {
      status = "not found";
    }
    return status;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(_addApiKey(walletTransactionModel.toJson()))
        .then((value) {
      isAdded = true;
      log("Added To Wallet");
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updateUserWallet({required String amount}) async {
    bool isAdded = false;
    await getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<bool?> updateDriverWallet(
      {required String driverId, required String amount}) async {
    bool isAdded = false;
    log("Added To Driver $amount");
    await getDriver(driverId).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateDriver(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore
        .collection(CollectionName.languages)
        .where("enable", isEqualTo: true)
        .where("isDeleted", isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return languageList;
  }

  static Future<ReferralModel?> getReferral() async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        referralModel = ReferralModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      referralModel = null;
    });
    return referralModel;
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.size > 0) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isExit;
  }

  static Future<ReferralModel?> getReferralUserByCode(
      String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        referralModel = ReferralModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(ratingModel.id)
          .set(_addApiKey(ratingModel.toJson()));
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return null;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "customerApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore
        .collection("chat")
        .doc(inboxModel.orderId)
        .set(_addApiKey(inboxModel.toJson()))
        .then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection("chat")
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(_addApiKey(conversationModel.toJson()))
        .then((document) {
      return conversationModel;
    });
  }

  static Future<List<FaqModel>> getFaq() async {
    List<FaqModel> faqModel = [];
    await fireStore
        .collection(CollectionName.faq)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        FaqModel documentModel = FaqModel.fromJson(element.data());
        faqModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return faqModel;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.users)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool?> setSOS(SosModel sosModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.sos)
        .doc(sosModel.id)
        .set(_addApiKey(sosModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<SosModel?> getSOS(String orderId) async {
    SosModel? sosModel;
    try {
      await fireStore
          .collection(CollectionName.sos)
          .where("orderId", isEqualTo: orderId)
          .get()
          .then((value) {
        sosModel = SosModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return sosModel;
  }

  String? getArabicCountryName(String countryName) {
    Map<String, String> arabicCountries = {
      "egypt": "مصر",
      "saudi arabia": "المملكة العربية السعودية",
      "united arab emirates": "الإمارات",
      "kuwait": "الكويت",
      "qatar": "قطر",
      "oman": "عُمان",
      "bahrain": "البحرين",
      "jordan": "الأردن",
      "lebanon": "لبنان",
      "syria": "سوريا",
      "iraq": "العراق",
      "palestine": "فلسطين",
      "yemen": "اليمن",
      "libya": "ليبيا",
      "algeria": "الجزائر",
      "morocco": "المغرب",
      "tunisia": "تونس",
      "sudan": "السودان",
      "mauritania": "موريتانيا",
      "comoros": "جزر القمر",
      "djibouti": "جيبوتي",
      "somalia": "الصومال"
    };

    String removeDiacritics(String input) {
      // Regex to match Arabic diacritics
      final diacriticsRegExp = RegExp(r'[\u064B-\u0652]');
      return input.replaceAll(diacriticsRegExp, '');
    }

    String normalized = countryName.trim().toLowerCase();

    // Remove diacritics from Arabic values for comparison
    bool containsArabicValue(String input) {
      return arabicCountries.values
          .any((value) => removeDiacritics(value) == removeDiacritics(input));
    }

    if (containsArabicValue(countryName)) {
      // Return the original input (with or without diacritics)
      return removeDiacritics(countryName.trim());
    }

    if (arabicCountries.containsKey(normalized)) {
      return arabicCountries[normalized];
    }

    // إذا غير موجود
    return removeDiacritics(countryName);
  }

  Future<List<AriPortModel>?> getAirports() async {
    List<AriPortModel> airPortList = [];
    // ShowToastDialog.showToast( "${Constant.country}  =============  ${getArabicCountryName(Constant.country.toString())}",
    //   duration: const Duration(seconds: 6),
    // );
    //
    var country = getArabicCountryName(Constant.country.toString());
    await fireStore
        .collection(CollectionName.airPorts)
        //.where('country', isEqualTo: "السعودية")
        .get()
        .then((value) {
      for (var element in value.docs) {
        AriPortModel ariPortModel = AriPortModel.fromJson(element.data());
        var countryFromDB =
            getArabicCountryName(element['country'].toString()).toString();
        if (countryFromDB.contains(country.toString())) {
          airPortList.add(ariPortModel);
        }
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  static Future<bool> paymentStatusCheck() async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.rideComplete)
        .where("paymentStatus", isEqualTo: false)
        .get()
        .then((value) {
      ShowToastDialog.closeLoader();
      if (value.size >= 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool> currentCheckInterCityRideCheck() async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", whereIn: [
          Constant.rideInProgress,
          Constant.rideActive,
          Constant.ridePlaced
        ])
        .get()
        .then((value) {
          ShowToastDialog.closeLoader();
          print(value.size);
          if (value.size >= 1) {
            isFirst = true;
          } else {
            isFirst = false;
          }
        });
    return isFirst;
  }

  static Future<bool> paymentStatusCheckIntercity() async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.rideComplete)
        .where("paymentStatus", isEqualTo: false)
        .get()
        .then((value) {
      ShowToastDialog.closeLoader();
      print(value.size);
      if (value.size >= 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  /// Get accepted driver IDs for an intercity order
  static Future<List<dynamic>?> getAcceptedIntercityDriverIds(
      String orderId) async {
    try {
      DocumentSnapshot orderSnapshot = await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderId)
          .get();

      if (orderSnapshot.exists) {
        Map<String, dynamic> orderData =
            orderSnapshot.data() as Map<String, dynamic>;
        return orderData['acceptedDriverId'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      log('Error getting accepted intercity driver IDs: $e');
      return [];
    }
  }

  /// Get driver offer details for an intercity order
  static Future<DriverIdAcceptReject?> getIntercityDriverOffer(
      String orderId, String driverId) async {
    try {
      QuerySnapshot offerSnapshot = await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderId)
          .collection('acceptedDrivers')
          .where('driverId', isEqualTo: driverId)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        return DriverIdAcceptReject.fromJson(
            offerSnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      log('Error getting intercity driver offer: $e');
      return null;
    }
  }

  /// Update intercity order with new data
  static Future<void> updateIntercityOrder(
      String orderId, Map<String, dynamic> data) async {
    try {
      await fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderId)
          .update(data);
    } catch (e) {
      log('Error updating intercity order: $e');
      throw e;
    }
  }
}
