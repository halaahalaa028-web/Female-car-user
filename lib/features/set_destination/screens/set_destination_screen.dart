import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/home/controllers/banner_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/banner_view.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/input_field_for_set_route.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/pick_location_widget.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/pickup_time_date_widget.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/process_button_widget.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/reservation_note_widget.dart';
import 'package:ride_sharing_user_app/helper/route_helper.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/location/view/pick_map_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/divider_widget.dart';

class SetDestinationScreen extends StatefulWidget {
  final Address? address;
  final String? searchText;
  final RideType rideType;
  final bool? isFormHatlyButton;
  final bool? isFormEpatlyButton;
  final bool? shouldSelectHatlyAndEpatlyCategory;

  const SetDestinationScreen({
    super.key,
    this.address,
    this.searchText,
    this.rideType = RideType.regularRide,
    this.isFormHatlyButton = false,
    this.isFormEpatlyButton = false,
    this.shouldSelectHatlyAndEpatlyCategory = false,
  });

  @override
  State<SetDestinationScreen> createState() => _SetDestinationScreenState();
}

class _SetDestinationScreenState extends State<SetDestinationScreen> {
  FocusNode pickLocationFocus = FocusNode();
  FocusNode destinationLocationFocus = FocusNode();
  ScrollController scrollController = ScrollController();
  double dialogTopPosition = 0;
  double bottomWhiteSpace = 0;
  var keyboardVisibilityController = KeyboardVisibilityController();
  late StreamSubscription<bool> keyboardSubscription;
  final GlobalKey _key = GlobalKey();

