import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/auth/registration_welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  static const locationCodesByProvince = <String, Map<String, String>>{
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

  final touchedFields = <String>{};

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool submitted = false;
  bool stepValidationAttempted = false;
  int currentStep = 0;

  String? selectedProvince;
  String? selectedCity;
  String? registrationError;

  List<String> get availableCities {
    final values = locationsByProvince[selectedProvince];

    if (values == null) {
      return const [];
    }

    return List<String>.from(values)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<String> get cityPickerOptions => availableCities;

  bool get hasMinimumLength => passwordController.text.length >= 8;

  bool get hasLetter => RegExp(r'[A-Za-z]').hasMatch(passwordController.text);

  bool get hasNumber => RegExp(r'\d').hasMatch(passwordController.text);

  String? get provinceDisplayValue => selectedProvince;

  String get locationPreview {
    final city = selectedCity;
    final province = selectedProvince;

    if (city == null || province == null) {
      return '';
    }

    return '$city, $province, Caraga Region';
  }

  String get selectedLocalityType {
    final city = selectedCity ?? '';

    return city == 'Butuan City' || city.startsWith('City of ')
        ? 'City'
        : 'Municipality';
  }

  String? get selectedProvinceCode => provinceCodes[selectedProvince];

  String? get selectedLocalityCode {
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

    passwordController.addListener(handlePasswordChanged);
    confirmPasswordController.addListener(handleConfirmPasswordChanged);
  }

  @override
  void dispose() {
    passwordController.removeListener(handlePasswordChanged);
    confirmPasswordController.removeListener(handleConfirmPasswordChanged);

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

  void fieldChanged(String field) {
    if (!mounted) {
      return;
    }

    setState(() {
      touchedFields.add(field);
      registrationError = null;
    });
  }

  String collapseSpaces(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  String phoneDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String normalizePhilippinePhone(String value) {
    final digits = phoneDigits(value);

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

  String? validateFullName(String? value) {
    final fullName = collapseSpaces(value ?? '');

    if (fullName.isEmpty) {
      return 'Enter your full name.';
    }

    if (fullName.length < 2) {
      return 'Enter at least 2 characters.';
    }

    final namePattern = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ.' -]+$");

    if (!namePattern.hasMatch(fullName)) {
      return 'Use letters, spaces, hyphens, or apostrophes only.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final email = normalizeEmail(value ?? '');

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final input = (value ?? '').trim();

    if (input.isEmpty) {
      return 'Enter your phone number.';
    }

    final digits = phoneDigits(input);

    final isLocalFormat = digits.startsWith('09') && digits.length == 11;
    final isShortLocalFormat = digits.startsWith('9') && digits.length == 10;
    final isInternationalFormat =
        digits.startsWith('639') && digits.length == 12;

    if (!isLocalFormat && !isShortLocalFormat && !isInternationalFormat) {
      return 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
    }

    return null;
  }

  String? validateProvince(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select your province.';
    }

    if (!provinces.contains(value)) {
      return 'Select a valid Caraga province.';
    }

    return null;
  }

  String? validateCity(String? value) {
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

  String? validatePassword(String? value) {
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

  String? validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }

    if (confirmPassword != passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  bool fieldIsValid(String field) {
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
        return selectedProvince != null &&
            validateProvince(selectedProvince) == null;
      case 'city':
        return validateCity(selectedCity) == null;
      case 'confirmPassword':
        return validateConfirmPassword(confirmPasswordController.text) == null;
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

    if (validateConfirmPassword(confirmPasswordController.text) != null) {
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
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (sheetContext) {
        return _LocationPickerSearchHost(
          builder: (context, searchController, searchFocusNode) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final query = searchController.text.trim().toLowerCase();
                final filteredOptions = options.where((option) {
                  if (query.isEmpty) return true;
                  return option.toLowerCase().contains(query);
                }).toList();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3000152A),
                          blurRadius: 26,
                          offset: Offset(0, -8),
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
                            color: const Color(0xFFD6E2E9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                          child: Row(
                            children: [
                              Icon(icon, color: const Color(0xFF0875D1), size: 25),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Color(0xFF102C44),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Color(0xFF718697),
                                        fontSize: 10.5,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
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
                                  color: Color(0xFF536C7E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (searchable)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                            child: TextField(
                              controller: searchController,
                              focusNode: searchFocusNode,
                              autofocus: false,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              textInputAction: TextInputAction.search,
                              onChanged: (_) => setSheetState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search city or municipality',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF8A9CA9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF0875D1),
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
                                          color: Color(0xFF7A90A1),
                                        ),
                                      ),
                                filled: true,
                                fillColor: const Color(0xFFF3F7FA),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD7E4EC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0875D1),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Divider(height: 1, color: Color(0xFFE7EEF3)),
                        Flexible(
                          child: filteredOptions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        color: Color(0xFF8A9CA9),
                                        size: 36,
                                      ),
                                      SizedBox(height: 9),
                                      Text(
                                        'No matching location found.',
                                        style: TextStyle(
                                          color: Color(0xFF718697),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                                  itemCount: filteredOptions.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    height: 1,
                                    color: Color(0xFFEAF0F4),
                                  ),
                                  itemBuilder: (context, index) {
                                    final option = filteredOptions[index];
                                    final isSelected = option == selectedValue;

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          searchFocusNode.unfocus();
                                          Navigator.pop(sheetContext, option);
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFEAF5FD)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF8BC8F2)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      option,
                                                      style: TextStyle(
                                                        color: const Color(0xFF102C44),
                                                        fontSize: 12.5,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w900
                                                            : FontWeight.w800,
                                                      ),
                                                    ),
                                                    if (optionSubtitleBuilder != null) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        optionSubtitleBuilder(option),
                                                        style: const TextStyle(
                                                          color: Color(0xFF7A90A1),
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle_rounded
                                                    : Icons.chevron_right_rounded,
                                                color: isSelected
                                                    ? const Color(0xFF16A77A)
                                                    : const Color(0xFF8A9CA9),
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
      },
    );
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
      optionSubtitleBuilder: (option) {
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

      if (provinceChanged) {
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

    if (province == null) {
      setState(() {
        touchedFields.add('province');
      });
      return;
    }

    final options = cityPickerOptions;

    final selected = await showSelectionSheet(
      title: 'Select City or Municipality',
      subtitle: 'Choose a city or municipality in $province',
      options: options,
      icon: Icons.location_city_outlined,
      selectedValue: selectedCity,
      searchable: options.length > 10,
      optionSubtitleBuilder: (option) {
        return option == 'Butuan City' || option.startsWith('City of ')
            ? 'City · $province'
            : 'Municipality · $province';
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      selectedCity = selected;
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
      barrierColor: Colors.black.withAlpha(115),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE0EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3000152A),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF0875D1),
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create your account?',
                              style: TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Check your details before we save them.',
                              style: TextStyle(
                                color: Color(0xFF718697),
                                fontSize: 10.8,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2EBF0)),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF536C7E),
                            side: const BorderSide(color: Color(0xFFD1DFE8)),
                            minimumSize: const Size.fromHeight(49),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Edit Details',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0875D1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(49),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: highlight
                    ? const Color(0xFF16A77A)
                    : const Color(0xFF0875D1),
                size: 18,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A90A1),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: highlight
                        ? const Color(0xFF155D4C)
                        : const Color(0xFF102C44),
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE4ECF1)),
      ],
    );
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

    final fullName = collapseSpaces(fullNameController.text);
    final email = normalizeEmail(emailController.text);
    final phone = normalizePhilippinePhone(phoneController.text);
    final province = selectedProvince!;
    final administrativeArea = selectedProvince!;
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
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      createdUser = credential.user;

      if (createdUser == null) {
        setRegistrationError(
          'Unable to create your account. Please try again.',
        );
        return;
      }

      await createdUser.updateDisplayName(fullName);

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
            'administrativeAreaType': 'province',
            'cityMunicipality': city,
            'cityMunicipalityCode': localityCode,
            'cityMunicipalityType': localityType,
            'isHighlyUrbanizedCity': false,
            'location': location,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 560),
          pageBuilder: (_, __, ___) => RegistrationWelcomeScreen(
            fullName: fullName,
          ),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            );
          },
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

      setRegistrationError(authenticationErrorMessage(error));
    } catch (_) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // The account may require reauthentication before deletion.
        }
      }

      setRegistrationError('Unable to finish registration. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String authenticationErrorMessage(FirebaseAuthException error) {
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

  void setRegistrationError(String message) {
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
    String? helperText,
  }) {
    const radius = 18.0;

    return InputDecoration(
      labelText: label,
      helperText: helperText,
      labelStyle: const TextStyle(
        color: Color(0xFF6F8597),
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF0875D1),
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF7A90A1),
        fontSize: 10,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF0875D1), size: 21),
      suffixIcon: suffixIcon ??
          (isValid
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A77A),
                  size: 20,
                )
              : null),
      filled: true,
      fillColor: const Color(0xFFF3F7FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        color: Color(0xFFC84238),
        fontSize: 10.5,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: isValid ? const Color(0xFF8FD7C1) : const Color(0xFFD7E4EC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFF0875D1), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE66B62), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFD9544B), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE4EBF0)),
      ),
    );
  }

  Widget buildRegistrationError() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: registrationError == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(registrationError),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0C2BD)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFC84238),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      registrationError!,
                      style: const TextStyle(
                        color: Color(0xFF8F332C),
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

  Widget buildPickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback? onTap,
    required FormFieldValidator<String> validator,
    required String fieldKey,
    String? helperText,
    bool enabled = true,
  }) {
    final isValid = fieldIsValid(fieldKey);

    return FormField<String>(
      key: ValueKey('$label-$value-$selectedProvince-$selectedCity-$currentStep'),
      initialValue: value,
      validator: validator,
      autovalidateMode: (stepValidationAttempted || submitted)
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (field) {
        final hasError = field.hasError;
        final borderColor = hasError
            ? const Color(0xFFE66B62)
            : isValid
                ? const Color(0xFF8FD7C1)
                : const Color(0xFFD7E4EC);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xFFF3F7FA)
                        : const Color(0xFFF0F3F5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 1.1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: enabled
                            ? const Color(0xFF0875D1)
                            : const Color(0xFF9AABB7),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF718697),
                                fontSize: 9.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              value ?? 'Select $label',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: value == null
                                    ? const Color(0xFF8B9CA8)
                                    : const Color(0xFF102C44),
                                fontSize: 13.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!enabled)
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF9AABB7),
                          size: 20,
                        )
                      else if (isValid)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF16A77A),
                          size: 20,
                        )
                      else
                        const Icon(
                          Icons.expand_more_rounded,
                          color: Color(0xFF60788A),
                          size: 23,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFC84238),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else if (helperText != null) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  helperText,
                  style: const TextStyle(
                    color: Color(0xFF7A90A1),
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget buildStepProgress() {
    final stepLabel = currentStep == 0
        ? 'Personal Details'
        : currentStep == 1
            ? 'Location'
            : 'Security';

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of 3',
              style: const TextStyle(
                color: Color(0xFF0875D1),
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              stepLabel,
              style: const TextStyle(
                color: Color(0xFF6C8293),
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: List.generate(3, (index) {
            final active = index <= currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0875D1)
                      : const Color(0xFFDCE6EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget buildStepHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0875D1), size: 27),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF718697),
                  fontSize: 11,
                  height: 1.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRequirementLine({required bool met, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: met ? const Color(0xFF16A77A) : const Color(0xFF9EB0BC),
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: met ? const Color(0xFF147D64) : const Color(0xFF718697),
            fontSize: 10.2,
            fontWeight: met ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget buildPasswordRequirements() {
    return Wrap(
      spacing: 14,
      runSpacing: 7,
      children: [
        buildRequirementLine(met: hasMinimumLength, label: '8+ characters'),
        buildRequirementLine(met: hasLetter, label: 'Letter'),
        buildRequirementLine(met: hasNumber, label: 'Number'),
      ],
    );
  }

  Widget buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildStepHeading(
          icon: Icons.badge_outlined,
          title: 'Personal Details',
          subtitle: 'Tell us who you are and how we can contact you.',
        ),
        const SizedBox(height: 17),
        TextFormField(
          controller: fullNameController,
          focusNode: fullNameFocusNode,
          enabled: !isLoading,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: validateFullName,
          onChanged: (_) => fieldChanged('fullName'),
          onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
          decoration: inputStyle(
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            isValid: fieldIsValid('fullName'),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          enabled: !isLoading,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          enableSuggestions: false,
          validator: validateEmail,
          onChanged: (_) => fieldChanged('email'),
          onFieldSubmitted: (_) => phoneFocusNode.requestFocus(),
          decoration: inputStyle(
            label: 'Email Address',
            icon: Icons.email_outlined,
            isValid: fieldIsValid('email'),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          enabled: !isLoading,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
            LengthLimitingTextInputFormatter(16),
          ],
          validator: validatePhone,
          onChanged: (_) => fieldChanged('phone'),
          decoration: inputStyle(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            isValid: fieldIsValid('phone'),
            helperText: 'Use 09XXXXXXXXX or +639XXXXXXXXX',
          ),
        ),
      ],
    );
  }

  Widget buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildStepHeading(
          icon: Icons.location_on_outlined,
          title: 'Location',
          subtitle: 'Choose your province and city or municipality in Caraga.',
        ),
        const SizedBox(height: 17),
        buildPickerField(
          label: 'Province',
          value: selectedProvince,
          icon: Icons.map_outlined,
          onTap: showProvincePicker,
          validator: validateProvince,
          fieldKey: 'province',
          helperText: 'Choose one of Caraga’s five provinces.',
        ),
        const SizedBox(height: 14),
        buildPickerField(
          label: 'City or Municipality',
          value: selectedCity,
          icon: Icons.location_city_outlined,
          onTap: showCityPicker,
          validator: validateCity,
          fieldKey: 'city',
          helperText: selectedProvince == null
              ? 'Select a province first.'
              : 'Choose your city or municipality.',
          enabled: selectedProvince != null,
        ),
        if (locationPreview.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBDE6D8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A77A),
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locationPreview,
                    style: const TextStyle(
                      color: Color(0xFF155D4C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildStepHeading(
          icon: Icons.shield_outlined,
          title: 'Account Security',
          subtitle: 'Create a password you will use to sign in.',
        ),
        const SizedBox(height: 17),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          enabled: !isLoading,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          autocorrect: false,
          enableSuggestions: false,
          validator: validatePassword,
          onFieldSubmitted: (_) => confirmPasswordFocusNode.requestFocus(),
          decoration: inputStyle(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
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
                color: const Color(0xFF60788A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        buildPasswordRequirements(),
        const SizedBox(height: 14),
        TextFormField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocusNode,
          enabled: !isLoading,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          autocorrect: false,
          enableSuggestions: false,
          validator: validateConfirmPassword,
          onFieldSubmitted: (_) => createAccount(),
          decoration: inputStyle(
            label: 'Confirm Password',
            icon: Icons.lock_reset_rounded,
            isValid: fieldIsValid('confirmPassword'),
            suffixIcon: IconButton(
              tooltip: obscureConfirmPassword
                  ? 'Show password'
                  : 'Hide password',
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF60788A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF0875D1),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your contact and location details are used for account identification and Cash on Delivery coordination.',
                style: TextStyle(
                  color: Color(0xFF718697),
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool validateCurrentStep() {
    FocusScope.of(context).unfocus();

    setState(() {
      stepValidationAttempted = true;
      registrationError = null;
      if (currentStep == 0) {
        touchedFields.addAll(['fullName', 'email', 'phone']);
      } else if (currentStep == 1) {
        touchedFields.addAll(['province', 'city']);
      } else {
        touchedFields.addAll(['password', 'confirmPassword']);
      }
    });

    final formValid = formKey.currentState?.validate() ?? false;

    if (!formValid) {
      if (currentStep == 0) {
        if (validateFullName(fullNameController.text) != null) {
          fullNameFocusNode.requestFocus();
        } else if (validateEmail(emailController.text) != null) {
          emailFocusNode.requestFocus();
        } else if (validatePhone(phoneController.text) != null) {
          phoneFocusNode.requestFocus();
        }
      } else if (currentStep == 1) {
        if (validateProvince(selectedProvince) != null) {
          showProvincePicker();
        } else if (validateCity(selectedCity) != null) {
          showCityPicker();
        }
      } else if (validatePassword(passwordController.text) != null) {
        passwordFocusNode.requestFocus();
      } else if (validateConfirmPassword(confirmPasswordController.text) != null) {
        confirmPasswordFocusNode.requestFocus();
      }
    }

    return formValid;
  }

  void nextStep() {
    if (isLoading || !validateCurrentStep()) {
      return;
    }

    if (currentStep < 2) {
      setState(() {
        currentStep += 1;
        stepValidationAttempted = false;
        submitted = false;
        registrationError = null;
      });
    }
  }

  void previousStep() {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (currentStep > 0) {
      setState(() {
        currentStep -= 1;
        stepValidationAttempted = false;
        submitted = false;
        registrationError = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget buildStepBody() {
    switch (currentStep) {
      case 0:
        return buildPersonalStep();
      case 1:
        return buildLocationStep();
      default:
        return buildSecurityStep();
    }
  }

  Widget buildHeader() {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/auth_caraga_header.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x2200192D), Color(0xA8063B5E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoading ? null : previousStep,
                        borderRadius: BorderRadius.circular(17),
                        child: Ink(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/isdalink_logo.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'CREATE YOUR ACCOUNT',
                  style: TextStyle(
                    color: Color(0xFFD8EBF7),
                    fontSize: 10.5,
                    letterSpacing: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Join IsdaLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your vendor account in three quick steps.',
                  style: TextStyle(
                    color: Color(0xFFE5F0F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActionButtons() {
    final isLastStep = currentStep == 2;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : isLastStep
                ? createAccount
                : nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0875D1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9CBD7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: isLoading && isLastStep
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Creating Account...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastStep ? 'Create Account' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F8FA),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: keyboardOpen ? 12 : mediaQuery.padding.bottom + 8,
            ),
            child: Column(
              children: [
                buildHeader(),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F8FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(17, 16, 17, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE0EAF0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1000152A),
                                blurRadius: 16,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildStepProgress(),
                              const SizedBox(height: 17),
                              buildRegistrationError(),
                              AutofillGroup(
                                child: Form(
                                  key: formKey,
                                  autovalidateMode:
                                      (stepValidationAttempted || submitted)
                                          ? AutovalidateMode.onUserInteraction
                                          : AutovalidateMode.disabled,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: KeyedSubtree(
                                      key: ValueKey(currentStep),
                                      child: buildStepBody(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              buildActionButtons(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Color(0xFF647C8F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0875D1),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        ),
      ),
    );
  }
}

class _LocationPickerSearchHost extends StatefulWidget {
  const _LocationPickerSearchHost({required this.builder});

  final Widget Function(
    BuildContext context,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  )
  builder;

  @override
  State<_LocationPickerSearchHost> createState() =>
      _LocationPickerSearchHostState();
}

class _LocationPickerSearchHostState extends State<_LocationPickerSearchHost> {
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
    return widget.builder(context, searchController, searchFocusNode);
  }
}
