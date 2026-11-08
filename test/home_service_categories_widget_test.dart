import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_service_categories_widget.dart';

void main() {
  testWidgets('HomeServiceCategoriesWidget renders trip and removes parcel',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: HomeServiceCategoriesWidget(),
        ),
      ),
    );

    // Verify trip car icon is present
    expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);

    // Verify parcel inventory icon is NOT present
    expect(find.byIcon(Icons.inventory_2_rounded), findsNothing);
  });
}
