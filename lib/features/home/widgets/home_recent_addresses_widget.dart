import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/address/controllers/address_controller.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeRecentAddressesWidget extends StatelessWidget {
  const HomeRecentAddressesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return GetBuilder<AddressController>(
      builder: (addressController) {
        final recentList = addressController.recentAddressList;
        if (recentList.isEmpty) {
          return const SizedBox.shrink();
        }

        // Display at most 4 recent search results
        final displayList = recentList.take(4).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, addressController),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.hintColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 52,
                      endIndent: 16,
                      color: theme.hintColor.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      return _RecentAddressTile(
                        address: item,
                        theme: theme,
                        onTap: () => _onTapAddress(item),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, AddressController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history_rounded,
            size: 16,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _tr('recent_searches', fallbackEn: 'Recent Searches', fallbackAr: 'عمليات البحث الأخيرة'),
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeDefault + 1,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        InkWell(
          onTap: () => controller.clearRecentAddresses(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _tr('clear', fallbackEn: 'Clear', fallbackAr: 'مسح'),
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.hintColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _tr(String key, {required String fallbackEn, required String fallbackAr}) {
    final translated = key.tr;
    if (translated != key && translated.trim().isNotEmpty) {
      return translated;
    }
    final isAr = Get.locale?.languageCode == 'ar';
    return isAr ? fallbackAr : fallbackEn;
  }

  void _onTapAddress(Address addr) {
    if (addr.latitude != null &&
        addr.latitude != 0 &&
        addr.longitude != null &&
        addr.longitude != 0) {
      Get.to(() => SetDestinationScreen(address: addr));
    } else {
      Get.to(() => SetDestinationScreen(searchText: addr.address));
    }
  }
}

class _RecentAddressTile extends StatelessWidget {
  final Address address;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RecentAddressTile({
    required this.address,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fullText = address.address?.trim() ?? '';
    final commaIndex = fullText.indexOf(',');
    final hasComma = commaIndex > 0;

    final primaryTitle = hasComma ? fullText.substring(0, commaIndex).trim() : fullText;
    final secondaryTitle = hasComma ? fullText.substring(commaIndex + 1).trim() : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: theme.primaryColor,
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
                      primaryTitle,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryTitle,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall + 1,
                          color: theme.hintColor.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.hintColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
