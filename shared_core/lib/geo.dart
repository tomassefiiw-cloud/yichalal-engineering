import 'package:geolocator/geolocator.dart';

/// Thin wrapper over geolocator with friendly error handling.
class Geo {
  /// Request permission + get current position. Returns null on any failure
  /// (denied, disabled, timeout) — caller can fall back to address-based coords.
  static Future<Position?> current({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Open the system settings page so the user can grant permission manually.
  static Future<void> openAppSettings() => Geolocator.openAppSettings();
}
