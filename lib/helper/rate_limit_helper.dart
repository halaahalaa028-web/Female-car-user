import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/rate_limit_blocked_dialog.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimitHelper {
  static const int maxRequests = 3;
  static const Duration windowDuration = Duration(hours: 1);
  static const Duration blockDuration = Duration(hours: 2);

  static const String _prefixTimestamps = 'rate_limit_req_timestamps_';
  static const String _prefixBlockedUntil = 'rate_limit_blocked_until_';

  static SharedPreferences _getPrefs(SharedPreferences? preferences) {
    return preferences ?? Get.find<SharedPreferences>();
  }

  static String _resolveUserId(String? userId) {
    if (userId != null && userId.isNotEmpty) return userId;
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().profileModel?.data?.id ?? 'guest_user';
    }
    return 'guest_user';
  }

  static bool isBlocked({String? userId, SharedPreferences? preferences, DateTime? now}) {
    final prefs = _getPrefs(preferences);
    final userKey = _resolveUserId(userId);
    final int? blockedUntilMs = prefs.getInt('$_prefixBlockedUntil$userKey');

    if (blockedUntilMs == null) {
      return false;
    }

    final int currentTimeMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (currentTimeMs < blockedUntilMs) {
      return true;
    }

    resetBlock(userId: userKey, preferences: prefs);
    return false;
  }

  static Duration getRemainingBlockDuration({String? userId, SharedPreferences? preferences, DateTime? now}) {
    final prefs = _getPrefs(preferences);
    final userKey = _resolveUserId(userId);
    final int? blockedUntilMs = prefs.getInt('$_prefixBlockedUntil$userKey');

    if (blockedUntilMs == null) {
      return Duration.zero;
    }

    final DateTime currentTime = now ?? DateTime.now();
    final DateTime expiry = DateTime.fromMillisecondsSinceEpoch(blockedUntilMs);
    final Duration diff = expiry.difference(currentTime);

    return diff.isNegative ? Duration.zero : diff;
  }

  static String getFormattedRemainingTime(Duration duration, {bool? isArabic}) {
    if (duration.inSeconds <= 0) return '';
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    final bool arabic = isArabic ?? (Get.locale?.languageCode == 'ar');

    if (hours > 0 && minutes > 0) {
      return arabic ? '$hours ساعة و $minutes دقيقة' : '$hours hr and $minutes min';
    } else if (hours > 0) {
      return arabic ? '$hours ساعة' : '$hours hr';
    } else if (minutes > 0) {
      return arabic ? '$minutes دقيقة' : '$minutes min';
    } else {
      return arabic ? 'أقل من دقيقة' : 'Less than a minute';
    }
  }

  static bool recordAttemptAndCheckIfBlocked({String? userId, SharedPreferences? preferences, DateTime? now}) {
    final prefs = _getPrefs(preferences);
    final userKey = _resolveUserId(userId);
    final DateTime currentTime = now ?? DateTime.now();

    if (isBlocked(userId: userKey, preferences: prefs, now: currentTime)) {
      return true;
    }

    final List<int> timestamps = _loadTimestamps(prefs, userKey);
    final int cutoffMs = currentTime.subtract(windowDuration).millisecondsSinceEpoch;

    final List<int> validTimestamps = timestamps.where((t) => t > cutoffMs).toList();
    validTimestamps.add(currentTime.millisecondsSinceEpoch);

    if (validTimestamps.length >= maxRequests) {
      final int blockedUntilMs = currentTime.add(blockDuration).millisecondsSinceEpoch;
      prefs.setInt('$_prefixBlockedUntil$userKey', blockedUntilMs);
      prefs.remove('$_prefixTimestamps$userKey');
      return true;
    }

    _saveTimestamps(prefs, userKey, validTimestamps);
    return false;
  }

  static void resetBlock({String? userId, SharedPreferences? preferences}) {
    final prefs = _getPrefs(preferences);
    final userKey = _resolveUserId(userId);
    prefs.remove('$_prefixBlockedUntil$userKey');
    prefs.remove('$_prefixTimestamps$userKey');
  }

  static void showBlockedDialog(BuildContext context, {Duration? duration}) {
    final remaining = duration ?? getRemainingBlockDuration();
    Get.dialog(
      RateLimitBlockedDialog(remainingTime: getFormattedRemainingTime(remaining)),
      barrierDismissible: false,
    );
  }

  static List<int> _loadTimestamps(SharedPreferences prefs, String userKey) {
    final String? raw = prefs.getString('$_prefixTimestamps$userKey');
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  static void _saveTimestamps(SharedPreferences prefs, String userKey, List<int> timestamps) {
    prefs.setString('$_prefixTimestamps$userKey', jsonEncode(timestamps));
  }
}
