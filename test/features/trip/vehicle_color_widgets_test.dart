import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/bidding_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/remaining_distance_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/rider_details_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/rider_details.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/rider_info.dart';

class FakeLocalizationController extends GetxController implements LocalizationController {
  @override
  bool get isLtr => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeConfigController extends GetxController implements ConfigController {
  @override
  ConfigModel? get config => ConfigModel(
        imageBaseUrl: ImageBaseUrl(
          profileImageDriver: 'https://example.com/driver',
          vehicleModel: 'https://example.com/vehicle',
        ),
        currencySymbol: 'SAR',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeRideController extends GetxController implements RideController {
  TripDetails? _tripDetails;

  @override
  TripDetails? get tripDetails => _tripDetails;

  @override
  List<RemainingDistanceModel> remainingDistanceModel = [];

  void setTripDetails(TripDetails? details) {
    _tripDetails = details;
    update();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late FakeRideController fakeRideController;
  late FakeConfigController fakeConfigController;
  late FakeLocalizationController fakeLocalizationController;

  setUp(() {
    fakeRideController = FakeRideController();
    fakeConfigController = FakeConfigController();
    fakeLocalizationController = FakeLocalizationController();
    Get.put<RideController>(fakeRideController);
    Get.put<ConfigController>(fakeConfigController);
    Get.put<LocalizationController>(fakeLocalizationController);
  });

  tearDown(() {
    Get.reset();
  });

  group('RiderInfo Widget - Vehicle Color Tests', () {
    testWidgets('Displays Model and Color separated by bullet when vehicleColor is present',
        (tester) async {
      final tripDetails = TripDetails(
        vehicle: Vehicle(
          licencePlateNumber: '1234 ABC',
          vehicleColor: 'Pearl White',
          model: Model(name: 'Toyota Corolla'),
        ),
        vehicleCategory: VehicleCategory(name: 'Sedan'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RiderInfo(tripDetails: tripDetails),
          ),
        ),
      );

      expect(find.text('Toyota Corolla • Pearl White'), findsOneWidget);
      expect(find.text('1234 ABC'), findsOneWidget);
    });

    testWidgets('Displays only Model without bullet when vehicleColor is null or whitespace',
        (tester) async {
      final tripDetailsNull = TripDetails(
        vehicle: Vehicle(
          licencePlateNumber: '5678 DEF',
          vehicleColor: null,
          model: Model(name: 'Hyundai Elantra'),
        ),
        vehicleCategory: VehicleCategory(name: 'Sedan'),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RiderInfo(tripDetails: tripDetailsNull),
          ),
        ),
      );

      expect(find.text('Hyundai Elantra'), findsOneWidget);
      expect(find.textContaining('•'), findsNothing);
    });
  });

  group('ActivityScreenRiderDetails Widget - Vehicle Color Tests', () {
    testWidgets('Displays Plate Number and Color separated by bullet when vehicleColor is present',
        (tester) async {
      final tripDetails = TripDetails(
        vehicle: Vehicle(
          licencePlateNumber: '9999 XYZ',
          vehicleColor: 'Midnight Black',
          model: Model(name: 'Kia Cerato'),
        ),
      );
      fakeRideController.setTripDetails(tripDetails);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: ActivityScreenRiderDetails(),
              ),
            ),
          ),
        ),
      );

      final plateWithColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('9999 XYZ • Midnight Black'),
      );
      expect(plateWithColorFinder, findsOneWidget);
      expect(find.text('Kia Cerato'), findsOneWidget);
    });

    testWidgets('Displays only Plate Number without bullet when vehicleColor is null or empty',
        (tester) async {
      final tripDetails = TripDetails(
        vehicle: Vehicle(
          licencePlateNumber: '4321 JKL',
          vehicleColor: '   ',
          model: Model(name: 'Nissan Sunny'),
        ),
      );
      fakeRideController.setTripDetails(tripDetails);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: ActivityScreenRiderDetails(),
              ),
            ),
          ),
        ),
      );

      final plateOnlyFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('4321 JKL') &&
            !widget.text.toPlainText().contains('•'),
      );
      expect(plateOnlyFinder, findsOneWidget);
    });
  });

  group('RiderDetailsWidget (Bidding) - Vehicle Color Tests', () {
    testWidgets('Displays Model and Color separated by bullet on bidding card',
        (tester) async {
      final bidding = Bidding(
        id: 'bid-1',
        bidFare: 75.0,
        driverAvgRating: '4.9',
        driver: Driver(
          firstName: 'Amira',
          lastName: 'Hassan',
          profileImage: 'profile.jpg',
          vehicle: Vehicle(
            vehicleColor: 'Silver',
            model: Model(name: 'Renault Megane'),
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RiderDetailsWidget(
              tripId: 'trip-1',
              bidding: bidding,
            ),
          ),
        ),
      );

      final modelWithColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Renault Megane • Silver'),
      );
      expect(modelWithColorFinder, findsOneWidget);
    });

    testWidgets('Displays only Model on bidding card when vehicleColor is omitted',
        (tester) async {
      final bidding = Bidding(
        id: 'bid-2',
        bidFare: 50.0,
        driverAvgRating: '4.8',
        driver: Driver(
          firstName: 'Nour',
          lastName: 'Khaled',
          profileImage: 'profile.jpg',
          vehicle: Vehicle(
            vehicleColor: null,
            model: Model(name: 'Honda Civic'),
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RiderDetailsWidget(
              tripId: 'trip-2',
              bidding: bidding,
            ),
          ),
        ),
      );

      final modelOnlyFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Honda Civic') &&
            !widget.text.toPlainText().contains('•'),
      );
      expect(modelOnlyFinder, findsOneWidget);
    });
  });
}
