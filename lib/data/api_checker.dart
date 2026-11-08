import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';

/// Central place that turns *any* server answer into a user-facing message.
///
/// Handled shapes:
///  * `{message, errors: [{error_code|code, message}]}`   (app / 403 / 400)
///  * `{message, errors: {field: ["msg"]}}`               (Laravel 422)
///  * `{message}` only                                    (403, 404 ...)
///  * non-JSON bodies (HTML redirect / maintenance / proxy pages)
///  * no connection / timeout (status 0 / 1), 429, 5xx
class ApiChecker {
  static void checkApi(Response response) {
    if (response.statusCode == 401) {
      Get.find<ConfigController>().removeSharedData();
      Get.offAll(() => const SignInScreen());
      return;
    }
    showCustomSnackBar(messageFor(response));
  }

  /// Returns the text that should be shown for [response]. Never throws and
  /// never returns an empty string.
  static String messageFor(Response response) {
    try {
      final int? status = response.statusCode;

      if (status == 0 || status == 1) {
        return 'connection_to_api_server_failed'.tr;
      }
      if (status == 429) {
        return 'too_many_attempts_wait'
            .tr
            .replaceAll('{s}', '${retryAfterSeconds(response)}');
      }

      final dynamic body = response.body;
      if (body is Map) {
        final String? fromErrors = _firstErrorMessage(body['errors']);
        if (fromErrors != null) return _clean(fromErrors);
        final dynamic message = body['message'];
        if (message is String && message.trim().isNotEmpty) {
          return _clean(message);
        }
      }

      if (status != null && status >= 500) {
        return 'server_error_try_again'.tr;
      }
      // Never show raw markup (HTML error / redirect pages) to the user.
      final String? text = response.statusText;
      if (text != null && text.trim().isNotEmpty && !text.trim().startsWith('<')) {
        return _clean(text);
      }
    } catch (_) {
      // fall through to the generic message
    }
    return 'something_went_wrong'.tr;
  }

  /// Seconds the server asked us to wait (`Retry-After`), default 60.
  static int retryAfterSeconds(Response response) {
    final Map<String, String>? headers = response.headers;
    String? raw;
    headers?.forEach((key, value) {
      if (key.toLowerCase() == 'retry-after') raw = value;
    });
    final int? parsed = int.tryParse(raw ?? '');
    return (parsed == null || parsed <= 0) ? 60 : parsed;
  }

  static String? _firstErrorMessage(dynamic errors) {
    if (errors is List && errors.isNotEmpty) {
      final dynamic first = errors.first;
      if (first is Map && first['message'] is String) {
        return first['message'] as String;
      }
      if (first is String) return first;
    } else if (errors is Map && errors.isNotEmpty) {
      final dynamic first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }
    return null;
  }

  static String _clean(String message) =>
      message.replaceFirst(RegExp(r'^lang\.'), '').trim();
}
