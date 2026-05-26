import 'dart:math';
import 'package:intl/intl.dart';

class Fmt {
  static final _etb = NumberFormat.currency(locale: 'en_US', symbol: 'ETB ', decimalDigits: 0);
  static String etb(num v) => _etb.format(v);
  static String etbRange(num lo, num hi) => '${etb(lo)} – ${etb(hi)}';
  static String dateTime(DateTime d) => DateFormat('dd MMM yyyy, HH:mm').format(d);
  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String dist(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toStringAsFixed(0)} m';

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
