import 'dart:math' as math;
import 'package:dio/dio.dart';

Future<T> retry<T>(Future<T> Function() fn, {int n = 3}) async {
  for (var i = 0; i < n; i++) {
    try {
      return await fn();
    } catch (_) {
      if (i == n - 1) rethrow;
      await Future.delayed(Duration(milliseconds: 800 * (i + 1)));
    }
  }
  throw Exception('unreachable');
}

Future<String> fetchAddress(double? lat, double? lon) async {
  if (lat == null || lon == null) return 'Coordinates unavailable';
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
    );
    if (response.statusCode == 200 && response.data['display_name'] != null) {
      return response.data['display_name'];
    }
    return 'Address not found';
  } catch (e) {
    return 'Error fetching address: $e';
  }
}

double distKm(Map<String, double> a, Map<String, double> b) {
  const R = 6371.0;
  final dLat = (b['lat']! - a['lat']!) * math.pi / 180;
  final dLon = (b['lon']! - a['lon']!) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(a['lat']! * math.pi / 180) *
          math.cos(b['lat']! * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}