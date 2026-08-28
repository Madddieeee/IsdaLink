import 'package:google_maps_flutter/google_maps_flutter.dart';

class CaragaMapDefaults {
  const CaragaMapDefaults._();

  static final bounds = LatLngBounds(
    southwest: const LatLng(7.55, 124.65),
    northeast: const LatLng(10.75, 126.85),
  );

  // Locality targets follow the PSA Philippine Standard Geographic Code.
  // Bounds are derived from OCHA/NAMRIA administrative boundaries with
  // a small tolerance for generalized coastlines and border coordinates.
  static const _provinceAreas = <String, _CaragaMapArea>{
    'Agusan del Norte': _CaragaMapArea(
      target: LatLng(9.070000, 125.570000),
      south: 8.690628, west: 125.213400,
      north: 9.470886, east: 125.775509,
    ),
    'Agusan del Sur': _CaragaMapArea(
      target: LatLng(8.510000, 125.970000),
      south: 7.943381, west: 125.239561,
      north: 9.171620, east: 126.265053,
    ),
    'Dinagat Islands': _CaragaMapArea(
      target: LatLng(10.130000, 125.610000),
      south: 9.844500, west: 125.455340,
      north: 10.479595, east: 125.714772,
    ),
    'Surigao del Norte': _CaragaMapArea(
      target: LatLng(9.790000, 125.500000),
      south: 9.318040, west: 125.383695,
      north: 10.070544, east: 126.174928,
    ),
    'Surigao del Sur': _CaragaMapArea(
      target: LatLng(8.750000, 126.120000),
      south: 7.925008, west: 125.735439,
      north: 9.504016, east: 126.459292,
    ),
  };

