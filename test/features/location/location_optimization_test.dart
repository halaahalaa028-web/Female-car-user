import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/location/domain/services/location_service_interface.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';

class MockLocationService implements LocationServiceInterface {
  int geocodeCalls = 0;
  int searchCalls = 0;

  @override
  Future<Response> getAddressFromGeocode(LatLng? latLng) async {
    geocodeCalls++;
    return const Response(
      statusCode: 200,
      body: {
        'data': {
          'results': [
            {'formatted_address': 'Mock Address, Cairo, Egypt'}
          ]
        }
      },
    );
  }

  @override
  Future<Response> searchLocation(String text) async {
    searchCalls++;
    return const Response(
      statusCode: 200,
      body: {
        'response_code': 'default_200',
        'message': 'success',
        'data': {
          'suggestions': [
            {
              'placePrediction': {
                'text': {'text': 'Mock Place, Cairo'}
              }
            }
          ]
        },
        'errors': <String>[]
      },
    );
  }

  @override
  Future getZone(String lat, String lng) async => const Response(statusCode: 200, body: {'data': {'id': 'zone_1'}});

  @override
  Future getPlaceDetails(String placeID) async => const Response(statusCode: 200, body: {});

  @override
  Future<bool> saveUserAddress(Address? address) async => true;

  @override
  String? getUserAddress() => null;
}

class MockApiClient extends ApiClient {
  MockApiClient({required super.sharedPreferences}) : super(appBaseUrl: 'https://mock.test');
  @override
  void updateHeader(String? updateToken, Address? address, {String? zoneId}) {}
}

class TestLocationController extends LocationController {
  TestLocationController({required super.locationServiceInterface});

  @override
  Future<Address?> getCurrentLocation({bool isAnimate = false, GoogleMapController? mapController, LocationType type = LocationType.from}) async {
    return Address(latitude: 30.0444, longitude: 31.2357, address: 'Cairo');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocationService mockService;
  late TestLocationController controller;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    Get.put<ApiClient>(MockApiClient(sharedPreferences: sp));
    mockService = MockLocationService();
    controller = TestLocationController(locationServiceInterface: mockService);
    Get.put<LocationController>(controller);
  });

  tearDown(() {
    controller.onClose();
  });

  group('LocationController Google Maps Optimization Tests', () {
    testWidgets('searchLocation ignores queries with length < 3', (tester) async {
      final context = tester.element(find.byType(Container));

      await tester.pumpWidget(Container());
      final result1 = await controller.searchLocation(context, 'a');
      final result2 = await controller.searchLocation(context, 'ab');

      expect(mockService.searchCalls, 0);
      expect(result1, isEmpty);
      expect(result2, isEmpty);
    });

    testWidgets('searchLocation debounces network calls within 400ms', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));

      // Fast typing: "cai", "cair", "cairo"
      controller.searchLocation(context, 'cai');
      await tester.pump(const Duration(milliseconds: 100));

      controller.searchLocation(context, 'cair');
      await tester.pump(const Duration(milliseconds: 100));

      final future = controller.searchLocation(context, 'cairo');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      final result = await future;

      // Only the last debounced request should hit the service
      expect(mockService.searchCalls, 1);
      expect(result, isNotEmpty);
    });

    testWidgets('searchLocation returns cached results on repeated queries', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));

      // First search
      final future1 = controller.searchLocation(context, 'Degla');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await future1;
      expect(mockService.searchCalls, 1);

      // Second identical search
      final result2 = await controller.searchLocation(context, 'degla');
      expect(mockService.searchCalls, 1); // No new network call!
      expect(result2, isNotEmpty);
    });

    test('getAddressFromGeocode caches results by ~11m precision coordinates', () async {
      const latLng1 = LatLng(30.044412, 31.235712);
      const latLngProximate = LatLng(30.044418, 31.235718); // Differs by < 1 meter
      const latLngFar = LatLng(30.055500, 31.240000);

      // 1. Initial geocode call
      final addr1 = await controller.getAddressFromGeocode(latLng1);
      expect(mockService.geocodeCalls, 1);
      expect(addr1, 'Mock Address, Cairo, Egypt');

      // 2. Proximate location within ~11 meters (same 4 decimal places) -> Cache hit!
      final addr2 = await controller.getAddressFromGeocode(latLngProximate);
      expect(mockService.geocodeCalls, 1); // No new network call!
      expect(addr2, 'Mock Address, Cairo, Egypt');

      // 3. Different location -> Cache miss, calls service
      await controller.getAddressFromGeocode(latLngFar);
      expect(mockService.geocodeCalls, 2);
    });

    testWidgets('updatePosition debounces rapid camera movements within 300ms', (tester) async {
      await tester.pumpWidget(Container());

      // Simulate dragging map rapidly across 3 positions
      controller.updatePosition(const LatLng(30.0100, 31.0100), false, null);
      await tester.pump(const Duration(milliseconds: 100));

      controller.updatePosition(const LatLng(30.0200, 31.0200), false, null);
      await tester.pump(const Duration(milliseconds: 100));

      controller.updatePosition(const LatLng(30.0300, 31.0300), false, null);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Only the final resting position triggers geocode
      expect(mockService.geocodeCalls, 1);
    });
  });
}
