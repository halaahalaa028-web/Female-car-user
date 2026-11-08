import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/helper/otp_send_guard.dart';
import 'package:ride_sharing_user_app/helper/phone_mask_helper.dart';

void main() {
  late DateTime now;
  late OtpSendGuard guard;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    guard = OtpSendGuard(now: () => now);
  });

  void advance(int seconds) => now = now.add(Duration(seconds: seconds));

  group('OTP cooldown per phone', () {
    test('first send is allowed', () {
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.send);
    });

    test('a second send inside the cooldown reuses the last code', () {
      guard.markSent('+966500000001');
      advance(10);
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.reuseLastCode);
    });

    test('after the cooldown a new code may be sent', () {
      guard.markSent('+966500000001');
      advance(28);
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.send);
    });

    test('cooldown is per phone number', () {
      guard.markSent('+966500000001');
      expect(guard.check('+966500000002', cooldownSeconds: 28), OtpSendDecision.send);
    });

    test('cooldownSecondsFor stays slightly below the resend time', () {
      expect(OtpSendGuard.cooldownSecondsFor(30), 28);
      expect(OtpSendGuard.cooldownSecondsFor(60), 58);
      expect(OtpSendGuard.cooldownSecondsFor(2), 2);
      expect(OtpSendGuard.cooldownSecondsFor(null), 28);
      expect(OtpSendGuard.cooldownSecondsFor(0), 28);
    });
  });

  group('server 429 block', () {
    test('blocks every phone until Retry-After has passed', () {
      guard.markRateLimited(42);
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.blockedByServer);
      expect(guard.check('+966500000002', cooldownSeconds: 28), OtpSendDecision.blockedByServer);
      expect(guard.blockedSecondsLeft(), 43);
      advance(20);
      expect(guard.blockedSecondsLeft(), 23);
      advance(23);
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.send);
      expect(guard.blockedSecondsLeft(), 0);
    });

    test('reset clears everything', () {
      guard.markSent('+966500000001');
      guard.markRateLimited(100);
      guard.reset();
      expect(guard.check('+966500000001', cooldownSeconds: 28), OtpSendDecision.send);
    });
  });

  group('maskPhoneNumber', () {
    String strip(String s) =>
        s.replaceAll(String.fromCharCode(0x2066), '').replaceAll(String.fromCharCode(0x2069), '');

    test('masks the middle of a normal number', () {
      expect(strip(maskPhoneNumber('+966500000123')), '+9665*****123');
    });

    test('is wrapped in left-to-right isolate marks (RTL safe)', () {
      final String masked = maskPhoneNumber('+966500000123');
      expect(masked.codeUnitAt(0), 0x2066);
      expect(masked.codeUnitAt(masked.length - 1), 0x2069);
    });

    test('never throws on short or empty input', () {
      expect(() => maskPhoneNumber(''), returnsNormally);
      expect(strip(maskPhoneNumber('123')), '123');
      expect(strip(maskPhoneNumber('12345')), '1**45');
    });
  });
}