  static const _localityAreas = <String, _CaragaMapArea>{
    'Agusan del Norte|Buenavista': _CaragaMapArea(
      target: LatLng(8.844877, 125.379041),
      south: 8.751580, west: 125.230037,
      north: 8.991506, east: 125.509430,
    ),
    'Agusan del Norte|Butuan City': _CaragaMapArea(
      target: LatLng(8.903146, 125.577028),
      south: 8.740690, west: 125.455216,
      north: 9.056310, east: 125.743619,
    ),
    'Agusan del Norte|Carmen': _CaragaMapArea(
      target: LatLng(8.953248, 125.259258),
      south: 8.854489, west: 125.213400,
      north: 9.028491, east: 125.312384,
    ),
    'Agusan del Norte|City of Cabadbaran': _CaragaMapArea(
      target: LatLng(9.143948, 125.653666),
      south: 9.057913, west: 125.512221,
      north: 9.230395, east: 125.775509,
    ),
    'Agusan del Norte|Jabonga': _CaragaMapArea(
      target: LatLng(9.346079, 125.606931),
      south: 9.285986, west: 125.445348,
      north: 9.462061, east: 125.753410,
    ),
    'Agusan del Norte|Kitcharao': _CaragaMapArea(
      target: LatLng(9.411514, 125.631750),
      south: 9.369201, west: 125.547441,
      north: 9.470886, east: 125.752423,
    ),
    'Agusan del Norte|Las Nieves': _CaragaMapArea(
      target: LatLng(8.734798, 125.501050),
      south: 8.690628, west: 125.230037,
      north: 8.768590, east: 125.677411,
    ),
    'Agusan del Norte|Magallanes': _CaragaMapArea(
      target: LatLng(9.027772, 125.544398),
      south: 9.026259, west: 125.525767,
      north: 9.073992, east: 125.579208,
    ),
    'Agusan del Norte|Nasipit': _CaragaMapArea(
      target: LatLng(8.927931, 125.334059),
      south: 8.854489, west: 125.275885,
      north: 8.999486, east: 125.398590,
    ),
    'Agusan del Norte|Remedios T. Romualdez': _CaragaMapArea(
      target: LatLng(9.064643, 125.654273),
      south: 9.026259, west: 125.551145,
      north: 9.094860, east: 125.757086,
    ),
    'Agusan del Norte|Santiago': _CaragaMapArea(
      target: LatLng(9.258593, 125.644970),
      south: 9.208370, west: 125.516002,
      north: 9.315524, east: 125.766331,
    ),
    'Agusan del Norte|Tubay': _CaragaMapArea(
      target: LatLng(9.214007, 125.549911),
      south: 9.131576, west: 125.488375,
      north: 9.320970, east: 125.634949,
    ),
    'Agusan del Sur|Bunawan': _CaragaMapArea(
      target: LatLng(8.193608, 126.031869),
      south: 8.101518, west: 125.886409,
      north: 8.275236, east: 126.189982,
    ),
    'Agusan del Sur|City of Bayugan': _CaragaMapArea(
      target: LatLng(8.758950, 125.797411),
      south: 8.600227, west: 125.657239,
      north: 8.895713, east: 125.940096,
    ),
    'Agusan del Sur|Esperanza': _CaragaMapArea(
      target: LatLng(8.611350, 125.462100),
      south: 8.470070, west: 125.239561,
      north: 8.748743, east: 125.804581,
    ),
    'Agusan del Sur|La Paz': _CaragaMapArea(
      target: LatLng(8.257233, 125.601939),
      south: 8.156342, west: 125.300693,
      north: 8.362269, east: 125.902409,
    ),
    'Agusan del Sur|Loreto': _CaragaMapArea(
      target: LatLng(8.097878, 125.667294),
      south: 7.943381, west: 125.371389,
      north: 8.275236, east: 125.913692,
    ),
    'Agusan del Sur|Prosperidad': _CaragaMapArea(
      target: LatLng(8.646503, 125.907979),
      south: 8.495595, west: 125.787541,
      north: 8.841130, east: 126.008246,
    ),
    'Agusan del Sur|Rosario': _CaragaMapArea(
      target: LatLng(8.332876, 126.033854),
      south: 8.255369, west: 125.880722,
      north: 8.455829, east: 126.177178,
    ),
    'Agusan del Sur|San Francisco': _CaragaMapArea(
      target: LatLng(8.471224, 125.947690),
      south: 8.330962, west: 125.845837,
      north: 8.607765, east: 126.063090,
    ),
    'Agusan del Sur|San Luis': _CaragaMapArea(
      target: LatLng(8.432450, 125.521729),
      south: 8.303562, west: 125.239561,
      north: 8.623169, east: 125.819575,
    ),
    'Agusan del Sur|Santa Josefa': _CaragaMapArea(
      target: LatLng(8.004643, 126.019445),
      south: 7.944304, west: 125.955055,
      north: 8.117518, east: 126.073375,
    ),
    'Agusan del Sur|Sibagat': _CaragaMapArea(
      target: LatLng(8.968486, 125.775000),
      south: 8.744793, west: 125.657239,
      north: 9.171620, east: 125.903900,
    ),
    'Agusan del Sur|Talacogon': _CaragaMapArea(
      target: LatLng(8.403089, 125.789908),
      south: 8.312260, west: 125.536585,
      north: 8.546719, east: 125.915613,
    ),
    'Agusan del Sur|Trento': _CaragaMapArea(
      target: LatLng(8.067979, 126.144812),
      south: 7.944304, west: 125.976416,
      north: 8.196573, east: 126.265053,
    ),
    'Agusan del Sur|Veruela': _CaragaMapArea(
      target: LatLng(8.037232, 125.904737),
      south: 7.943381, west: 125.769268,
      north: 8.131063, east: 125.992416,
    ),
    'Dinagat Islands|Basilisa': _CaragaMapArea(
      target: LatLng(10.089826, 125.556304),
      south: 9.981560, west: 125.468710,
      north: 10.165739, east: 125.627455,
    ),
    'Dinagat Islands|Cagdianao': _CaragaMapArea(
      target: LatLng(10.027403, 125.655948),
      south: 9.844500, west: 125.603437,
      north: 10.194983, east: 125.714772,
    ),
    'Dinagat Islands|Dinagat': _CaragaMapArea(
      target: LatLng(9.974075, 125.608028),
      south: 9.931606, west: 125.526712,
      north: 10.005629, east: 125.646196,
    ),
    'Dinagat Islands|Libjo': _CaragaMapArea(
      target: LatLng(10.189933, 125.564465),
      south: 10.112733, west: 125.482835,
      north: 10.285352, east: 125.669892,
    ),
    'Dinagat Islands|Loreto': _CaragaMapArea(
      target: LatLng(10.366614, 125.617896),
      south: 10.238929, west: 125.455340,
      north: 10.479595, east: 125.689633,
    ),
    'Dinagat Islands|San Jose': _CaragaMapArea(
      target: LatLng(10.018305, 125.605740),
      south: 9.988351, west: 125.560625,
      north: 10.058334, east: 125.645513,
    ),
    'Dinagat Islands|Tubajon': _CaragaMapArea(
      target: LatLng(10.281765, 125.581316),
      south: 10.200037, west: 125.505872,
      north: 10.356805, east: 125.664870,
    ),
    'Surigao del Norte|Alegria': _CaragaMapArea(
      target: LatLng(9.485403, 125.607826),
      south: 9.421680, west: 125.543009,
      north: 9.548939, east: 125.708172,
    ),
    'Surigao del Norte|Bacuag': _CaragaMapArea(
      target: LatLng(9.572632, 125.629287),
      south: 9.497800, west: 125.581172,
      north: 9.628302, east: 125.693173,
    ),
    'Surigao del Norte|Burgos': _CaragaMapArea(
      target: LatLng(9.999501, 126.073631),
      south: 9.961719, west: 126.049294,
      north: 10.048595, east: 126.105061,
    ),
    'Surigao del Norte|City of Surigao': _CaragaMapArea(
      target: LatLng(9.776333, 125.541788),
      south: 9.657185, west: 125.418133,
      north: 9.925173, east: 125.740596,
    ),
    'Surigao del Norte|Claver': _CaragaMapArea(
      target: LatLng(9.475170, 125.785631),
      south: 9.318040, west: 125.690865,
      north: 9.593277, east: 125.891799,
    ),
    'Surigao del Norte|Dapa': _CaragaMapArea(
      target: LatLng(9.750088, 126.045986),
      south: 9.679377, west: 125.957999,
      north: 9.808324, east: 126.125450,
    ),
    'Surigao del Norte|Del Carmen': _CaragaMapArea(
      target: LatLng(9.858371, 125.995441),
      south: 9.772423, west: 125.884029,
      north: 9.926761, east: 126.060770,
    ),
    'Surigao del Norte|General Luna': _CaragaMapArea(
      target: LatLng(9.788442, 126.132131),
      south: 9.749418, west: 126.084340,
      north: 9.852773, east: 126.174928,
    ),
    'Surigao del Norte|Gigaquit': _CaragaMapArea(
      target: LatLng(9.506836, 125.686767),
      south: 9.397130, west: 125.626789,
      north: 9.609682, east: 125.740698,
    ),
    'Surigao del Norte|Mainit': _CaragaMapArea(
      target: LatLng(9.562122, 125.503149),
      south: 9.439851, west: 125.442027,
      north: 9.625960, east: 125.614401,
    ),
    'Surigao del Norte|Malimono': _CaragaMapArea(
      target: LatLng(9.565679, 125.436717),
      south: 9.431441, west: 125.383695,
      north: 9.666498, east: 125.480637,
    ),
    'Surigao del Norte|Pilar': _CaragaMapArea(
      target: LatLng(9.855117, 126.083399),
      south: 9.791856, west: 126.041906,
      north: 9.928616, east: 126.128616,
    ),
    'Surigao del Norte|Placer': _CaragaMapArea(
      target: LatLng(9.639170, 125.587130),
      south: 9.585080, west: 125.525795,
      north: 9.714639, east: 125.668473,
    ),
    'Surigao del Norte|San Benito': _CaragaMapArea(
      target: LatLng(9.938587, 126.003641),
      south: 9.899551, west: 125.930375,
      north: 9.992812, east: 126.056001,
    ),
    'Surigao del Norte|San Francisco': _CaragaMapArea(
      target: LatLng(9.713976, 125.415970),
      south: 9.649145, west: 125.383695,
      north: 9.793454, east: 125.445936,
    ),
    'Surigao del Norte|San Isidro': _CaragaMapArea(
      target: LatLng(9.934006, 126.070400),
      south: 9.882530, west: 126.021775,
      north: 9.979439, east: 126.122232,
    ),
    'Surigao del Norte|Santa Monica': _CaragaMapArea(
      target: LatLng(10.013642, 126.049714),
      south: 9.962424, west: 126.017228,
      north: 10.070544, east: 126.079460,
    ),
    'Surigao del Norte|Sison': _CaragaMapArea(
      target: LatLng(9.647121, 125.495095),
      south: 9.605250, west: 125.428050,
      north: 9.705444, east: 125.548527,
    ),
    'Surigao del Norte|Socorro': _CaragaMapArea(
      target: LatLng(9.656000, 125.942853),
      south: 9.552243, west: 125.888850,
      north: 9.768417, east: 125.998319,
    ),
    'Surigao del Norte|Tagana-an': _CaragaMapArea(
      target: LatLng(9.706757, 125.590585),
      south: 9.641405, west: 125.525369,
      north: 9.773575, east: 125.713209,
    ),
    'Surigao del Norte|Tubod': _CaragaMapArea(
      target: LatLng(9.573619, 125.567334),
      south: 9.532918, west: 125.527047,
      north: 9.614970, east: 125.612500,
    ),
    'Surigao del Sur|Barobo': _CaragaMapArea(
      target: LatLng(8.523671, 126.125593),
      south: 8.436658, west: 125.992117,
      north: 8.607765, east: 126.362020,
    ),
    'Surigao del Sur|Bayabas': _CaragaMapArea(
      target: LatLng(8.951507, 126.254867),
      south: 8.888563, west: 126.208085,
      north: 9.023458, east: 126.316829,
    ),
    'Surigao del Sur|Cagwait': _CaragaMapArea(
      target: LatLng(8.895234, 126.276111),
      south: 8.839071, west: 126.208864,
      north: 8.957070, east: 126.336770,
    ),
    'Surigao del Sur|Cantilan': _CaragaMapArea(
      target: LatLng(9.300455, 125.871626),
      south: 9.230570, west: 125.735439,
      north: 9.407343, east: 126.014754,
    ),
    'Surigao del Sur|Carmen': _CaragaMapArea(
      target: LatLng(9.183075, 125.894484),
      south: 9.085480, west: 125.767498,
      north: 9.254041, east: 126.032011,
    ),
    'Surigao del Sur|Carrascal': _CaragaMapArea(
      target: LatLng(9.386672, 125.873102),
      south: 9.297530, west: 125.735439,
      north: 9.504016, east: 125.996708,
    ),
    'Surigao del Sur|City of Bislig': _CaragaMapArea(
      target: LatLng(8.182793, 126.285343),
      south: 8.050979, west: 126.146967,
      north: 8.309547, east: 126.457228,
    ),
    'Surigao del Sur|City of Tandag': _CaragaMapArea(
      target: LatLng(9.074338, 126.128361),
      south: 8.982375, west: 126.046569,
      north: 9.154480, east: 126.227614,
    ),
    'Surigao del Sur|Cortes': _CaragaMapArea(
      target: LatLng(9.210014, 126.148509),
      south: 9.132936, west: 126.064749,
      north: 9.317303, east: 126.211016,
    ),
    'Surigao del Sur|Hinatuan': _CaragaMapArea(
      target: LatLng(8.392143, 126.300902),
      south: 8.236580, west: 126.157051,
      north: 8.555111, east: 126.396251,
    ),
    'Surigao del Sur|Lanuza': _CaragaMapArea(
      target: LatLng(9.160559, 126.010809),
      south: 9.073232, west: 125.858155,
      north: 9.291991, east: 126.166348,
    ),
    'Surigao del Sur|Lianga': _CaragaMapArea(
      target: LatLng(8.694389, 126.078790),
      south: 8.555767, west: 125.962289,
      north: 8.801478, east: 126.188722,
    ),
    'Surigao del Sur|Lingig': _CaragaMapArea(
      target: LatLng(8.063556, 126.369612),
      south: 7.925008, west: 126.219791,
      north: 8.250712, east: 126.459292,
    ),
    'Surigao del Sur|Madrid': _CaragaMapArea(
      target: LatLng(9.240806, 125.888602),
      south: 9.181577, west: 125.747234,
      north: 9.294737, east: 126.029396,
    ),
    'Surigao del Sur|Marihatag': _CaragaMapArea(
      target: LatLng(8.824845, 126.209103),
      south: 8.759944, west: 126.080150,
      north: 8.876779, east: 126.342148,
    ),
    'Surigao del Sur|San Agustin': _CaragaMapArea(
      target: LatLng(8.753778, 126.195582),
      south: 8.683465, west: 126.133132,
      north: 8.810095, east: 126.258442,
    ),
    'Surigao del Sur|San Miguel': _CaragaMapArea(
      target: LatLng(8.928001, 125.987018),
      south: 8.731795, west: 125.863041,
      north: 9.093403, east: 126.099700,
    ),
    'Surigao del Sur|Tagbina': _CaragaMapArea(
      target: LatLng(8.415460, 126.180350),
      south: 8.280009, west: 126.055895,
      north: 8.518690, east: 126.294822,
    ),
    'Surigao del Sur|Tago': _CaragaMapArea(
      target: LatLng(8.949478, 126.146258),
      south: 8.846151, west: 126.031491,
      north: 9.093730, east: 126.250260,
    ),
  };

