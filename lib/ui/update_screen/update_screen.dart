import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constant/show_toast_dialog.dart';
import '../../utils/Preferences.dart';
import '../../utils/fire_store_utils.dart';
import '../auth_screen/login_screen.dart';
import '../dashboard_screen.dart';
import '../on_boarding_screen.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkForUpdates();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> checkForUpdates() async {
    String currentVersion = await VersionChecker.getInstalledVersion();
    String? storeVersion = await VersionChecker.getStoreVersion();

    if (storeVersion != "" &&
        VersionChecker.isUpToDate(currentVersion, storeVersion)) {
      _navigateToNextScreen();
    } else {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("تحديث متاح"),
          content: Text("يرجى تحديث التطبيق للمتابعة"),
          actions: [
            TextButton(
              onPressed: launchUpdateUrl,
              child: Text("تحديث الآن"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToNextScreen() async {
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(() => const OnBoardingScreen());
    } else {
      // ✅ CRITICAL FIX: Handle authentication state safely
      try {
        bool isLogin = await FireStoreUtils.isLogin();
        if (isLogin == true) {
          Get.offAll(() => const DashBoardScreen());
        } else {
          Get.offAll(() => const LoginScreen());
        }
      } catch (e) {
        // ✅ FALLBACK: If authentication check fails, go to login screen
        print('UpdateScreen: Authentication check failed: $e');
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  void launchUpdateUrl() async {
    const android =
        'https://play.google.com/store/apps/details?id=com.wdni.customers';
    const ios =
        'https://apps.apple.com/us/app/ودني-مشاوير-توصيل-وأكثر/id6747665421';
    final uri = Platform.isIOS ? Uri.parse(ios) : Uri.parse(android);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ShowToastDialog.showToast("Could not launch".tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black);
  }
}

class VersionChecker {
  static Future<String> getInstalledVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<String> getStoreVersion() async {
    try {
      return FireStoreUtils.getStoreVersion();
    } catch (e) {
      return ShowToastDialog.showToast(e.toString());
    }
  }

  static bool isUpToDate(String current, String latest) {
    List<int> currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentVal = i < currentParts.length ? currentParts[i] : 0;
      int latestVal = latestParts[i];
      if (currentVal < latestVal) return false;
      if (currentVal > latestVal) return true;
    }
    return true; // equal
  }
}
