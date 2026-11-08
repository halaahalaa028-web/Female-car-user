import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/category_widget.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/category_shimmer.dart';
import 'package:ride_sharing_user_app/features/parcel/screens/parcel_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GetBuilder<CategoryController>(builder: (categoryController) {
      return SizedBox(
        height: 115,
        width: Get.width,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            categoryController.categoryList != null
                ? categoryController.categoryList!.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: categoryController.categoryList!.length,
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return CategoryWidget(
                              index: index,
                              category:
                                  categoryController.categoryList![index]);
                        })
                    : const SizedBox()
                : const CategoryShimmer(),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => Get.to(() => const ParcelScreen()),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 80,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.cardColor,
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: Get.isDarkMode ? 0.2 : 0.04,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(
                              Dimensions.paddingSizeSmall),
                          child: Image.asset(Images.parcel),
                        ),
                        Text(
                          'parcel'.tr,
                          style: textMedium.copyWith(
                            color: theme.textTheme.bodyMedium!.color!
                                .withValues(alpha: 0.9),
                            fontSize: Dimensions.fontSizeExtraSmall,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                ),
              ),
            ),
            if (Get.find<ConfigController>().config?.scheduleTripStatus ??
                false)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => Get.to(() => const SetDestinationScreen(
                      rideType: RideType.scheduleRide)),
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: theme.cardColor,
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.12),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: Get.isDarkMode ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall),
                            child: Image.asset(Images.scheduleTripIcon),
                          ),
                          Text(
                            'schedule_trip'.tr,
                            style: textMedium.copyWith(
                              color: theme.textTheme.bodyMedium!.color!
                                  .withValues(alpha: 0.9),
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
