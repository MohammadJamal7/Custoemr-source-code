import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer/utils/timer_state_manager.dart';

/// A global service to manage timers across the app
/// This ensures timers continue running even when the user navigates away from screens
class GlobalTimerService extends GetxService {
  // Singleton instance
  static GlobalTimerService get instance => Get.find<GlobalTimerService>();

  // Map of active timers by key
  final Map<String, _TimerEntry> _activeTimers = {};
  
  // Timer for periodic cleanup and processing
  Timer? _processingTimer;
  
  // Stream controllers for timer events
  final _timerExpiredController = StreamController<String>.broadcast();
  Stream<String> get onTimerExpired => _timerExpiredController.stream;
  
  // Initialize the service
  Future<GlobalTimerService> init() async {
    // Start the processing timer
    _processingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processTimers();
    });
    
    return this;
  }
  
  // Register a timer with the service
  Future<void> registerTimer({
    required String key,
    required int durationSeconds,
    DateTime? startTime,
    bool restoreFromStorage = true,
  }) async {
    // Check if we should restore from storage
    if (restoreFromStorage) {
      final state = await TimerStateManager.getTimerState(key);
      if (state != null && state.startTime != null && state.isRunning) {
        startTime = state.startTime;
        durationSeconds = state.phaseDuration;
      }
    }
    
    // Use provided start time or create a new one
    final effectiveStartTime = startTime ?? DateTime.now();
    
    // Create a value notifier for the remaining seconds
    final remainingSeconds = ValueNotifier<int>(
      _calculateRemainingSeconds(effectiveStartTime, durationSeconds)
    );
    
    // Create a timer entry
    _activeTimers[key] = _TimerEntry(
      key: key,
      startTime: effectiveStartTime,
      durationSeconds: durationSeconds,
      remainingSeconds: remainingSeconds,
    );
    
    // Save to persistent storage
    await TimerStateManager.saveTimerState(
      orderId: key,
      startTime: effectiveStartTime,
      isRunning: true,
      phaseDuration: durationSeconds,
    );
    
    print('GlobalTimerService: Registered timer $key with $durationSeconds seconds');
  }
  
  // Get a value notifier for a timer's remaining seconds
  ValueNotifier<int>? getRemainingSecondsNotifier(String key) {
    return _activeTimers[key]?.remainingSeconds;
  }
  
  // Get the remaining seconds for a timer
  int getRemainingSeconds(String key) {
    final entry = _activeTimers[key];
    if (entry == null) return 0;
    
    return _calculateRemainingSeconds(entry.startTime, entry.durationSeconds);
  }
  
  // Check if a timer is active
  bool isTimerActive(String key) {
    return _activeTimers.containsKey(key);
  }
  
  // Remove a timer
  Future<void> removeTimer(String key) async {
    _activeTimers.remove(key);
    await TimerStateManager.clearTimerState(key);
    print('GlobalTimerService: Removed timer $key');
  }
  
  // Process all active timers
  void _processTimers() {
    final expiredKeys = <String>[];
    
    // Update all timers
    for (final entry in _activeTimers.entries) {
      final timer = entry.value;
      final remaining = _calculateRemainingSeconds(
        timer.startTime, 
        timer.durationSeconds
      );
      
      // Update the value notifier if the value has changed
      if (timer.remainingSeconds.value != remaining) {
        timer.remainingSeconds.value = remaining;
      }
      
      // Check if timer has expired
      if (remaining <= 0) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Handle expired timers
    for (final key in expiredKeys) {
      _timerExpiredController.add(key);
      print('GlobalTimerService: Timer expired: $key');
    }
  }
  
  // Calculate remaining seconds
  int _calculateRemainingSeconds(DateTime startTime, int durationSeconds) {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final remaining = durationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
  
  // Dispose the service
  @override
  void onClose() {
    _processingTimer?.cancel();
    _timerExpiredController.close();
    for (final entry in _activeTimers.values) {
      entry.remainingSeconds.dispose();
    }
    _activeTimers.clear();
    super.onClose();
  }
}

// Helper class for timer entries
class _TimerEntry {
  final String key;
  final DateTime startTime;
  final int durationSeconds;
  final ValueNotifier<int> remainingSeconds;
  
  _TimerEntry({
    required this.key,
    required this.startTime,
    required this.durationSeconds,
    required this.remainingSeconds,
  });
}
