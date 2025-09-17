import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/chat_screen/inbox_screen.dart';
import 'package:customer/ui/contact_us/contact_us_screen.dart';
import 'package:customer/ui/faq/faq_screen.dart';
import 'package:customer/ui/home_screens/home_screen.dart';
import 'package:customer/ui/interCity/interCity_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_order_screen.dart';
import 'package:customer/ui/orders/order_screen.dart';
import 'package:customer/ui/profile_screen/profile_screen.dart';
import 'package:customer/ui/referral_screen/referral_screen.dart';
import 'package:customer/ui/settings_screen/setting_screen.dart';
import 'package:customer/ui/wallet/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/banner_model.dart';
import '../utils/fire_store_utils.dart';

class DashBoardController extends GetxController {
  RxList<DrawerItem> drawerItems = [
    DrawerItem('City', "assets/icons/ic_city.svg"),
    DrawerItem('OutStation', "assets/icons/ic_intercity.svg"),
    DrawerItem('Rides', "assets/icons/ic_order.svg"),
    DrawerItem('OutStation Rides', "assets/icons/ic_order.svg"),
    DrawerItem('My Wallet', "assets/icons/ic_wallet.svg"),
    DrawerItem('Settings', "assets/icons/ic_settings.svg"),
    DrawerItem('Referral a friends', "assets/icons/ic_referral.svg"),
    DrawerItem('Inbox', "assets/icons/ic_inbox.svg"),
    DrawerItem('Profile', "assets/icons/ic_profile.svg"),
    DrawerItem('Contact us', "assets/icons/ic_contact_us.svg"),
    DrawerItem('FAQs', "assets/icons/ic_faq.svg"),
    DrawerItem('Log out', "assets/icons/ic_logout.svg"),
  ].obs;

  getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        // Use the new HomeScreen (banners + location pickers only)
        return HomeScreen();
      case 1:
        return const InterCityScreen(showAppBar: false);
      case 2:
        return const OrderScreen(showDrawer: false);
      case 3:
        return const InterCityOrderScreen(showDrawer: false);
      case 4:
        return const WalletScreen();
      case 5:
        return const SettingScreen();
      case 6:
        return const ReferralScreen();
      case 7:
        return const InboxScreen();
      case 8:
        return const ProfileScreen();
      case 9:
        return const ContactUsScreen();
      case 10:
        return const FaqScreen();
      default:
        return const Text("Error");
    }
  }

  // Global payment status listeners
  StreamSubscription? _cityPaymentListener;
  StreamSubscription? _intercityPaymentListener;

  @override
  void onInit() {
    super.onInit();

    // ✅ SAFETY CHECK: Ensure guest flag is correct for authenticated users
    if (FirebaseAuth.instance.currentUser != null && Constant.isGuestUser) {
      print(
          "🔧 FIXING: User is authenticated but marked as guest, correcting...");
      Constant.isGuestUser = false;
    }

    // ✅ FIXED: Location permission will be requested by HomeController when needed
    // _requestLocationPermissionMandatory(); // REMOVED

    // ✅ SMART APPROACH: Enable payment listeners with delay to avoid startup navigation
    // Wait 5 seconds after dashboard loads before starting listeners
    Timer(const Duration(seconds: 5), () {
      _startSmartPaymentListeners();
    });
  }

  @override
  void onClose() {
    _cityPaymentListener?.cancel();
    _intercityPaymentListener?.cancel();
    super.onClose();
  }

  /// SMART payment listeners that only detect REAL-TIME payment confirmations
  /// Started with delay to avoid navigation on app startup
  void _startSmartPaymentListeners() {
    final currentUserId = FireStoreUtils.getCurrentUid();

    if (currentUserId.isEmpty || currentUserId == "Guest") {
      print("❌ SKIPPING PAYMENT LISTENERS: Guest user or invalid ID");
      return;
    }

    print(
        "🎯 SMART LISTENERS: Starting payment listeners for user: $currentUserId");

    // ✅ ULTRA-SIMPLE APPROACH: Only listen for MODIFICATIONS (never additions)
    // This completely prevents navigation on app startup
    _cityPaymentListener = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: Constant.rideComplete)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // ✅ ONLY listen for MODIFIED documents (payment status changes)
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final orderId = data['id'] ?? change.doc.id;
          final paymentStatus = data['paymentStatus'] ?? false;

          // ✅ Navigate ONLY if payment was just confirmed by driver
          if (paymentStatus == true) {
            print("🚀 PAYMENT CONFIRMED: City order $orderId");

            // Navigate to completed rides tab immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAll(() =>
                  const OrderScreen(showDrawer: true, initialTabIndex: 1));
            });
          }
        }
      }
    });

    // Listen for intercity ride payment confirmations
    _intercityPaymentListener = FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: Constant.rideComplete)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // ✅ ONLY listen for MODIFIED documents (payment status changes)
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final orderId = data['id'] ?? change.doc.id;
          final paymentStatus = data['paymentStatus'] ?? false;

          // ✅ Navigate ONLY if payment was just confirmed by driver
          if (paymentStatus == true) {
            print("🚀 PAYMENT CONFIRMED: Intercity order $orderId");

            // Navigate to completed rides tab immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAll(() => const InterCityOrderScreen(initialTabIndex: 1));
            });
          }
        }
      }
    });
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    if (index == 11) {
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
    Get.back();
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) >
        const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      ShowToastDialog.showToast("Double press to exit");
      return Future.value(false);
    }
    return Future.value(true);
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
