import 'package:customer/constant/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Helper class to fix drawer links appearing disabled after ride cancellation
class DrawerHelper {
  /// Force disable guest mode for authenticated users
  static void ensureDrawerLinksEnabled() {
    if (FirebaseAuth.instance.currentUser != null) {
      Constant.isGuestUser = false;
    }
  }
  
  /// Reset guest mode and rebuild UI if needed
  static void resetGuestModeAndRebuild(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      // Force disable guest mode
      Constant.isGuestUser = false;
      
      // We don't need to force a rebuild with markNeedsBuild
      // This was causing infinite rebuilds and loading screens
    }
  }
  
  /// Check if user is authenticated and not in guest mode
  static bool isAuthenticatedAndNotGuest() {
    return FirebaseAuth.instance.currentUser != null && !Constant.isGuestUser;
  }
  
  /// Ensure drawer is always enabled for authenticated users
  static void setupDrawerEnabledListener(StatefulWidget widget, State state) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && state.mounted) {
        Constant.isGuestUser = false;
        state.setState(() {});
      }
    });
  }
}
