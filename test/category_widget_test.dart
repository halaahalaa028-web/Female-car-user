import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/category_widget.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/compact_category_card.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';

class FakeRideController extends GetxController implements RideController {
  int _rideCategoryIndex = 0;
  @override
  int get rideCategoryIndex => _rideCategoryIndex;

  @override
  void setRideCategoryIndex(int index) {
    _rideCategoryIndex = index;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeConfigController extends GetxController implements ConfigController {
  @override
  ConfigModel? get config => ConfigModel(
        imageBaseUrl: ImageBaseUrl(vehicleCategory: 'https://example.com'),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.put<RideController>(FakeRideController());
    Get.put<ConfigController>(FakeConfigController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CategoryWidget displays category name, discount, and fare properly',
      (WidgetTester tester) async {
    final category = Category(
      id: '1',
      name: 'رحلة',
      image: 'car.png',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: CategoryWidget(
            index: 0,
            category: category,
            isSelected: true,
            fareText: '50.00 ج.م',
            originalFareText: '70.00 ج.م',
            discountText: 'خصم 20.00 ج.م',
          ),
        ),
      ),
    );

    expect(find.text('رحلة'), findsOneWidget);
    expect(find.text('خصم 20.00 ج.م'), findsOneWidget);
    expect(find.text('50.00 ج.م'), findsOneWidget);
    expect(find.text('70.00 ج.م'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('CompactCategoryCard displays name, framed image, and fare without overflow',
      (WidgetTester tester) async {
    final category = Category(
      id: '1',
      name: 'مطار',
      image: 'airport.png',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: CompactCategoryCard(
              index: 0,
              category: category,
              isSelected: true,
              fareText: '25.0 ج.م',
              discountText: 'خصم 10.0 ج.م',
              showFare: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('مطار'), findsOneWidget);
    expect(find.text('25.0 ج.م'), findsOneWidget);
    expect(find.text('خصم 10.0 ج.م'), findsOneWidget);
  });
}
