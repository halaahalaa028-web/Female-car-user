import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/address/controllers/address_controller.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/address/screens/my_address.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeQuickDestinationsWidget extends StatelessWidget {
  const HomeQuickDestinationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<AddressController>(
      builder: (addressController) {
        Address? homeAddr;
        Address? officeAddr;

        if (addressController.addressList != null) {
          for (final addr in addressController.addressList!) {
            if (addr.addressLabel == 'home' && homeAddr == null) {
              homeAddr = addr;
            } else if (addr.addressLabel == 'office' && officeAddr == null) {
              officeAddr = addr;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _QuickChip(
                theme: theme,
                icon: Icons.home_rounded,
                label: 'home'.tr,
                onTap: () => _navToDestination(homeAddr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                theme: theme,
                icon: Icons.work_rounded,
                label: 'office'.tr,
                onTap: () => _navToDestination(officeAddr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickChip(
                theme: theme,
                icon: Icons.bookmark_rounded,
                label: 'saved_address'.tr,
                onTap: () => Get.to(() => const MyAddressScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navToDestination(Address? addr) {
    if (Get.isRegistered<RideController>()) {
      Get.find<RideController>().setSelectedCategoryFilter('رحلة');
    }
    if (addr != null) {
      Get.to(() => SetDestinationScreen(address: addr));
    } else {
      Get.to(() => const SetDestinationScreen());
    }
  }
}

class _QuickChip extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.hintColor.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
