import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
import 'package:isdalink/screens/map/vendor_delivery_map_card.dart';

class RegionLocationScreen extends StatefulWidget {
  const RegionLocationScreen({
    super.key,
  });

  @override
  State<RegionLocationScreen> createState() =>
      _RegionLocationScreenState();
}

class _RegionLocationScreenState extends State<RegionLocationScreen> {
  final formKey = GlobalKey<FormState>();
  final deliveryAddressController = TextEditingController();

  static const provinces = <String>[
    'Agusan del Norte',
    'Agusan del Sur',
    'Dinagat Islands',
    'Surigao del Norte',
    'Surigao del Sur',
  ];

  static const provinceCodes = <String, String>{
    'Agusan del Norte': '1600200000',
    'Agusan del Sur': '1600300000',
    'Dinagat Islands': '1608500000',
    'Surigao del Norte': '1606700000',
    'Surigao del Sur': '1606800000',
  };

  static const butuanCityCode = '1630400000';

  static const locationsByProvince = <String, List<String>>{
    'Agusan del Norte': [
      'Butuan City',
      'Buenavista',
      'Carmen',
      'City of Cabadbaran',
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
      'Bunawan',
      'City of Bayugan',
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
      'Alegria',
      'Bacuag',
      'Burgos',
      'City of Surigao',
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
      'Barobo',
      'Bayabas',
      'Cagwait',
      'Cantilan',
      'Carmen',
      'Carrascal',
      'City of Bislig',
      'City of Tandag',
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

  static const locationCodesByProvince =
      <String, Map<String, String>>{
    'Agusan del Norte': {
      'Butuan City': butuanCityCode,
      'Buenavista': '1600201000',
      'City of Cabadbaran': '1600203000',
      'Carmen': '1600204000',
      'Jabonga': '1600205000',
      'Kitcharao': '1600206000',
      'Las Nieves': '1600207000',
      'Magallanes': '1600208000',
      'Nasipit': '1600209000',
      'Santiago': '1600210000',
      'Tubay': '1600211000',
      'Remedios T. Romualdez': '1600212000',
    },
    'Agusan del Sur': {
      'City of Bayugan': '1600301000',
      'Bunawan': '1600302000',
      'Esperanza': '1600303000',
      'La Paz': '1600304000',
      'Loreto': '1600305000',
      'Prosperidad': '1600306000',
      'Rosario': '1600307000',
      'San Francisco': '1600308000',
      'San Luis': '1600309000',
      'Santa Josefa': '1600310000',
      'Talacogon': '1600311000',
      'Trento': '1600312000',
      'Veruela': '1600313000',
      'Sibagat': '1600314000',
    },
    'Dinagat Islands': {
      'Basilisa': '1608501000',
      'Cagdianao': '1608502000',
      'Dinagat': '1608503000',
      'Libjo': '1608504000',
      'Loreto': '1608505000',
      'San Jose': '1608506000',
      'Tubajon': '1608507000',
    },
    'Surigao del Norte': {
      'Alegria': '1606701000',
      'Bacuag': '1606702000',
      'Burgos': '1606704000',
      'Claver': '1606706000',
      'Dapa': '1606707000',
      'Del Carmen': '1606708000',
      'General Luna': '1606710000',
      'Gigaquit': '1606711000',
      'Mainit': '1606714000',
      'Malimono': '1606715000',
      'Pilar': '1606716000',
      'Placer': '1606717000',
      'San Benito': '1606718000',
      'San Francisco': '1606719000',
      'San Isidro': '1606720000',
      'Santa Monica': '1606721000',
      'Sison': '1606722000',
      'Socorro': '1606723000',
      'City of Surigao': '1606724000',
      'Tagana-an': '1606725000',
      'Tubod': '1606727000',
    },
    'Surigao del Sur': {
      'Barobo': '1606801000',
      'Bayabas': '1606802000',
      'City of Bislig': '1606803000',
      'Cagwait': '1606804000',
      'Cantilan': '1606805000',
      'Carmen': '1606806000',
      'Carrascal': '1606807000',
      'Cortes': '1606808000',
      'Hinatuan': '1606809000',
      'Lanuza': '1606810000',
      'Lianga': '1606811000',
      'Lingig': '1606812000',
      'Madrid': '1606813000',
      'Marihatag': '1606814000',
      'San Agustin': '1606815000',
      'San Miguel': '1606816000',
      'Tagbina': '1606817000',
      'Tago': '1606818000',
      'City of Tandag': '1606819000',
    },
  };

  bool isLoading = true;
  bool isSaving = false;
  bool submitted = false;

  String? selectedProvince;
  String? selectedCity;
  double? deliveryLatitude;
  double? deliveryLongitude;

  String? initialProvince;
  String? initialCity;
  String initialDeliveryAddress = '';
  double? initialDeliveryLatitude;
  double? initialDeliveryLongitude;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get hasChanges {
    return selectedProvince != initialProvince ||
        selectedCity != initialCity ||
        deliveryAddressController.text.trim() != initialDeliveryAddress ||
        deliveryLatitude != initialDeliveryLatitude ||
        deliveryLongitude != initialDeliveryLongitude;
  }

  List<String> get availableCities {
    final province = selectedProvince;

    if (province == null) {
      return const <String>[];
    }

    final values = locationsByProvince[province] ?? const <String>[];

    return List<String>.from(values)
      ..sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );
  }

  String get locationPreview {
    if (selectedProvince == null || selectedCity == null) {
      return 'Location not selected';
    }

    return '$selectedCity, $selectedProvince, Caraga Region';
  }

  String normalizeAddress(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  bool isGeneralLocationOnly(
    String address, {
    String legacyLocation = '',
  }) {
    final normalizedAddress = normalizeAddress(address);

    if (normalizedAddress.isEmpty) {
      return true;
    }

    final province = selectedProvince?.trim() ?? '';
    final city = selectedCity?.trim() ?? '';
    final generalLocations = <String>{
      'Caraga Region',
      province,
      city,
      legacyLocation,
      if (city.isNotEmpty && province.isNotEmpty) '$city, $province',
      if (city.isNotEmpty && province.isNotEmpty)
        '$city, $province, Caraga Region',
    };

    return generalLocations
        .where((value) => value.trim().isNotEmpty)
        .map(normalizeAddress)
        .contains(normalizedAddress);
  }

  @override
  void initState() {
    super.initState();
    deliveryAddressController.addListener(handleAddressChanged);
    loadLocation();
  }

  @override
  void dispose() {
    deliveryAddressController.removeListener(handleAddressChanged);
    deliveryAddressController.dispose();
    super.dispose();
  }

  void handleAddressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String getStringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    final value = data?[key];
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  double? coordinateValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> loadLocation() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      final storedProvince = getStringValue(
        data,
        'province',
        '',
      );

      final storedCity = getStringValue(
        data,
        'cityMunicipality',
        '',
      );

      final legacyLocation = getStringValue(
        data,
        'location',
        getStringValue(
          data,
          'marketLocation',
          '',
        ),
      );

      if (storedCity == 'City of Butuan' ||
          storedCity == 'Butuan City' ||
          legacyLocation.toLowerCase().contains('butuan')) {
        selectedProvince = 'Agusan del Norte';
        selectedCity = 'Butuan City';
      } else {
        selectedProvince = provinces.contains(storedProvince)
            ? storedProvince
            : null;

        if (storedCity.isNotEmpty) {
          selectedCity = storedCity;
        } else if (legacyLocation.contains(',')) {
          selectedCity = legacyLocation.split(',').first.trim();
        }
      }

      if (selectedProvince != null &&
          !availableCities.contains(selectedCity)) {
        selectedCity = null;
      }

      final storedDeliveryAddress = getStringValue(
        data,
        'deliveryAddress',
        '',
      );

      deliveryAddressController.text = isGeneralLocationOnly(
        storedDeliveryAddress,
        legacyLocation: legacyLocation,
      )
          ? ''
          : storedDeliveryAddress;
      deliveryLatitude = coordinateValue(data?['deliveryLatitude']);
      deliveryLongitude = coordinateValue(data?['deliveryLongitude']);

      initialProvince = selectedProvince;
      initialCity = selectedCity;
      initialDeliveryAddress = deliveryAddressController.text.trim();
      initialDeliveryLatitude = deliveryLatitude;
      initialDeliveryLongitude = deliveryLongitude;
    } catch (_) {
      showMessage(
        'Unable to load your saved location.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? validateProvince(
    String? value,
  ) {
    if (value == null || !provinces.contains(value)) {
      return 'Select your province.';
    }

    return null;
  }

  String? validateCity(
    String? value,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Select your city or municipality.';
    }

    if (selectedProvince == null) {
      return 'Select your province first.';
    }

    if (!availableCities.contains(value)) {
      return 'Select a valid city or municipality.';
    }

    return null;
  }

  String localityType(
    String value,
  ) {
    if (value == 'Butuan City' || value.startsWith('City of ')) {
      return 'City';
    }

    return 'Municipality';
  }

  Future<String?> showSelectionSheet({
    required String title,
    required String subtitle,
    required List<String> options,
    required IconData icon,
    String? selectedValue,
    bool searchable = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(165),
      builder: (
        sheetContext,
      ) {
        return _LocationPickerSearchHost(
          builder: (
            context,
            searchController,
            searchFocusNode,
          ) {
            return StatefulBuilder(
              builder: (
                context,
                setSheetState,
              ) {
            final query =
                searchController.text.trim().toLowerCase();

            final filteredOptions = options.where(
              (option) {
                if (query.isEmpty) {
                  return true;
                }

                return option.toLowerCase().contains(query);
              },
            ).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(sheetContext).size.height * 0.80,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFD),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 30,
                      offset: Offset(0, -12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBED0DC),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        12,
                        14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5FD),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFF146BFF),
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Color(0xFF102C44),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF7B8FA3),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () {
                              searchFocusNode.unfocus();
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF52677A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (searchable)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          13,
                        ),
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          autofocus: false,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) {
                            setSheetState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search city or municipality',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8BA0B1),
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF146BFF),
                            ),
                            suffixIcon:
                                searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          searchController.clear();
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                        ),
                                      ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2ECF3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2ECF3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF146BFF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Divider(
                      height: 1,
                      color: Colors.black.withAlpha(15),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          20,
                        ),
                        itemCount: filteredOptions.length,
                        separatorBuilder: (
                          context,
                          index,
                        ) {
                          return const SizedBox(height: 4);
                        },
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final option = filteredOptions[index];
                          final isSelected =
                              option == selectedValue;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                searchFocusNode.unfocus();
                                Navigator.pop(
                                  sheetContext,
                                  option,
                                );
                              },
                              borderRadius:
                                  BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 170),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  12,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE6F5FF)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF32A9FF)
                                        : const Color(0xFFE5EDF3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option,
                                            style: TextStyle(
                                              color: const Color(
                                                0xFF102C44,
                                              ),
                                              fontSize: 12.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w900
                                                  : FontWeight.w800,
                                            ),
                                          ),
                                          if (title.contains('City'))
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                top: 3,
                                              ),
                                              child: Text(
                                                localityType(option),
                                                style:
                                                    const TextStyle(
                                                  color: Color(
                                                    0xFF7B8FA3,
                                                  ),
                                                  fontSize: 9.8,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons
                                              .check_circle_rounded
                                          : Icons
                                              .chevron_right_rounded,
                                      color: isSelected
                                          ? const Color(0xFF1DBB8A)
                                          : const Color(0xFF9DB0BE),
                                      size: 21,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              );
            },
            );
          },
        );
      },
    );
  }

  Future<void> showProvincePicker() async {
    if (isSaving) {
      return;
    }

    final selected = await showSelectionSheet(
      title: 'Select Province',
      subtitle: 'Choose one of Caraga Region’s five provinces',
      options: provinces,
      icon: Icons.map_outlined,
      selectedValue: selectedProvince,
    );

    if (selected == null || !mounted) {
      return;
    }

    final provinceChanged = selectedProvince != selected;

    if (provinceChanged) {
      deliveryAddressController.clear();
    }

    setState(() {
      selectedProvince = selected;

      if (provinceChanged) {
        selectedCity = null;
        deliveryLatitude = null;
        deliveryLongitude = null;
      }
    });
  }

  Future<void> showCityPicker() async {
    if (isSaving) {
      return;
    }

    final province = selectedProvince;

    if (province == null) {
      setState(() {
        submitted = true;
      });
      return;
    }

    final selected = await showSelectionSheet(
      title: 'Select City or Municipality',
      subtitle: 'Choose a city or municipality in $province',
      options: availableCities,
      icon: Icons.location_city_outlined,
      selectedValue: selectedCity,
      searchable: true,
    );

    if (selected == null || !mounted) {
      return;
    }

    final cityChanged = selectedCity != selected;

    if (cityChanged) {
      deliveryAddressController.clear();
    }

    setState(() {
      selectedCity = selected;
      submitted = false;

      if (cityChanged) {
        deliveryLatitude = null;
        deliveryLongitude = null;
      }
    });
  }

  Future<void> chooseDeliveryPin() async {
    if (isSaving) {
      return;
    }

    final province = selectedProvince;
    final city = selectedCity;

    if (province == null || city == null) {
      setState(() {
        submitted = true;
      });
      showMessage(
        'Select your province and city or municipality first.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await Navigator.of(context).push<CaragaLocationResult>(
      MaterialPageRoute(
        builder: (_) => CaragaLocationPickerScreen(
          title: 'Delivery Location',
          subtitle: locationPreview,
          province: province,
          locality: city,
          initialLatitude: deliveryLatitude,
          initialLongitude: deliveryLongitude,
          instructionText:
              'Tap the map at your usual COD delivery location. This saved pin will be reused for future orders until you update it.',
          markerTitle: 'Saved vendor delivery location',
          confirmButtonLabel: 'Save Delivery Pin',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      deliveryLatitude = result.latitude;
      deliveryLongitude = result.longitude;
    });
  }

  Future<void> saveLocation() async {
    final user = currentUser;

    if (user == null || isSaving || !hasChanges) {
      return;
    }

    setState(() {
      submitted = true;
    });

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (deliveryLatitude == null || deliveryLongitude == null) {
      showMessage(
        'Set your delivery location on the map before saving.',
        isError: true,
      );
      return;
    }

    final city = selectedCity!;
    final province = selectedProvince!;
    final location = '$city, $province, Caraga Region';
    final provinceCode = provinceCodes[province];
    final cityCode = locationCodesByProvince[province]?[city];
    final cityType = localityType(city);
    final deliveryAddress = deliveryAddressController.text.trim();

    setState(() {
      isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final userData = <String, dynamic>{
        'region': 'Caraga Region',
        'province': province,
        'provinceCode': provinceCode,
        'administrativeArea': province,
        'administrativeAreaType': 'Province',
        'cityMunicipality': city,
        'cityMunicipalityCode': cityCode,
        'cityMunicipalityType': cityType,
        'isHighlyUrbanizedCity': false,
        'location': location,
        'marketLocation': location,
        'deliveryAddress': deliveryAddress,
        'deliveryLatitude': deliveryLatitude,
        'deliveryLongitude': deliveryLongitude,
        'deliveryReferenceType': 'map_pin',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(
        firestore.collection('users').doc(user.uid),
        userData,
        SetOptions(merge: true),
      );

      // This screen manages the user's normal account/market location only.
      // An approved supplier's verified business location is managed through
      // Supplier Profile and requires administrator approval for changes.

      await batch.commit();

      if (!mounted) {
        return;
      }

      deliveryAddressController.text = deliveryAddress;

      setState(() {
        initialProvince = selectedProvince;
        initialCity = selectedCity;
        initialDeliveryAddress = deliveryAddress;
        initialDeliveryLatitude = deliveryLatitude;
        initialDeliveryLongitude = deliveryLongitude;
      });

      showMessage(
        'Region and location updated successfully.',
      );
    } on FirebaseException {
      showMessage(
        'Unable to save your location. Please try again.',
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while saving your location.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget header() {
    final hasLocation = selectedCity != null;
    final statusLabel = hasChanges
        ? 'UNSAVED'
        : hasLocation
            ? 'SYNCED'
            : 'SET LOCATION';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B66),
            Color(0xFF075FAE),
            Color(0xFF146BFF),
          ],
          stops: [
            0.0,
            0.52,
            1.0,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x24146BFF),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -54,
            right: -50,
            child: Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
                border: Border.all(
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 58,
            right: 20,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              47,
              18,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSaving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        borderRadius: BorderRadius.circular(99),
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(34),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(28),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFFBCE8FF),
                              fontSize: 9,
                              letterSpacing: 1.35,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Region and Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.5,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Manage the Caraga location displayed on your profile and used for COD coordination.',
                  style: TextStyle(
                    color: Color(0xFFDDEFFF),
                    fontSize: 11.5,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    12,
                    13,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(31),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(31),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(31),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PROFILE LOCATION',
                              style: TextStyle(
                                color: Color(0xFFBCE8FF),
                                fontSize: 9,
                                letterSpacing: 0.85,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locationPreview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasChanges
                              ? const Color(0xFFFFB25A).withAlpha(42)
                              : const Color(0xFF42D59B).withAlpha(40),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: hasChanges
                                ? const Color(0xFFFFC27A).withAlpha(105)
                                : const Color(0xFF73E4B8).withAlpha(95),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: hasChanges
                                ? const Color(0xFFFFE0B8)
                                : const Color(0xFFD9FFF0),
                            fontSize: 8.5,
                            letterSpacing: 0.65,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE9F7FF),
                Color(0xFFDDF1FF),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget lockedRegionTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        12,
        13,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F4FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: Color(0xFF146BFF),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGION',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Caraga Region',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF8BA0B1),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget pickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    required FormFieldValidator<String> validator,
    String? helperText,
    String? emptyDisplay,
  }) {
    return FormField<String>(
      key: ValueKey(
        '$label-$value-$submitted',
      ),
      initialValue: value,
      autovalidateMode: submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      validator: validator,
      builder: (
        field,
      ) {
        final hasValue = value != null && value.trim().isNotEmpty;
        final valid = hasValue && !field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSaving
                    ? null
                    : onTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  height: 61,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                  ),
                  decoration: BoxDecoration(
                    color: valid
                        ? const Color(0xFFF0FBF7)
                        : const Color(0xFFF2F7FB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: field.hasError
                          ? const Color(0xFFD32F2F)
                          : valid
                              ? const Color(0xFF1DBB8A)
                              : const Color(0xFFB8DFFF),
                      width: valid || field.hasError
                          ? 1.45
                          : 1.25,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          color: valid
                              ? const Color(0xFFE3F8F0)
                              : const Color(0xFFE5F4FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: valid
                              ? const Color(0xFF147D64)
                              : const Color(0xFF146BFF),
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                color: valid
                                    ? const Color(0xFF147D64)
                                    : const Color(0xFF7B8FA3),
                                fontSize: 8.8,
                                letterSpacing: 0.55,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasValue
                                  ? value
                                  : emptyDisplay ?? 'Select $label',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasValue
                                    ? const Color(0xFF102C44)
                                    : const Color(0xFF8BA0B1),
                                fontSize: 12.5,
                                fontWeight: hasValue
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (valid)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF1DBB8A),
                          size: 20,
                        ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF52677A),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  6,
                  8,
                  0,
                ),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (helperText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  6,
                  8,
                  0,
                ),
                child: Text(
                  helperText,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget deliveryAddressField() {
    return TextFormField(
      controller: deliveryAddressController,
      enabled: !isSaving,
      keyboardType: TextInputType.streetAddress,
      textCapitalization: TextCapitalization.words,
      minLines: 1,
      maxLines: 3,
      validator: (value) {
        if (value == null || isGeneralLocationOnly(value)) {
          return 'Enter a barangay, street, block, house, or landmark.';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: 'Detailed delivery address',
        hintText: 'Block, street, barangay, house, or landmark',
        helperText:
            'Required. Province and city are saved separately from this address.',
        prefixIcon: const Icon(
          Icons.home_work_outlined,
          color: Color(0xFF146BFF),
        ),
        filled: true,
        fillColor: const Color(0xFFF2F7FB),
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFB8DFFF),
            width: 1.25,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF146BFF),
            width: 1.45,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 1.45,
          ),
        ),
      ),
    );
  }

  Widget locationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            sectionHeader(
              title: 'Location Details',
              subtitle:
                  'Keep the location shown in Account Center accurate.',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 17),
            lockedRegionTile(),
            const SizedBox(height: 12),
            pickerField(
              label: 'Province',
              value: selectedProvince,
              icon: Icons.map_outlined,
              onTap: showProvincePicker,
              validator: validateProvince,
              emptyDisplay: 'Select province',
              helperText:
                  'Choose one of Caraga Region’s five provinces.',
            ),
            const SizedBox(height: 12),
            pickerField(
              label: 'City or Municipality',
              value: selectedCity,
              icon: Icons.location_city_outlined,
              onTap: showCityPicker,
              validator: validateCity,
              helperText: selectedProvince == null
                  ? 'Select a province first.'
                  : 'Search within $selectedProvince.',
            ),
            const SizedBox(height: 14),
            deliveryAddressField(),
            const SizedBox(height: 14),
            VendorDeliveryMapCard(
              latitude: deliveryLatitude,
              longitude: deliveryLongitude,
              province: selectedProvince ?? '',
              locality: selectedCity ?? '',
              onTap: chooseDeliveryPin,
              height: 160,
            ),
          ],
        ),
      ),
    );
  }

  Widget saveButton() {
    final canSave = hasChanges && !isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 53,
          child: ElevatedButton.icon(
            onPressed: canSave
                ? saveLocation
                : null,
            icon: isSaving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    hasChanges
                        ? Icons.save_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
            label: Text(
              isSaving
                  ? 'Saving Location...'
                  : hasChanges
                      ? 'Save Location'
                      : 'Location Up to Date',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              disabledBackgroundColor: const Color(0xFFDCE7EF),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF7B8FA3),
              elevation: canSave
                  ? 7
                  : 0,
              shadowColor: const Color(0x55146BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loadingBody() {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF146BFF),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FB),
        body: Center(
          child: Text(
            'Please log in first to manage your location.',
            style: TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return loadingBody();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: Column(
          children: [
            header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  22,
                ),
                children: [
                  locationCard(),
                ],
              ),
            ),
            saveButton(),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerSearchHost extends StatefulWidget {
  const _LocationPickerSearchHost({
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  ) builder;

  @override
  State<_LocationPickerSearchHost> createState() =>
      _LocationPickerSearchHostState();
}

class _LocationPickerSearchHostState
    extends State<_LocationPickerSearchHost> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      searchController,
      searchFocusNode,
    );
  }
}
