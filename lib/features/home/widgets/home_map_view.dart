import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widget/custom_title.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';

class HomeMapView extends StatefulWidget {
  final String title;
  final bool isFullScreen;
  const HomeMapView({super.key, required this.title, this.isFullScreen = false});

  @override
  HomeMapViewState createState() => HomeMapViewState();
}

class HomeMapViewState extends State<HomeMapView> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _mapCompleter =
      Completer<GoogleMapController>();
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    final locationController = Get.find<LocationController>();
    final address = locationController.getUserAddress();
    if (address != null &&
        address.latitude != null &&
        address.longitude != null) {
      _initialPosition = LatLng(address.latitude!, address.longitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  void _animateToPosition(LatLng pos) {
    if (!mounted || _mapController == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapController != null) {
        try {
          _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        final address = locationController.getUserAddress();
        if (address != null &&
            address.latitude != null &&
            address.longitude != null) {
          final newPos = LatLng(address.latitude!, address.longitude!);
          if (_initialPosition == null ||
              _initialPosition!.latitude != newPos.latitude ||
              _initialPosition!.longitude != newPos.longitude) {
            _initialPosition = newPos;
            _animateToPosition(newPos);
          }
        }

        final LatLng targetPosition = _initialPosition ?? const LatLng(0, 0);

        return GetBuilder<MapController>(
          id: 'home_map_markers',
          builder: (mapController) {
            final Widget mapWidget = RepaintBoundary(
              child: GoogleMap(
                style: Get.isDarkMode
                    ? Get.find<ThemeController>().darkMap
                    : Get.find<ThemeController>().lightMap,
                markers:
                    mapController.nearestDeliveryManMarkers ?? {},
                initialCameraPosition: CameraPosition(
                  target: targetPosition,
                  zoom: 14,
                ),
                minMaxZoomPreference:
                    const MinMaxZoomPreference(0, 18),
                gestureRecognizers:
                    <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (gController) {
                  if (!_mapCompleter.isCompleted) {
                    _mapCompleter.complete(gController);
                    _mapController = gController;
                    mapController.setMapController(gController);
                    if (_initialPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_initialPosition!),
                      );
                    }
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                compassEnabled: false,
                mapToolbarEnabled: false,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                buildingsEnabled: true,
                trafficEnabled: false,
                indoorViewEnabled: false,
              ),
            );

            if (widget.isFullScreen) {
              return SizedBox.expand(child: mapWidget);
            }

            return Padding(
              padding:
                  const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: Column(
                children: [
                  CustomTitle(
                    title: widget.title.tr,
                    color: Get.isDarkMode
                        ? Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withValues(alpha: 0.9)
                        : Theme.of(context).textTheme.bodyLarge!.color,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Container(
                    height: Get.height * 0.25,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                      child: mapWidget,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
