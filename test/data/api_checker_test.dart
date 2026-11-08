import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'connection_to_api_server_failed': 'No connection',
          'too_many_attempts_wait': 'Wait {s} seconds',
          'server_error_try_again': 'Server problem',
          'something_went_wrong': 'Something went wrong',
        },
      };
}

void main() {
  setUpAll(() {
    Get.addTranslations(_TestTranslations().keys);
    Get.locale = const Locale('en');
  });

  String msg(Response r) => ApiChecker.messageFor(r);

  group('422 validation', () {
    test('Laravel style: errors is a Map of lists -> first message', () {
      expect(
        msg(const Response(statusCode: 422, body: {
          'message': 'The phone field is required. (and 1 more error)',
          'errors': {
            'phone_or_email': ['The phone or email field is required.'],
            'password': ['The password field is required.'],
          },
        })),
        'The phone or email field is required.',
      );
    });

    test('errors is a list of {code,message}', () {
      expect(
        msg(const Response(statusCode: 422, body: {
          'errors': [
            {'code': 'phone', 'message': 'Phone is invalid'}
          ],
        })),
        'Phone is invalid',
      );
    });

    test('falls back to message when errors is empty', () {
      expect(msg(const Response(statusCode: 422, body: {'message': 'Invalid data', 'errors': []})),
          'Invalid data');
    });
  });

  group('403', () {
    test('uses first error message', () {
      expect(
        msg(const Response(statusCode: 403, body: {
          'errors': [
            {'code': 'blocked', 'message': 'Account blocked'}
          ],
        })),
        'Account blocked',
      );
    });

    test('message only body', () {
      expect(msg(const Response(statusCode: 403, body: {'message': 'Forbidden for you'})),
          'Forbidden for you');
    });

    test('403 with HTML body does not crash and never shows markup', () {
      expect(msg(const Response(statusCode: 403, body: '<html>nginx</html>', statusText: 'Forbidden')),
          'Forbidden');
      expect(msg(const Response(statusCode: 403, body: '<html>nginx</html>', statusText: '<html>')),
          'Something went wrong');
    });
  });

  group('429', () {
    test('shows Retry-After seconds', () {
      expect(
        msg(const Response(statusCode: 429, body: {'message': 'Too Many Attempts.'}, headers: {'retry-after': '42'})),
        'Wait 42 seconds',
      );
    });

    test('Retry-After header is matched case-insensitively', () {
      expect(
        msg(const Response(statusCode: 429, headers: {'Retry-After': '7'})),
        'Wait 7 seconds',
      );
    });

    test('missing / invalid Retry-After defaults to 60', () {
      expect(msg(const Response(statusCode: 429)), 'Wait 60 seconds');
      expect(msg(const Response(statusCode: 429, headers: {'retry-after': 'soon'})), 'Wait 60 seconds');
      expect(ApiChecker.retryAfterSeconds(const Response(statusCode: 429, headers: {'retry-after': '0'})), 60);
    });
  });

  group('5xx', () {
    test('500 / 502 / 503 with JSON message prefer that message', () {
      expect(msg(const Response(statusCode: 500, body: {'message': 'DB down'})), 'DB down');
    });

    test('5xx with HTML page gives the friendly text, not markup', () {
      for (final int code in [500, 502, 503, 504]) {
        expect(
          msg(Response(statusCode: code, body: '<html>maintenance</html>', statusText: 'Service Unavailable')),
          'Server problem',
          reason: 'status $code',
        );
      }
    });

    test('5xx with empty body', () {
      expect(msg(const Response(statusCode: 500)), 'Server problem');
    });
  });

  group('HTML / non JSON responses', () {
    test('redirect page (302) never leaks markup', () {
      expect(msg(const Response(statusCode: 302, body: '<html>redirect</html>', statusText: '<html>')),
          'Something went wrong');
    });

    test('plain-text body with a reason phrase uses the phrase', () {
      expect(msg(const Response(statusCode: 404, body: 'Not here', statusText: 'Not Found')), 'Not Found');
    });
  });

  group('no connection', () {
    test('status 0 and 1 (timeout / socket error)', () {
      expect(msg(const Response(statusCode: 1, statusText: 'x')), 'No connection');
      expect(msg(const Response(statusCode: 0)), 'No connection');
    });
  });

  group('cleanup & robustness', () {
    test('"lang." prefix is removed', () {
      expect(
        msg(const Response(statusCode: 400, body: {
          'errors': [
            {'error_code': 'first_name', 'message': 'lang.The first name field is required.'}
          ],
        })),
        'The first name field is required.',
      );
      expect(msg(const Response(statusCode: 403, body: {'message': 'lang.Account blocked'})), 'Account blocked');
    });

    test('garbage never throws and is never empty', () {
      expect(msg(const Response()), 'Something went wrong');
      expect(msg(const Response(statusCode: 418, body: {'errors': 5, 'message': 7})), 'Something went wrong');
      expect(msg(const Response(statusCode: 422, body: {'errors': {'a': []}})), 'Something went wrong');
    });
  });
}
