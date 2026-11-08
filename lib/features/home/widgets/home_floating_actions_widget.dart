import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/screens/safety_setup_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeFloatingActionsWidget extends StatelessWidget {
  const HomeFloatingActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSafetyButton(theme, isDark),
        _buildLocationButton(theme, isDark),
      ],
    );
  }

  Widget _buildSafetyButton(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () => Get.to(() => const SafetySetupScreen()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                color: theme.primaryColor,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'safety'.tr,
              style: textSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall + 1,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () {
        final mapController = Get.find<MapController>().mapController;
        Get.find<LocationController>()
            .getCurrentLocation(mapController: mapController);
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.hintColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.my_location_rounded,
            color: theme.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}
