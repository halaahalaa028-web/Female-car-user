import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/rate_limit_blocked_dialog.dart';
import 'package:ride_sharing_user_app/helper/rate_limit_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimitHelper Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      Get.reset();
    });

    test('initial state is not blocked', () {
      final blocked = RateLimitHelper.isBlocked(userId: 'user_1', preferences: prefs);
      expect(blocked, isFalse);

      final remaining = RateLimitHelper.getRemainingBlockDuration(userId: 'user_1', preferences: prefs);
      expect(remaining, Duration.zero);
    });

    test('1 and 2 requests do not block user', () {
      final now = DateTime(2026, 9, 7, 12, 0);

      // Attempt 1
      final blocked1 = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now,
      );
      expect(blocked1, isFalse);
      expect(RateLimitHelper.isBlocked(userId: 'user_1', preferences: prefs, now: now), isFalse);

      // Attempt 2 (10 minutes later)
      final blocked2 = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 10)),
      );
      expect(blocked2, isFalse);
      expect(RateLimitHelper.isBlocked(userId: 'user_1', preferences: prefs, now: now.add(const Duration(minutes: 10))), isFalse);
    });

    test('3rd request within 1 hour triggers a 2-hour block', () {
      final now = DateTime(2026, 9, 7, 12, 0);

      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now,
      );
      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 15)),
      );

      // 3rd attempt at 30 minutes
      final blocked3 = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 30)),
      );
      expect(blocked3, isTrue);

      // Verify isBlocked
      final isBlockedNow = RateLimitHelper.isBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 30)),
      );
      expect(isBlockedNow, isTrue);

      // Verify remaining duration is 2 hours
      final remaining = RateLimitHelper.getRemainingBlockDuration(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 30)),
      );
      expect(remaining, const Duration(hours: 2));

      // 1 hour later (1 hour left of block)
      final remainingAfter1Hr = RateLimitHelper.getRemainingBlockDuration(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(hours: 1, minutes: 30)),
      );
      expect(remainingAfter1Hr, const Duration(hours: 1));

      // After 2 hours (block expired)
      final isBlockedAfterExpiry = RateLimitHelper.isBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(hours: 2, minutes: 31)),
      );
      expect(isBlockedAfterExpiry, isFalse);
      expect(
        RateLimitHelper.getRemainingBlockDuration(
          userId: 'user_1',
          preferences: prefs,
          now: now.add(const Duration(hours: 2, minutes: 31)),
        ),
        Duration.zero,
      );
    });

    test('requests older than 1 hour are pruned from rolling window', () {
      final now = DateTime(2026, 9, 7, 12, 0);

      // Attempt 1 at 12:00
      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now,
      );

      // Attempt 2 at 12:45
      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 45)),
      );

      // Attempt 3 at 13:05 (1 hour and 5 minutes after attempt 1)
      // Attempt 1 should be pruned, so window only has Attempt 2 and Attempt 3 (total 2)
      final blocked3 = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(hours: 1, minutes: 5)),
      );
      expect(blocked3, isFalse);
      expect(
        RateLimitHelper.isBlocked(
          userId: 'user_1',
          preferences: prefs,
          now: now.add(const Duration(hours: 1, minutes: 5)),
        ),
        isFalse,
      );

      // Attempt 4 at 13:10 (Attempt 2, 3, 4 within 1 hour: 12:45, 13:05, 13:10) -> Now blocked!
      final blocked4 = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(hours: 1, minutes: 10)),
      );
      expect(blocked4, isTrue);
    });

    test('resetBlock clears both block and attempt history', () {
      final now = DateTime(2026, 9, 7, 12, 0);

      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now,
      );
      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 10)),
      );
      RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_1',
        preferences: prefs,
        now: now.add(const Duration(minutes: 20)),
      );

      expect(RateLimitHelper.isBlocked(userId: 'user_1', preferences: prefs, now: now.add(const Duration(minutes: 20))), isTrue);

      // Reset block (e.g. trip completed)
      RateLimitHelper.resetBlock(userId: 'user_1', preferences: prefs);

      expect(RateLimitHelper.isBlocked(userId: 'user_1', preferences: prefs, now: now.add(const Duration(minutes: 20))), isFalse);
      expect(RateLimitHelper.getRemainingBlockDuration(userId: 'user_1', preferences: prefs), Duration.zero);
    });

    test('users are isolated by userId', () {
      final now = DateTime(2026, 9, 7, 12, 0);

      // Block user_A
      for (int i = 0; i < 3; i++) {
        RateLimitHelper.recordAttemptAndCheckIfBlocked(
          userId: 'user_A',
          preferences: prefs,
          now: now.add(Duration(minutes: i * 5)),
        );
      }
      expect(RateLimitHelper.isBlocked(userId: 'user_A', preferences: prefs, now: now.add(const Duration(minutes: 15))), isTrue);

      // user_B should not be blocked
      expect(RateLimitHelper.isBlocked(userId: 'user_B', preferences: prefs, now: now.add(const Duration(minutes: 15))), isFalse);
      final bAttempt = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'user_B',
        preferences: prefs,
        now: now.add(const Duration(minutes: 15)),
      );
      expect(bAttempt, isFalse);
    });

    test('getFormattedRemainingTime formats accurately', () {
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(hours: 1, minutes: 45), isArabic: false), '1 hr and 45 min');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(hours: 2), isArabic: false), '2 hr');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(minutes: 25), isArabic: false), '25 min');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(seconds: 30), isArabic: false), 'Less than a minute');
      expect(RateLimitHelper.getFormattedRemainingTime(Duration.zero, isArabic: false), '');

      // Arabic formatting
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(hours: 1, minutes: 45), isArabic: true), '1 ساعة و 45 دقيقة');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(hours: 2), isArabic: true), '2 ساعة');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(minutes: 25), isArabic: true), '25 دقيقة');
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(seconds: 30), isArabic: true), 'أقل من دقيقة');
    });

    test('handles default fallbacks and corrupted json gracefully', () {
      Get.put<SharedPreferences>(prefs);

      // Without explicit userId and now (uses guest_user and DateTime.now)
      expect(RateLimitHelper.isBlocked(), isFalse);
      expect(RateLimitHelper.getRemainingBlockDuration(), Duration.zero);

      // Format remaining time with default locale
      expect(RateLimitHelper.getFormattedRemainingTime(const Duration(hours: 1)), isNotEmpty);

      // Corrupted JSON in timestamps should be handled by catch block
      prefs.setString('rate_limit_req_timestamps_corrupted_user', '{bad_json}');
      final attempt = RateLimitHelper.recordAttemptAndCheckIfBlocked(
        userId: 'corrupted_user',
        preferences: prefs,
      );
      expect(attempt, isFalse);
    });

    testWidgets('RateLimitBlockedDialog renders remaining time and OK button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: RateLimitBlockedDialog(remainingTime: '1 hr and 30 min'),
          ),
        ),
      );

      expect(find.textContaining('1 hr and 30 min', skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.access_time_filled_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    });

    testWidgets('showBlockedDialog displays dialog and dismisses on OK tap', (tester) async {
      Get.put<SharedPreferences>(prefs);
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RateLimitHelper.showBlockedDialog(context, duration: const Duration(hours: 1)),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(RateLimitBlockedDialog), findsOneWidget);

      // Tap OK button
      await tester.tap(find.text('ok'));
      await tester.pumpAndSettle();

      expect(find.byType(RateLimitBlockedDialog), findsNothing);
    });
  });
}
