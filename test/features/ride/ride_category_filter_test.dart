import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/home/domain/repositories/category_repo.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/estimated_fare_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';
import 'package:ride_sharing_user_app/features/coupon/controllers/coupon_controller.dart';
import 'package:ride_sharing_user_app/features/coupon/domain/services/coupon_service_interface.dart';

class MockRideService implements RideServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryRepo implements CategoryRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCouponService implements CouponServiceInterface {
  @override
  Future<dynamic> getCouponList(String categoryType, {int? offset = 1}) async =>
      const Response(statusCode: 200, body: {'data': []});

  @override
  Future<dynamic> customerAppliedCoupon(String couponId) async =>
      const Response(statusCode: 200);
}

void main() {
  late RideController rideController;
  late CategoryController categoryController;

  setUp(() {
    Get.testMode = true;
    final couponController = CouponController(couponServiceInterface: MockCouponService());
    Get.put<CouponController>(couponController);

    categoryController = CategoryController(categoryRepo: MockCategoryRepo());
    categoryController.categoryList = [
      Category(id: 'cat_travel', name: 'سفر'),
      Category(id: 'cat_trip', name: 'رحلة'),
      Category(id: 'cat_airport', name: 'مطار'),
    ];
    Get.put<CategoryController>(categoryController);

    rideController = RideController(rideServiceInterface: MockRideService());
    rideController.fareList = [
      FareModel(vehicleCategoryId: 'cat_travel', vehicleCategoryType: 'سفر', estimatedFare: 362.0),
      FareModel(vehicleCategoryId: 'cat_trip', vehicleCategoryType: 'رحلة', estimatedFare: 384.8),
      FareModel(vehicleCategoryId: 'cat_airport', vehicleCategoryType: 'مطار', estimatedFare: 822.1),
    ];
    Get.put<RideController>(rideController);
  });

  tearDown(() {
    Get.reset();
  });

  test('setSelectedCategoryFilter updates state and selects matching category index', () {
    expect(rideController.selectedCategoryFilter, isNull);

    // Select 'سفر'
    rideController.setSelectedCategoryFilter('سفر');
    expect(rideController.selectedCategoryFilter, 'سفر');
    expect(rideController.rideCategoryIndex, 0);
    expect(rideController.selectedCategoryId, 'cat_travel');

    // Select 'مطار'
    rideController.setSelectedCategoryFilter('مطار');
    expect(rideController.selectedCategoryFilter, 'مطار');
    expect(rideController.rideCategoryIndex, 2);
    expect(rideController.selectedCategoryId, 'cat_airport');

    // Select 'رحلة'
    rideController.setSelectedCategoryFilter('رحلة');
    expect(rideController.selectedCategoryFilter, 'رحلة');
    expect(rideController.rideCategoryIndex, 1);
    expect(rideController.selectedCategoryId, 'cat_trip');
  });

  test('clearCategoryFilter resets filter to null', () {
    rideController.setSelectedCategoryFilter('سفر');
    expect(rideController.selectedCategoryFilter, 'سفر');

    rideController.clearCategoryFilter();
    expect(rideController.selectedCategoryFilter, isNull);
  });

  test('resetControllerValue resets selectedCategoryFilter and rideCategoryIndex', () {
    rideController.setSelectedCategoryFilter('مطار');
    expect(rideController.rideCategoryIndex, 2);
    expect(rideController.selectedCategoryFilter, 'مطار');

    rideController.resetControllerValue();
    expect(rideController.selectedCategoryFilter, isNull);
    expect(rideController.rideCategoryIndex, 0);
  });

  test('applyCategoryFilterIfAvailable safely handles unknown category names without crash', () {
    rideController.setSelectedCategoryFilter('غير_موجود');
    expect(rideController.selectedCategoryFilter, 'غير_موجود');
    // Index should remain at previous valid index (0)
    expect(rideController.rideCategoryIndex, 0);
  });
}
