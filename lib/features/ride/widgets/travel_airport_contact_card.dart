import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class TravelAirportContactCard extends StatelessWidget {
  const TravelAirportContactCard({super.key});

  static const List<String> contactNumbers = [
    '01022150503',
    '01151444494',
  ];

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final internationalPhone = cleanPhone.startsWith('0') ? '2$cleanPhone' : cleanPhone;
    final message = Uri.encodeComponent('مرحباً، أود الاستفسار عن حجز رحلة');
    final uri = Uri.parse('https://wa.me/$internationalPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Get.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'للتواصل والحجز المباشر',
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'خدمة عملاء رحلات السفر والمطار متوفرة للتنسيق',
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...contactNumbers.map((phone) => _buildPhoneRow(context, theme, phone)),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, ThemeData theme, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.hintColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone_rounded,
              size: 16,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              phone,
              textDirection: TextDirection.ltr,
              style: textRobotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            // WhatsApp Action
            InkWell(
              onTap: () => _openWhatsApp(phone),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 13,
                      color: Color(0xFF25D366),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'واتساب',
                      style: textMedium.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF25D366),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Call Action
            InkWell(
              onTap: () => _makeCall(phone),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'اتصال',
                      style: textMedium.copyWith(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
