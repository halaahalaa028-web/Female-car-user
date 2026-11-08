import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/address/domain/models/address_model.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/domain/repositories/category_repo.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/location/domain/services/location_service_interface.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/services/config_service_interface.dart';

import 'package:ride_sharing_user_app/features/coupon/controllers/coupon_controller.dart';
import 'package:ride_sharing_user_app/features/coupon/domain/services/coupon_service_interface.dart';

class MockApiClient extends ApiClient {
  MockApiClient({required super.sharedPreferences}) : super(appBaseUrl: 'https://mock.test');
  @override
  void updateHeader(String? updateToken, Address? address, {String? zoneId}) {}
}

class MockCouponService implements CouponServiceInterface {
  @override
  Future customerAppliedCoupon(String couponId) async => const Response(statusCode: 200);
  @override
  Future getCouponList(String categoryType, {int? offset = 1}) async => const Response(statusCode: 200, body: <String, dynamic>{'data': []});
}

class MockConfigService implements ConfigServiceInterface {
  @override
  void disableIntro() {}
  @override
  Future getConfigData() async => const Response(statusCode: 200, body: {});
  @override
  bool haveOngoingRides() => false;
  @override
  Future<bool> initSharedData() async => true;
  @override
  Future<bool> removeSharedData() async => true;
  @override
  void saveOngoingRides(bool value) {}
  @override
  bool? showIntro() => false;
}

class MockLocationService implements LocationServiceInterface {
  @override
  Future<Response> getAddressFromGeocode(LatLng? latLng) async => const Response(statusCode: 200, body: {});
  @override
  Future<Response> searchLocation(String text) async => const Response(statusCode: 200, body: {});
  @override
  Future getZone(String lat, String lng) async => const Response(statusCode: 200, body: {'data': {'id': 'zone_1'}});
  @override
  Future getPlaceDetails(String placeID) async => const Response(statusCode: 200, body: {});
  @override
  Future<bool> saveUserAddress(Address? address) async => true;
  @override
  String? getUserAddress() => null;
}

class TestLocationController extends LocationController {
  TestLocationController({required super.locationServiceInterface});

  @override
  Future<Address?> getCurrentLocation({bool isAnimate = false, GoogleMapController? mapController, LocationType type = LocationType.from}) async {
    return Address(latitude: 30.0444, longitude: 31.2357, address: 'Cairo');
  }
}

class MockParcelService implements ParcelServiceInterface {
  @override
  Future getParcelCategory() async => const Response(statusCode: 200, body: {});
  @override
  Future getSuggestedVehicleCategory(String weight) async => const Response(statusCode: 200, body: {});
  @override
  Future getRunningParcelList(int offset) async => const Response(statusCode: 200, body: {});
  @override
  Future getUnpaidParcelList(int offset) async => const Response(statusCode: 200, body: {});
}

class MockCategoryRepo extends CategoryRepo {
  MockCategoryRepo({required super.apiClient});
  @override
  Future<Response?> getCategoryList() async => const Response(statusCode: 200, body: {'data': []});
}

class MockRideService implements RideServiceInterface {
  int fareCalls = 0;

  @override
  Future<Response> getEstimatedFare({
    required LatLng pickupLatLng,
    required LatLng destinationLatLng,
    required LatLng currentLatLng,
    required String type,
    required String pickupAddress,
    required String destinationAddress,
    LatLng? extraOneLatLng = const LatLng(0, 0),
    LatLng? extraTwoLatLng = const LatLng(0, 0),
    bool extraOne = false,
    bool extraTwo = false,
    String? parcelWeight,
    String? parcelCategoryId,
    String? rideRequestType,
    required String? scheduledAt,
  }) async {
    fareCalls++;
    return const Response(
      statusCode: 200,
      body: {
        'data': [
          {
            'id': 'fare_1',
            'zone_id': 'zone_1',
            'vehicle_category_id': 'cat_1',
            'vehicle_category_type': 'Car',
            'base_fare': 10.0,
            'base_fare_per_km': 5.0,
            'fare': 55.0,
            'estimated_distance': '10 km',
            'estimated_duration': '20 mins',
            'estimated_fare': 55.0,
            'encoded_polyline': 'mock_encoded_polyline',
            'discount_amount': 0.0,
            'discount_fare': 55.0,
            'coupon_applicable': false,
          }
        ]
      },
    );
  }

