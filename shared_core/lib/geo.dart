import 'package:location/location.dart' as loc;

/// Thin wrapper over the `location` plugin (which uses Google Play Services
/// when available, otherwise raw Android Location Manager). Compatible with
/// Flutter 3.24 + AGP 8.3 + compileSdk 35.
class GeoPos {
  final double latitude;
  final double longitude;
  final double? accuracy;
  GeoPos(this.latitude, this.longitude, {this.accuracy});
}

class Geo {
  static final loc.Location _loc = loc.Location();

  /// Request permission + get current position. Returns null on any failure
  /// (denied, disabled, timeout) — caller falls back to address-based coords.
  static Future<GeoPos?> current() async {
    try {
      bool serviceEnabled = await _loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _loc.requestService();
        if (!serviceEnabled) return null;
      }
      var perm = await _loc.hasPermission();
      if (perm == loc.PermissionStatus.denied) {
        perm = await _loc.requestPermission();
      }
      if (perm != loc.PermissionStatus.granted && perm != loc.PermissionStatus.grantedLimited) {
        return null;
      }
      final d = await _loc.getLocation();
      if (d.latitude == null || d.longitude == null) return null;
      return GeoPos(d.latitude!, d.longitude!, accuracy: d.accuracy);
    } catch (_) {
      return null;
    }
  }
}
