import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

/// Client-side rate limiting for the auth endpoints.
///
/// Keeps a sliding window of recent requests below the server's limit and, if
/// the server still answers HTTP 429, waits for `Retry-After` and retries
/// automatically instead of surfacing "Too Many Attempts" to the user.
///
/// Time is injected ([now] / [delay]) so the behaviour can be unit tested
/// without waiting for real time.
class AuthRequestThrottle {
  AuthRequestThrottle({
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
    this.authMaxPerWindow = 4,
    this.sendOtpMaxPerWindow = 2,
    this.window = const Duration(seconds: 60),
    this.maxRetries = 2,
  })  : _now = now ?? DateTime.now,
        _delay = delay ?? Future<void>.delayed;

  /// Shared instance used by [ApiClient].
  static final AuthRequestThrottle instance = AuthRequestThrottle();

  /// True while a request is deliberately being held back (local budget or
  /// server `Retry-After`). The UI shows a "please wait" hint while it is true.
  static final ValueNotifier<bool> isWaiting = ValueNotifier<bool>(false);

  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final int authMaxPerWindow;
  final int sendOtpMaxPerWindow;
  final Duration window;
  final int maxRetries;

  final List<DateTime> _authTimes = [];
  final List<DateTime> _sendOtpTimes = [];

  static const Set<String> throttledUris = {
    AppConstants.sendOTP,
    AppConstants.otpVerification,
    AppConstants.otpLogin,
    AppConstants.loginUri,
    AppConstants.resetPassword,
  };

  static bool isThrottled(String uri) => throttledUris.contains(uri);

  List<DateTime> _timesFor(String uri) =>
      uri == AppConstants.sendOTP ? _sendOtpTimes : _authTimes;
  int _maxFor(String uri) =>
      uri == AppConstants.sendOTP ? sendOtpMaxPerWindow : authMaxPerWindow;

  /// Waits (if needed) until a request to [uri] fits in the local budget and
  /// then reserves one slot.
  Future<void> acquire(String uri) async {
    final List<DateTime> times = _timesFor(uri);
    final int max = _maxFor(uri);
    while (true) {
      final DateTime now = _now();
      times.removeWhere((t) => now.difference(t) >= window);
      if (times.length < max) {
        times.add(now);
        return;
      }
      final DateTime oldest = times.reduce((a, b) => a.isBefore(b) ? a : b);
      final Duration wait = window - now.difference(oldest);
      isWaiting.value = true;
      await _delay(wait + const Duration(milliseconds: 100));
    }
  }

  /// Runs [send] respecting the budget. A 429 answer is retried up to
  /// [maxRetries] times after the server's `Retry-After`.
  Future<Response> execute(String uri, Future<Response> Function() send) async {
    if (!isThrottled(uri)) return send();
    int attempt = 0;
    try {
      while (true) {
        await acquire(uri);
        isWaiting.value = false;
        final Response result = await send();
        if (result.statusCode == 429 && attempt < maxRetries) {
          attempt++;
          final int retry = ApiChecker.retryAfterSeconds(result);
          // Fill the local window so other auth calls also wait; the stamps
          // expire exactly when the server's Retry-After elapses.
          final DateTime stamp = _now().add(Duration(seconds: retry)).subtract(window);
          final List<DateTime> times = _timesFor(uri);
          while (times.length < _maxFor(uri)) {
            times.add(stamp);
          }
          isWaiting.value = true;
          await _delay(Duration(seconds: retry.clamp(1, 65) + 1));
          continue;
        }
        return result;
      }
    } finally {
      isWaiting.value = false;
    }
  }
}
