import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/auth_request_throttle.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

/// Fake clock: `delay` just advances the clock and records the wait, so tests
/// never wait for real time.
class _Clock {
  DateTime now = DateTime(2026, 1, 1, 12);
  final List<Duration> delays = [];

  Future<void> delay(Duration d) async {
    delays.add(d);
    now = now.add(d);
  }
}

void main() {
  late _Clock clock;
  late AuthRequestThrottle throttle;

  setUp(() {
    clock = _Clock();
    throttle = AuthRequestThrottle(now: () => clock.now, delay: clock.delay);
    AuthRequestThrottle.isWaiting.value = false;
  });

  Future<Response> ok() async => const Response(statusCode: 200);

  group('local window', () {
    test('requests under the budget are not delayed', () async {
      for (int i = 0; i < 4; i++) {
        await throttle.execute(AppConstants.loginUri, ok);
      }
      expect(clock.delays, isEmpty);
    });

    test('the request over the budget waits for the window to pass', () async {
      for (int i = 0; i < 4; i++) {
        await throttle.execute(AppConstants.loginUri, ok);
      }
      final Response r = await throttle.execute(AppConstants.loginUri, ok);
      expect(r.statusCode, 200);
      expect(clock.delays, hasLength(1));
      // ~60s window (+100ms safety)
      expect(clock.delays.single.inSeconds, inInclusiveRange(59, 61));
    });

    test('send-otp has a smaller budget (2 / minute)', () async {
      await throttle.execute(AppConstants.sendOTP, ok);
      await throttle.execute(AppConstants.sendOTP, ok);
      expect(clock.delays, isEmpty);
      await throttle.execute(AppConstants.sendOTP, ok);
      expect(clock.delays, hasLength(1));
    });

    test('send-otp and other auth routes have separate budgets', () async {
      await throttle.execute(AppConstants.sendOTP, ok);
      await throttle.execute(AppConstants.sendOTP, ok);
      await throttle.execute(AppConstants.loginUri, ok);
      expect(clock.delays, isEmpty);
    });

    test('old requests leave the window as time passes', () async {
      await throttle.execute(AppConstants.sendOTP, ok);
      await throttle.execute(AppConstants.sendOTP, ok);
      clock.now = clock.now.add(const Duration(seconds: 61));
      await throttle.execute(AppConstants.sendOTP, ok);
      expect(clock.delays, isEmpty);
    });

    test('routes that are not auth routes are never throttled', () async {
      for (int i = 0; i < 20; i++) {
        await throttle.execute('/api/customer/config', ok);
      }
      expect(clock.delays, isEmpty);
    });

    test('isWaiting is true while held back and false afterwards', () async {
      final List<bool> seen = [];
      AuthRequestThrottle.isWaiting.addListener(() => seen.add(AuthRequestThrottle.isWaiting.value));
      for (int i = 0; i < 5; i++) {
        await throttle.execute(AppConstants.loginUri, ok);
      }
      expect(seen, contains(true));
      expect(AuthRequestThrottle.isWaiting.value, isFalse);
    });
  });

  group('429 handling', () {
    test('retries after Retry-After and returns the successful answer', () async {
      int calls = 0;
      final Response r = await throttle.execute(AppConstants.loginUri, () async {
        calls++;
        return calls == 1
            ? const Response(statusCode: 429, headers: {'retry-after': '5'})
            : const Response(statusCode: 200);
      });
      expect(r.statusCode, 200);
      expect(calls, 2);
      expect(clock.delays.first, const Duration(seconds: 6)); // retry-after + 1
    });

    test('gives up after maxRetries and returns the 429', () async {
      int calls = 0;
      final Response r = await throttle.execute(AppConstants.loginUri, () async {
        calls++;
        return const Response(statusCode: 429, headers: {'retry-after': '1'});
      });
      expect(r.statusCode, 429);
      expect(calls, 1 + throttle.maxRetries);
    });

    test('Retry-After is clamped (a huge value does not block for hours)', () async {
      int calls = 0;
      await throttle.execute(AppConstants.loginUri, () async {
        calls++;
        return calls == 1
            ? const Response(statusCode: 429, headers: {'retry-after': '99999'})
            : const Response(statusCode: 200);
      });
      expect(clock.delays.first.inSeconds, lessThanOrEqualTo(66));
    });

    test('a 429 also holds back the next auth call until the window passes', () async {
      int calls = 0;
      await throttle.execute(AppConstants.loginUri, () async {
        calls++;
        return calls == 1 ? const Response(statusCode: 429, headers: {'retry-after': '30'}) : await ok();
      });
      final int delaysBefore = clock.delays.length;
      await throttle.execute(AppConstants.loginUri, ok);
      // The retry wait (31s) already covered the 30s Retry-After, so no extra wait.
      expect(clock.delays.length, delaysBefore);
    });

    test('non-429 errors are returned immediately without retry', () async {
      int calls = 0;
      final Response r = await throttle.execute(AppConstants.loginUri, () async {
        calls++;
        return const Response(statusCode: 422);
      });
      expect(r.statusCode, 422);
      expect(calls, 1);
      expect(clock.delays, isEmpty);
    });

    test('isWaiting is reset even if the request throws', () async {
      await expectLater(
        throttle.execute(AppConstants.loginUri, () async => throw StateError('boom')),
        throwsStateError,
      );
      expect(AuthRequestThrottle.isWaiting.value, isFalse);
    });
  });
}
