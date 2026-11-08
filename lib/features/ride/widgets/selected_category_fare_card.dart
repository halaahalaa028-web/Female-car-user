import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SelectedCategoryFareCard extends StatelessWidget {
  const SelectedCategoryFareCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return GetBuilder<RideController>(builder: (rideController) {
      return GetBuilder<CategoryController>(builder: (categoryController) {
        final categories = categoryController.categoryList;
        if (categories == null || categories.isEmpty) {
          return const SizedBox();
        }

        final selectedIndex = rideController.rideCategoryIndex < categories.length
            ? rideController.rideCategoryIndex
            : 0;
        final selectedCategory = categories[selectedIndex];

        final hasDiscount = rideController.discountAmount.toDouble() > 0;
        final finalFare = hasDiscount
            ? rideController.discountFare
            : rideController.estimatedFare;
        final fareText =
            finalFare > 0 ? PriceConverter.convertPrice(finalFare) : null;
        final originalFareText =
            (hasDiscount && rideController.estimatedFare > 0)
                ? PriceConverter.convertPrice(rideController.estimatedFare)
                : null;
        final discountBadgeText = hasDiscount
            ? 'خصم ${PriceConverter.convertPrice(rideController.discountAmount)}'
            : null;

        final imageBase =
            Get.find<ConfigController>().config?.imageBaseUrl?.vehicleCategory;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: isDark ? 0.40 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Vehicle thumbnail
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (selectedCategory.image != null && selectedCategory.image!.isNotEmpty)
                      ? (selectedCategory.id == '0'
                          ? Image.asset(
                              selectedCategory.image ?? '',
                              fit: BoxFit.contain,
                            )
                          : ImageWidget(
                              image: '$imageBase/${selectedCategory.image}',
                              fit: BoxFit.contain,
                              placeholder: Images.car,
                            ))
                      : Image.asset(
                          Images.car,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Category title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            selectedCategory.name ?? '',
                            style: textBold.copyWith(
                              fontSize: 16.5,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (discountBadgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFFF7675)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              discountBadgeText,
                              style: textBold.copyWith(
                                fontSize: 9.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'fast_and_affordable'.tr.isNotEmpty &&
                              'fast_and_affordable'.tr != 'fast_and_affordable'
                          ? 'fast_and_affordable'.tr
                          : 'أسرع وصول • سيارة مريحة',
                      style: textRegular.copyWith(
                        fontSize: 12.5,
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Prominent Fare display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fareText != null)
                    Text(
                      fareText,
                      style: textRobotoBold.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                      ),
                    ),
                  if (originalFareText != null)
                    Text(
                      originalFareText,
                      style: textRobotoRegular.copyWith(
                        fontSize: 13,
                        color: theme.hintColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      });
    });
  }
}
