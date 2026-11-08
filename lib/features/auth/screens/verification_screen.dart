import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:ride_sharing_user_app/common_widgets/rate_limit_wait_hint.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/phone_mask_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';

class VerificationScreen extends StatefulWidget {
  final String number;
  final bool fromOtpLogin;
  final String? session;

  /// True when the code was requested from the "login with OTP" screen: the
  /// dedicated `otp-login` endpoint is used so the server returns a session
  /// token (the generic `otp-verification` endpoint does not log anyone in).
  final bool loginWithOtp;
  const VerificationScreen({super.key,required this.number,  this.fromOtpLogin = false, this.session, this.loginWithOtp = false});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  int? _seconds = 0;
  final StreamController<ErrorAnimationType> _errorController = StreamController<ErrorAnimationType>();
  String errorText = '';

  @override
  void initState() {
    super.initState();
    Get.find<AuthController>().updateVerificationCode('',isUpdate: false);
    _startTimer();
  }

  void _startTimer() {
    // Always stop the previous timer first: restarting on "resend" used to
    // leave two timers running (the countdown then ran at double speed).
    _timer?.cancel();
    final int resend = Get.find<ConfigController>().config?.otpResendTime ?? 60;
    _seconds = resend > 0 ? resend : 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int left = (_seconds ?? 0) - 1;
      if (left <= 0) timer.cancel();
      setState(() => _seconds = left < 0 ? 0 : left);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _errorController.close();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: BodyWidget(
          appBar: AppBarWidget(title: 'verification'.tr, showBackButton: true, centerTitle: true),
          body: Center(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeLarge),
            child: GetBuilder<AuthController>(builder: (authController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  FutureBuilder<String>(
                      future: loadSvgAndChangeColors(Images.verificationGraphics, Theme.of(context).primaryColor),
                      builder: (context, snapshot){
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return SvgPicture.string(
                              snapshot.data!
                          );
                        }
                        return SvgPicture.asset(Images.verificationGraphics);
                      }
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                    'verification'.tr,
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeTwenty),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    '${'we_have_send_a_varification_code_to'.tr} ${maskPhoneNumber(widget.number)}',
                    style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),fontSize: Dimensions.fontSizeSmall),
                    maxLines: 2,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSignUp),

                  (Get.find<ConfigController>().config?.isDemo ?? true) ? 
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(
                      bottom: Dimensions.paddingSizeOverLarge,
                    ),
                    child: Text('for_demo_purpose_use'.tr, style: textSemiBold.copyWith(
                      color: Theme.of(context).disabledColor,
                    )),
                  ) : 
                  const SizedBox(height:  Dimensions.paddingSizeDefault),

                  SizedBox(
                    width: Get.width - 60,
                    child: PinCodeTextField(
                      length: 6,
                      cursorColor: Theme.of(context).textTheme.bodyMedium?.color,
                      cursorHeight: 20,
                      autoFocus: true,
                      appContext: context,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.slide,
                      errorAnimationController: _errorController,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        fieldHeight: 40,
                        fieldWidth: 40,
                        borderWidth: 1,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        selectedColor: Theme.of(context).hintColor.withValues(alpha:0.2),
                        selectedFillColor: Get.isDarkMode ? Colors.grey.withValues(alpha:0.6) : Colors.white,
                        inactiveFillColor: Theme.of(context).cardColor,
                        inactiveColor: Theme.of(context).hintColor.withValues(alpha:0.2),
                        activeColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                        activeFillColor: Theme.of(context).cardColor,
                        errorBorderColor: Colors.red,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      onChanged: (query){
                        errorText = '';
                        authController.updateVerificationCode(query);
                      },
                      beforeTextPaste: (text) => true,
                      textStyle: textSemiBold.copyWith(),

                      pastedTextStyle: textRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                    ),
                  ),

                  if(errorText.isNotEmpty)
                    Center(child: Text(errorText, style: textRegular.copyWith(color: Theme.of(context).colorScheme.error))),

                  !authController.otpVerifying ?
                  Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: ButtonWidget(
                      buttonText: 'verify'.tr,
                      radius: 50,
                      textColor: authController.verificationCode.length == 6 ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyMedium?.color,
                      onPressed: authController.verificationCode.length == 6 ? () {
                        final bool useOtpLogin = widget.loginWithOtp && (widget.session == null || widget.session!.isEmpty);
                        (useOtpLogin
                            ? authController.otpLogin(widget.number, authController.verificationCode, fromOtpLogin: true)
                            : authController.otpVerification(
                                widget.number, authController.verificationCode, accountVerification: widget.fromOtpLogin,
                                session: widget.session)
                        ).then((value){
                          // Only a rejected code is "incorrect"; rate limits, network and
                          // server errors already showed their own message.
                          if(mounted && const [400, 403, 404, 422].contains(value.statusCode)){
                            setState(() => errorText = 'incorrect_otp'.tr);
                            _errorController.add(ErrorAnimationType.shake);
                          }
                        });
                      } : null,
                    ),
                  ) :
                  SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0),
                  const RateLimitWaitHint(),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('did_not_receive_the_code'.tr,style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:.6))),

                      _seconds! <= 0 ?
                      TextButton(
                        onPressed: () async {
                          if(Get.find<ConfigController>().config?.isFirebaseOtpVerification ?? false){

                            await authController.firebaseOtpSend(widget.number,canRoute: false);
                            showCustomSnackBar('otp_sent_successfully'.tr, isError: false);

                            _startTimer();

                          }else if(Get.find<ConfigController>().config?.isSmsGateway ?? false){
                            authController.sendOtp(widget.number).then((value){
                              if(mounted && value.statusCode == 200) {
                                _startTimer();
                              }
                            });
                          }else{
                            showCustomSnackBar('sms_gateway_not_integrate'.tr);
                          }
                        },
                        child: Text('resend_code'.tr,style: textBold.copyWith(color: Theme.of(context).primaryColorDark.withValues(alpha:.6)),
                            textAlign: TextAlign.end),
                      ) :
                      Row(children: [
                        Text(
                          '${'resend_it'.tr} ',
                        ),

                        Text('(${_seconds}s)', style: textRegular.copyWith(color: Theme.of(context).primaryColor)),
                      ])
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                ],
              );
            }),
          )),
        ),
      ),
    );
  }
}
