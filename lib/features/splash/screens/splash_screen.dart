import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  bool _startupRoutingStarted = false;
  bool? _lastConnectionState;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.forward();

    // Initialize local preferences, but do not wait for a connectivity event
    // before starting the app's navigation flow.
    Get.find<ConfigController>().initSharedData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startApplicationRouting();
    });

    _listenForConnectivityChanges();
  }

  void _startApplicationRouting() {
    if (_startupRoutingStarted || !mounted) return;
    _startupRoutingStarted = true;
    debugPrint('Splash: starting login/routing flow without waiting for connectivity stream');
    LoginHelper().handleIncomingLinks(widget.notificationData, widget.userName);
  }

  void _listenForConnectivityChanges() {
    _onConnectivityChanged = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!mounted) return;
      final bool isConnected =
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet);

      // Connectivity is only used for feedback. It must never control
      // whether the login screen is allowed to open.
      if (_lastConnectionState == isConnected) return;
      _lastConnectionState = isConnected;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: Duration(seconds: isConnected ? 2 : 5),
            content: Text(
              isConnected ? 'connected'.tr : 'no_connection'.tr,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }, onError: (Object error) {
      debugPrint('Connectivity stream error: $error');
      // Routing already started independently; ignore plugin stream failures.
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(Images.logo, width: 200, height: 200),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Theme.of(context).primaryColor,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
