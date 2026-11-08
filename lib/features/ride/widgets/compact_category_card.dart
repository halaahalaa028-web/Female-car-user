import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class CompactCategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final int index;
  final String? fareText;
  final String? originalFareText;
  final String? discountText;
  final Function(void)? onTap;

  final bool showFare;

  const CompactCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.index,
    this.fareText,
    this.originalFareText,
    this.discountText,
    this.onTap,
    this.showFare = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;
    final imageBase =
        Get.find<ConfigController>().config?.imageBaseUrl?.vehicleCategory;

    return InkWell(
      onTap: () {
        Get.find<RideController>().setRideCategoryIndex(index);
        if (onTap != null) {
          onTap!(null);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 118,
        height: 114,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.hintColor.withValues(alpha: 0.16),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? theme.primaryColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Distinctive Discount badge or selected indicator
            SizedBox(
              height: 17,
              child: discountText != null && discountText!.isNotEmpty
                  ? _buildDiscountTag(theme)
                  : (isSelected
                      ? Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        )
                      : const SizedBox()),
            ),

            // Center: Enlarged Vehicle Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (category.image != null && category.image!.isNotEmpty)
                      ? (category.id == '0'
                          ? Image.asset(
                              category.image ?? '',
                              fit: BoxFit.contain,
                            )
                          : ImageWidget(
                              image: '$imageBase/${category.image}',
                              fit: BoxFit.contain,
                              placeholder: Images.car,
                            ))
                      : Image.asset(
                          Images.car,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),

            // Bottom: Title & optional Fare
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                category.name ?? '',
                style: textBold.copyWith(
                  fontSize: 14.0,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showFare && fareText != null && fareText!.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fareText!,
                  style: textRobotoBold.copyWith(
                    fontSize: 12.5,
                    color: isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTag(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFF7675)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        discountText!,
        style: textBold.copyWith(
          fontSize: 8.5,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