  TextEditingController? _noteController;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupKeyboardListener();
    if (widget.shouldSelectHatlyAndEpatlyCategory == true) {
      _noteController = TextEditingController();
    }
  }

  void _initData() {
    Get.find<RideController>().setRideType(widget.rideType);
    Get.find<LocationController>().initAddLocationData();
    Get.find<LocationController>().initTextControllers();
    Get.find<RideController>().clearExtraRoute();
    Get.find<MapController>().initializeData();
    Get.find<RideController>().initData();
    Get.find<ParcelController>().updatePaymentPerson(false, notify: false);

    if (Get.find<BannerController>().bannerList == null ||
        Get.find<BannerController>().bannerList!.isEmpty) {
      Get.find<BannerController>().getBannerList();
    }

    final locationController = Get.find<LocationController>();
    locationController.setPickUp(locationController.getUserAddress());

    if (widget.address != null) {
      locationController.setDestination(widget.address);
    }
    if (widget.searchText != null) {
      locationController.setDestination(Address(address: widget.searchText));
      Future.delayed(const Duration(seconds: 1)).then((_) {
        locationController.searchLocation(Get.context!, widget.searchText ?? '',
            type: LocationType.to);
      });
    }

    if (widget.shouldSelectHatlyAndEpatlyCategory == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100)).then((_) {
          final categoryController = Get.find<CategoryController>();
          final rideController = Get.find<RideController>();

          String targetCategoryName = '';
          if (widget.isFormHatlyButton == true ||
              widget.isFormEpatlyButton == true) {
            targetCategoryName = 'hatly';
          }

          // Find the index of the target category (case-insensitive comparison)
          if (targetCategoryName.isNotEmpty &&
              categoryController.categoryList != null &&
              categoryController.categoryList!.isNotEmpty) {
            for (int i = 0; i < categoryController.categoryList!.length; i++) {
              if (categoryController.categoryList![i].name?.toLowerCase() ==
                  targetCategoryName.toLowerCase()) {
                rideController.setRideCategoryIndex(i);
                break;
              }
            }
          }
        });
      });
    }
  }

  void _setupKeyboardListener() {
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        bottomWhiteSpace = 0;
      }
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    pickLocationFocus.dispose();
    destinationLocationFocus.dispose();
    scrollController.dispose();
    _noteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GetBuilder<RideController>(builder: (rideController) {
          return BodyWidget(
            appBar: AppBarWidget(
              title: rideController.rideType == RideType.scheduleRide
                  ? 'schedule_trip_setup'.tr
                  : 'trip_setup'.tr,
              centerTitle: true,
              onBackPressed: () {
                if (Navigator.canPop(context)) {
                  Get.back();
                } else {
                  Get.offAll(() => const DashboardScreen());
                }
              },
            ),
            body: GetBuilder<LocationController>(builder: (locationController) {
              return GetBuilder<RideController>(builder: (rideController) {
                bool isReversed = widget.isFormEpatlyButton == true;

                return Stack(
                clipBehavior: Clip.none,
                children: [
                  // --- Main Content Layer ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeSmall,
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeSmall,
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BannerView(),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          const PickupTimeDateWidget(),
                          Text('set_your_location'.tr, style: textSemiBold),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          // --- Grey Box for Locations ---
                          Container(
                            decoration: BoxDecoration(
                              color: theme.hintColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeSmall),
                            ),
                            child: Column(children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LocationFromToWidget(isReversed: isReversed),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeDefault),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 1. Pickup Location
                                          if (!isReversed)
                                            _buildRouteInput(
                                              type: LocationType.from,
                                              hint: widget.isFormHatlyButton == true ? 'from' : 'pick_location',
                                              controller: locationController
                                                  .pickupLocationController,
                                              address:
                                                  locationController.fromAddress,
                                              locationController:
                                                  locationController,
                                              rideController: rideController,
                                              focusNode: pickLocationFocus,
                                            ),

                                          if (isReversed)
                                            _buildRouteInput(
                                              type: LocationType.to,
                                              hint: widget.isFormEpatlyButton == true ? 'to' : 'destination',
                                              controller: locationController
                                                  .destinationLocationController,
                                              address: locationController
                                                  .toAddress,
                                              locationController:
                                                  locationController,
                                              rideController: rideController,
                                              focusNode:
                                                  destinationLocationFocus,
                                            ),

                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: Dimensions
                                                    .paddingSizeExtraSmall),
                                            child: Text(isReversed ? 'from'.tr : 'to'.tr,
                                                style: textRegular.copyWith(
                                                    color: theme.textTheme
                                                        .bodyMedium?.color)),
                                          ),

                                          // 2. Extra Route One
                                          if (locationController
                                              .extraOneRoute && !isReversed) ...[
                                            _buildRouteInput(
                                              type: LocationType.extraOne,
                                              hint: 'extra_route_one',
                                              controller: locationController
                                                  .extraRouteOneController,
                                              address: locationController
                                                  .extraRouteAddress,
                                              locationController:
                                                  locationController,
                                                  rideController: rideController,
                                                  isRemovable: true,
                                            ),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeDefault),
                                          ],

                                          // 3. Extra Route Two
                                          if (locationController
                                              .extraTwoRoute && !isReversed) ...[
                                            _buildRouteInput(
                                              type: LocationType.extraTwo,
                                              hint: 'extra_route_two',
                                              controller: locationController
                                                  .extraRouteTwoController,
                                              address: locationController
                                                  .extraRouteTwoAddress,
                                              locationController:
                                                  locationController,
                                                  rideController: rideController,
                                                  isRemovable: true,
                                            ),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeDefault),
                                          ],

                                          // 4. Destination Location & Add Button
                                          Row(children: [
                                            Expanded(
                                              child: isReversed
                                                  ? _buildRouteInput(
                                                      type: LocationType.from,
                                                      hint: widget.isFormEpatlyButton == true ? 'from' : 'pick_location',
                                                      controller: locationController
                                                          .pickupLocationController,
                                                      address:
                                                          locationController.fromAddress,
                                                      locationController:
                                                          locationController,
                                                      rideController: rideController,
                                                      focusNode: pickLocationFocus,
                                                    )
                                                  : _buildRouteInput(
                                                      type: LocationType.to,
                                                      hint: widget.isFormHatlyButton == true ? 'to' : 'destination',
                                                      controller: locationController
                                                          .destinationLocationController,
                                                      address: locationController
                                                          .toAddress,
                                                      locationController:
                                                          locationController,
                                                          rideController: rideController,
                                                          focusNode:
                                                          destinationLocationFocus,
                                                    ),
                                            ),

                                            // Add Button Logic
                                            SizedBox(
                                                width: locationController
                                                        .extraTwoRoute
                                                    ? 0
                                                    : Dimensions
                                                        .paddingSizeSmall),
                                            if (_canAddMoreRoutes(
                                                locationController) && !isReversed)
                                              InkWell(
                                                onTap: () => locationController
                                                    .setExtraRoute(),
                                                child: Container(
                                                  height: 35,
                                                  width: 35,
                                                  decoration: BoxDecoration(
                                                    color: theme.primaryColor,
                                                    borderRadius: BorderRadius
                                                        .circular(Dimensions
                                                            .paddingSizeExtraSmall),
                                                  ),
                                                  child: const Icon(Icons.add,
                                                      color: Colors.white),
                                                ),
                                              ),
                                          ]),

                                          // Entrance Input Logic
                                          const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeDefault),
                                          _buildEntranceInput(
                                              locationController, theme),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                          ),

                          // Hint Text
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeExtraLarge,
                              0,
                              Dimensions.paddingSizeExtraLarge,
                              Dimensions.paddingSizeSmall,
                            ),
                            child: Text(
                              'you_can_add_multiple_route_to'.tr,
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: theme.textTheme.bodyMedium!.color!
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          if (widget.isFormHatlyButton == true ||
                              widget.isFormEpatlyButton == true)
                          const SizedBox(
                            height: 20,
                          ),
                          if (widget.isFormHatlyButton == true ||
                              widget.isFormEpatlyButton == true)
                          Text("Ride Notes".tr),
                          const SizedBox(
                            height: 10,
                          ),
                          if (widget.isFormHatlyButton == true ||
                              widget.isFormEpatlyButton == true)
                            TextFormField(
                              controller: Get.find<RideController>().noteController,
                              maxLines: 4 ,
                              decoration: InputDecoration(
                                hint: Text('Enter your note'.tr),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                              ),
                            ),
                          // Schedule Note
                          if (rideController.rideType == RideType.scheduleRide)
                            ReservationNoteWidget(globalKey: _key),
                          SizedBox(height: bottomWhiteSpace)
                        ],
                      ),
                    ),
                  ),

                  // --- Search Suggestions Layer (Floating) ---
                  if (locationController.resultShow)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => locationController.setSearchResultShowHide(
                            show: false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? theme.canvasColor
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeDefault),
                          ),
                          margin:
                              EdgeInsets.fromLTRB(30, dialogTopPosition, 30, 0),
                          child: _buildSearchResults(locationController, theme),
                        ),
                      ),
                    ),
                ],
              );
            });
        }));
        }),
        bottomNavigationBar: ProcessButtonWidget(
          pickLocationFocus: pickLocationFocus,
          destinationLocationFocus: destinationLocationFocus,
        ),
      ),
    );
  }

  // --- Helper Widgets & Methods ---

  /// 1. Reusable Widget for Route Inputs (From, To, Extra)
  Widget _buildRouteInput({
    required LocationType type,
    required String hint,
    required TextEditingController controller,
    required Address? address,
    required LocationController locationController,
    required RideController rideController,
    FocusNode? focusNode,
    bool isRemovable = false,
  }) {
    return PickLocationWidget(
      locationType: type,
      textFieldHint: hint.tr,
      rideDetails: rideController.rideDetails,
      focusNode: focusNode,
      textEditingController: controller,
      isShowCrossButton: isRemovable,
      locationIconTap: () {
        RouteHelper.goPageAndHideTextField(
          context,
          PickMapScreen(type: type, address: address),
        );
      },
      textFieldTap: () {
        setScrollAndDialogPosition(type, locationController);
      },
    );
  }

  /// 2. Helper for Entrance Input
  Widget _buildEntranceInput(
      LocationController locationController, ThemeData theme) {
    if (locationController.addEntrance) {
      return SizedBox(
        width: 200,
        height: 40,
        child: InputField(
          showSuffix: false,
          controller: locationController.entranceController,
          node: locationController.entranceNode,
          hint: 'enter_entrance'.tr,
        ),
      );
    } else {
      return InkWell(
        onTap: () => locationController.setAddEntrance(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 30,
              child: Transform(
                alignment: Alignment.center,
                transform: Get.find<LocalizationController>().isLtr
                    ? Matrix4.rotationY(0)
                    : Matrix4.rotationY(math.pi),
                child: Image.asset(
                  Images.curvedArrow,
                  color:
                      theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.add, color: theme.primaryColor, size: 16),
                Padding(
                  padding:
                      const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                  child: Text(
                    'add_entrance'.tr,
                    style: textRegular.copyWith(
                      color: theme.primaryColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  /// 3. Helper for Search Results List
  Widget _buildSearchResults(
      LocationController locationController, ThemeData theme) {
    return ListView.builder(
      itemCount:
          locationController.predictionList?.data?.suggestions?.length ?? 0,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final suggestion =
            locationController.predictionList?.data?.suggestions?[index];
        return InkWell(
          onTap: () {
            Get.find<LocationController>().setLocation(
              fromSearch: true,
              suggestion?.placePrediction?.placeId ?? '',
              suggestion?.placePrediction?.text?.text ?? '',
              null,
              type: locationController.locationType,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingSizeDefault,
              horizontal: Dimensions.paddingSizeSmall,
            ),
            child: Row(children: [
              const Icon(Icons.location_on),
              Expanded(
                child: Text(
                  suggestion?.placePrediction?.text?.text ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayMedium!.copyWith(
                    color: theme.textTheme.bodyLarge!.color,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  bool _canAddMoreRoutes(LocationController controller) {
    bool configAllowed =
        Get.find<ConfigController>().config!.addIntermediatePoint!;
    return !(!configAllowed || controller.extraTwoRoute);
  }

  /// 4. Optimized Position Calculation
  void setScrollAndDialogPosition(
      LocationType locationType, LocationController locationController) {
    // Jump scroll to reveal content above keyboard
    scrollController
        .jumpTo(MediaQuery.of(context).size.height + Get.height * 0.3);

    // Calculate whitespace for Schedule Ride note
    double scheduleNoteHeight = _key.currentContext?.size?.height ?? 0;
    bottomWhiteSpace =
        Get.find<RideController>().rideType == RideType.scheduleRide
            ? (Get.height * 0.4 - scheduleNoteHeight)
            : Get.height * 0.4;

    // Position mapping
    Map<LocationType, double> positionMap = {
      LocationType.from: 0.2,
      LocationType.extraOne: locationController.extraTwoRoute ? 0.18 : 0.23,
      LocationType.extraTwo: 0.23,
      LocationType.to: 0.28,
    };

    dialogTopPosition = Get.height * (positionMap[locationType] ?? 0.2);

    setState(() {});
  }
}

// Keep this static widget as is
class _LocationFromToWidget extends StatelessWidget {
  final bool isReversed;
  const _LocationFromToWidget({this.isReversed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, 0, 0),
      child: Column(children: [
        SizedBox(
          width: Dimensions.iconSizeLarge,
          child: Image.asset(
            isReversed ? Images.activityDirection : Images.currentLocation,
            color: theme.textTheme.bodyMedium!.color,
          ),
        ),
        SizedBox(
            height: 60,
            width: 10,
            child: CustomDivider(
              height: 5,
              dashWidth: .75,
              axis: Axis.vertical,
              color: theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.5),
            )),
        SizedBox(
          width: Dimensions.iconSizeMedium,
          child: Transform(
            alignment: Alignment.center,
            transform: Get.find<LocalizationController>().isLtr
                ? (isReversed ? Matrix4.rotationY(math.pi) : Matrix4.rotationY(0))
                : (isReversed ? Matrix4.rotationY(0) : Matrix4.rotationY(math.pi)),
            child: Image.asset(
              isReversed ? Images.currentLocation : Images.activityDirection,
              color: theme.textTheme.bodyMedium!.color,
            ),
          ),
        ),
      ]),
    );
  }
}
