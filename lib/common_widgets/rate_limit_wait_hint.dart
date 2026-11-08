import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/auth_request_throttle.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

/// Small hint shown while an auth request is deliberately held back to respect
/// the server's rate limit ("please wait...").
class RateLimitWaitHint extends StatelessWidget {
  const RateLimitWaitHint({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthRequestThrottle.isWaiting,
      builder: (context, waiting, _) {
        if (!waiting) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Center(
            child: Text(
              'please_wait_retrying'.tr,
              textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        );
      },
    );
  }
}
