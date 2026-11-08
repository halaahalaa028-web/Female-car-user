import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/custom_text_field.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class RideNoteWidget extends StatelessWidget {
  const RideNoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return GetBuilder<RideController>(builder: (rideController) {
      final hasNote = rideController.noteController.text.trim().isNotEmpty;

      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showNoteDialog(context, rideController),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasNote
                      ? theme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasNote
                        ? theme.primaryColor.withValues(alpha: 0.4)
                        : theme.hintColor.withValues(alpha: 0.16),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasNote
                          ? Icons.sticky_note_2_rounded
                          : Icons.edit_note_rounded,
                      size: 20,
                      color: hasNote ? theme.primaryColor : theme.hintColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasNote
                            ? rideController.noteController.text
                            : 'add_note'.tr,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault - 0.5,
                          color: hasNote
                              ? (isDark ? Colors.white : Colors.black87)
                              : theme.hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasNote) ...[
                      InkWell(
                        onTap: () {
                          rideController.noteController.clear();
                          rideController.update();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (rideController.isCouponApplicable) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'coupon_applied'.tr,
                    style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  void _showNoteDialog(BuildContext context, RideController rideController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'add_note'.tr,
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  prefix: false,
                  borderRadius: 12,
                  hintText: 'add_note'.tr,
                  controller: rideController.noteController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    rideController.update();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'done'.tr.isNotEmpty ? 'done'.tr : 'تأكيد',
                    style: textBold.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
