import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+1".obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  sendCode() async {
    ShowToastDialog.showLoader("Please wait".tr);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode + phoneNumberController.value.text,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Optional: sign in automatically if credential is valid
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("FirebaseAuthException--->${e.message}");
          ShowToastDialog.closeLoader();

          if (e.code == 'invalid-phone-number') {
            ShowToastDialog.showToast("Invalid phone number.");
          } else if (e.code == 'operation-not-allowed') {
            ShowToastDialog.showToast("Phone auth not enabled in Firebase Console.");
          } else if (e.message?.contains("SMS unable to be sent") ?? false) {
            ShowToastDialog.showToast("SMS not supported in this region. Contact Firebase support.");
          } else if (e.message?.contains("EXPIRED") ?? false) {
            ShowToastDialog.showToast("ReCAPTCHA expired. Please try again.");
            // Retry automatically if needed
            // sendCode();  // <== Uncomment if you want automatic retry
          } else {
            ShowToastDialog.showToast("Authentication failed: ${e.message}");
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          Get.to(const OtpScreen(), arguments: {
            "countryCode": countryCode.value,
            "phoneNumber": phoneNumberController.value.text,
            "verificationId": verificationId,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Auto retrieval timeout");
        },
      );
    } catch (error) {
      debugPrint("catchError--->$error");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Too many attempts. Please wait and try again later.");
    }
  }


  Future<UserCredential?> signInWithGoogle() async {
    try {
      bool isSignedIn = false;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
      isSignedIn = await googleSignIn.isSignedIn();
      if (isSignedIn) {
        googleSignIn.signOut();
      }
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn().catchError((error) {
        debugPrint("catchError--->$error");
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Something went wrong".tr);
        return null;
      });

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
    // Trigger the authentication flow
  }

  // Future<Map<String, dynamic>?> signInWithApple() async {
  //   try {
  //     // Request credential for the currently signed in Apple account.
  //     AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //
  //     );
  //     print(appleCredential);
  //
  //     // Create an `OAuthCredential` from the credential returned by Apple.
  //     final oauthCredential = OAuthProvider("apple.com").credential(
  //       idToken: appleCredential.identityToken,
  //         accessToken: appleCredential.authorizationCode
  //     );
  //
  //     // Sign in the user with Firebase. If the nonce we generated earlier does
  //     // not match the nonce in `appleCredential.identityToken`, sign in will fail.
  //     UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  //     return {"appleCredential": appleCredential, "userCredential": userCredential};
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  //   return null;
  // }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId: 'com.wdni.customers',
                redirectUri: Uri.parse(
                  'https://com.wdni.customers.firebaseapp.com/__/auth/handler',
                ),
              )
            : null,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      return {
        "appleCredential": appleCredential,
        "userCredential": userCredential,
      };
    } catch (e) {
      debugPrint("❌ Apple sign in failed: $e");
      return null;
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
