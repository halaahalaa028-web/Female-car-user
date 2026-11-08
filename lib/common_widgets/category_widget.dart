import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class CategoryWidget extends StatelessWidget {
  final Category category;
  final bool? isSelected;
  final bool fromSelect;
  final int index;
  final Function(void)? onTap;
  final String? fareText;
  final String? originalFareText;
  final String? discountText;
  final String? subtitle;

  const CategoryWidget({
    super.key,
    required this.category,
    this.isSelected,
    this.fromSelect = false,
    required this.index,
    this.onTap,
    this.fareText,
    this.originalFareText,
    this.discountText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;
    final isSelectedState = isSelected ?? false;

    return InkWell(
      onTap: () {
        Get.find<RideController>().setRideCategoryIndex(index);
        if (onTap != null) {
          onTap!(null);
        }
        if (!fromSelect) {
          Get.to(() => const SetDestinationScreen());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelectedState
              ? theme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.04)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelectedState
                ? theme.primaryColor
                : theme.hintColor.withValues(alpha: 0.14),
            width: isSelectedState ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelectedState
                  ? theme.primaryColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: isSelectedState ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _buildLeadingImage(theme, isDark, isSelectedState),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCenterInfo(theme, isSelectedState),
            ),
            const SizedBox(width: 10),
            _buildTrailingSection(theme, isSelectedState),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingImage(ThemeData theme, bool isDark, bool isSelected) {
    final imageBase =
        Get.find<ConfigController>().config?.imageBaseUrl?.vehicleCategory;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? theme.canvasColor : const Color(0xFFF7F8FA)),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.25)
              : theme.hintColor.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: category.id == '0'
            ? Image.asset(
                category.image ?? '',
                fit: BoxFit.contain,
              )
            : ImageWidget(
                image: '$imageBase/${category.image}',
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _buildCenterInfo(ThemeData theme, bool isSelected) {
    final subtitleText = subtitle ??
        ('fast_and_affordable'.tr.isNotEmpty &&
                'fast_and_affordable'.tr != 'fast_and_affordable'
            ? 'fast_and_affordable'.tr
            : 'أسرع وصول • سيارة مريحة');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                category.name ?? '',
                style: textBold.copyWith(
                  color: isSelected
                      ? theme.primaryColor
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: Dimensions.fontSizeDefault + 1,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (discountText != null && discountText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildDiscountBadge(theme),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          style: textRegular.copyWith(
            color: theme.hintColor,
            fontSize: Dimensions.fontSizeExtraSmall,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDiscountBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 9,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            discountText!,
            style: textBold.copyWith(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingSection(ThemeData theme, bool isSelected) {
    final hasFare = fareText != null && fareText!.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFare) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fareText!,
                style: textRobotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.primaryColor
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
              if (originalFareText != null && originalFareText!.isNotEmpty)
                Text(
                  originalFareText!,
                  style: textRobotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: theme.hintColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? theme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : theme.hintColor.withValues(alpha: 0.35),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      ],
    );
  }
}
