/// Decides whether a new "send OTP" request may go out.
///
/// * a code was just sent to the same phone  -> reuse it (no new request)
/// * the server answered 429 recently        -> block until `Retry-After`
///
/// Time is injected so it can be tested without real waiting.
enum OtpSendDecision { send, reuseLastCode, blockedByServer }

class OtpSendGuard {
  OtpSendGuard({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, DateTime> _lastSent = {};
  DateTime? _blockedUntil;

  /// Cooldown derived from the configured resend time (the resend button only
  /// appears after it, so we stay a little below it).
  static int cooldownSecondsFor(int? otpResendTime) {
    final int resend = (otpResendTime == null || otpResendTime <= 0) ? 30 : otpResendTime;
    return resend > 2 ? resend - 2 : resend;
  }

  OtpSendDecision check(String phone, {required int cooldownSeconds}) {
    final DateTime now = _now();
    if (_blockedUntil != null && now.isBefore(_blockedUntil!)) {
      return OtpSendDecision.blockedByServer;
    }
    final DateTime? last = _lastSent[phone];
    if (last != null && now.difference(last).inSeconds < cooldownSeconds) {
      return OtpSendDecision.reuseLastCode;
    }
    return OtpSendDecision.send;
  }

  /// Seconds left of a server imposed block (0 when not blocked).
  int blockedSecondsLeft() {
    if (_blockedUntil == null) return 0;
    final int left = _blockedUntil!.difference(_now()).inSeconds + 1;
    return left > 0 ? left : 0;
  }

  void markSent(String phone) => _lastSent[phone] = _now();

  void markRateLimited(int retryAfterSeconds) {
    _blockedUntil = _now().add(Duration(seconds: retryAfterSeconds));
  }

  void reset() {
    _lastSent.clear();
    _blockedUntil = null;
  }
}
