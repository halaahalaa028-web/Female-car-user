import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/widgets/banner_view.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_my_address.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_quick_destinations_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_recent_addresses_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_service_categories_widget.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeBottomBarWidget extends StatelessWidget {
  final DraggableScrollableController sheetController;

  const HomeBottomBarWidget({
    super.key,
    required this.sheetController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.40,
      minChildSize: 0.20,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.20, 0.40, 0.85],
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag handle with touch target & snap toggle
                    _buildDragHandle(theme),

                    // Primary Content (Categories, Shortcuts)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          HomeServiceCategoriesWidget(),
                          SizedBox(height: 12),
                          HomeQuickDestinationsWidget(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),

                    const HomeRecentAddressesWidget(),

                    // Subtle divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        height: 1,
                        color: theme.hintColor.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Expanded Section: Offers & Banners
                    _buildSectionHeader(
                      theme: theme,
                      icon: Icons.local_offer_rounded,
                      title: 'my_offer'.tr,
                    ),
                    const SizedBox(height: 8),
                    const BannerView(),
                    const SizedBox(height: 14),

                    // Expanded Section: Saved Addresses
                    const HomeMyAddress(),

                    // Safe Area bottom clearance for gestures
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!sheetController.isAttached) return;
        final target = sheetController.size > 0.60
            ? 0.40
            : (sheetController.size < 0.35 ? 0.40 : 0.85);
        sheetController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        alignment: Alignment.center,
        child: Container(
          width: 42,
          height: 4.5,
          decoration: BoxDecoration(
            color: theme.hintColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeDefault + 1,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
