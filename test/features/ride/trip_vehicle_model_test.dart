import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/bidding_model.dart';

void main() {
  group('Vehicle Model vehicle_color Tests', () {
    test('Vehicle.fromJson parses vehicle_color correctly when present', () {
      final json = {
        'licence_plate_number': '1234 ABC',
        'vehicle_color': 'White',
        'vin_number': 'VIN987654321',
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.vehicleColor, 'White');
      expect(vehicle.licencePlateNumber, '1234 ABC');
      expect(vehicle.vinNumber, 'VIN987654321');
    });

    test('Vehicle.fromJson handles null or missing vehicle_color gracefully', () {
      final jsonMissing = {
        'licence_plate_number': '5678 XYZ',
      };
      final jsonNull = {
        'licence_plate_number': '5678 XYZ',
        'vehicle_color': null,
      };

      final vehicleMissing = Vehicle.fromJson(jsonMissing);
      final vehicleNull = Vehicle.fromJson(jsonNull);

      expect(vehicleMissing.vehicleColor, isNull);
      expect(vehicleNull.vehicleColor, isNull);
    });

    test('Vehicle.toJson preserves vehicle_color in output map', () {
      final vehicle = Vehicle(
        licencePlateNumber: '9999 DEF',
        vehicleColor: 'Silver',
      );

      final json = vehicle.toJson();

      expect(json['vehicle_color'], 'Silver');
      expect(json['licence_plate_number'], '9999 DEF');
    });

    test('Driver and TripDetails correctly deserialize Vehicle with vehicle_color', () {
      final driverJson = {
        'id': 'drv-1',
        'first_name': 'Fatima',
        'last_name': 'Ali',
        'vehicle': {
          'licence_plate_number': '1111 GHI',
          'vehicle_color': 'Red',
          'model': {
            'id': 'm-1',
            'name': 'Toyota Camry',
            'is_active': true,
          },
        },
      };

      final driver = Driver.fromJson(driverJson);

      expect(driver.vehicle, isNotNull);
      expect(driver.vehicle?.vehicleColor, 'Red');
      expect(driver.vehicle?.model?.name, 'Toyota Camry');
    });

    test('Bidding correctly deserializes driver vehicle color', () {
      final bidJson = {
        'id': 'bid-100',
        'bid_fare': '45.50',
        'driver': {
          'id': 'drv-2',
          'first_name': 'Sarah',
          'vehicle': {
            'licence_plate_number': '2222 JKL',
            'vehicle_color': 'Black',
            'model': {
              'id': 'm-2',
              'name': 'Hyundai Elantra',
              'is_active': true,
            },
          },
        },
      };

      final bidding = Bidding.fromJson(bidJson);

      expect(bidding.driver?.vehicle?.vehicleColor, 'Black');
      expect(bidding.driver?.vehicle?.licencePlateNumber, '2222 JKL');
    });
  });
}
