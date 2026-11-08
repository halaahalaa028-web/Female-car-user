import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';

/// In-memory auth service: records calls and returns canned answers.
class _FakeAuthService extends Fake implements AuthServiceInterface {
  Future<dynamic> Function() onLogin = () async => const Response(statusCode: 200);
  Future<dynamic> Function() onSendOtp = () async => const Response(statusCode: 200);
  Future<dynamic> Function() onVerifyOtp = () async => const Response(statusCode: 200);
  Future<dynamic> Function() onOtpLogin = () async => const Response(statusCode: 200);

  int loginCalls = 0;
  int sendOtpCalls = 0;
  String? savedToken;
  bool tokenCleared = false;

  @override
  Future<dynamic> login({required String phone, required String password}) {
    loginCalls++;
    return onLogin();
  }

  @override
  Future<dynamic> sendOtp({required String phone}) {
    sendOtpCalls++;
    return onSendOtp();
  }

  @override
  Future<dynamic> verifyOtp({required String phone, required String otp}) => onVerifyOtp();

  @override
  Future<dynamic> otpLogin({required String phone, required String otp}) => onOtpLogin();

  @override
  Future<bool?> saveUserToken(String token) async {
    savedToken = token;
    tokenCleared = false;
    return true;
  }

  @override
  bool clearSharedData() {
    savedToken = null;
    tokenCleared = true;
    return true;
  }

  @override
  Future<dynamic> updateToken() async => const Response(statusCode: 200);

  @override
  Future<void> saveUserNumberAndPassword(String code, String number, String password, bool externalUser) async {}

  @override
  Future<bool> clearUserNumberAndPassword() async => true;

  @override
  String getUserPassword(bool externalUser) => '';
}

/// Records every UI side effect instead of touching GetX navigation.
class _FakeEffects extends AuthSideEffects {
  _FakeEffects({this.cfg, Future<Response?> Function()? profile})
      : profile = profile ?? (() async => const Response(statusCode: 200));

  final ConfigModel? cfg;
  Future<Response?> Function() profile;

  final List<String> messages = [];
  final List<bool> messageIsError = [];
  final List<int> reportedStatuses = [];
  final List<String> events = [];

  @override
  ConfigModel? get config => cfg;
  @override
  Future<Response?> loadProfile() => profile();
  @override
  void startPusher() => events.add('pusher');
  @override
  void showMessage(String message, {bool isError = true}) {
    messages.add(message);
    messageIsError.add(isError);
  }

  @override
  void reportError(Response response) => reportedStatuses.add(response.statusCode ?? -1);
  @override
  void openVerification(String number) => events.add('verification:$number');
  @override
  void openResetPassword(String phone) => events.add('reset:$phone');
  @override
  void openSignIn() => events.add('signin');
  @override
  void openEditProfile() => events.add('edit_profile');
  @override
  void goDashboard({bool resetNavBar = false}) => events.add('dashboard');
}

