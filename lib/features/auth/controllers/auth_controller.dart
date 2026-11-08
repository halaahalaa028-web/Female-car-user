import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/sign_up_body.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/reset_password_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/verification_screen.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/edit_profile_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';
import 'package:ride_sharing_user_app/helper/country_code_helper.dart';
import 'package:ride_sharing_user_app/helper/otp_send_guard.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';

class AuthController extends GetxController implements GetxService {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});

  bool _isLoading = false;
  bool _isOtpSending = false;
  String _verificationCode = '';
  bool _isActiveRememberMe = false;
  bool otpVerifying = false;
  String countryDialCode = '+880';
  bool get isLoading => _isLoading;
  bool get isOtpSending => _isOtpSending;
  String get verificationCode => _verificationCode;
  bool get isActiveRememberMe => _isActiveRememberMe;
  bool showNavigationBar = true;

  void toggleNavigationBar(){
    showNavigationBar = false;
    update();
  }

  void setCountryCode( String countryCode){
    countryDialCode  = countryDialCode;
    update();
  }

  /// Collaborators with side effects (navigation, snackbars, other
  /// controllers). Kept behind one object so the login/OTP logic can be unit
  /// tested with a fake.
  AuthSideEffects effects = const AuthSideEffects();

  /// Decides whether a new OTP request may go out (cooldown / 429 block).
  final OtpSendGuard otpGuard = OtpSendGuard();
  final Map<String, Future<Response>> _otpInFlight = {};

  static dynamic _dataOf(Response? response) {
    final dynamic body = response?.body;
    return body is Map ? body['data'] : null;
  }

  static String _tokenOf(Response? response) {
    final dynamic data = _dataOf(response);
    return (data is Map ? data['token'] : null)?.toString().trim() ?? '';
  }

  static bool _isPhoneNotVerified(Response? response) {
    final dynamic data = _dataOf(response);
    return data is Map && data['is_phone_verified'] == 0;
  }

  Future<void> login(String countryCode, String phone, String password) async {
    if (_isLoading) return; // ignore double taps while a login is running
    _isLoading = true;
    update();

    final String fullPhoneNumber = countryCode + phone;
    bool tokenSaved = false;
    try {
      final Response? response = await authServiceInterface.login(phone: fullPhoneNumber, password: password);

      if (response == null) {
        effects.showMessage('something_went_wrong'.tr);
      } else if (response.statusCode == 200) {
        if (_isPhoneNotVerified(response)) {
          _startPhoneVerification(fullPhoneNumber);
        } else {
          final String token = _tokenOf(response);
          if (token.isEmpty) {
            // 200 but no token: never continue with an empty session.
            effects.showMessage('login_failed_try_again'.tr);
          } else {
            saveUserNumberAndPassword(countryCode, phone, password, true);
            tokenSaved = true;
            final bool ready = await _startSession(token);
            if (ready) {
              _navigateLogin(countryCode, phone, password);
            } else {
              tokenSaved = false; // _startSession already cleared it
            }
          }
        }
      } else if (response.statusCode == 202) {
        if (_isPhoneNotVerified(response)) {
          _startPhoneVerification(fullPhoneNumber);
        } else {
          // 202 for any other reason (e.g. account waiting for approval).
          effects.showMessage(ApiChecker.messageFor(response), isError: false);
        }
      } else {
        // 4xx / 5xx / no connection / HTML pages / rate limit ...
        effects.reportError(response);
      }
    } catch (_) {
      if (tokenSaved) await clearSharedData();
      effects.showMessage('login_failed_try_again'.tr);
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _startPhoneVerification(String fullPhoneNumber) {
    final ConfigModel? config = effects.config;
    if (config?.isFirebaseOtpVerification ?? false) {
      firebaseOtpSend(fullPhoneNumber, isLogin: true);
    } else if (config?.isSmsGateway ?? false) {
      effects.openVerification(fullPhoneNumber);
    } else {
      effects.showMessage('sms_gateway_not_integrate'.tr);
    }
  }

  /// Saves [token], starts the realtime/FCM side and loads the profile.
  /// Returns false (and drops the token again) when the profile cannot be
  /// loaded, so the app never keeps a half-initialised session.
  Future<bool> _startSession(String token) async {
    await setUserToken(token);
    effects.startPusher();
    updateToken().catchError((_) {});
    final Response? profile = await effects.loadProfile();
    if (profile?.statusCode != 200) {
      await clearSharedData();
      if (profile == null) effects.showMessage('login_failed_try_again'.tr);
      // otherwise the profile controller already showed the server message
      return false;
    }
    return true;
  }


  Future<void> externalLogin(String countryCode, String phone, String password) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.externalLogin(phone: countryCode+phone, password: password);
    if(response!.statusCode == 200){
      if (response.body['data']?['is_phone_verified'] == 0) {
        _isLoading = false;
        Get.to(() => VerificationScreen(number: countryCode + phone, fromOtpLogin: true));
        update();
        return;
      }
      saveUserNumberAndPassword(countryCode,phone,password,true);
      _isLoading = false;
      setUserToken(response.body['data']['token']);
      PusherHelper.initializePusher();
      updateToken();
      await Get.find<ProfileController>().getProfileInfo();
      _navigateLogin(countryCode, phone, password);
    }else if(response.statusCode == 202) {
      _isLoading = false;
      if(response.body['data']['is_phone_verified'] == 0) {
        Get.to(() =>  VerificationScreen(number: countryCode + phone, fromOtpLogin: true));
      }
    }else{
      _isLoading = false;
      ApiChecker.checkApi(response);
      Get.to(() =>  const SignInScreen());
    }

    update();

  }

  Future<void> logOut() async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.logOut();
    _isLoading = false;
    if(response!.statusCode == 200){
      Get.back();
      Get.offAll(() => const SignInScreen());
      showCustomSnackBar('successfully_logout'.tr, isError: false);
      clearSharedData();
      Get.find<RideController>().clearRideDetails();
      Get.find<ParcelController>().clearParcelModel();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
    }else{
      ApiChecker.checkApi(response);
      update();
    }
  }

  Future<void> register(SignUpBody signUpBody) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.registration(signUpBody: signUpBody);
    if(response!.statusCode == 200){
      String countryCode = CountryCodeHelper.getCountryCode(signUpBody.phone!) ?? '';
      String phoneWithoutCountryCode = signUpBody.phone!.startsWith(countryCode)
          ? signUpBody.phone!.substring(countryCode.length)
          : signUpBody.phone!;
      saveUserNumberAndPassword(countryCode, phoneWithoutCountryCode, signUpBody.password!, true);

      showCustomSnackBar('otp_sent_successfully'.tr, isError: false);
      Get.to(() => VerificationScreen(
        number: signUpBody.phone!,
        fromOtpLogin: true,
      ));
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();

  }

  void _navigateLogin(String code, String phone, String password){
    if (_isActiveRememberMe) {
      saveUserNumberAndPassword(code,phone, password,false);
    } else {
      clearUserNumberAndPassword();
    }
    effects.goDashboard(resetNavBar: true);
  }

  /// Sends an OTP. Calls for the same phone while one is in flight share the
  /// same request, a code sent less than the resend time ago is reused, and a
  /// 429 from the server blocks further sends until `Retry-After`.
  Future<Response> sendOtp(String phone) {
    final Future<Response>? inFlight = _otpInFlight[phone];
    if (inFlight != null) return inFlight;
    final Future<Response> request =
        _sendOtpOnce(phone).whenComplete(() {
      // Block body on purpose: returning the removed future from the callback
      // would make whenComplete wait on itself (deadlock).
      _otpInFlight.remove(phone);
    });
    _otpInFlight[phone] = request;
    return request;
  }

  Future<Response> _sendOtpOnce(String phone) async {
    final OtpSendDecision decision = otpGuard.check(phone,
        cooldownSeconds: OtpSendGuard.cooldownSecondsFor(effects.config?.otpResendTime));
    if (decision == OtpSendDecision.blockedByServer) {
      effects.showMessage('too_many_attempts_wait'.tr
          .replaceAll('{s}', '${otpGuard.blockedSecondsLeft()}'));
      return const Response(statusCode: 429);
    }
    if (decision == OtpSendDecision.reuseLastCode) {
      return const Response(statusCode: 200);
    }

    _isOtpSending = true;
    update();
    Response response;
    try {
      response = (await authServiceInterface.sendOtp(phone: phone)) ?? const Response(statusCode: 1);
    } catch (_) {
      response = const Response(statusCode: 1);
    }
    _isOtpSending = false;
    if (response.statusCode == 200) {
      otpGuard.markSent(phone);
      effects.showMessage('otp_sent_successfully'.tr, isError: false);
    } else {
      if (response.statusCode == 429) {
        otpGuard.markRateLimited(ApiChecker.retryAfterSeconds(response));
      }
      effects.reportError(response);
    }
    update();
    return response;
  }

  Future<void> firebaseOtpSend(String phoneNumber,{bool canRoute = true, bool isLogin = true})async {
    _isOtpSending = true;
    update();

    Response? response = await authServiceInterface.isUserRegistered(phone: phoneNumber);
    if(response!.statusCode == 200){
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          _isOtpSending = false;
          update();

          if(e.code == 'invalid-phone-number') {
            showCustomSnackBar('please_submit_a_valid_phone_number'.tr);
          }else{
            showCustomSnackBar(e.message?.replaceAll('_', ' ') ?? '');
          }

        },
        codeSent: (String vId, int? resendToken) {

          _isOtpSending = false;
          update();
          if(canRoute){
            Get.to(() =>  VerificationScreen(number: phoneNumber, fromOtpLogin: isLogin, session: vId));
          }

        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }else{
      _isOtpSending = false;
      ApiChecker.checkApi(response);
      update();
    }

  }


  Future<Response> otpVerification(String phone, String otp, {bool accountVerification = false,String? session}) async{
    otpVerifying = true;
    update();
    try {
      final bool firebase = effects.config?.isFirebaseOtpVerification ?? false;
      if (firebase && (session == null || session.isEmpty)) {
        effects.showMessage('something_went_wrong'.tr);
        return const Response(statusCode: 400);
      }
      final Response response = (firebase
              ? await authServiceInterface.verifyFirebaseOtp(phone: phone, otp: otp, session: session!)
              : await authServiceInterface.verifyOtp(phone: phone, otp: otp)) ??
          const Response(statusCode: 1);

      if (response.statusCode != 200) {
        effects.reportError(response);
        return response;
      }
      if (_isOtpMismatch(response)) {
        effects.reportError(response);
        return _asMismatch(response);
      }

      _verificationCode = '';
      updateVerificationCode('');
      if (!accountVerification) {
        effects.openResetPassword(phone);
        return response;
      }

      final String token = _tokenOf(response);
      if (token.isNotEmpty) {
        if (!await _startSession(token)) return const Response(statusCode: 502);
        if (_dataOf(response)['is_profile_verified'] == 0) {
          effects.openEditProfile();
        } else {
          effects.goDashboard();
        }
      } else {
        // Verified, but the server sent no token: sign in with the saved
        // credentials when we have them, otherwise ask the user to sign in.
        final String countryCode = CountryCodeHelper.getCountryCode(phone) ?? '';
        final String phoneWithoutCountryCode =
            phone.startsWith(countryCode) ? phone.substring(countryCode.length) : phone;
        final String savedPassword = getUserPassword(true);
        if (savedPassword.isNotEmpty) {
          login(countryCode, phoneWithoutCountryCode, savedPassword);
        } else {
          effects.openSignIn();
        }
      }
      return response;
    } catch (_) {
      effects.showMessage('something_went_wrong'.tr);
      return const Response(statusCode: 500);
    } finally {
      otpVerifying = false;
      update();
    }
  }

  static bool _isOtpMismatch(Response response) {
    final dynamic body = response.body;
    return body is Map && body['response_code'] == 'otp_mismatch_404';
  }

  /// The server answers a wrong code with HTTP 200 + `otp_mismatch_404`;
  /// give callers a real error status so they can show "incorrect OTP".
  static Response _asMismatch(Response response) =>
      Response(statusCode: 404, body: response.body, statusText: response.statusText);

  /// Logs in with a code via the dedicated `otp-login` endpoint.
  Future<Response> otpLogin(String phone, String otp, {bool fromOtpLogin = false}) async{
    _isLoading = true;
    update();
    try {
      final Response response = (await authServiceInterface.otpLogin(phone: phone, otp: otp)) ??
          const Response(statusCode: 1);
      if (response.statusCode != 200) {
        effects.reportError(response);
        return response;
      }
      if (_isOtpMismatch(response)) {
        effects.reportError(response);
        return _asMismatch(response);
      }
      final String token = _tokenOf(response);
      if (token.isEmpty) {
        // 200 but no token: never continue with an empty session.
        effects.showMessage('login_failed_try_again'.tr);
        return Response(statusCode: 502, body: response.body);
      }
      if (fromOtpLogin) {
        if (!await _startSession(token)) return const Response(statusCode: 502);
        if (_dataOf(response)['is_profile_verified'] == 0) {
          effects.openEditProfile();
        } else {
          effects.goDashboard();
        }
      } else {
        await setUserToken(token);
        effects.openResetPassword(phone);
      }
      return response;
    } catch (_) {
      effects.showMessage('login_failed_try_again'.tr);
      return const Response(statusCode: 500);
    } finally {
      _isLoading = false;
      update();
    }
  }


  Future<void> forgetPassword(String phone) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.forgetPassword(phone);
    if (response!.statusCode  == 200) {
      _isLoading = false;
      showCustomSnackBar('successfully_sent_otp'.tr, isError: false);
    }else{
      _isLoading = false;
      showCustomSnackBar('invalid_number'.tr);
    }
    update();
  }

  Future<void> updateToken() async {
    await authServiceInterface.updateToken();
  }

  Future<void> resetPassword(String phone, String password) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.resetPassword(phone, password);
    if (response!.statusCode == 200) {

      showCustomSnackBar('password_change_successfully'.tr, isError: false);
      Get.offAll(()=> const SignInScreen());
    }else{
      showCustomSnackBar(response.body['message']);
    }
    _isLoading = false;
    update();
  }

  Future<void> changePassword(String password, String newPassword) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.changePassword(password, newPassword);
    if (response!.statusCode == 200) {
      Get.back();
      showCustomSnackBar('password_change_successfully'.tr, isError: false);
    }else{
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  void updateVerificationCode(String query, {bool isUpdate = true}) {
    _verificationCode = query;
    if(isUpdate){
      update();
    }
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  void setRememberMe() {
    _isActiveRememberMe = true;
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  Future <bool> clearSharedData() async {
    return authServiceInterface.clearSharedData();
  }

  void saveUserNumberAndPassword(String code,String number, String password,bool externalUser) {
    authServiceInterface.saveUserNumberAndPassword(code, number, password, externalUser);
  }

  String getUserNumber(bool externalUser) {
    return authServiceInterface.getUserNumber(externalUser);
  }

  String getLoginCountryCode(bool externalUser) {
    return authServiceInterface.getLoginCountryCode(externalUser);
  }
  String getUserPassword(bool externalUser) {
    return authServiceInterface.getUserPassword(externalUser);
  }

  Future<bool> clearUserNumberAndPassword() async {
    return authServiceInterface.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  Future <void> setUserToken(String token) async{
    authServiceInterface.saveUserToken(token);
  }

  Future<void> permanentlyDelete() async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.permanentlyDelete();
    if(response!.statusCode == 200){
      Get.back();
      Get.offAll(const SignInScreen());
      showCustomSnackBar('successfully_delete_account'.tr, isError: false);
      clearSharedData();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
    }else{
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }


  void saveFindingRideCreatedTime(){
    authServiceInterface.saveRideCreatedTime(DateTime.now());
  }

  void remainingFindingRideTime() async{
    String time = await authServiceInterface.remainingTime();
    if(time.isNotEmpty){
      DateTime oldTime = DateTime.parse(time);
      DateTime newTime = DateTime.now();
      int diff =  newTime.difference(oldTime).inSeconds;
      Get.find<RideController>().resumeCountingTimeState(diff);
    }
  }
}


/// Side effects used by [AuthController] (navigation, snackbars, other
/// controllers). Replaced with a fake in unit tests.
class AuthSideEffects {
  const AuthSideEffects();

  ConfigModel? get config => Get.find<ConfigController>().config;
  Future<Response?> loadProfile() => Get.find<ProfileController>().getProfileInfo();
  void startPusher() => PusherHelper.initializePusher();
  void showMessage(String message, {bool isError = true}) => showCustomSnackBar(message, isError: isError);
  void reportError(Response response) => ApiChecker.checkApi(response);
  void openVerification(String number) => Get.to(() => VerificationScreen(number: number, fromOtpLogin: true));
  void openResetPassword(String phone) => Get.to(() => ResetPasswordScreen(phoneNumber: phone));
  void openSignIn() => Get.offAll(() => const SignInScreen());
  void openEditProfile() => Get.offAll(() => const EditProfileScreen(fromLogin: true));
  void goDashboard({bool resetNavBar = false}) {
    final BottomMenuController menu = Get.find<BottomMenuController>();
    if (resetNavBar) menu.resetNavBar();
    menu.navigateToDashboard();
  }
}
