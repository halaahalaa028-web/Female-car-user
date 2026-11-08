import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/address/screens/my_address.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/my_level/screens/my_level_screen.dart';
import 'package:ride_sharing_user_app/features/my_offer/screens/my_offer_screen.dart';
import 'package:ride_sharing_user_app/features/notification/screens/notification_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/edit_profile_screen.dart';
import 'package:ride_sharing_user_app/features/safety_setup/screens/safety_setup_screen.dart';
import 'package:ride_sharing_user_app/features/settings/screens/setting_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/support/screens/support_screen.dart';
import 'package:ride_sharing_user_app/features/trip/screens/trip_screen.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wallet_screen.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;
    final items = _menuItems(context);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      backgroundColor: theme.cardColor,
      elevation: 10,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme, isDark),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                itemCount: items.length,
                separatorBuilder: (_, i) => i == items.length - 2
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 0.8,
                          color: theme.primaryColor.withValues(alpha: 0.12),
                        ),
                      )
                    : const SizedBox(height: 4),
                itemBuilder: (ctx, index) =>
                    _buildMenuItem(ctx, items[index], theme),
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final profile = profileController.profileModel?.data;
        final levelName = profile?.level?.name;
        final baseUrl =
            Get.find<ConfigController>().config?.imageBaseUrl?.profileImage ??
                '';
        final imageUrl = profile?.profileImage != null
            ? '$baseUrl/${profile?.profileImage}'
            : '';

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.08),
                theme.colorScheme.secondary
                    .withValues(alpha: isDark ? 0.12 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _nav(() => const EditProfileScreen(), context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: ImageWidget(
                          height: 48,
                          width: 48,
                          image: imageUrl,
                          placeholder: Images.personPlaceholder,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profileController.customerName(),
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault + 1,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile?.phone ?? '',
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: theme.hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (levelName != null && levelName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 13,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${'level'.tr}: $levelName',
                                  style: textMedium.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, _DrawerItemData item, ThemeData theme) {
    final isDestructive = item.isDestructive;
    final badgeColor = isDestructive
        ? theme.colorScheme.error.withValues(alpha: 0.1)
        : theme.primaryColor.withValues(alpha: 0.08);
    final iconColor =
        isDestructive ? theme.colorScheme.error : theme.primaryColor;
    final textColor = isDestructive
        ? theme.colorScheme.error
        : theme.textTheme.bodyLarge?.color ?? theme.textTheme.bodyMedium?.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(item.icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: textSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.hintColor.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppConstants.appName,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: theme.primaryColor.withValues(alpha: 0.75),
            ),
          ),
          // Show the real installed version (pubspec), not the API compatibility number.
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final PackageInfo? info = snapshot.data;
              return Text(
                info == null ? '' : 'v${info.version}+${info.buildNumber}',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: theme.hintColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_DrawerItemData> _menuItems(BuildContext context) => [
        // _DrawerItemData(
        //   title: 'home'.tr,
        //   icon: Icons.home_rounded,
        //   onTap: () => Navigator.pop(context),
        // ),
        _DrawerItemData(
          title: 'activity'.tr,
          icon: Icons.directions_car_rounded,
          onTap: () => _nav(() => const TripScreen(fromProfile: true), context),
        ),
        _DrawerItemData(
          title: 'notification'.tr,
          icon: Icons.notifications_rounded,
          onTap: () => _nav(() => const NotificationScreen(), context),
        ),
        _DrawerItemData(
          title: 'my_wallet'.tr,
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => _nav(() => const WalletScreen(), context),
        ),
        _DrawerItemData(
          title: 'my_address'.tr,
          icon: Icons.location_on_rounded,
          onTap: () => _nav(() => const MyAddressScreen(), context),
        ),
        _DrawerItemData(
          title: 'my_offer'.tr,
          icon: Icons.local_offer_rounded,
          onTap: () => _nav(() => const MyOfferScreen(), context),
        ),
        _DrawerItemData(
          title: 'my_level'.tr,
          icon: Icons.emoji_events_rounded,
          onTap: () => _nav(() => const MyLevelScreen(), context),
        ),
        _DrawerItemData(
          title: 'safety'.tr,
          icon: Icons.security_rounded,
          onTap: () => _nav(() => const SafetySetupScreen(), context),
        ),
        _DrawerItemData(
          title: 'settings'.tr,
          icon: Icons.settings_rounded,
          onTap: () => _nav(() => const SettingScreen(), context),
        ),
        _DrawerItemData(
          title: 'help_support'.tr,
          icon: Icons.support_agent_rounded,
          onTap: () => _nav(() => const HelpAndSupportScreen(), context),
        ),
        _DrawerItemData(
          title: 'logout'.tr,
          icon: Icons.logout_rounded,
          isDestructive: true,
          onTap: () {
            Navigator.pop(context);
            _showLogoutDialog();
          },
        ),
      ];

  void _nav(Widget Function() page, BuildContext context) {
    Navigator.pop(context);
    Get.to(page);
  }

  void _showLogoutDialog() {
    Get.bottomSheet(
      Builder(
        builder: (dialogContext) => GetBuilder<AuthController>(
          builder: (authController) => ConfirmationBottomsheetWidget(
            icon: Images.exitIcon,
            title: 'Logout'.tr,
            description: 'do_you_want_to_log_out_this_account'.tr,
            iconColor: Theme.of(dialogContext).cardColor,
            isLoading: authController.isLoading,
            onYesPressed: () => Get.find<AuthController>().logOut(),
            onNoPressed: () => Get.back(),
          ),
        ),
      ),
    );
  }
}

class _DrawerItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}
