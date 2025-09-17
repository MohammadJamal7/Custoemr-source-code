import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../constant/collection_name.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 28,
                    color: Color(0xFFe1e8e0),
                  ),
                  Image.asset("assets/images/login_image.jpeg",
                      width: Responsive.width(100, context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Login".tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                              "Welcome Back! We are happy to have \n you back"
                                  .tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400)),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 30),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Divider(
                                height: 0,
                                thickness: 2,
                              )),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "Log in using".tr,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(
                                height: 0,
                                thickness: 2,
                              )),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 16,
                                    offset: Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Material(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () async {
                                      ShowToastDialog.showLoader(
                                          "Please wait".tr);
                                      await controller
                                          .signInWithGoogle()
                                          .then((value) async {
                                        ShowToastDialog.closeLoader();
                                        if (value != null) {
                                          String uid = value.user?.uid ?? '';
                                          bool isDriver = await FireStoreUtils
                                              .checkUserInCollection(uid,
                                                  CollectionName.driverUsers);
                                          log(uid.toString());
                                          log(isDriver.toString());
                                          if (isDriver) {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            ShowToastDialog.showToast(
                                                "thisDriverAccount".tr);
                                            Get.offAll(const LoginScreen());
                                            return;
                                          }
                                          if (value
                                              .additionalUserInfo!.isNewUser) {
                                            print("----->new user");
                                            // ✅ CRITICAL FIX: Set guest flag to false for new authenticated users
                                            Constant.isGuestUser = false;
                                            UserModel userModel = UserModel();
                                            userModel.id = value.user!.uid;
                                            userModel.email = value.user!.email;
                                            userModel.fullName =
                                                value.user!.displayName;
                                            userModel.profilePic =
                                                value.user!.photoURL;
                                            userModel.loginType =
                                                Constant.googleLoginType;

                                            ShowToastDialog.closeLoader();
                                            Get.to(const InformationScreen(),
                                                arguments: {
                                                  "userModel": userModel,
                                                });
                                          } else {
                                            print("----->old user");
                                            FireStoreUtils.userExitOrNot(
                                                    value.user!.uid)
                                                .then((userExit) async {
                                              ShowToastDialog.closeLoader();
                                              if (userExit == true) {
                                                UserModel? userModel =
                                                    await FireStoreUtils
                                                        .getUserProfile(
                                                            value.user!.uid);
                                                if (userModel != null) {
                                                  if (userModel.isActive ==
                                                      true) {
                                                    // ✅ CRITICAL FIX: Set guest flag to false for authenticated users
                                                    Constant.isGuestUser =
                                                        false;
                                                    Get.offAll(
                                                        const DashBoardScreen());
                                                  } else {
                                                    await FirebaseAuth.instance
                                                        .signOut();
                                                    ShowToastDialog.showToast(
                                                        "This user is disable please contact administrator"
                                                            .tr);
                                                  }
                                                }
                                              } else {
                                                UserModel userModel =
                                                    UserModel();
                                                userModel.id = value.user!.uid;
                                                userModel.email =
                                                    value.user!.email;
                                                userModel.fullName =
                                                    value.user!.displayName;
                                                userModel.profilePic =
                                                    value.user!.photoURL;
                                                userModel.loginType =
                                                    Constant.googleLoginType;

                                                Get.to(
                                                    const InformationScreen(),
                                                    arguments: {
                                                      "userModel": userModel,
                                                    });
                                              }
                                            });
                                          }
                                        }
                                      });

                                      // ShowToastDialog.showLoader("Please wait".tr);
                                      // await controller.signInWithGoogle().then((value) async {
                                      //   ShowToastDialog.closeLoader();
                                      //
                                      //   if (value == null || value.user == null) {
                                      //     ShowToastDialog.showToast("فشل تسجيل الدخول. حاول مرة أخرى.");
                                      //     return;
                                      //   }
                                      //
                                      //   final user = value.user!;
                                      //   if (value.additionalUserInfo!.isNewUser) {
                                      //     log("----->new user");
                                      //     UserModel userModel = UserModel();
                                      //     userModel.id = user.uid;
                                      //     userModel.email = user.email;
                                      //     userModel.fullName = user.displayName;
                                      //     userModel.profilePic = user.photoURL;
                                      //     userModel.loginType = Constant.googleLoginType;
                                      //
                                      //     Get.to(const InformationScreen(), arguments: {
                                      //       "userModel": userModel,
                                      //     });
                                      //   } else {
                                      //     log("----->old user");
                                      //     final exists = await FireStoreUtils.userExitOrNot(user.uid);
                                      //     if (exists) {
                                      //       Get.to(const DashBoardScreen());
                                      //     } else {
                                      //       UserModel userModel = UserModel();
                                      //       userModel.id = user.uid;
                                      //       userModel.email = user.email;
                                      //       userModel.fullName = user.displayName;
                                      //       userModel.profilePic = user.photoURL;
                                      //       userModel.loginType = Constant.googleLoginType;
                                      //
                                      //       Get.to(const InformationScreen(), arguments: {
                                      //         "userModel": userModel,
                                      //       });
                                      //     }
                                      //   }
                                      // });
                                    },
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset(
                                            'assets/icons/ic_google.png'), // شعار Google
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (Platform.isIOS) ...[
                              SizedBox(width: 20),
                              Text(
                                'أو',
                                style: TextStyle(
                                  color: themeChange.getThem()
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 16,
                                      offset: Offset(5, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: SignInWithAppleButton(
                                      style: SignInWithAppleButtonStyle.white,
                                      onPressed: () async {
                                        ShowToastDialog.showLoader(
                                            "Please wait".tr);
                                        await controller
                                            .signInWithApple()
                                            .then((value) async {
                                          ShowToastDialog.closeLoader();

                                          if (value != null) {
                                            Map<String, dynamic> map = value;
                                            AuthorizationCredentialAppleID
                                                appleCredential =
                                                map['appleCredential'];
                                            UserCredential userCredential =
                                                map['userCredential'];
                                            if (userCredential
                                                    .additionalUserInfo
                                                    ?.isNewUser ??
                                                false) {
                                              // ✅ CRITICAL FIX: Set guest flag to false for new Apple authenticated users
                                              Constant.isGuestUser = false;
                                              UserModel userModel = UserModel();
                                              userModel.id =
                                                  userCredential.user?.uid ??
                                                      '';
                                              userModel.profilePic =
                                                  userCredential.user?.photoURL;
                                              userModel.loginType =
                                                  Constant.appleLoginType;
                                              userModel.email = userCredential
                                                      .additionalUserInfo
                                                      ?.profile?['email'] ??
                                                  '';
                                              userModel.fullName =
                                                  "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}"
                                                      .trim();

                                              Get.to(const InformationScreen(),
                                                  arguments: {
                                                    "userModel": userModel,
                                                  });
                                            } else {
                                              FireStoreUtils.userExitOrNot(
                                                      userCredential
                                                              .user?.uid ??
                                                          '')
                                                  .then((userExit) async {
                                                ShowToastDialog.closeLoader();
                                                if (userExit) {
                                                  UserModel? userModel =
                                                      await FireStoreUtils
                                                          .getUserProfile(
                                                              userCredential
                                                                  .user!.uid);
                                                  if (userModel != null) {
                                                    if (userModel.isActive ==
                                                        true) {
                                                      // ✅ CRITICAL FIX: Set guest flag to false for existing Apple authenticated users
                                                      Constant.isGuestUser =
                                                          false;
                                                      Get.offAll(
                                                          const DashBoardScreen());
                                                    } else {
                                                      await FirebaseAuth
                                                          .instance
                                                          .signOut();
                                                      ShowToastDialog.showToast(
                                                          "This user is disable please contact administrator"
                                                              .tr);
                                                    }
                                                  }
                                                } else {
                                                  UserModel userModel =
                                                      UserModel();
                                                  userModel.id = userCredential
                                                          .user?.uid ??
                                                      '';
                                                  userModel.profilePic =
                                                      userCredential
                                                          .user?.photoURL;
                                                  userModel.loginType =
                                                      Constant.appleLoginType;
                                                  userModel
                                                      .email = userCredential
                                                          .additionalUserInfo
                                                          ?.profile?['email'] ??
                                                      '';
                                                  userModel.fullName =
                                                      "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}"
                                                          .trim();

                                                  Get.to(
                                                      const InformationScreen(),
                                                      arguments: {
                                                        "userModel": userModel,
                                                      });
                                                }
                                              });
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ButtonThem.buildBorderButton(
                          context,
                          title: "Continue as Guest".tr,
                          iconVisibility: false,
                          onPress: () {
                            Constant.isGuestUser = true;
                            Get.offAll(const DashBoardScreen());
                          },
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        // ✅ UNDER DEVELOPMENT: Phone login temporarily disabled - MOVED TO BOTTOM
                        Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkTextField.withOpacity(0.5)
                                : AppColors.textField.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                      .withOpacity(0.5)
                                  : AppColors.textFieldBorder.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              TextFormField(
                                enabled: false, // ✅ Disable the field
                                validator: (value) =>
                                    value != null && value.isNotEmpty
                                        ? null
                                        : 'Required',
                                keyboardType: TextInputType.number,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller:
                                    controller.phoneNumberController.value,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.poppins(
                                  color: themeChange.getThem()
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.6),
                                ),
                                decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    prefixIcon: CountryCodePicker(
                                      enabled:
                                          false, // ✅ Disable country picker
                                      onChanged: (value) {
                                        controller.countryCode.value =
                                            value.dialCode.toString();
                                      },
                                      dialogBackgroundColor:
                                          themeChange.getThem()
                                              ? AppColors.darkBackground
                                              : AppColors.background,
                                      initialSelection:
                                          "YE", // ✅ Set Yemen as default
                                      comparator: (a, b) =>
                                          b.name!.compareTo(a.name.toString()),
                                      flagDecoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(2)),
                                      ),
                                      padding: const EdgeInsets.only(
                                          right:
                                              12.0), // ✅ Add internal padding to move flag right
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppColors.darkTextFieldBorder
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppColors.darkTextFieldBorder
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppColors.darkTextFieldBorder
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppColors.darkTextFieldBorder
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                          color: themeChange.getThem()
                                              ? AppColors.darkTextFieldBorder
                                              : AppColors.textFieldBorder,
                                          width: 1),
                                    ),
                                    hintText: "Phone number".tr),
                              ),
                              // ✅ Overlay message for under development
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.construction,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "قيد التطوير",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "قريباً!",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 7,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        // ✅ Disabled continue button with under development message - MOVED TO BOTTOM
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  "Next".tr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // ✅ Overlay message
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.construction,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "قريباً",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            bottomNavigationBar: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'By tapping "Next" you agree to '.tr,
                    style: GoogleFonts.poppins(),
                    children: <TextSpan>[
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "terms",
                              ));
                            },
                          text: 'Terms and conditions'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      TextSpan(text: ' and '.tr, style: GoogleFonts.poppins()),
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "privacy",
                              ));
                            },
                          text: 'privacy policy'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      // can add more TextSpans here...
                    ],
                  ),
                )),
          );
        });
  }
}
