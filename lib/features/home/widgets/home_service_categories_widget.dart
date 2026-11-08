import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/screens/set_destination_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class _CategoryItemDef {
  final String key;
  final String title;
  final IconData icon;

  const _CategoryItemDef({
    required this.key,
    required this.title,
    required this.icon,
  });
}

class HomeServiceCategoriesWidget extends StatelessWidget {
  const HomeServiceCategoriesWidget({super.key});

  static const List<_CategoryItemDef> _serviceDefs = [
    _CategoryItemDef(
      key: 'سفر',
      title: 'سفر',
      icon: Icons.directions_car_filled_rounded,
    ),
    _CategoryItemDef(
      key: 'رحلة',
      title: 'رحلة',
      icon: Icons.directions_car_rounded,
    ),
    _CategoryItemDef(
      key: 'مطار',
      title: 'مطار',
      icon: Icons.local_taxi_rounded,
    ),
  ];

  Category? _findCategory(List<Category>? list, String key) {
    if (list == null || list.isEmpty) return null;
    final normalizedKey = key.trim().toLowerCase();
    for (final cat in list) {
      final name = (cat.name ?? '').trim().toLowerCase();
      if (name.contains(normalizedKey) || normalizedKey.contains(name)) {
        return cat;
      }
    }
    return null;
  }

  void _onCategoryTapped(String categoryKey) {
    if (Get.isRegistered<RideController>()) {
      Get.find<RideController>().setSelectedCategoryFilter(categoryKey);
    }
    Get.to(() => const SetDestinationScreen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    if (Get.isRegistered<CategoryController>()) {
      return GetBuilder<CategoryController>(
        builder: (categoryController) {
          return _buildCategoryRow(
              context, theme, isDark, categoryController.categoryList);
        },
      );
    }
    return _buildCategoryRow(context, theme, isDark, null);
  }

  Widget _buildCategoryRow(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<Category>? categories,
  ) {
    return Row(
      children: _serviceDefs.asMap().entries.map((entry) {
        final index = entry.key;
        final def = entry.value;
        final catModel = _findCategory(categories, def.key);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == _serviceDefs.length - 1 ? 0 : 5,
            ),
            child: _buildCategoryCard(
              context: context,
              theme: theme,
              isDark: isDark,
              def: def,
              category: catModel,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required _CategoryItemDef def,
    required Category? category,
  }) {
    final imageBase = Get.isRegistered<ConfigController>()
        ? Get.find<ConfigController>().config?.imageBaseUrl?.vehicleCategory
        : null;

    final bool hasValidImage =
        category?.image != null && category!.image!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onCategoryTapped(def.key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: isDark ? 0.22 : 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 42,
                child: Center(
                  child: hasValidImage
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
                      : Icon(
                          def.icon,
                          size: 28,
                          color: theme.primaryColor,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category?.name?.isNotEmpty == true
                    ? category!.name!
                    : def.title,
                style: textBold.copyWith(
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
