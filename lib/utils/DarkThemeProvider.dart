import 'package:customer/utils/DarkThemePreference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  int _darkTheme = 0;

  int get darkTheme => _darkTheme;

  set darkTheme(int value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }

  bool getThem() {
    if (_darkTheme == 0) {
      // 0 => Dark
      return true;
    } else if (_darkTheme == 1) {
      // 1 => Light
      return false;
    } else {
      // Any other value => Default to Dark (ignore system theme)
      return true;
    }
  }

  bool getSystemThem() {
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
}
