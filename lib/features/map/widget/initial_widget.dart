import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/widget/ride_note_widget.dart';
import 'package:ride_sharing_user_app/features/map/widget/ride_quick_action_bar.dart';
import 'package:ride_sharing_user_app/features/parcel/widgets/fare_input_widget.dart';
import 'package:ride_sharing_user_app/features/parcel/widgets/route_widget.dart';
import 'package:ride_sharing_user_app/features/payment/controllers/payment_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/ride_category.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/selected_category_fare_card.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/travel_airport_contact_card.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/trip_details_screen.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/rate_limit_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';


class InitialWidget extends StatefulWidget {
  final GlobalKey<ExpandableBottomSheetState> expandableKey;
  const InitialWidget({super.key, required this.expandableKey});

  @override
  State<InitialWidget> createState() => _InitialWidgetState();
}

class _InitialWidgetState extends State<InitialWidget> {
//  String? zoneExtraFareReason;


  @override
  void initState() {
    var rideController = Get.find<RideController>();
    if(Get.find<PaymentController>().paymentType == 'wallet' &&
        (rideController.discountAmount.toDouble() > 0 ? rideController.discountFare : rideController.estimatedFare) >
            Get.find<ProfileController>().profileModel!.data!.wallet!.walletBalance!
    ){
      Get.find<PaymentController>().setPaymentType(0);
    }
  //  zoneExtraFareReason = _getExtraFairReason(Get.find<ConfigController>().config?.zoneExtraFare, Get.find<LocationController>().zoneID);

    if (rideController.fareList.isEmpty &&
        Get.find<LocationController>().fromAddress != null &&
        Get.find<LocationController>().toAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rideController.getEstimatedFare(false);
      });
    }

    super.initState();
  }

  bool _isTravelOrAirport(RideController rideController) {
    final filter = (rideController.selectedCategoryFilter ?? '').trim().toLowerCase();
    if (filter.contains('سفر') || filter.contains('مطار') ||
        filter.contains('travel') || filter.contains('airport')) {
      return true;
    }
    final activeName = (rideController.selectedType?.vehicleCategoryType ?? '').trim().toLowerCase();
    if (activeName.contains('سفر') || activeName.contains('مطار') ||
        activeName.contains('travel') || activeName.contains('airport')) {
      return true;
    }
    if (Get.isRegistered<CategoryController>()) {
      final categories = Get.find<CategoryController>().categoryList;
      if (categories != null &&
          rideController.rideCategoryIndex >= 0 &&
          rideController.rideCategoryIndex < categories.length) {
        final catName = (categories[rideController.rideCategoryIndex].name ?? '').trim().toLowerCase();
        if (catName.contains('سفر') || catName.contains('مطار') ||
            catName.contains('travel') || catName.contains('airport')) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideController>(builder: (rideController){
      return GetBuilder<LocationController>(builder: (locationController){
        return Column(mainAxisSize: MainAxisSize.min, children:  [
          if (rideController.selectedCategoryFilter == null || rideController.selectedCategoryFilter!.isEmpty) ...[
            RideCategoryWidget(onTap:(value) async {
              if(rideController.isCouponApplicable){
                await Future.delayed(const Duration(milliseconds: 500));
                widget.expandableKey.currentState?.expand(duration: 1000);
              }else{
                widget.expandableKey.currentState?.contract(duration: 500);
                widget.expandableKey.currentState?.expand(duration: 1000);
              }

            }),
            const SizedBox(height: 10),
          ],

          // 1. Selected Category Fare & Details Card
          const SelectedCategoryFareCard(),
          const SizedBox(height: 10),

          // 1.1 Direct Contact Card for Travel & Airport
          if (_isTravelOrAirport(rideController)) ...[
            const TravelAirportContactCard(),
            const SizedBox(height: 10),
          ],

          // 2. Quick Action Bar: Pickup Time & Payment Method in one sleek row
          const RideQuickActionBar(),
          const SizedBox(height: 10),

          // 2. Route & Distance Details (compact styling)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).hintColor.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.25 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: 8,
            ),
            child: RouteWidget(
              totalDistance: (rideController.fareList.isEmpty ||
                      rideController.fareList.length <=
                          rideController.rideCategoryIndex)
                  ? '0'
                  : rideController.fareList[rideController.rideCategoryIndex]
                          .estimatedDistance ??
                      '0',
              fromAddress: locationController.fromAddress?.address ?? '',
              extraOneAddress:
                  locationController.extraRouteAddress?.address ?? '',
              extraTwoAddress:
                  locationController.extraRouteTwoAddress?.address ?? '',
              toAddress: locationController.toAddress?.address ?? '',
              entrance: locationController.entranceController.text,
            ),
          ),
          const SizedBox(height: 10),

          if (rideController.fareList.isNotEmpty &&
              rideController.fareList.length >
                  rideController.rideCategoryIndex &&
              (rideController.fareList[rideController.rideCategoryIndex]
                          .extraFareReason ??
                      '') !=
                  '') ...[
            Text(
                '${'fares_are_a_bit_higher'.tr}${rideController.fareList[rideController.rideCategoryIndex].extraFareReason}',
                style: textRegular.copyWith(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    fontSize: 11),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
          ],

          // 3. Compact Note & Coupon bar
          const RideNoteWidget(),
          const SizedBox(height: 12),

          rideController.isLoading || rideController.isSubmit ?
          Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0)) :
          (Get.find<ConfigController>().config!.bidOnFare! && rideController.rideType != RideType.scheduleRide) ?
          FareInputWidget(
            expandableKey: widget.expandableKey,
            fromRide: true,
            fare: rideController.discountAmount.toDouble() > 0 ?
            rideController.discountFare.toString() :
            rideController.estimatedFare.toString(),
          ) :
          ButtonWidget(buttonText: "find_rider".tr, onPressed: () {
            if (RateLimitHelper.isBlocked()) {
              RateLimitHelper.showBlockedDialog(context);
              return;
            }
            if (rideController.fareList.isEmpty ||
                rideController.selectedCategoryId.isEmpty) {
              showCustomSnackBar('service_not_available_in_this_area'.tr,
                  isError: true);
              return;
            }
            if(rideController.rideType == RideType.regularRide) {
              _sendFindRiderRequest(rideController);
            }else{
              rideController.submitRideRequest(rideController.noteController.text, false).then((value){
                if(value.statusCode == 200){
                  Get.find<MapController>().initializeData();
                  showCustomSnackBar(
                      '${'your_trip'.tr} #${rideController.tripDetails?.refId} ${'has_been_successfully_scheduled'.tr}',
                      subMessage: 'you_will_be_notified_when_a_driver_start_for_your'.tr
                  );
                  Get.offAll(() =>  TripDetailsScreen(tripId: rideController.tripDetails?.id ?? ''));
                }
              });
            }
          }),
        ]);
      });
    });
  }

  // String? _getExtraFairReason(List<ZoneExtraFare>? list, String? zoneId){
  //   for(int i = 0; i < (list?.length ?? 0); i++) {
  //
  //     if(list?[i].zoneId == zoneId || list?[i].zoneId == 'all') {
  //       return list?[i].reason ?? '';
  //     }
  //   }
  //   return null;
  //
  // }

  void _sendFindRiderRequest(RideController rideController){
    rideController.submitRideRequest(rideController.noteController.text, false).then((value) {
      if (value.statusCode == 200) {
        Get.find<AuthController>().saveFindingRideCreatedTime();
        rideController.updateRideCurrentState(RideState.findingRider);
        Get.find<MapController>().initializeData();
        Get.find<MapController>().setOwnCurrentLocation(
            LatLng(
                Get.find<LocationController>().fromAddress?.latitude ?? 0,
                Get.find<LocationController>().fromAddress?.longitude ?? 0
            )
        );
        Get.find<MapController>().notifyMapController();
      }
    });
  }
}
