import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/features/address/controllers/address_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/banner_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/app_drawer_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_bottom_bar_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_floating_actions_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_map_view.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_ongoing_rides_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_top_bar_widget.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/my_offer/controller/offer_controller.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/helper/home_screen_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JustTheController rideShareToolTip = JustTheController();
  final JustTheController parcelDeliveryToolTip = JustTheController();

  late final DraggableScrollableController _sheetController;
  double _sheetExtent = 0.40;

  late final ProfileController _profileController;
  late final RideController _rideController;
  late final ParcelController _parcelController;
  late final ConfigController _configController;
  late final LocationController _locationController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetChanged);

    _profileController = Get.find<ProfileController>();
    _rideController = Get.find<RideController>();
    _parcelController = Get.find<ParcelController>();
    _configController = Get.find<ConfigController>();
    _locationController = Get.find<LocationController>();

    Get.find<AddressController>().updateLastLocation();
    _loadData();
    _scheduleToolTips();
  }

  void _onSheetChanged() {
    if (!_sheetController.isAttached) return;
    final newExtent = _sheetController.size;
    if ((newExtent - _sheetExtent).abs() > 0.005) {
      if (mounted) {
        setState(() {
          _sheetExtent = newExtent;
        });
      }
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    rideShareToolTip.dispose();
    parcelDeliveryToolTip.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _parcelController.getUnpaidParcelList();
    Get.find<BannerController>().getBannerList();
    Get.find<CategoryController>().getCategoryList();
    Get.find<AddressController>().getAddressList(1);
    Get.find<AddressController>().getRecentAddressList();
    Get.find<CategoryController>().setCouponFilterIndex(0, isUpdate: false);
    Get.find<OfferController>().getOfferList(1);

    if (_profileController.profileModel == null) {
      _profileController.getProfileInfo();
    }

    await Future.wait([
      _rideController.getRunningRideList(),
      _rideController.getCurrentRegularRide(),
      _parcelController.getRunningParcelList(),
      if (_locationController.getUserAddress()?.latitude != null)
        _rideController.getNearestDriverList(
          _locationController.getUserAddress()!.latitude!.toString(),
          _locationController.getUserAddress()!.longitude!.toString(),
        ),
    ]);

    if (_rideController.runningRideList?.data != null) {
      for (var element in _rideController.runningRideList!.data!) {
        PusherHelper().pusherDriverStatus(element.id!);
      }
    }

    if (_rideController.rideDetails != null) {
      _rideController.getBiddingList(_rideController.rideDetails!.id!, 1);
    } else {
      _rideController.clearBiddingList();
    }

    if (_parcelController.parcelListModel?.data?.isNotEmpty ?? false) {
      for (var element in _parcelController.parcelListModel!.data!) {
        PusherHelper().pusherDriverStatus(element.id!);
      }
    }

    HomeScreenHelper.checkMaintanceMode();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomOffset = (_sheetExtent * screenHeight) + 12;
    final fadeProgress = ((_sheetExtent - 0.42) / 0.12).clamp(0.0, 1.0);
    final controlsOpacity = 1.0 - fadeProgress;
    final bool showControls = controlsOpacity > 0.02;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        } else {
          Get.find<BottomMenuController>().exitApp();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawerWidget(),
        body: Stack(
          children: [
            // Edge-to-edge Google Map
            const Positioned.fill(
              child: HomeMapView(
                title: 'rider_around_you',
                isFullScreen: true,
              ),
            ),

            // Top Floating Bar (Menu pill + Scanner button)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: HomeTopBarWidget(
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onScanTap: () => _loadData(),
                ),
              ),
            ),

            // Ongoing rides / parcel tooltip badges
            if (showControls)
              Positioned(
                bottom: bottomOffset + 52,
                right: Dimensions.paddingSizeDefault,
                child: Opacity(
                  opacity: controlsOpacity,
                  child: HomeOngoingRidesWidget(
                    rideShareToolTip: rideShareToolTip,
                    parcelDeliveryToolTip: parcelDeliveryToolTip,
                  ),
                ),
              ),

            // Bottom Floating Controls Row (Safety + My Location)
            if (showControls)
              Positioned(
                bottom: bottomOffset,
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault,
                child: Opacity(
                  opacity: controlsOpacity,
                  child: const HomeFloatingActionsWidget(),
                ),
              ),

            // Expandable & Scrollable Bottom Sheet
            HomeBottomBarWidget(sheetController: _sheetController),
          ],
        ),
      ),
    );
  }

  void _scheduleToolTips() {
    if (!_configController.isShowToolTips) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1)).then((_) {
        if (!mounted) return;
        if ((_rideController.runningRideList?.data?.length ?? 0) > 0) {
          rideShareToolTip.showTooltip();
          _configController.hideToolTips();
          Future.delayed(const Duration(seconds: 5)).then((_) {
            if (mounted) rideShareToolTip.hideTooltip();
          });
        }
        if ((_parcelController.parcelListModel?.totalSize ?? 0) > 0) {
          parcelDeliveryToolTip.showTooltip();
          _configController.hideToolTips();
          Future.delayed(const Duration(seconds: 5)).then((_) {
            if (mounted) parcelDeliveryToolTip.hideTooltip();
          });
        }
      });
    });
  }
}
