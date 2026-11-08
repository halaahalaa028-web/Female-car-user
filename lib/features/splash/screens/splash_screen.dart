import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
// import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  final String? userName;
  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late AnimationController _controller;
// Typed as Animation<double>

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    // REMOVED: ..addListener(() { setState(() {}); });
    // We don't want to rebuild the whole screen anymore.

    _controller.forward();

    Get.find<ConfigController>().initSharedData();
    _checkConnectivity();
  }

  void _checkConnectivity() {
    bool isFirst = true;
    _onConnectivityChanged = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      // Safety check: Ensure the widget is still mounted before showing SnackBar
      if (!mounted) return;

      if (!isFirst || !isConnected) {
        ScaffoldMessenger.of(Get.context!).removeCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(
            isConnected ? 'connected'.tr : 'no_connection'.tr,
            textAlign: TextAlign.center,
          ),
        ));
        if (isConnected) {
          LoginHelper()
              .handleIncomingLinks(widget.notificationData, widget.userName);
        }
      } else {
        ScaffoldMessenger.of(Get.context!).removeCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        LoginHelper()
            .handleIncomingLinks(widget.notificationData, widget.userName);
      }
      isFirst = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _onConnectivityChanged?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        alignment: Alignment.bottomCenter,
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(Images.logo, width: 200, height: 200)),
            const SizedBox(height: 30),
            SizedBox(
              width : 150,
              child: LinearProgressIndicator(
                color: Theme.of(context).primaryColor,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Stack(
            //   alignment: AlignmentDirectional.bottomCenter,
            //   children: [
            //     // AnimatedBuilder rebuilds ONLY this part
            //     AnimatedBuilder(
            //       animation: _animation,
            //       // The 'child' argument allows us to pass the heavy SVG widgets ONCE.
            //       // They will NOT be rebuilt on every frame, only transformed.
            //       child: Column(
            //         children: [
            //           Padding(
            //             // Since padding changes, we apply it in the builder,
            //             // but we keep the SVG itself in the static child if possible,
            //             // or just simplify the structure.
            //             // Here, we split it: The SVG is static, the container moves.
            //             padding:
            //                 EdgeInsets.zero, // We handle padding in builder
            //             child: Image.asset(Images.logo),
            //           ),
            //           SizedBox(height: Get.height * 0.25),
            //           SvgPicture.asset(Images.splashSvgBackground)
            //         ],
            //       ),
            //       builder: (context, child) {
            //         final double value =
            //             _animation.value; // Direct double access

            //         return Transform.translate(
            //           // Direct calculation, no parsing
            //           offset: Offset(0, 320 - (320 * value)),
            //           child: Column(
            //             children: [
            //               Image.asset(Images.logo)
            //               // Opacity(
            //               //   opacity: value,
            //               //   child: Padding(
            //               //     padding: EdgeInsets.only(left: 120 - (120 * value)),
            //               //     // We use the 'child' passed from above to avoid rebuilding SVGs
            //               //     child: SvgPicture.asset(Images.splashSvgLogo),
            //               //   ),
            //               // ),
            //               // SizedBox(height: Get.height * 0.25),
            //               // SvgPicture.asset(Images.splashSvgBackground),
            //             ],
            //           ),
            //         );
            //       },
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
