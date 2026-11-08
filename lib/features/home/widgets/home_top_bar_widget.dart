import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/notification/screens/notification_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wallet_screen.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeTopBarWidget extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback? onScanTap;

  const HomeTopBarWidget({
    super.key,
    required this.onMenuTap,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Pill: Hamburger Menu + "Hi first_name"
          GetBuilder<ProfileController>(
            builder: (profileController) {
              final firstName = profileController.customerFirstName();
              final displayName = firstName.isNotEmpty ? firstName : 'user'.tr;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMenuTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.only(left: 6, right: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.hintColor.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_rounded,
                            color: theme.primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hi, $displayName',
                          style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Right Actions: Wallet Balance Pill + Notification Bell
          GetBuilder<ProfileController>(
            builder: (profileController) {
              final balance = profileController
                  .profileModel?.data?.wallet?.walletBalance;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (balance != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.to(() => const WalletScreen()),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: theme.hintColor.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.35 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PriceConverter.convertPrice(balance),
                                style: textBold.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.to(() => const NotificationScreen()),
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
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
