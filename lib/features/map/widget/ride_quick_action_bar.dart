import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ride_sharing_user_app/features/payment/controllers/payment_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/set_destination/widget/schedule_date_time_picker_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/helper/ride_controller_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class RideQuickActionBar extends StatelessWidget {
  const RideQuickActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return GetBuilder<RideController>(builder: (rideController) {
      return GetBuilder<PaymentController>(builder: (paymentController) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.hintColor.withValues(alpha: 0.14),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // 1. Pickup Time Pill
              Expanded(
                child: _buildPickupTimeSection(context, rideController, theme),
              ),

              // Vertical divider
              Container(
                height: 22,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: theme.hintColor.withValues(alpha: 0.2),
              ),

              // 2. Payment Method Pill
              Expanded(
                child: _buildPaymentSection(
                  context,
                  paymentController,
                  rideController,
                  theme,
                ),
              ),
            ],
          ),
        );
      });
    });
  }

  Widget _buildPickupTimeSection(
    BuildContext context,
    RideController rideController,
    ThemeData theme,
  ) {
    final isScheduled = rideController.rideType == RideType.scheduleRide;
    final scheduledText = isScheduled
        ? '${DateFormat('d MMM').format(RideControllerHelper.dateFormatToShow(rideController.scheduleTripDate))}, '
            '${DateFormat('hh:mm a').format(RideControllerHelper.timeFormatToShow(rideController.scheduleTripTime))}'
        : 'pickup_now'.tr;

    return InkWell(
      onTap: () {
        if (Get.find<ConfigController>().config?.scheduleTripStatus ?? false) {
          Get.bottomSheet(
            const ScheduleDateTimePickerWidget(),
            enableDrag: false,
            isScrollControlled: true,
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScheduled ? Icons.calendar_today_rounded : Icons.access_time_rounded,
              size: 18,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                scheduledText,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault - 0.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(
    BuildContext context,
    PaymentController paymentController,
    RideController rideController,
    ThemeData theme,
  ) {
    final selectedPayment = paymentController.paymentTypeIndex == 0
        ? 'cash'
        : paymentController.paymentTypeIndex == 1
            ? 'digital'
            : 'wallet';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedPayment,
        isDense: true,
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: theme.hintColor,
        ),
        items: paymentController.paymentTypeList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  value == 'cash'
                      ? Images.paymentTypeIcon
                      : value == 'wallet'
                          ? Images.profileMyWallet
                          : Images.paymentTypeIcon,
                  height: 16,
                  width: 16,
                  color: theme.primaryColor,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value.tr,
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault - 0.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          final double fare = rideController.discountAmount.toDouble() > 0
              ? rideController.discountFare
              : rideController.estimatedFare;
          final double walletBalance = Get.find<ProfileController>()
                  .profileModel
                  ?.data
                  ?.wallet
                  ?.walletBalance ??
              0.0;

          if (value == 'wallet' && fare > walletBalance) {
            showCustomSnackBar(
              'your_wallet_has_insufficient_balance'.tr,
              isError: true,
              subMessage:
                  '${'wallet_balance'.tr}: ${PriceConverter.convertPrice(walletBalance)}',
            );
          } else {
            paymentController.setPaymentType(
              value == 'cash' ? 0 : value == 'digital' ? 1 : 2,
            );
          }
        },
      ),
    );
  }
}
