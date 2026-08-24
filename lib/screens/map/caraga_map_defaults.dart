import 'package:google_maps_flutter/google_maps_flutter.dart';

class CaragaMapDefaults {
  const CaragaMapDefaults._();

  static final bounds = LatLngBounds(
    southwest: const LatLng(7.55, 124.65),
    northeast: const LatLng(10.75, 126.85),
  );

  static const _provinceTargets = <String, LatLng>{
    'Agusan del Norte': LatLng(9.0700, 125.5700),
    'Agusan del Sur': LatLng(8.5100, 125.9700),
    'Dinagat Islands': LatLng(10.1300, 125.6100),
    'Surigao del Norte': LatLng(9.7900, 125.5000),
    'Surigao del Sur': LatLng(8.7500, 126.1200),
  };

  static const _localityTargets = <String, LatLng>{
    'Agusan del Norte|Butuan City': LatLng(8.9475, 125.5406),
    'Agusan del Norte|Buenavista': LatLng(8.9760, 125.4080),
    'Agusan del Norte|City of Cabadbaran': LatLng(9.1236, 125.5355),
    'Agusan del Norte|Nasipit': LatLng(8.9853, 125.3392),
    'Agusan del Sur|City of Bayugan': LatLng(8.7566, 125.7675),
    'Agusan del Sur|Prosperidad': LatLng(8.5800, 125.8960),
    'Dinagat Islands|San Jose': LatLng(10.0080, 125.5880),
    'Surigao del Norte|City of Surigao': LatLng(9.7890, 125.4950),
    'Surigao del Sur|City of Bislig': LatLng(8.2150, 126.3160),
    'Surigao del Sur|City of Tandag': LatLng(9.0780, 126.1980),
  };

  static bool contains(LatLng location) {
    return location.latitude >= bounds.southwest.latitude &&
        location.latitude <= bounds.northeast.latitude &&
        location.longitude >= bounds.southwest.longitude &&
        location.longitude <= bounds.northeast.longitude;
  }

  static LatLng targetFor({
    double? latitude,
    double? longitude,
    String? province,
    String? locality,
  }) {
    if (latitude != null && longitude != null) {
      final savedLocation = LatLng(latitude, longitude);

      if (contains(savedLocation)) {
        return savedLocation;
      }
    }

    final provinceValue = province?.trim() ?? '';
    final localityValue = locality?.trim() ?? '';
    final localityTarget =
        _localityTargets['$provinceValue|$localityValue'];

    if (localityTarget != null) {
      return localityTarget;
    }

    return _provinceTargets[provinceValue] ??
        const LatLng(8.9475, 125.5406);
  }

  static double zoomFor({
    required bool hasSavedPin,
    String? locality,
  }) {
    if (hasSavedPin) {
      return 16;
    }

    if (locality != null && locality.trim().isNotEmpty) {
      return 11.5;
    }

    return 8.4;
  }
}
