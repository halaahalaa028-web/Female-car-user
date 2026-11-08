import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/estimated_fare_model.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/compact_category_card.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';

class RideCategoryWidget extends StatelessWidget {
  final Function(void)? onTap;
  const RideCategoryWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideController>(builder: (rideController) {
      return GetBuilder<CategoryController>(builder: (categoryController) {
        final categories = categoryController.categoryList;
        if (categories == null) {
          return Center(
            child: SpinKitCircle(
              color: Theme.of(context).primaryColor,
              size: 40.0,
            ),
          );
        }
        if (categories.isEmpty) {
          return Center(child: Text('no_category_found'.tr));
        }

        final defaultHasDiscount = rideController.discountAmount.toDouble() > 0;
        final defaultFinalFare = defaultHasDiscount
            ? rideController.discountFare
            : rideController.estimatedFare;

        final filter = rideController.selectedCategoryFilter?.trim().toLowerCase();
        final List<int> visibleIndices = [];
        if (filter != null && filter.isNotEmpty) {
          for (int i = 0; i < categories.length; i++) {
            final catName = (categories[i].name ?? '').trim().toLowerCase();
            if (catName.contains(filter) || filter.contains(catName)) {
              visibleIndices.add(i);
            }
          }
        }

        final indicesToShow = visibleIndices.isNotEmpty
            ? visibleIndices
            : List.generate(categories.length, (i) => i);

        if (indicesToShow.length <= 1 && filter != null && filter.isNotEmpty) {
          return const SizedBox();
        }

        if (indicesToShow.length == 1) {
          final singleIndex = indicesToShow.first;
          return Center(
            child: SizedBox(
              width: 130,
              child: _buildItemCard(
                context,
                categories[singleIndex],
                singleIndex,
                rideController,
                defaultFinalFare,
              ),
            ),
          );
        }

        if (indicesToShow.length <= 3) {
          return Row(
            children: List.generate(indicesToShow.length, (i) {
              final index = indicesToShow[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == indicesToShow.length - 1 ? 0 : 4,
                  ),
                  child: _buildItemCard(
                    context,
                    categories[index],
                    index,
                    rideController,
                    defaultFinalFare,
                  ),
                ),
              );
            }),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: indicesToShow.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final index = indicesToShow[i];
              return _buildItemCard(
                context,
                categories[index],
                index,
                rideController,
                defaultFinalFare,
              );
            },
          ),
        );
      });
    });
  }

  Widget _buildItemCard(
    BuildContext context,
    Category category,
    int index,
    RideController rideController,
    double defaultFinalFare,
  ) {
    final isSelected = rideController.rideCategoryIndex == index;
    FareModel? itemFare;
    if (rideController.fareList.isNotEmpty) {
      for (final fare in rideController.fareList) {
        if (fare.vehicleCategoryId == category.id) {
          itemFare = fare;
          break;
        }
      }
    }

    final double baseFareVal = itemFare != null
        ? (((itemFare.extraFareFee ?? 0) > 0) ||
                ((itemFare.surgeMultiplier ?? 0) > 0)
            ? (itemFare.extraEstimatedFare ?? 0)
            : (itemFare.estimatedFare ?? 0))
        : (isSelected ? defaultFinalFare : 0.0);

    final double discountAmountVal = itemFare != null
        ? (((itemFare.extraFareFee ?? 0) > 0) ||
                ((itemFare.surgeMultiplier ?? 0) > 0)
            ? (itemFare.extraDiscountAmount ?? 0)
            : (itemFare.discountAmount ?? 0))
        : (isSelected ? rideController.discountAmount.toDouble() : 0.0);

    final double discountFareVal = itemFare != null
        ? (((itemFare.extraFareFee ?? 0) > 0) ||
                ((itemFare.surgeMultiplier ?? 0) > 0)
            ? (itemFare.extraDiscountFare ?? 0)
            : (itemFare.discountFare ?? 0))
        : (isSelected ? rideController.discountFare : 0.0);

    final bool itemHasDiscount = discountAmountVal > 0;
    final double finalItemFare = itemHasDiscount ? discountFareVal : baseFareVal;

    final itemFareText =
        finalItemFare > 0 ? PriceConverter.convertPrice(finalItemFare) : null;
    final itemOriginalFareText = (itemHasDiscount && baseFareVal > 0)
        ? PriceConverter.convertPrice(baseFareVal)
        : null;
    final itemDiscountBadgeText = itemHasDiscount
        ? 'خصم ${PriceConverter.convertPrice(discountAmountVal)}'
        : null;

    return CompactCategoryCard(
      index: index,
      category: category,
      isSelected: isSelected,
      fareText: itemFareText,
      originalFareText: itemOriginalFareText,
      discountText: itemDiscountBadgeText,
      showFare: true,
      onTap: onTap,
    );
  }
}