  @override
  Future biddingList(String tripId, int offset) async => const Response(statusCode: 200);
  @override
  Future getCurrentRegularRide() async => const Response(statusCode: 200);
  @override
  Future getDirection({required LatLng pickupLatLng, required LatLng destinationLatLng, required LatLng extraOneLatLng, required LatLng extraTwoLatLng}) async => const Response(statusCode: 200);
  @override
  Future getDriverLocation(String tripId) async => const Response(statusCode: 200);
  @override
  Future getFinalFare(String id) async => const Response(statusCode: 200);
  @override
  Future getRideDetails(String tripId) async => const Response(statusCode: 200);
  @override
  Future getRunningRideList() async => const Response(statusCode: 200);
  @override
  Future ignoreBidding(String biddingId) async => const Response(statusCode: 200);
  @override
  Future nearestDriverList(String lat, String lng) async => const Response(statusCode: 200);
  @override
  Future parcelReceived(String tripId) async => const Response(statusCode: 200);
  @override
  Future remainDistance(String requestID) async => const Response(statusCode: 200);
  @override
  Future submitRideRequest({required String pickupLat, required String pickupLng, required String destinationLat, required String destinationLng, required String customerCurrentLat, required String customerCurrentLng, required String vehicleCategoryId, required String estimatedDistance, required String estimatedTime, required String estimatedFare, required String actualFare, required String note, required bool bid, required String paymentMethod, required String type, required String pickupAddress, required String destinationAddress, required String encodedPolyline, required List<String> middleAddress, required String entrance, required double extraEstimatedFare, required double extraDiscountFare, required double extraDiscountAmount, required double extraReturnFee, required double extraCancellationFee, required double extraFareAmount, required double extraFareFee, required String? zoneId, String? areaId, String extraLatOne = '', String extraLngOne = '', String extraLatTwo = '', String extraLngTwo = '', bool extraOne = false, bool extraTwo = false, String? senderName, String? senderPhone, String? senderAddress, String? receiverName, String? receiverPhone, String? receiverAddress, String? parcelCategoryId, String? weight, String? payer, String? tripRequestId, double? returnFee, double? cancellationFee, required String? scheduledAt, String? rideRequestType, double? surgeMultiplier}) async => const Response(statusCode: 200);
  @override
  Future tripAcceptOrReject(String tripId, String type, String driverId) async => const Response(statusCode: 200);
  @override
  Future tripStatusUpdate(String id, String status, String cancellationCause) async => const Response(statusCode: 200);
  @override
  Future updateScheduleTripTimeDate(String? tripId, String? scheduledAt) async => const Response(statusCode: 200);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRideService mockRideService;
  late RideController rideController;
  late TestLocationController locationController;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final apiClient = MockApiClient(sharedPreferences: sp);
    Get.put<ApiClient>(apiClient);

    Get.put<ConfigController>(ConfigController(configServiceInterface: MockConfigService()));

    locationController = TestLocationController(locationServiceInterface: MockLocationService());
    Get.put<LocationController>(locationController);

    Get.put<ParcelController>(ParcelController(parcelServiceInterface: MockParcelService()));
    Get.put<CouponController>(CouponController(couponServiceInterface: MockCouponService()));
    Get.put<CategoryController>(CategoryController(categoryRepo: MockCategoryRepo(apiClient: apiClient)));

    mockRideService = MockRideService();
    rideController = RideController(rideServiceInterface: mockRideService);
    Get.put<RideController>(rideController);

    locationController.fromAddress = Address(latitude: 30.0444, longitude: 31.2357, address: 'Tahrir Square');
    locationController.toAddress = Address(latitude: 30.0626, longitude: 31.2497, address: 'Ramses Station');
  });

  tearDown(() {
    Get.reset();
  });

  group('RideController Fare Estimation Memoization Tests', () {
    test('First getEstimatedFare makes network call and caches response', () async {
      final response = await rideController.getEstimatedFare(false);

      expect(response.statusCode, 200);
      expect(mockRideService.fareCalls, 1);
      expect(rideController.fareList.length, 1);
      expect(rideController.fareList.first.estimatedFare, 55.0);
    });

    test('Second getEstimatedFare with identical coordinates returns cached response', () async {
      // First call -> network request
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 1);

      // Second call -> cached, 0 network requests
      final cachedResponse = await rideController.getEstimatedFare(false);
      expect(cachedResponse.statusCode, 200);
      expect(mockRideService.fareCalls, 1); // Remains 1!
    });

    test('getEstimatedFare with changed coordinates makes a new network call', () async {
      // First call
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 1);

      // User changes destination coordinates
      locationController.toAddress = Address(latitude: 30.0800, longitude: 31.3200, address: 'Nasr City');

      // Second call -> cache miss, network request fired
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 2);
    });

    test('getEstimatedFare with forceUpdate: true bypasses cache', () async {
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 1);

      // Force update bypasses memoized response
      await rideController.getEstimatedFare(false, forceUpdate: true);
      expect(mockRideService.fareCalls, 2);
    });

    test('clearFareCache and initData invalidate the cache', () async {
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 1);

      // Clear cache
      rideController.clearFareCache();

      // Next call triggers network request
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 2);

      // initData also clears cache
      rideController.initData();
      await rideController.getEstimatedFare(false);
      expect(mockRideService.fareCalls, 3);
    });
  });
}
