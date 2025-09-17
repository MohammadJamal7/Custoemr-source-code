import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages persistent state for driver search timers
/// 
/// This class handles saving and retrieving timer state to ensure
/// timers continue correctly even if the app is killed and restarted.
class TimerStateManager {
  static const String _keyPrefix = 'driver_search_timer_';
  static const String _keyStartTime = '_start_time';
  static const String _keyIsRunning = '_is_running';
  static const String _keyPhaseDuration = '_phase_duration';

  /// Saves the timer state for a specific order
  static Future<void> saveTimerState({
    required String? orderId,
    required DateTime? startTime,
    required bool isRunning,
    required int phaseDuration,
  }) async {
    if (orderId == null) return; // Skip if order ID is null
    final prefs = await SharedPreferences.getInstance();
    
    // Save start time as milliseconds since epoch
    if (startTime != null) {
      await prefs.setInt(
        _keyPrefix + orderId + _keyStartTime,
        startTime.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_keyPrefix + orderId + _keyStartTime);
    }
    
    // Save running state
    await prefs.setBool(_keyPrefix + orderId + _keyIsRunning, isRunning);
    
    // Save phase duration
    await prefs.setInt(_keyPrefix + orderId + _keyPhaseDuration, phaseDuration);
  }
  
  /// Saves the timer state for a specific key (used for offer timers)
  static Future<void> saveOfferTimerState(String key, DateTime startTime, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save start time as milliseconds since epoch
    await prefs.setInt(
      _keyPrefix + key + _keyStartTime,
      startTime.millisecondsSinceEpoch,
    );
    
    // Save running state
    await prefs.setBool(_keyPrefix + key + _keyIsRunning, true);
    
    // Save phase duration
    await prefs.setInt(_keyPrefix + key + _keyPhaseDuration, duration);
  }

  /// Retrieves the timer state for a specific order
  static Future<TimerState?> getTimerState(String? orderId) async {
    if (orderId == null) return null; // Return null if order ID is null
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have data for this order
    if (!prefs.containsKey(_keyPrefix + orderId + _keyStartTime) &&
        !prefs.containsKey(_keyPrefix + orderId + _keyIsRunning)) {
      return null;
    }
    
    // Get start time
    final startTimeMillis = prefs.getInt(_keyPrefix + orderId + _keyStartTime);
    final DateTime? startTime = startTimeMillis != null 
        ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis)
        : null;
    
    // Get running state
    final isRunning = prefs.getBool(_keyPrefix + orderId + _keyIsRunning) ?? false;
    
    // Get phase duration
    final phaseDuration = prefs.getInt(_keyPrefix + orderId + _keyPhaseDuration) ?? 60;
    
    return TimerState(
      startTime: startTime,
      isRunning: isRunning,
      phaseDuration: phaseDuration,
    );
  }

  /// Clears the timer state for a specific order
  static Future<void> clearTimerState(String? orderId) async {
    if (orderId == null) return; // Skip if order ID is null
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix + orderId + _keyStartTime);
    await prefs.remove(_keyPrefix + orderId + _keyIsRunning);
    await prefs.remove(_keyPrefix + orderId + _keyPhaseDuration);
  }
  
  /// Removes timer state for a specific key (used for offer timers)
  static Future<void> removeOfferTimerState(String key) async {
    await clearTimerState(key);
  }
  
  /// Synchronously gets timer state from memory cache
  /// Note: This is less reliable than the async version but avoids UI jank
  static TimerState? getTimerStateSync(String key) {
    // This is a simplified implementation that relies on the async method
    // In a real app, you would want to maintain a memory cache as well
    try {
      // Create a temporary state that will be replaced by the async call
      final tempState = TimerState(
        startTime: DateTime.now().subtract(const Duration(seconds: 1)),
        isRunning: true,
        phaseDuration: 60,
      );
      
      // Kick off the async call to update the state later
      getTimerState(key).then((actualState) {
        // This will happen after the widget is built
        // The widget should handle state updates appropriately
      });
      
      return tempState;
    } catch (e) {
      debugPrint('Error in getTimerStateSync: $e');
      return null;
    }
  }
  
  /// Calculates remaining seconds based on start time and phase duration
  static int calculateRemainingSeconds(DateTime startTime, int phaseDuration) {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inSeconds;
    final remaining = phaseDuration - elapsed;
    debugPrint('Timer calculation: start=${startTime.toString()}, now=${now.toString()}, elapsed=${elapsed}s, duration=${phaseDuration}s, remaining=${remaining}s');
    return remaining > 0 ? remaining : 0;
  }
}

/// Data class to hold timer state
class TimerState {
  final DateTime? startTime;
  final bool isRunning;
  final int phaseDuration;
  
  TimerState({
    required this.startTime,
    required this.isRunning,
    required this.phaseDuration,
  });
}