  static bool contains(LatLng location) {
    return location.latitude >= bounds.southwest.latitude &&
        location.latitude <= bounds.northeast.latitude &&
        location.longitude >= bounds.southwest.longitude &&
        location.longitude <= bounds.northeast.longitude;
  }

  static bool containsForSelection(
    LatLng location, {
    String? province,
    String? locality,
  }) {
    final provinceValue = province?.trim() ?? '';
    final localityValue = locality?.trim() ?? '';

    if (localityValue.isNotEmpty) {
      final localityArea =
          _localityAreas['$provinceValue|$localityValue'];
      return localityArea?.contains(location) ?? false;
    }

    if (provinceValue.isNotEmpty) {
      return _provinceAreas[provinceValue]?.contains(location) ?? false;
    }

    return contains(location);
  }

  static bool containsCoordinates({
    required double latitude,
    required double longitude,
    String? province,
    String? locality,
  }) {
    return containsForSelection(
      LatLng(latitude, longitude),
      province: province,
      locality: locality,
    );
  }

  static LatLngBounds boundsFor({
    String? province,
    String? locality,
  }) {
    final provinceValue = province?.trim() ?? '';
    final localityValue = locality?.trim() ?? '';
    final localityArea =
        _localityAreas['$provinceValue|$localityValue'];

    if (localityArea != null) {
      return localityArea.bounds;
    }

    return _provinceAreas[provinceValue]?.bounds ?? bounds;
  }

