import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/parcel/screens/parcel_list_view_screen.dart';
import 'package:ride_sharing_user_app/features/parcel/widgets/driver_request_dialog.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_list_view_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeOngoingRidesWidget extends StatelessWidget {
  final JustTheController rideShareToolTip;
  final JustTheController parcelDeliveryToolTip;

  const HomeOngoingRidesWidget({
    super.key,
    required this.rideShareToolTip,
    required this.parcelDeliveryToolTip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parcelController = Get.find<ParcelController>();

    return GetBuilder<RideController>(
      builder: (rideController) {
        final parcelCount = parcelController.parcelListModel?.totalSize ?? 0;
        final runningRides = rideController.runningRideList?.data?.length ?? 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (parcelCount > 0)
              _buildParcelBadge(context, theme, parcelCount),
            if (runningRides > 0) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildRideBadge(context, theme, runningRides),
            ],
            if (rideController.biddingList.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildBiddingBadge(context, theme, rideController),
            ],
          ],
        );
      },
    );
  }

  Widget _buildParcelBadge(BuildContext context, ThemeData theme, int count) {
    return JustTheTooltip(
      backgroundColor: Get.isDarkMode ? theme.primaryColor : theme.textTheme.bodyMedium!.color,
      controller: parcelDeliveryToolTip,
      preferredDirection: AxisDirection.right,
      tailLength: 10,
      tailBaseWidth: 20,
      content: Container(
        width: 150,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Text('parcel_delivery'.tr, style: textRegular.copyWith(color: Colors.white)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => const ParcelListViewScreen(title: 'ongoing_parcel_list')),
        child: _badgeContainer(theme, Images.parcelDeliveryIcon, count),
      ),
    );
  }

  Widget _buildRideBadge(BuildContext context, ThemeData theme, int count) {
    return JustTheTooltip(
      backgroundColor: Get.isDarkMode ? theme.primaryColor : theme.textTheme.bodyMedium!.color,
      controller: rideShareToolTip,
      preferredDirection: AxisDirection.right,
      tailLength: 10,
      tailBaseWidth: 20,
      content: Container(
        width: 100,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Text('ride_share'.tr, style: textRegular.copyWith(color: Colors.white)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => const RideListViewScreen()),
        child: _badgeContainer(theme, Images.rideShareIcon, count),
      ),
    );
  }

  Widget _buildBiddingBadge(BuildContext context, ThemeData theme, RideController rideController) {
    return InkWell(
      onTap: () {
        if (!rideController.isLoading && rideController.rideDetails?.id != null) {
          rideController.getBiddingList(rideController.rideDetails!.id!, 1).then((_) {
            if (rideController.biddingList.isNotEmpty) {
              Get.dialog(
                DriverRideRequestDialog(tripId: rideController.rideDetails!.id!),
                barrierDismissible: true,
                barrierColor: Colors.black.withValues(alpha: 0.5),
              );
            }
          });
        }
      },
      child: Stack(
        children: [
          Container(
            height: 38,
            width: 38,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSeven),
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor),
            child: Image.asset(Images.biddingIcon),
          ),
          Positioned(
            right: 0,
            top: 6,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeContainer(ThemeData theme, String icon, int count) {
    return Stack(
      children: [
        Container(
          height: 38,
          width: 38,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor),
          child: Image.asset(icon),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.error),
            child: Center(
              child: Text('$count', style: textRegular.copyWith(color: Colors.white, fontSize: 10)),
            ),
          ),
        ),
      ],
    );
  }
}
