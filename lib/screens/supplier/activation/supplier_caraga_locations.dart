class SupplierCaragaLocations {
  const SupplierCaragaLocations._();

  static const Map<String, List<String>> byProvince = {
    'Agusan del Norte': [
      'Butuan City',
      'City of Cabadbaran',
      'Buenavista',
      'Carmen',
      'Jabonga',
      'Kitcharao',
      'Las Nieves',
      'Magallanes',
      'Nasipit',
      'Remedios T. Romualdez',
      'Santiago',
      'Tubay',
    ],
    'Agusan del Sur': [
      'City of Bayugan',
      'Bunawan',
      'Esperanza',
      'La Paz',
      'Loreto',
      'Prosperidad',
      'Rosario',
      'San Francisco',
      'San Luis',
      'Santa Josefa',
      'Sibagat',
      'Talacogon',
      'Trento',
      'Veruela',
    ],
    'Dinagat Islands': [
      'Basilisa',
      'Cagdianao',
      'Dinagat',
      'Libjo',
      'Loreto',
      'San Jose',
      'Tubajon',
    ],
    'Surigao del Norte': [
      'City of Surigao',
      'Alegria',
      'Bacuag',
      'Burgos',
      'Claver',
      'Dapa',
      'Del Carmen',
      'General Luna',
      'Gigaquit',
      'Mainit',
      'Malimono',
      'Pilar',
      'Placer',
      'San Benito',
      'San Francisco',
      'San Isidro',
      'Santa Monica',
      'Sison',
      'Socorro',
      'Tagana-an',
      'Tubod',
    ],
    'Surigao del Sur': [
      'City of Bislig',
      'City of Tandag',
      'Barobo',
      'Bayabas',
      'Cagwait',
      'Cantilan',
      'Carmen',
      'Carrascal',
      'Cortes',
      'Hinatuan',
      'Lanuza',
      'Lianga',
      'Lingig',
      'Madrid',
      'Marihatag',
      'San Agustin',
      'San Miguel',
      'Tagbina',
      'Tago',
    ],
  };

  static List<String> get provinces => byProvince.keys.toList();

  static List<String> localitiesFor(String? province) {
    if (province == null) {
      return const <String>[];
    }

    return byProvince[province] ?? const <String>[];
  }

  static bool isValidSelection({
    required String? province,
    required String? locality,
  }) {
    if (locality == null || locality.isEmpty) {
      return false;
    }

    return province != null &&
        (byProvince[province]?.contains(locality) ?? false);
  }
}
