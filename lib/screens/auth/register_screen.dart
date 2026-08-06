import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final fullNameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

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
      'Tagana-An',
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

  static const locationCodesByProvince = <String, Map<String, String>>{
    'Agusan del Norte': {
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
      'Tagana-An': '1606725000',
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

  final touchedFields = <String>{};

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool submitted = false;

  String? selectedProvince;
  String? selectedCity;
  String? registrationError;

  bool get isButuanCitySelection => selectedCity == 'City of Butuan';

  List<String> get availableCities {
    final values = locationsByProvince[selectedProvince];

    if (values == null) {
      return const [];
    }

    return List<String>.from(values)..sort(
        (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
      );
  }

  List<String> get cityPickerOptions {
    if (selectedProvince == null) {
      return const [
        'City of Butuan',
      ];
    }

    return [
      ...availableCities,
      'City of Butuan',
    ];
  }

  bool get hasMinimumLength => passwordController.text.length >= 8;

  bool get hasLetter => RegExp(
        r'[A-Za-z]',
      ).hasMatch(
        passwordController.text,
      );

  bool get hasNumber => RegExp(
        r'\d',
      ).hasMatch(
        passwordController.text,
      );

  String? get provinceDisplayValue {
    if (isButuanCitySelection) {
      return 'Not required';
    }

    return selectedProvince;
  }

  String get locationPreview {
    if (isButuanCitySelection) {
      return 'City of Butuan, Caraga Region';
    }

    final city = selectedCity;
    final province = selectedProvince;

    if (city == null || province == null) {
      return '';
    }

    return '$city, $province';
  }

  String get selectedLocalityType {
    if (isButuanCitySelection) {
      return 'Highly Urbanized City';
    }

    final city = selectedCity ?? '';

    return city.startsWith('City of ')
        ? 'City'
        : 'Municipality';
  }

  String? get selectedProvinceCode {
    if (isButuanCitySelection) {
      return null;
    }

    return provinceCodes[selectedProvince];
  }

  String? get selectedLocalityCode {
    if (isButuanCitySelection) {
      return butuanCityCode;
    }

    final province = selectedProvince;
    final city = selectedCity;

    if (province == null || city == null) {
      return null;
    }

    return locationCodesByProvince[province]?[city];
  }

  @override
  void initState() {
    super.initState();

    passwordController.addListener(
      handlePasswordChanged,
    );
    confirmPasswordController.addListener(
      handleConfirmPasswordChanged,
    );
  }

  @override
  void dispose() {
    passwordController.removeListener(
      handlePasswordChanged,
    );
    confirmPasswordController.removeListener(
      handleConfirmPasswordChanged,
    );

    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    fullNameFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void handlePasswordChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      touchedFields.add('password');
      registrationError = null;
    });
  }

  void handleConfirmPasswordChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      touchedFields.add('confirmPassword');
      registrationError = null;
    });
  }

  void fieldChanged(
    String field,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      touchedFields.add(field);
      registrationError = null;
    });
  }

  String collapseSpaces(
    String value,
  ) {
    return value.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  String normalizeEmail(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  String phoneDigits(
    String value,
  ) {
    return value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String normalizePhilippinePhone(
    String value,
  ) {
    final digits = phoneDigits(
      value,
    );

    if (digits.startsWith('09') && digits.length == 11) {
      return '+63${digits.substring(1)}';
    }

    if (digits.startsWith('9') && digits.length == 10) {
      return '+63$digits';
    }

    if (digits.startsWith('639') && digits.length == 12) {
      return '+$digits';
    }

    return value.trim();
  }

  String? validateFullName(
    String? value,
  ) {
    final fullName = collapseSpaces(
      value ?? '',
    );

    if (fullName.isEmpty) {
      return 'Enter your full name.';
    }

    if (fullName.length < 2) {
      return 'Enter at least 2 characters.';
    }

    final namePattern = RegExp(
      r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ.' -]+$",
    );

    if (!namePattern.hasMatch(fullName)) {
      return 'Use letters, spaces, hyphens, or apostrophes only.';
    }

    return null;
  }

  String? validateEmail(
    String? value,
  ) {
    final email = normalizeEmail(
      value ?? '',
    );

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? validatePhone(
    String? value,
  ) {
    final input = (value ?? '').trim();

    if (input.isEmpty) {
      return 'Enter your phone number.';
    }

    final digits = phoneDigits(
      input,
    );

    final isLocalFormat =
        digits.startsWith('09') && digits.length == 11;
    final isShortLocalFormat =
        digits.startsWith('9') && digits.length == 10;
    final isInternationalFormat =
        digits.startsWith('639') && digits.length == 12;

    if (!isLocalFormat &&
        !isShortLocalFormat &&
        !isInternationalFormat) {
      return 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
    }

    return null;
  }

  String? validateProvince(
    String? value,
  ) {
    if (isButuanCitySelection) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Select your province.';
    }

    if (!provinces.contains(value)) {
      return 'Select a valid Caraga province.';
    }

    return null;
  }

  String? validateCity(
    String? value,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Select your city or municipality.';
    }

    if (value == 'City of Butuan') {
      return null;
    }

    if (selectedProvince == null) {
      return 'Select your province first.';
    }

    if (!availableCities.contains(value)) {
      return 'Select a valid city or municipality.';
    }

    return null;
  }

  String? validatePassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Create a password.';
    }

    if (password != password.trim()) {
      return 'Remove spaces at the beginning or end.';
    }

    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Include at least one letter.';
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number.';
    }

    return null;
  }

  String? validateConfirmPassword(
    String? value,
  ) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }

    if (confirmPassword != passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  bool fieldIsValid(
    String field,
  ) {
    if (field == 'province' && isButuanCitySelection) {
      return true;
    }

    if (!touchedFields.contains(field)) {
      return false;
    }

    switch (field) {
      case 'fullName':
        return validateFullName(fullNameController.text) == null;
      case 'email':
        return validateEmail(emailController.text) == null;
      case 'phone':
        return validatePhone(phoneController.text) == null;
      case 'province':
        return isButuanCitySelection ||
            (selectedProvince != null &&
                validateProvince(selectedProvince) == null);
      case 'city':
        return validateCity(selectedCity) == null;
      case 'confirmPassword':
        return validateConfirmPassword(
              confirmPasswordController.text,
            ) ==
            null;
      default:
        return false;
    }
  }

  void focusFirstInvalidField() {
    if (validateFullName(fullNameController.text) != null) {
      fullNameFocusNode.requestFocus();
      return;
    }

    if (validateEmail(emailController.text) != null) {
      emailFocusNode.requestFocus();
      return;
    }

    if (validatePhone(phoneController.text) != null) {
      phoneFocusNode.requestFocus();
      return;
    }

    if (validateProvince(selectedProvince) != null) {
      showProvincePicker();
      return;
    }

    if (validateCity(selectedCity) != null) {
      showCityPicker();
      return;
    }

    if (validatePassword(passwordController.text) != null) {
      passwordFocusNode.requestFocus();
      return;
    }

    if (validateConfirmPassword(
          confirmPasswordController.text,
        ) !=
        null) {
      confirmPasswordFocusNode.requestFocus();
    }
  }

  Future<String?> showSelectionSheet({
    required String title,
    required String subtitle,
    required List<String> options,
    required IconData icon,
    String? selectedValue,
    bool searchable = false,
    String Function(String option)? optionSubtitleBuilder,
  }) async {
    final searchController = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(180),
      builder: (
        sheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final query = searchController.text.trim().toLowerCase();
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
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.80,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B2435),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x7A000000),
                      blurRadius: 34,
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
                        color: const Color(0xFF7790A2),
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
                              color: const Color(0xFF146BFF).withAlpha(38),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFF89CAFF),
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF9EB5C5),
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
                              Navigator.pop(
                                sheetContext,
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFD5E4EF),
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
                          autofocus: options.length > 12,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (_) {
                            setSheetState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search city or municipality',
                            hintStyle: const TextStyle(
                              color: Color(0xFF7F98AA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8DB7D3),
                            ),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      searchController.clear();
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFA9BFCD),
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFF071C2A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0x3D8DB7D3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF32A9FF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Divider(
                      height: 1,
                      color: Colors.white.withAlpha(16),
                    ),
                    Flexible(
                      child: filteredOptions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF7892A5),
                                    size: 38,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No matching location found.',
                                    style: TextStyle(
                                      color: Color(0xFFA9BFCD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
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
                                return const SizedBox(height: 3);
                              },
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final option = filteredOptions[index];
                                final isSelected = option == selectedValue;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(
                                        sheetContext,
                                        option,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 170),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0A5162)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF29BDE3)
                                              : Colors.transparent,
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
                                                    color: Colors.white,
                                                    fontSize: 12.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w900
                                                        : FontWeight.w700,
                                                  ),
                                                ),
                                                if (optionSubtitleBuilder !=
                                                    null) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    optionSubtitleBuilder(
                                                      option,
                                                    ),
                                                    style: const TextStyle(
                                                      color:
                                                          Color(0xFF88A2B4),
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF42D59B),
                                              size: 20,
                                            )
                                          else
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: Color(0xFF718A9C),
                                              size: 20,
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

    searchController.dispose();

    return result;
  }

  Future<void> showProvincePicker() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final selected = await showSelectionSheet(
      title: 'Select Province',
      subtitle: 'Choose one of the five provinces in Caraga',
      options: provinces,
      icon: Icons.map_outlined,
      selectedValue: selectedProvince,
      optionSubtitleBuilder: (
        option,
      ) {
        final localityCount = locationsByProvince[option]?.length ?? 0;

        return '$localityCount cities and municipalities available';
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      final provinceChanged = selectedProvince != selected;

      selectedProvince = selected;

      if (provinceChanged || isButuanCitySelection) {
        selectedCity = null;
        touchedFields.remove('city');
      }

      registrationError = null;
      touchedFields.add('province');
    });
  }

  Future<void> showCityPicker() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final province = selectedProvince;
    final options = cityPickerOptions;

    final selected = await showSelectionSheet(
      title: 'Select City or Municipality',
      subtitle: province == null
          ? 'Choose City of Butuan, or select a province for other locations'
          : 'Complete locations in $province, plus City of Butuan',
      options: options,
      icon: Icons.location_city_outlined,
      selectedValue: selectedCity,
      searchable: options.length > 10,
      optionSubtitleBuilder: (
        option,
      ) {
        if (option == 'City of Butuan') {
          return 'Independent highly urbanized city · No province';
        }

        return option.startsWith('City of ')
            ? 'City · $province'
            : 'Municipality · $province';
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      selectedCity = selected;

      if (selected == 'City of Butuan') {
        selectedProvince = null;
        touchedFields.remove('province');
      }

      registrationError = null;
      touchedFields.add('city');
    });
  }

  Future<bool> confirmAccountDetails({
    required String fullName,
    required String email,
    required String phone,
    required String location,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(190),
      builder: (
        dialogContext,
      ) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  17,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF20A2334),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0x4D7EC9FF),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x7A000000),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0D5D88),
                            Color(0xFF124BD9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Vendor Account?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review the details that will be saved to your IsdaLink profile.',
                                  style: TextStyle(
                                    color: Color(0xFFD5E8F7),
                                    fontSize: 10.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xA3071B2A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withAlpha(18),
                        ),
                      ),
                      child: Column(
                        children: [
                          buildSummaryRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Name',
                            value: fullName,
                          ),
                          buildSummaryRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: email,
                          ),
                          buildSummaryRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: phone,
                          ),
                          buildSummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: location,
                            showDivider: false,
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        10,
                        12,
                        10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x261C9BEA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x4D58B9F2),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            color: Color(0xFF8ED0FF),
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Your selected location will appear automatically in Account Center after registration.',
                              style: TextStyle(
                                color: Color(0xFFC5DDEA),
                                fontSize: 10.2,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD4E3ED),
                              side: const BorderSide(
                                color: Color(0x667FB3D4),
                              ),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF176FFF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              elevation: 8,
                              shadowColor: const Color(0x66146BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'Create',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  Widget buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: highlight
                      ? const Color(0x2642D59B)
                      : const Color(0x24146BFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: highlight
                      ? const Color(0xFF42D59B)
                      : const Color(0xFF7BBEFF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 54,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 6,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF819AAC),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: highlight
                          ? const Color(0xFFD8FFF1)
                          : Colors.white,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.white.withAlpha(16),
          ),
      ],
    );
  }

  Future<void> showRegistrationSuccess() async {
    final navigator = Navigator.of(
      context,
      rootNavigator: true,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 56,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                22,
                23,
                22,
                22,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2435),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(25),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF42D59B),
                    size: 58,
                  ),
                  SizedBox(height: 13),
                  Text(
                    'Account Created',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Welcome to IsdaLink.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFAFC4D2),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (mounted && navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> createAccount() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      submitted = true;
      registrationError = null;
    });

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      focusFirstInvalidField();
      return;
    }

    final fullName = collapseSpaces(
      fullNameController.text,
    );
    final email = normalizeEmail(
      emailController.text,
    );
    final phone = normalizePhilippinePhone(
      phoneController.text,
    );
    final province = isButuanCitySelection
        ? null
        : selectedProvince;
    final administrativeArea = isButuanCitySelection
        ? 'City of Butuan'
        : selectedProvince!;
    final city = selectedCity!;
    final location = locationPreview;
    final provinceCode = selectedProvinceCode;
    final localityCode = selectedLocalityCode;
    final localityType = selectedLocalityType;
    final password = passwordController.text;

    final confirmed = await confirmAccountDetails(
      fullName: fullName,
      email: email,
      phone: phone,
      location: location,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      registrationError = null;
    });

    User? createdUser;

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        setRegistrationError(
          'Unable to create your account. Please try again.',
        );
        return;
      }

      await createdUser.updateDisplayName(
        fullName,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'name': fullName,
        'email': email,
        'phone': phone,
        'role': 'vendor',
        'accountType': 'vendor',
        'supplierStatus': 'not_applicable',
        'region': 'Caraga Region',
        'province': province,
        'provinceCode': provinceCode,
        'administrativeArea': administrativeArea,
        'administrativeAreaType': isButuanCitySelection
            ? 'highly_urbanized_city'
            : 'province',
        'cityMunicipality': city,
        'cityMunicipalityCode': localityCode,
        'cityMunicipalityType': localityType,
        'isHighlyUrbanizedCity': isButuanCitySelection,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      await showRegistrationSuccess();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // The account may require reauthentication before deletion.
        }
      }

      setRegistrationError(
        authenticationErrorMessage(
          error,
        ),
      );
    } catch (_) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // The account may require reauthentication before deletion.
        }
      }

      setRegistrationError(
        'Unable to finish registration. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String authenticationErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Create a stronger password with letters and numbers.';
      case 'operation-not-allowed':
        return 'Account registration is currently unavailable.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  void setRegistrationError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      registrationError = message;
    });
  }

  InputDecoration inputStyle({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    bool isValid = false,
  }) {
    const radius = 16.0;

    final effectiveSuffixIcon = suffixIcon ??
        (isValid
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF42D59B),
                size: 20,
              )
            : null);

    final enabledBorderColor = isValid
        ? const Color(0x9942D59B)
        : const Color(0x557FB3D4);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFC5D6E2),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF83C8FF),
        fontWeight: FontWeight.w900,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFC5D6E2),
        size: 21,
      ),
      suffixIcon: effectiveSuffixIcon,
      filled: true,
      fillColor: const Color(0xE60A2638),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        color: Color(0xFFFFA199),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: enabledBorderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFF32A9FF),
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFFFF756B),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFFFF8B82),
          width: 1.7,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0x337FB3D4),
        ),
      ),
    );
  }

  Widget buildLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1596FF),
            Color(0xFF155BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(42),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73146BFF),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: const Icon(
        Icons.set_meal_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }

  Widget buildVendorAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        12,
        13,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xC20A2638),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withAlpha(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF146BFF).withAlpha(42),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: Color(0xFF8EC8FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Browse suppliers and place COD orders. Supplier access can be requested later.',
                  style: TextStyle(
                    color: Color(0xFFB9CDDB),
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback? onTap,
    required FormFieldValidator<String> validator,
    required String fieldKey,
    String? helperText,
    String? displayValue,
    bool enabled = true,
  }) {
    final visibleValue = displayValue ?? value;
    final isValid = fieldIsValid(fieldKey);

    return FormField<String>(
      key: ValueKey(
        '$label-$value-$visibleValue-$selectedProvince-$selectedCity-$submitted',
      ),
      initialValue: value,
      validator: validator,
      autovalidateMode: submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (
        field,
      ) {
        final hasError = field.hasError;
        final borderColor = hasError
            ? const Color(0xFFFF756B)
            : isValid
                ? const Color(0xFF42D59B)
                : const Color(0xFF32A9FF);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled
                    ? onTap
                    : null,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  height: 58,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xE60A2638)
                        : const Color(0xB3071C2B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: hasError || isValid
                          ? 1.6
                          : 1.35,
                    ),
                    boxShadow: isValid
                        ? const [
                            BoxShadow(
                              color: Color(0x1F42D59B),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isValid
                              ? const Color(0x2442D59B)
                              : const Color(0x24146BFF),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          icon,
                          color: isValid
                              ? const Color(0xFF62E3B2)
                              : enabled
                                  ? const Color(0xFFC5D6E2)
                                  : const Color(0xFF6F8798),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: visibleValue == null
                                  ? Alignment.centerLeft
                                  : Alignment.bottomLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: visibleValue == null
                                      ? 0
                                      : 8,
                                ),
                                child: Text(
                                  visibleValue ?? label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: visibleValue == null
                                        ? const Color(0xFFB8CBD9)
                                        : visibleValue == 'Not required'
                                            ? const Color(0xFFB8CBD9)
                                            : Colors.white,
                                    fontSize: visibleValue == null
                                        ? 13
                                        : 12.5,
                                    fontWeight: visibleValue == null
                                        ? FontWeight.w700
                                        : FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            if (visibleValue != null)
                              Positioned(
                                top: 5,
                                left: 0,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isValid
                                        ? const Color(0xFF71E4B8)
                                        : const Color(0xFF83C8FF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      if (isValid)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF42D59B),
                          size: 20,
                        ),
                      const SizedBox(width: 3),
                      Icon(
                        enabled
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.lock_outline_rounded,
                        color: enabled
                            ? const Color(0xFFC7D9E5)
                            : const Color(0xFF6F8798),
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (helperText != null && !hasError)
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
                    color: Color(0xFF8FA6B7),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (hasError)
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
                    color: Color(0xFFFFA199),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget buildSectionHeader({
    required int step,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0E7FB3),
                Color(0xFF145BFF),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33146BFF),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE7F3FA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8EA7B8),
                  fontSize: 9.8,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0x26146BFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0x40146BFF),
            ),
          ),
          child: Text(
            'STEP $step',
            style: const TextStyle(
              color: Color(0xFF8FCBFF),
              fontSize: 8.8,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFormDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 17,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              color: Colors.white.withAlpha(17),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF2D86CE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Divider(
              height: 1,
              color: Colors.white.withAlpha(17),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileLocationPreview() {
    if (locationPreview.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        11,
      ),
      decoration: BoxDecoration(
        color: const Color(0x2442D59B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x7042D59B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0x2E42D59B),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF62E3B2),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile location',
                  style: TextStyle(
                    color: Color(0xFFBDF3DE),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  locationPreview,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This will appear automatically in Account Center.',
                  style: TextStyle(
                    color: Color(0xFFAED9CA),
                    fontSize: 9.4,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF42D59B),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget buildRegistrationPrivacyNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1F1C9BEA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x3D58B9F2),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF8ED0FF),
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your contact and location details are used for account identification and Cash on Delivery coordination.',
              style: TextStyle(
                color: Color(0xFFB8CFDD),
                fontSize: 9.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget requirementChip({
    required bool isMet,
    required String label,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isMet
              ? const Color(0x2442D59B)
              : const Color(0x2B587286),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMet
                ? const Color(0x8042D59B)
                : const Color(0x335D7890),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMet
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isMet
                  ? const Color(0xFF42D59B)
                  : const Color(0xFF7892A5),
              size: 15,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMet
                      ? const Color(0xFFD6FFF0)
                      : const Color(0xFFA6BAC8),
                  fontSize: 9.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPasswordRequirements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        11,
        10,
        11,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xB3071C2B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withAlpha(18),
        ),
      ),
      child: Row(
        children: [
          requirementChip(
            isMet: hasMinimumLength,
            label: '8+ chars',
          ),
          const SizedBox(width: 7),
          requirementChip(
            isMet: hasLetter,
            label: 'Letter',
          ),
          const SizedBox(width: 7),
          requirementChip(
            isMet: hasNumber,
            label: 'Number',
          ),
        ],
      ),
    );
  }

  Widget buildRegistrationError() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: registrationError == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(
                registrationError,
              ),
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 14,
              ),
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                11,
              ),
              decoration: BoxDecoration(
                color: const Color(0x36FF6B61),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x8CFF7A70),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFFA199),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      registrationError!,
                      style: const TextStyle(
                        color: Color(0xFFFFD4D0),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildRegistrationForm() {
    return AutofillGroup(
      child: Form(
        key: formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            buildRegistrationError(),
            buildSectionHeader(
              step: 1,
              icon: Icons.badge_outlined,
              title: 'Personal details',
              subtitle: 'Enter the information used to identify your account.',
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: fullNameController,
              focusNode: fullNameFocusNode,
              enabled: !isLoading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.name,
              ],
              validator: validateFullName,
              onChanged: (_) {
                fieldChanged(
                  'fullName',
                );
              },
              onFieldSubmitted: (_) {
                emailFocusNode.requestFocus();
              },
              decoration: inputStyle(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                isValid: fieldIsValid(
                  'fullName',
                ),
              ),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: emailController,
              focusNode: emailFocusNode,
              enabled: !isLoading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.email,
              ],
              autocorrect: false,
              enableSuggestions: false,
              validator: validateEmail,
              onChanged: (_) {
                fieldChanged(
                  'email',
                );
              },
              onFieldSubmitted: (_) {
                phoneFocusNode.requestFocus();
              },
              decoration: inputStyle(
                label: 'Email Address',
                icon: Icons.email_outlined,
                isValid: fieldIsValid(
                  'email',
                ),
              ),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: phoneController,
              focusNode: phoneFocusNode,
              enabled: !isLoading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.telephoneNumber,
              ],
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9+\s-]'),
                ),
                LengthLimitingTextInputFormatter(16),
              ],
              validator: validatePhone,
              onChanged: (_) {
                fieldChanged(
                  'phone',
                );
              },
              onFieldSubmitted: (_) {
                showProvincePicker();
              },
              decoration: inputStyle(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                isValid: fieldIsValid(
                  'phone',
                ),
              ).copyWith(
                helperText: 'Example: 09171234567',
                helperStyle: const TextStyle(
                  color: Color(0xFF829AAC),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            buildFormDivider(),
            buildSectionHeader(
              step: 2,
              icon: Icons.location_on_outlined,
              title: 'Location in Caraga',
              subtitle: 'Choose your province and city or municipality for your profile.',
            ),
            const SizedBox(height: 13),
            buildPickerField(
              label: 'Province',
              value: selectedProvince,
              displayValue: provinceDisplayValue,
              icon: Icons.map_outlined,
              onTap: showProvincePicker,
              validator: validateProvince,
              fieldKey: 'province',
              helperText: isButuanCitySelection
                  ? 'No province is required for the independent City of Butuan. Tap to choose a province instead.'
                  : selectedProvince == null
                      ? 'Choose one of Caraga’s five provinces.'
                      : 'Used to filter the city and municipality choices.',
            ),
            const SizedBox(height: 11),
            buildPickerField(
              label: 'City or Municipality',
              value: selectedCity,
              icon: Icons.location_city_outlined,
              onTap: showCityPicker,
              validator: validateCity,
              fieldKey: 'city',
              helperText: isButuanCitySelection
                  ? 'Independent highly urbanized city in Caraga.'
                  : selectedProvince == null
                      ? 'Select a province first, or choose City of Butuan here.'
                      : selectedCity == null
                          ? 'Tap to search all locations in $selectedProvince.'
                          : '$selectedLocalityType in $selectedProvince.',
              enabled: true,
            ),
            if (locationPreview.isNotEmpty) ...[
              const SizedBox(height: 11),
              buildProfileLocationPreview(),
            ],
            buildFormDivider(),
            buildSectionHeader(
              step: 3,
              icon: Icons.shield_outlined,
              title: 'Account security',
              subtitle: 'Create a secure password for your IsdaLink account.',
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              enabled: !isLoading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              obscureText: obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.newPassword,
              ],
              autocorrect: false,
              enableSuggestions: false,
              validator: validatePassword,
              onFieldSubmitted: (_) {
                confirmPasswordFocusNode.requestFocus();
              },
              decoration: inputStyle(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: obscurePassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFFD5E4EF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            buildPasswordRequirements(),
            const SizedBox(height: 13),
            TextFormField(
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocusNode,
              enabled: !isLoading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              obscureText: obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.newPassword,
              ],
              autocorrect: false,
              enableSuggestions: false,
              validator: validateConfirmPassword,
              onFieldSubmitted: (_) {
                createAccount();
              },
              decoration: inputStyle(
                label: 'Confirm Password',
                icon: Icons.lock_reset_rounded,
                suffixIcon: IconButton(
                  tooltip: obscureConfirmPassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFFD5E4EF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            buildRegistrationPrivacyNote(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 53,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF176FFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF315473),
                  elevation: 8,
                  shadowColor: const Color(0x73146BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                          SizedBox(width: 11),
                          Text(
                            'Creating Account...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            6,
            18,
            8,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xD6074263),
                Color(0xB5073450),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  borderRadius: BorderRadius.circular(99),
                  child: Ink(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(28),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(24),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Create Account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.5,
                    letterSpacing: -0.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF020712),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Color(0xFF020712),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF020712),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/login_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xD0061A2A),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x57138CE7),
                        Color(0xEA061725),
                        Color(0xFF020712),
                      ],
                      stops: [
                        0.0,
                        0.50,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          32,
                        ),
                        child: Column(
                          children: [
                            buildLogo(),
                            const SizedBox(height: 12),
                            const Text(
                              'Join IsdaLink',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Set up your vendor account in three simple steps.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFB8CBD9),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),
                            buildVendorAccountCard(),
                            const SizedBox(height: 13),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    16,
                                    14,
                                    15,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xF2071B2A),
                                        Color(0xEA082536),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0x3658B9F2),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x4D000000),
                                        blurRadius: 28,
                                        offset: Offset(0, 16),
                                      ),
                                      BoxShadow(
                                        color: Color(0x19146BFF),
                                        blurRadius: 20,
                                        offset: Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: buildRegistrationForm(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'By creating an account, you confirm that the information provided is accurate.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF8BA2B3),
                                fontSize: 10.1,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Color(0xFFB8C9D6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.pop(context);
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF91CDFF),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
