import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/firebase_options.dart';
import 'package:ride_sharing_user_app/helper/notification_helper.dart';
import 'package:ride_sharing_user_app/helper/di_container.dart' as di;
import 'package:ride_sharing_user_app/helper/route_helper.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/localization/messages.dart';
import 'package:ride_sharing_user_app/theme/dark_theme.dart';
import 'package:ride_sharing_user_app/theme/light_theme.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep Flutter rendering even if a startup dependency fails.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter framework error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              'حدث خطأ أثناء عرض التطبيق:\n${details.exceptionAsString()}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

  // Start the first Flutter frame before Firebase, preferences, or assets load.
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Widget? _readyApp;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    bool firebaseReady = false;

    try {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (error, stackTrace) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      // If this fails, the user now sees the actual startup error instead
      // of an indefinitely black native launch screen.
      final Map<String, Map<String, String>> languages = await di.init();

      RemoteMessage? remoteMessage;
      if (firebaseReady) {
        try {
          FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
          remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
        } catch (error, stackTrace) {
          debugPrint('Firebase Messaging startup failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      try {
        await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp],
        );
      } catch (error) {
        debugPrint('Could not set preferred orientation: $error');
      }

      if (!mounted) return;
      setState(() {
        _readyApp = MyApp(
          languages: languages,
          notificationData: remoteMessage?.data,
        );
      });

      // Notifications are optional and must never block the first app screen.
      if (firebaseReady) {
        try {
          await NotificationHelper.initialize(
            flutterLocalNotificationsPlugin,
          );
        } catch (error, stackTrace) {
          debugPrint('Notification initialization failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('FATAL APP STARTUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _startupError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_readyApp != null) return _readyApp!;

    if (_startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 52),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تشغيل التطبيق',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'حدث خطأ أثناء تجهيز التطبيق. تفاصيل الخطأ:',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _startupError!,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text(
                'جاري تجهيز التطبيق...',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  final Map<String, dynamic>? notificationData;

  const MyApp({super.key, required this.languages, this.notificationData});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: Get.key,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
          ),
          theme: themeController.darkTheme ? darkTheme : lightTheme,
          locale: localizeController.locale,
          initialRoute: RouteHelper.getSplashRoute(
            notificationData: notificationData,
          ),
          getPages: RouteHelper.routes,
          translations: Messages(languages: languages),
          fallbackLocale: Locale(
            AppConstants.languages[0].languageCode,
            AppConstants.languages[0].countryCode,
          ),
          defaultTransition: Transition.fadeIn,
          smartManagement: SmartManagement.keepFactory,
          transitionDuration: const Duration(milliseconds: 500),
          builder: (context, child) {
            return SafeArea(
              top: false,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(0.95),
                ),
                child: child!,
              ),
            );
          },
        );
      });
    });
  }
}
