import 'dart:async';

import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/timer_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Driver search timer widget for intercity orders
class DriverSearchTimer extends StatefulWidget {
  final InterCityOrderModel orderModel;
  final Future<void> Function() onCancel;
  final VoidCallback onContinue;

  const DriverSearchTimer({
    super.key,
    required this.orderModel,
    required this.onCancel,
    required this.onContinue,
  });

  @override
  State<DriverSearchTimer> createState() => _DriverSearchTimerState();
}

class _DriverSearchTimerState extends State<DriverSearchTimer>
    with WidgetsBindingObserver {
  static const int phaseDuration = 120; // 5 minutes (5 * 60 seconds)
  int secondsRemaining = phaseDuration;
  Timer? _timer;
  bool _isRunning = false; // controls whether the minute countdown is active
  DateTime? _cycleStartAt; // wall-clock start of the current minute cycle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTimerState();
  }

  Future<void> _initializeTimerState() async {
    // Load saved timer state from persistent storage
    final timerState =
        await TimerStateManager.getTimerState(widget.orderModel.id);

    if (timerState != null && mounted) {
      setState(() {
        _isRunning = timerState.isRunning;
        _cycleStartAt = timerState.startTime;

        if (_isRunning && _cycleStartAt != null) {
          // Calculate remaining time based on saved start time
          secondsRemaining = TimerStateManager.calculateRemainingSeconds(
              _cycleStartAt!, timerState.phaseDuration);

          // If time already expired while app was closed, trigger minute end
          if (secondsRemaining <= 0) {
            // Use Future.microtask to avoid calling setState during build
            Future.microtask(() => _onMinuteEnded());
            secondsRemaining = 0;
          } else {
            // Start the timer with the remaining time
            _startTimerWithCurrentState();
          }
        }
      });
    } else {
      // No saved state, start fresh
      _startMinute();
    }
  }

  @override
  void dispose() async {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Clean up any stored dialog expiry time
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dialog_expiry_${widget.orderModel.id}');
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Check timer state when app resumes
    if (state == AppLifecycleState.resumed) {
      // Check if there's an active dialog that should have expired
      final prefs = await SharedPreferences.getInstance();
      final expiryTimeStr =
          prefs.getString('dialog_expiry_${widget.orderModel.id}');

      if (expiryTimeStr != null) {
        final expiryTime = DateTime.parse(expiryTimeStr);
        if (DateTime.now().isAfter(expiryTime)) {
          // Dialog should have expired while app was in background
          await prefs.remove('dialog_expiry_${widget.orderModel.id}');
          // Cancel the ride since dialog timed out
          await _onCancel();
          return;
        }
      }

      // Normal timer check
      if (_isRunning && _cycleStartAt != null) {
        final elapsed = DateTime.now().difference(_cycleStartAt!).inSeconds;
        final remaining = phaseDuration - elapsed;
        if (remaining <= 0) {
          _timer?.cancel();
          _onMinuteEnded();
        } else {
          setState(() => secondsRemaining = remaining);
        }
      }
    }
  }

  void _startMinute() {
    _timer?.cancel();
    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      secondsRemaining = phaseDuration;
      _isRunning = true;
      _cycleStartAt = now;
    });

    // Persist timer state
    TimerStateManager.saveTimerState(
      orderId: widget.orderModel.id,
      startTime: now,
      isRunning: true,
      phaseDuration: phaseDuration,
    );

    _startTimerWithCurrentState();
  }

  void _startTimerWithCurrentState() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (_cycleStartAt == null) {
        t.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_cycleStartAt!).inSeconds;
      final remaining = phaseDuration - elapsed;

      if (remaining <= 0) {
        t.cancel();
        _onMinuteEnded();
      } else {
        if (remaining != secondsRemaining) {
          setState(() => secondsRemaining = remaining);
        }
      }
    });
  }

  String _format(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onMinuteEnded() async {
    if (!mounted) return;
    setState(() {
      _isRunning = false; // pause while prompting
    });

    // Persist paused state
    await TimerStateManager.saveTimerState(
      orderId: widget.orderModel.id,
      startTime: null,
      isRunning: false,
      phaseDuration: phaseDuration,
    );

    // Ask user if they want to continue searching for another minute
    final bool? decision = await _showContinueDialog();
    if (!mounted) return;

    if (decision == true) {
      // Optional callback to allow parent to extend search server-side
      try {
        widget.onContinue();
      } catch (_) {}
      _startMinute();
    } else if (decision == false) {
      // Explicit No or dialog timeout -> cancel
      await _onCancel();
    }
  }

  Future<bool?> _showContinueDialog() async {
    // Auto-timeout after 20 seconds: if no response, close dialog with false (cancel)
    bool poppedByTimer = false;

    // Store the dialog expiry time in SharedPreferences
    final dialogExpiryTime = DateTime.now().add(const Duration(seconds: 20));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dialog_expiry_${widget.orderModel.id}',
        dialogExpiryTime.toIso8601String());

    // Create a background-aware timer that will check if dialog should be dismissed
    // This will work even when the app is in the background
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (poppedByTimer) {
        timer.cancel();
        return;
      }

      // Check if we've reached or passed the expiry time
      final now = DateTime.now();
      if (now.isAfter(dialogExpiryTime)) {
        timer.cancel();

        // Clean up the stored expiry time
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dialog_expiry_${widget.orderModel.id}');

        if (!poppedByTimer && mounted) {
          poppedByTimer = true;
          try {
            final rootNav = Navigator.of(context, rootNavigator: true);
            if (rootNav.canPop()) {
              rootNav.pop(false); // Return false to cancel the ride
              return;
            }
          } catch (_) {}
          try {
            final localNav = Navigator.of(context);
            if (!poppedByTimer && localNav.canPop()) {
              localNav.pop(false); // Return false to cancel the ride
            }
          } catch (_) {}
        }
      }
    });
    final result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Text(
          'continueSearchingMessage'.tr,
        ),
        actions: [
          Directionality(
            textDirection: TextDirection.ltr, // Force No(left) and Yes(right)
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('No'.tr),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.darkModePrimary, // Green background
                    foregroundColor: Colors.black, // Black text
                  ),
                  child: Text('Yes'.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (timer.isActive) timer.cancel();
    return result; // null => timeout; true => continue; false => cancel
  }

  // Method removed to fix lint error

  Future<void> _onCancel() async {
    _timer?.cancel();

    // Clear persisted timer state on cancel
    await TimerStateManager.clearTimerState(widget.orderModel.id);

    await widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    // Theme is used through themeChange
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fast moving line under the offers button (indeterminate)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: null, // indeterminate animation
              backgroundColor: themeChange.getThem()
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              color: AppColors.darkModePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRunning ? 'searchingDrivers'.tr : 'stillSearchingDrivers'.tr,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: 1 - (secondsRemaining / phaseDuration),
                    backgroundColor: themeChange.getThem()
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    color: AppColors.darkModePrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _format(secondsRemaining),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  // Change text color to red when less than 60 seconds remaining
                  color: secondsRemaining <= 60
                      ? Colors.red
                      : (themeChange.getThem() ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
