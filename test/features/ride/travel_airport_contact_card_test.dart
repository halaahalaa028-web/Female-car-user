import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/travel_airport_contact_card.dart';

void main() {
  testWidgets('TravelAirportContactCard renders contact numbers and action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: TravelAirportContactCard(),
        ),
      ),
    );

    // Verify header title
    expect(find.text('للتواصل والحجز المباشر'), findsOneWidget);

    // Verify phone numbers are present
    expect(find.text('01022150503'), findsOneWidget);
    expect(find.text('01151444494'), findsOneWidget);

    // Verify action buttons
    expect(find.text('اتصال'), findsNWidgets(2));
    expect(find.text('واتساب'), findsNWidgets(2));
    expect(find.byIcon(Icons.call_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.chat_bubble_rounded), findsNWidgets(2));
  });
}
