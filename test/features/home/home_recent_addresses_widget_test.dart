import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/address/controllers/address_controller.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/address/domain/services/address_service_interface.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_recent_addresses_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAddressService implements AddressServiceInterface {
  @override
  Future add(Address address) async => null;

  @override
  Future delete(String id) async => null;

  @override
  Future getList({int? offset = 1}) async => null;

  @override
  Future getRecentAddressList() async => null;

  @override
  Future update(Address address) async => null;

  @override
  Future updateLastLocation(String lat, String lng, String zoneID) async => null;
}

void main() {
  late AddressController addressController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs);

    addressController = AddressController(addressServiceInterface: MockAddressService());
    Get.put<AddressController>(addressController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('HomeRecentAddressesWidget renders nothing when recent list is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: HomeRecentAddressesWidget(),
        ),
      ),
    );

    expect(find.byIcon(Icons.history_rounded), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('HomeRecentAddressesWidget renders items when addresses exist',
      (WidgetTester tester) async {
    addressController.recentAddressList = [
      Address(
        id: 1,
        address: 'Cairo Festival City, New Cairo, Egypt',
        latitude: 30.03,
        longitude: 31.41,
      ),
      Address(
        id: 2,
        address: 'Tahrir Square, Downtown, Cairo, Egypt',
        latitude: 30.04,
        longitude: 31.23,
      ),
    ];
    addressController.update();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: HomeRecentAddressesWidget(),
        ),
      ),
    );

    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.text('Cairo Festival City'), findsOneWidget);
    expect(find.text('New Cairo, Egypt'), findsOneWidget);
    expect(find.text('Tahrir Square'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsNWidgets(2));
  });

  testWidgets('HomeRecentAddressesWidget clears addresses on clear tap',
      (WidgetTester tester) async {
    addressController.recentAddressList = [
      Address(id: 1, address: 'Zamalek, Cairo', latitude: 30.06, longitude: 31.22),
    ];
    addressController.update();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: HomeRecentAddressesWidget(),
        ),
      ),
    );

    expect(find.text('Zamalek'), findsOneWidget);

    // Tap clear button
    final clearFinder = find.text('Clear');
    expect(clearFinder, findsOneWidget);
    await tester.tap(clearFinder);
    await tester.pump();

    expect(addressController.recentAddressList, isEmpty);
    expect(find.byIcon(Icons.history_rounded), findsNothing);
  });
}
