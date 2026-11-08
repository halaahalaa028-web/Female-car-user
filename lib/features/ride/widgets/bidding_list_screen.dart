import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/parcel/widgets/driver_request_dialog.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/no_data_widget.dart';

class BiddingListScreen extends StatefulWidget {
  final String tripId;
  final bool fromList;
  const BiddingListScreen(
      {super.key, required this.tripId, this.fromList = false});

  @override
  State<BiddingListScreen> createState() => _BiddingListScreenState();
}

class _BiddingListScreenState extends State<BiddingListScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBiddingList();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _refreshBiddingList();
      });
    });
  }

  void _refreshBiddingList() {
    if (!mounted) {
      return;
    }
    final RideController rideController = Get.find<RideController>();
    if (!rideController.isLoading) {
      rideController.getBiddingList(widget.tripId, 1);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideController>(builder: (rideController) {
        return BodyWidget(
          appBar: AppBarWidget(
            title: 'bidding_list'.tr,
          ),
          body: rideController.biddingList.isNotEmpty
              ? DriverRideRequestDialog(
                  tripId: widget.tripId, fromList: widget.fromList)
              : const NoDataWidget(title: 'no_bid_request_found'),
        );
      }),
    );
  }
}
