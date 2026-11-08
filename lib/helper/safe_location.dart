import 'package:geolocator/geolocator.dart';

/// Reads the device position without ever throwing: returns null when the
/// location service is off, the permission is denied (or can't be determined)
/// or the platform call fails/times out.
class SafeLocation {
  static Future<Position?> currentPosition({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return null;
      }
      return await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: accuracy));
    } catch (_) {
      return null;
    }
  }
}
