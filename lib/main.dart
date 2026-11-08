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

  // Firebase is configured only here (not in the native AppDelegate).
  // Keep a Firebase startup error from preventing Flutter's first frame.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Load local dependencies and translations before creating the app.
  final Map<String, Map<String, String>> languages = await di.init();

  RemoteMessage? remoteMessage;
  if (firebaseReady) {
    try {
      remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
    } catch (error, stackTrace) {
      debugPrint('Initial notification retrieval failed: $error');
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

  // Show Flutter UI before optional notification setup.
  runApp(
    MyApp(
      languages: languages,
      notificationData: remoteMessage?.data,
    ),
  );

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    try {
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
