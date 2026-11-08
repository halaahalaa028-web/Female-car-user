import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/widgets/voice_search_dialog.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeSearchWidget extends StatelessWidget {
  const HomeSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Get.isDarkMode ? 0.25 : 0.07,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => Get.to(() => const SetDestinationScreen()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Image.asset(
                  Images.homeSearchIcon,
                  color: primaryColor,
                  height: 20,
                  width: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'where_to_go'.tr,
                    style: textRegular.copyWith(
                        color: theme.textTheme.bodyMedium!.color!
                            .withValues(alpha: 0.5),
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Get.dialog(const VoiceSearchDialog(),
                        barrierDismissible: false);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      Images.microPhoneIcon,
                      color: primaryColor,
                      height: 18,
                      width: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
