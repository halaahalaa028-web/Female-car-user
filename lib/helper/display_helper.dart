import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/responsive_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

void customPrint(String message) {
  if(kDebugMode) {
    print(message);
  }
}

void showCustomSnackBar(String message, {bool isError = true, int seconds = 3,String? subMessage}) {
  // Untranslated server keys arrive as "lang.some_message": never show the prefix.
  message = message.replaceFirst(RegExp(r'^lang\.'), '');
  subMessage = subMessage?.replaceFirst(RegExp(r'^lang\.'), '');
  if (Get.context == null) return; // no UI yet (e.g. very early startup / unit tests)
  if (Get.isSnackbarOpen) {
    // GetX can throw a failed assertion here when the snackbar is already being
    // removed; that used to abort the caller (e.g. leave the splash stuck).
    // (The error is raised asynchronously, so it has to be caught on the Future.)
    Future<void>.sync(() => Get.closeCurrentSnackbar()).catchError((_) {});
  }
  Get.showSnackbar(GetSnackBar(
    dismissDirection: DismissDirection.horizontal,
    margin: const EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(
      right: ResponsiveHelper.isDesktop ? Get.context!.width*0.7 : Dimensions.paddingSizeSmall,
    ),
    duration: Duration(seconds: seconds),
    backgroundColor: Get.isDarkMode ? Colors.white : Theme.of(Get.context!).textTheme.titleMedium!.color!,
    borderRadius: Dimensions.paddingSizeSmall,
    messageText: Row(children: [
      Image.asset(isError ? Images.errorMessageIcon : Images.successMessageIcon,height: 20,width: 20,),

      const SizedBox(width: Dimensions.paddingSize,),
      Expanded(child: SizedBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message, style: textMedium.copyWith(color: Get.isDarkMode ? Theme.of(Get.context!).textTheme.titleMedium!.color : Colors.white)),
        subMessage != null ?
        Text(subMessage, style: textMedium.copyWith(color: Colors.white.withValues(alpha:0.75))) : const SizedBox(),

      ]))),

    ]),

  ));

}