void main() {
  late _FakeAuthService service;
  late AuthController controller;

  _FakeEffects wire({ConfigModel? config, Future<Response?> Function()? profile}) {
    final _FakeEffects fx = _FakeEffects(cfg: config ?? ConfigModel(isSmsGateway: true, otpResendTime: 30), profile: profile);
    controller.effects = fx;
    return fx;
  }

  setUp(() {
    Get.reset();
    service = _FakeAuthService();
    controller = AuthController(authServiceInterface: service);
  });

  group('login()', () {
    test('success: saves token, starts pusher, loads profile, opens dashboard', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123', 'is_phone_verified': 1}
          });
      final _FakeEffects fx = wire();

      await controller.login('+966', '500000001', 'password1');

      expect(service.savedToken, 'abc123');
      expect(fx.events, ['pusher', 'dashboard']);
      expect(fx.messages, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('200 with an EMPTY token never starts a session', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': '', 'is_phone_verified': 1}
          });
      final _FakeEffects fx = wire();

      await controller.login('+966', '500000001', 'password1');

      expect(service.savedToken, isNull);
      expect(fx.events, isEmpty);
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('200 with a missing token / data / non-map body does not crash', () async {
      for (final dynamic body in <dynamic>[
        {'data': {}},
        {'data': null},
        {'message': 'ok'},
        '<html>proxy</html>',
        null,
      ]) {
        service.onLogin = () async => Response(statusCode: 200, body: body);
        final _FakeEffects fx = wire();
        await controller.login('+966', '500000001', 'password1');
        expect(service.savedToken, isNull, reason: 'body: $body');
        expect(fx.messages, ['login_failed_try_again'], reason: 'body: $body');
        expect(controller.isLoading, isFalse);
      }
    });

    test('202 + phone not verified opens the verification screen (SMS gateway)', () async {
      service.onLogin = () async => const Response(statusCode: 202, body: {
            'data': {'is_phone_verified': 0}
          });
      final _FakeEffects fx = wire();

      await controller.login('+966', '500000001', 'password1');

      expect(fx.events, ['verification:+966500000001']);
      expect(service.savedToken, isNull);
    });

    test('202 + phone not verified without any OTP gateway tells the user', () async {
      service.onLogin = () async => const Response(statusCode: 202, body: {
            'data': {'is_phone_verified': 0}
          });
      final _FakeEffects fx = wire(config: ConfigModel(isSmsGateway: false, isFirebaseOtpVerification: false));

      await controller.login('+966', '500000001', 'password1');

      expect(fx.messages, ['sms_gateway_not_integrate']);
      expect(fx.events, isEmpty);
    });

    test('202 for another reason (no data / pending approval) shows a neutral message and does not crash', () async {
      for (final dynamic body in <dynamic>[
        {'message': 'Waiting for approval'},
        {'data': null},
        null,
      ]) {
        service.onLogin = () async => Response(statusCode: 202, body: body);
        final _FakeEffects fx = wire();
        await controller.login('+966', '500000001', 'password1');
        expect(fx.messages, hasLength(1), reason: 'body: $body');
        expect(fx.messageIsError.single, isFalse);
        expect(fx.events, isEmpty);
        expect(service.savedToken, isNull);
      }
    });

    test('profile fetch FAILS after login: token is dropped and nothing navigates', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => const Response(statusCode: 500));

      await controller.login('+966', '500000001', 'password1');

      expect(service.tokenCleared, isTrue);
      expect(service.savedToken, isNull);
      expect(fx.events, ['pusher']); // no dashboard
      expect(controller.isLoading, isFalse);
    });

    test('profile fetch returns null: token dropped and the user is told', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => null);

      await controller.login('+966', '500000001', 'password1');

      expect(service.tokenCleared, isTrue);
      expect(fx.messages, ['login_failed_try_again']);
      expect(fx.events, isNot(contains('dashboard')));
    });

    test('profile fetch THROWS: token dropped, generic error, loading reset', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => throw Exception('boom'));

      await controller.login('+966', '500000001', 'password1');

      expect(service.tokenCleared, isTrue);
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('server errors go through the central error handler', () async {
      for (final int status in [403, 422, 429, 500, 1]) {
        service.onLogin = () async => Response(statusCode: status);
        final _FakeEffects fx = wire();
        await controller.login('+966', '500000001', 'password1');
        expect(fx.reportedStatuses, [status]);
        expect(service.savedToken, isNull);
      }
    });

    test('null response from the service does not crash', () async {
      service.onLogin = () async => null;
      final _FakeEffects fx = wire();
      await controller.login('+966', '500000001', 'password1');
      expect(fx.messages, ['something_went_wrong']);
    });

    test('an exception thrown by the service is caught and loading is reset', () async {
      service.onLogin = () async => throw Exception('socket');
      final _FakeEffects fx = wire();
      await controller.login('+966', '500000001', 'password1');
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('a second tap while a login is running is ignored', () async {
      service.onLogin = () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Response(statusCode: 200, body: {
          'data': {'token': 't'}
        });
      };
      wire();
      final Future<void> first = controller.login('+966', '500000001', 'password1');
      final Future<void> second = controller.login('+966', '500000001', 'password1');
      await Future.wait([first, second]);
      expect(service.loginCalls, 1);
    });
  });

  group('sendOtp()', () {
    test('a second request for the same phone inside the cooldown does not hit the server', () async {
      final _FakeEffects fx = wire();
      final Response a = await controller.sendOtp('+966500000001');
      final Response b = await controller.sendOtp('+966500000001');
      expect(a.statusCode, 200);
      expect(b.statusCode, 200);
      expect(service.sendOtpCalls, 1);
      expect(fx.messages, ['otp_sent_successfully']);
    });

    test('simultaneous taps share one request', () async {
      service.onSendOtp = () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Response(statusCode: 200);
      };
      wire();
      await Future.wait([
        controller.sendOtp('+966500000001'),
        controller.sendOtp('+966500000001'),
        controller.sendOtp('+966500000001'),
      ]);
      expect(service.sendOtpCalls, 1);
      expect(controller.isOtpSending, isFalse);
    });

    test('different phones are independent', () async {
      wire();
      await controller.sendOtp('+966500000001');
      await controller.sendOtp('+966500000002');
      expect(service.sendOtpCalls, 2);
    });

    test('a 429 blocks further sends and tells the user to wait', () async {
      service.onSendOtp = () async => const Response(statusCode: 429, headers: {'retry-after': '40'});
      final _FakeEffects fx = wire();

      final Response first = await controller.sendOtp('+966500000001');
      expect(first.statusCode, 429);
      expect(fx.reportedStatuses, [429]);

      final Response second = await controller.sendOtp('+966500000002');
      expect(second.statusCode, 429);
      expect(service.sendOtpCalls, 1, reason: 'blocked locally, server not called again');
      expect(fx.messages.single, 'too_many_attempts_wait');
    });

    test('a failed send is not remembered as "sent"', () async {
      service.onSendOtp = () async => const Response(statusCode: 500);
      wire();
      await controller.sendOtp('+966500000001');
      service.onSendOtp = () async => const Response(statusCode: 200);
      await controller.sendOtp('+966500000001');
      expect(service.sendOtpCalls, 2);
    });

    test('exception from the service becomes a connection error', () async {
      service.onSendOtp = () async => throw Exception('socket');
      final _FakeEffects fx = wire();
      final Response r = await controller.sendOtp('+966500000001');
      expect(r.statusCode, 1);
      expect(fx.reportedStatuses, [1]);
      expect(controller.isOtpSending, isFalse);
    });
  });

  group('OTP verification', () {
    test('wrong code (HTTP 200 + otp_mismatch_404) is reported as an error status', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {'response_code': 'otp_mismatch_404'});
      final _FakeEffects fx = wire();
      final Response r = await controller.otpVerification('+966500000001', '123456', accountVerification: true);
      expect(r.statusCode, 404);
      expect(fx.events, isEmpty);
      expect(controller.otpVerifying, isFalse);
    });

    test('non-account verification continues to reset password', () async {
      final _FakeEffects fx = wire();
      final Response r = await controller.otpVerification('+966500000001', '123456');
      expect(r.statusCode, 200);
      expect(fx.events, ['reset:+966500000001']);
    });

    test('verified but NO token and no saved password -> sign in (no crash)', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {'data': {}});
      final _FakeEffects fx = wire();
      await controller.otpVerification('+966500000001', '123456', accountVerification: true);
      expect(fx.events, ['signin']);
      expect(service.loginCalls, 0);
    });

    test('verified with a token starts a session', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok', 'is_profile_verified': 1}
          });
      final _FakeEffects fx = wire();
      await controller.otpVerification('+966500000001', '123456', accountVerification: true);
      expect(service.savedToken, 'tok');
      expect(fx.events, ['pusher', 'dashboard']);
    });

    test('verified with a token but profile not verified opens edit profile', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok', 'is_profile_verified': 0}
          });
      final _FakeEffects fx = wire();
      await controller.otpVerification('+966500000001', '123456', accountVerification: true);
      expect(fx.events, ['pusher', 'edit_profile']);
    });

    test('Firebase verification without a session does not crash', () async {
      final _FakeEffects fx = wire(config: ConfigModel(isFirebaseOtpVerification: true));
      final Response r = await controller.otpVerification('+966500000001', '123456', accountVerification: true);
      expect(r.statusCode, 400);
      expect(fx.messages, ['something_went_wrong']);
      expect(controller.otpVerifying, isFalse);
    });

    test('429 / network errors are reported, not treated as a wrong code', () async {
      for (final int status in [429, 1, 500]) {
        service.onVerifyOtp = () async => Response(statusCode: status);
        final _FakeEffects fx = wire();
        final Response r = await controller.otpVerification('+966500000001', '123456', accountVerification: true);
        expect(r.statusCode, status);
        expect(fx.reportedStatuses, [status]);
      }
    });
  });

  group('otpLogin()', () {
    test('success starts a session and opens the dashboard', () async {
      service.onOtpLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok', 'is_profile_verified': 1}
          });
      final _FakeEffects fx = wire();
      final Response r = await controller.otpLogin('+966500000001', '123456', fromOtpLogin: true);
      expect(r.statusCode, 200);
      expect(service.savedToken, 'tok');
      expect(fx.events, ['pusher', 'dashboard']);
    });

    test('empty token is rejected (no half-logged-in state)', () async {
      service.onOtpLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': ''}
          });
      final _FakeEffects fx = wire();
      final Response r = await controller.otpLogin('+966500000001', '123456', fromOtpLogin: true);
      expect(r.statusCode, 502);
      expect(service.savedToken, isNull);
      expect(fx.messages, ['login_failed_try_again']);
      expect(fx.events, isEmpty);
    });

    test('profile failure after OTP login drops the token', () async {
      service.onOtpLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok'}
          });
      final _FakeEffects fx = wire(profile: () async => const Response(statusCode: 500));
      final Response r = await controller.otpLogin('+966500000001', '123456', fromOtpLogin: true);
      expect(r.statusCode, 502);
      expect(service.tokenCleared, isTrue);
      expect(fx.events, isNot(contains('dashboard')));
    });

    test('wrong code maps to an error status', () async {
      service.onOtpLogin = () async => const Response(statusCode: 200, body: {'response_code': 'otp_mismatch_404'});
      wire();
      final Response r = await controller.otpLogin('+966500000001', '000000', fromOtpLogin: true);
      expect(r.statusCode, 404);
    });
  });
}
