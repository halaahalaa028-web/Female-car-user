import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/features/location/widget/location_search_dialog.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';

class PickMapScreen extends StatefulWidget {
  final LocationType type;
  final Address? address;
  final Function(Position position, String address)? onLocationPicked;
  const PickMapScreen(
      {super.key, this.onLocationPicked, required this.type, this.address});

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  bool _isCameraMoving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationController = Get.find<LocationController>();
    final LatLng initialTarget = widget.address != null
        ? LatLng(widget.address?.latitude ?? 0, widget.address?.longitude ?? 0)
        : widget.onLocationPicked != null
            ? LatLng(locationController.position.latitude,
                locationController.position.longitude)
            : locationController.initialPosition;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 16,
                ),
                minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                onMapCreated: (GoogleMapController mapController) {
                  _mapController = mapController;
                  final LatLng targetPos = _cameraPosition?.target ?? initialTarget;
                  Get.find<LocationController>().updatePosition(
                    targetPos,
                    false,
                    widget.type,
                  );
                },
                zoomControlsEnabled: false,
                onCameraMove: (CameraPosition cameraPosition) {
                  _cameraPosition = cameraPosition;
                },
                onCameraMoveStarted: () {
                  _isCameraMoving = true;
                  Get.find<LocationController>().disableButton();
                },
                onCameraIdle: () {
                  _isCameraMoving = false;
                  if (!mounted) return;
                  try {
                    Get.find<LocationController>().updatePosition(
                        _cameraPosition?.target, false, widget.type);
                  } catch (_) {}
                },
                style: Get.isDarkMode
                    ? Get.find<ThemeController>().darkMap
                    : Get.find<ThemeController>().lightMap,
              ),

              // Center Marker (IgnorePointer so drag gestures pass to GoogleMap)
              IgnorePointer(
                child: Center(
                  child: GetBuilder<LocationController>(
                    builder: (locController) {
                      return !locController.loading
                          ? Image.asset(
                              _isCameraMoving
                                  ? Images.pickLocationAnimatedIcon
                                  : Images.pickLocationIcon,
                              height: 44,
                              width: 24,
                              color: theme.primaryColor,
                            )
                          : SpinKitCircle(
                              color: theme.primaryColor, size: 40.0);
                    },
                  ),
                ),
              ),

              // Search Bar
              Positioned(
                top: Dimensions.paddingSizeLarge,
                left: Dimensions.paddingSizeSmall,
                right: Dimensions.paddingSizeSmall,
                child: GetBuilder<LocationController>(
                  builder: (locController) {
                    return InkWell(
                      onTap: () {
                        if (_mapController != null) {
                          Get.dialog(LocationSearchDialog(
                              mapController: _mapController!,
                              type: widget.type));
                        }
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(
                              Dimensions.radiusSmall),
                        ),
                        child: Row(children: [
                          Icon(
                            Icons.location_on,
                            size: 25,
                            color: theme
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: .6),
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
                          Expanded(
                            child: Text(
                              locController.pickAddress,
                              style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeSmall),
                          Icon(Icons.search,
                              size: 25,
                              color: theme.textTheme.bodyLarge!.color),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // My Location Floating Action Button
              Positioned(
                bottom: 80,
                right: Dimensions.paddingSizeSmall,
                child: FloatingActionButton(
                  hoverColor: Colors.transparent,
                  mini: true,
                  backgroundColor: theme.primaryColor,
                  onPressed: () => Get.find<LocationController>()
                      .getCurrentPosition(mapController: _mapController),
                  child: Icon(Icons.my_location,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),

              // Bottom Confirmation Button
              Positioned(
                bottom: 30.0,
                left: Dimensions.paddingSizeSmall,
                right: Dimensions.paddingSizeSmall,
                child: GetBuilder<LocationController>(
                  builder: (locController) {
                    return locController.picking
                        ? Center(
                            child: SpinKitCircle(
                                color: theme.primaryColor, size: 40.0))
                        : ButtonWidget(
                            fontSize: Dimensions.fontSizeDefault,
                            buttonText: locController.inZone
                                ? 'pick_location'.tr
                                : 'service_not_available_in_this_area'.tr,
                            onPressed: (locController.buttonDisabled ||
                                    locController.loading)
                                ? null
                                : () {
                                    if (locController.pickPosition.latitude !=
                                            0 &&
                                        locController.pickAddress.isNotEmpty) {
                                      if (widget.onLocationPicked != null) {
                                        widget.onLocationPicked!(
                                            locController.pickPosition,
                                            locController.pickAddress);
                                      }
                                      Address address = Address(
                                        latitude: locController
                                            .pickPosition.latitude,
                                        longitude: locController
                                            .pickPosition.longitude,
                                        addressLabel: 'others',
                                        address: locController.pickAddress,
                                        zoneId: locController.zoneID,
                                      );
                                      locController.saveAddressAndNavigate(
                                          address, widget.type);
                                    } else {
                                      showCustomSnackBar('pick_an_address'.tr);
                                    }
                                  },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