  static LatLng targetFor({
    double? latitude,
    double? longitude,
    String? province,
    String? locality,
  }) {
    if (latitude != null && longitude != null) {
      final savedLocation = LatLng(latitude, longitude);

      if (containsForSelection(
        savedLocation,
        province: province,
        locality: locality,
      )) {
        return savedLocation;
      }
    }

    final provinceValue = province?.trim() ?? '';
    final localityValue = locality?.trim() ?? '';
    final localityArea =
        _localityAreas['$provinceValue|$localityValue'];

    if (localityArea != null) {
      return localityArea.target;
    }

    return _provinceAreas[provinceValue]?.target ??
        const LatLng(8.9475, 125.5406);
  }

  static double zoomFor({
    required bool hasSavedPin,
    String? province,
    String? locality,
  }) {
    if (hasSavedPin) {
      return 16;
    }

    if (locality != null && locality.trim().isNotEmpty) {
      return 11.5;
    }

    if (province != null && province.trim().isNotEmpty) {
      return 9.2;
    }

    return 8.4;
  }
}

class _CaragaMapArea {
  const _CaragaMapArea({
    required this.target,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final LatLng target;
  final double south;
  final double west;
  final double north;
  final double east;

  bool contains(LatLng location) {
    return location.latitude >= south &&
        location.latitude <= north &&
        location.longitude >= west &&
        location.longitude <= east;
  }

  LatLngBounds get bounds => LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}
