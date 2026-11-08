import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class RateLimitBlockedDialog extends StatelessWidget {
  final String remainingTime;

  const RateLimitBlockedDialog({super.key, required this.remainingTime});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      surfaceTintColor: Theme.of(context).cardColor,
      backgroundColor: Theme.of(context).canvasColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      clipBehavior: Clip.none,
      child: SizedBox(
        width: 450,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Text(
                'rate_limit_title'.tr,
                textAlign: TextAlign.center,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                'rate_limit_description'.tr,
                textAlign: TextAlign.center,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              if (remainingTime.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Flexible(
                        child: Text(
                          '${'time_remaining'.tr}: $remainingTime',
                          textAlign: TextAlign.center,
                          style: textSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],

              ButtonWidget(
                buttonText: 'ok'.tr,
                onPressed: () => Get.back(),
                radius: Dimensions.radiusSmall,
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
