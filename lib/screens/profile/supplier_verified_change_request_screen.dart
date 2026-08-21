import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
import 'package:isdalink/screens/supplier/activation/supplier_caraga_locations.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/supplier_profile_service.dart';

enum _VerifiedChangeType {
  storeName,
  businessLocation,
  storePhoto,
  businessPermit,
}

class SupplierVerifiedChangeRequestScreen extends StatefulWidget {
  const SupplierVerifiedChangeRequestScreen({
    super.key,
    required this.uid,
    required this.profileData,
    this.previousRequestData,
  });

  final String uid;
  final Map<String, dynamic> profileData;
  final Map<String, dynamic>? previousRequestData;

  @override
  State<SupplierVerifiedChangeRequestScreen> createState() =>
      _SupplierVerifiedChangeRequestScreenState();
}

class _SupplierVerifiedChangeRequestScreenState
    extends State<SupplierVerifiedChangeRequestScreen> {
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final permitNumberController = TextEditingController();
  final reasonController = TextEditingController();

  final imagePicker = ImagePicker();
  final uploadService = const CloudinaryUploadService();
  final profileService = const SupplierProfileService();

  final selectedChanges = <_VerifiedChangeType>{};

  int step = 0;
  bool loadingPrivateData = true;
  bool submitting = false;
  bool uploadingStorePhoto = false;
  bool uploadingPermitPhoto = false;

  String selectedProvince = '';
  String selectedLocality = '';
  double? selectedLatitude;
  double? selectedLongitude;

  String currentPermitNumber = '';
  String currentPermitUrl = '';
  String currentStorePhotoUrl = '';
  String requestedStorePhotoUrl = '';
  String requestedPermitPhotoUrl = '';

  String stringValue(
    Map<String, dynamic>? data,
    String key, [
    String fallback = '',
  ]) {
    final value = data?[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  double? coordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  String get currentStoreName => stringValue(
        widget.profileData,
        'storeName',
        stringValue(
          widget.profileData,
          'businessName',
          stringValue(
            widget.profileData,
            'supplierName',
            'Fish Supplier',
          ),
        ),
      );

  String get currentProvince =>
      stringValue(widget.profileData, 'storeProvince');

  String get currentLocality =>
      stringValue(widget.profileData, 'storeCityMunicipality');

  String get currentAddress =>
      stringValue(widget.profileData, 'storeAddress');

  String get currentLocation => stringValue(
        widget.profileData,
        'storeLocation',
        stringValue(
          widget.profileData,
          'location',
          'Location not available',
        ),
      );

  double? get currentLatitude =>
      coordinate(widget.profileData['storeLatitude']);

  double? get currentLongitude =>
      coordinate(widget.profileData['storeLongitude']);

  bool get uploadBusy =>
      uploadingStorePhoto || uploadingPermitPhoto;

  bool get needsStorePhotoEvidence =>
      selectedChanges.contains(
        _VerifiedChangeType.businessLocation,
      ) ||
      selectedChanges.contains(
        _VerifiedChangeType.storePhoto,
      );

  bool get needsPermitEvidence =>
      selectedChanges.contains(
        _VerifiedChangeType.storeName,
      ) ||
      selectedChanges.contains(
        _VerifiedChangeType.businessPermit,
      );

  @override
  void initState() {
    super.initState();

    storeNameController.text = currentStoreName;
    storeAddressController.text = currentAddress;
    selectedProvince = currentProvince;
    selectedLocality = currentLocality;
    selectedLatitude = currentLatitude;
    selectedLongitude = currentLongitude;

    currentStorePhotoUrl = stringValue(
      widget.profileData,
      'storePhotoUrl',
      stringValue(
        widget.profileData,
        'profileImageUrl',
      ),
    );

    _applyPreviousRequestIfRevising();
    loadPrivateApplication();
  }

  void _applyPreviousRequestIfRevising() {
    final previous = widget.previousRequestData;
    final status = stringValue(
      previous,
      'status',
    ).toLowerCase();

    if (previous == null ||
        (status != 'rejected' && status != 'withdrawn')) {
      return;
    }

    final rawFields = previous['changedFields'];
    final fields = rawFields is List
        ? rawFields.map((value) => value.toString()).toSet()
        : <String>{};

    if (fields.contains('Store name')) {
      selectedChanges.add(_VerifiedChangeType.storeName);
    }
    if (fields.contains('Business location')) {
      selectedChanges.add(_VerifiedChangeType.businessLocation);
    }
    if (fields.contains('Store photo')) {
      selectedChanges.add(_VerifiedChangeType.storePhoto);
    }
    if (fields.contains('Business permit')) {
      selectedChanges.add(_VerifiedChangeType.businessPermit);
    }

    storeNameController.text = stringValue(
      previous,
      'requestedStoreName',
      currentStoreName,
    );
    storeAddressController.text = stringValue(
      previous,
      'requestedStoreAddress',
      currentAddress,
    );
    selectedProvince = stringValue(
      previous,
      'requestedStoreProvince',
      currentProvince,
    );
    selectedLocality = stringValue(
      previous,
      'requestedStoreCityMunicipality',
      currentLocality,
    );
    selectedLatitude = coordinate(
      previous['requestedStoreLatitude'],
    );
    selectedLongitude = coordinate(
      previous['requestedStoreLongitude'],
    );
    requestedStorePhotoUrl = stringValue(
      previous,
      'requestedStorePhotoUrl',
    );
    requestedPermitPhotoUrl = stringValue(
      previous,
      'requestedBusinessPermitUrl',
    );
    reasonController.text = stringValue(
      previous,
      'reason',
    );
  }

  @override
  void dispose() {
    storeNameController.dispose();
    storeAddressController.dispose();
    permitNumberController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> loadPrivateApplication() async {
    try {
      final application =
          await profileService.loadPrivateSupplierApplication(
        widget.uid,
      );

      if (!mounted) {
        return;
      }

      currentPermitNumber = stringValue(
        application,
        'businessPermitNumber',
      );
      currentPermitUrl = stringValue(
        application,
        'businessPermitUrl',
      );

      final previousPermit = stringValue(
        widget.previousRequestData,
        'requestedBusinessPermitNumber',
      );

      permitNumberController.text = previousPermit.isNotEmpty
          ? previousPermit
          : currentPermitNumber;
    } catch (_) {
      showMessage(
        'Could not load the private verification record.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingPrivateData = false;
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFD94A45)
              : const Color(0xFF147A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<ImageSource?> chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBED0DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose Photo Source',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          ImageSource.camera,
                        ),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                        ),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          ImageSource.gallery,
                        ),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                        ),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickAndUploadPhoto({
    required bool permit,
  }) async {
    if (submitting || uploadBusy) {
      return;
    }

    final source = await chooseImageSource();

    if (source == null) {
      return;
    }

    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (permit) {
          uploadingPermitPhoto = true;
        } else {
          uploadingStorePhoto = true;
        }
      });

      final folder = permit
          ? 'isdalink/supplier_verification/${widget.uid}/change_requests/permits'
          : 'isdalink/supplier_verification/${widget.uid}/change_requests/stores';

      final url = await uploadService.uploadImage(
        image,
        folder: folder,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (permit) {
          requestedPermitPhotoUrl = url;
        } else {
          requestedStorePhotoUrl = url;
        }
      });

      showMessage(
        permit
            ? 'Permit evidence uploaded.'
            : 'Current store photo uploaded.',
      );
    } catch (_) {
      showMessage(
        'The verification photo could not be uploaded. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (permit) {
            uploadingPermitPhoto = false;
          } else {
            uploadingStorePhoto = false;
          }
        });
      }
    }
  }

  Future<void> chooseBusinessPin() async {
    if (selectedProvince.isEmpty ||
        selectedLocality.isEmpty) {
      showMessage(
        'Choose the province and city/municipality first.',
        isError: true,
      );
      return;
    }

    final result = await Navigator.push<CaragaLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CaragaLocationPickerScreen(
          title: 'Requested Business Location',
          subtitle: '$selectedLocality, $selectedProvince',
          initialLatitude: selectedLatitude,
          initialLongitude: selectedLongitude,
          province: selectedProvince,
          locality: selectedLocality,
          instructionText:
              'Place the pin at the requested supplier business location. '
              'Your current approved location stays public until Admin approves this request.',
          markerTitle: 'Requested store location',
          confirmButtonLabel: 'Use Requested Location',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      selectedLatitude = result.latitude;
      selectedLongitude = result.longitude;
    });
  }

  bool sameCoordinate(
    double? left,
    double? right,
  ) {
    if (left == null || right == null) {
      return left == right;
    }

    return (left - right).abs() < 0.000001;
  }

  String get requestedLocation {
    return <String>[
      storeAddressController.text.trim(),
      selectedLocality,
      selectedProvince,
      'Caraga Region',
    ].where((value) => value.isNotEmpty).join(', ');
  }

  bool locationActuallyChanged() {
    return selectedProvince != currentProvince ||
        selectedLocality != currentLocality ||
        storeAddressController.text.trim() != currentAddress ||
        !sameCoordinate(
          selectedLatitude,
          currentLatitude,
        ) ||
        !sameCoordinate(
          selectedLongitude,
          currentLongitude,
        );
  }

  List<String> submissionChangedFields() {
    final changes = <String>[];

    if (selectedChanges.contains(
          _VerifiedChangeType.storeName,
        ) &&
        storeNameController.text.trim() != currentStoreName) {
      changes.add('Store name');
    }

    if (selectedChanges.contains(
          _VerifiedChangeType.businessLocation,
        ) &&
        locationActuallyChanged()) {
      changes.add('Business location');
    }

    if (requestedStorePhotoUrl.isNotEmpty &&
        requestedStorePhotoUrl != currentStorePhotoUrl) {
      changes.add('Store photo');
    }

    final permitChanged =
        permitNumberController.text.trim() != currentPermitNumber ||
            (requestedPermitPhotoUrl.isNotEmpty &&
                requestedPermitPhotoUrl != currentPermitUrl);

    if (needsPermitEvidence && permitChanged) {
      changes.add('Business permit');
    }

    return changes;
  }

  bool validateSelectionStep() {
    if (selectedChanges.isEmpty) {
      showMessage(
        'Choose at least one verified business detail to change.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateDetailsStep() {
    FocusScope.of(context).unfocus();

    if (selectedChanges.contains(
      _VerifiedChangeType.storeName,
    )) {
      final name = storeNameController.text.trim();

      if (name.length < 2 || name.length > 100) {
        showMessage(
          'Enter a valid store or business name.',
          isError: true,
        );
        return false;
      }

      if (name == currentStoreName) {
        showMessage(
          'The requested store name is the same as the approved name.',
          isError: true,
        );
        return false;
      }
    }

    if (selectedChanges.contains(
      _VerifiedChangeType.businessLocation,
    )) {
      if (!SupplierCaragaLocations.isValidSelection(
        province: selectedProvince,
        locality: selectedLocality,
      )) {
        showMessage(
          'Choose a valid Caraga province and city/municipality.',
          isError: true,
        );
        return false;
      }

      final address = storeAddressController.text.trim();

      if (address.length < 5 || address.length > 160) {
        showMessage(
          'Enter the complete requested store address.',
          isError: true,
        );
        return false;
      }

      if (selectedLatitude == null ||
          selectedLongitude == null) {
        showMessage(
          'Choose the requested business map pin.',
          isError: true,
        );
        return false;
      }

      if (!locationActuallyChanged()) {
        showMessage(
          'The requested business location is the same as the approved location.',
          isError: true,
        );
        return false;
      }
    }

    if (needsStorePhotoEvidence &&
        requestedStorePhotoUrl.isEmpty) {
      showMessage(
        'Upload a current store photo for Admin verification.',
        isError: true,
      );
      return false;
    }

    if (selectedChanges.contains(
          _VerifiedChangeType.storePhoto,
        ) &&
        requestedStorePhotoUrl == currentStorePhotoUrl) {
      showMessage(
        'Upload a new store photo before continuing.',
        isError: true,
      );
      return false;
    }

    if (needsPermitEvidence) {
      final permitNumber =
          permitNumberController.text.trim();

      if (permitNumber.length < 3 ||
          permitNumber.length > 80) {
        showMessage(
          'Enter a valid business permit number.',
          isError: true,
        );
        return false;
      }

      if (requestedPermitPhotoUrl.isEmpty) {
        showMessage(
          selectedChanges.contains(
            _VerifiedChangeType.storeName,
          )
              ? 'Upload current permit evidence for the requested business-name change.'
              : 'Upload the updated business permit photo.',
          isError: true,
        );
        return false;
      }

      if (selectedChanges.contains(
            _VerifiedChangeType.businessPermit,
          ) &&
          permitNumber == currentPermitNumber &&
          requestedPermitPhotoUrl == currentPermitUrl) {
        showMessage(
          'Change the permit information or upload updated permit evidence.',
          isError: true,
        );
        return false;
      }
    }

    final reason = reasonController.text.trim();

    if (reason.length < 8 || reason.length > 240) {
      showMessage(
        'Add a short reason for the request using 8 to 240 characters.',
        isError: true,
      );
      return false;
    }

    if (submissionChangedFields().isEmpty) {
      showMessage(
        'No verified changes were detected.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  void nextStep() {
    if (step == 0) {
      if (!validateSelectionStep()) {
        return;
      }

      setState(() {
        step = 1;
      });
      return;
    }

    if (step == 1) {
      if (!validateDetailsStep()) {
        return;
      }

      setState(() {
        step = 2;
      });
    }
  }

  void previousStep() {
    if (step == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      step -= 1;
    });
  }

  Future<void> submitRequest() async {
    if (submitting || uploadBusy) {
      return;
    }

    if (!validateDetailsStep()) {
      setState(() {
        step = 1;
      });
      return;
    }

    final fields = submissionChangedFields();

    final permitUrl = requestedPermitPhotoUrl.isNotEmpty
        ? requestedPermitPhotoUrl
        : currentPermitUrl;

    final storePhotoUrl = requestedStorePhotoUrl.isNotEmpty
        ? requestedStorePhotoUrl
        : currentStorePhotoUrl;

    if (permitUrl.isEmpty || storePhotoUrl.isEmpty) {
      showMessage(
        'Verification evidence is incomplete.',
        isError: true,
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      await profileService.submitVerifiedChangeRequest(
        uid: widget.uid,
        supplierName: currentStoreName,
        requestedStoreName:
            storeNameController.text.trim(),
        requestedStoreProvince: selectedProvince,
        requestedStoreCityMunicipality:
            selectedLocality,
        requestedStoreAddress:
            storeAddressController.text.trim(),
        requestedStoreLatitude:
            selectedLatitude ?? currentLatitude!,
        requestedStoreLongitude:
            selectedLongitude ?? currentLongitude!,
        requestedBusinessPermitNumber:
            permitNumberController.text.trim(),
        requestedBusinessPermitUrl: permitUrl,
        requestedStorePhotoUrl: storePhotoUrl,
        changedFields: fields,
        reason: reasonController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'Verified change request submitted for Admin review.',
      );
      Navigator.pop(context);
    } catch (_) {
      showMessage(
        'Could not submit the request. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  String changeTitle(_VerifiedChangeType type) {
    switch (type) {
      case _VerifiedChangeType.storeName:
        return 'Business / Store Name';
      case _VerifiedChangeType.businessLocation:
        return 'Business Location';
      case _VerifiedChangeType.storePhoto:
        return 'Store Photo';
      case _VerifiedChangeType.businessPermit:
        return 'Business Permit';
    }
  }

  String changeSubtitle(_VerifiedChangeType type) {
    switch (type) {
      case _VerifiedChangeType.storeName:
        return 'Change the verified name vendors see';
      case _VerifiedChangeType.businessLocation:
        return 'Move the approved address and map pin';
      case _VerifiedChangeType.storePhoto:
        return 'Replace the approved main store image';
      case _VerifiedChangeType.businessPermit:
        return 'Update permit number or permit evidence';
    }
  }

  IconData changeIcon(_VerifiedChangeType type) {
    switch (type) {
      case _VerifiedChangeType.storeName:
        return Icons.storefront_outlined;
      case _VerifiedChangeType.businessLocation:
        return Icons.location_on_outlined;
      case _VerifiedChangeType.storePhoto:
        return Icons.photo_camera_back_outlined;
      case _VerifiedChangeType.businessPermit:
        return Icons.description_outlined;
    }
  }

  String currentValue(_VerifiedChangeType type) {
    switch (type) {
      case _VerifiedChangeType.storeName:
        return currentStoreName;
      case _VerifiedChangeType.businessLocation:
        return currentLocation;
      case _VerifiedChangeType.storePhoto:
        return 'Current approved store image';
      case _VerifiedChangeType.businessPermit:
        return currentPermitNumber.isEmpty
            ? 'Permit on file'
            : currentPermitNumber;
    }
  }

  Widget selectionStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24,
      ),
      children: [
        _ApprovedStoreHero(
          storeName: currentStoreName,
          location: currentLocation,
          imageUrl: currentStorePhotoUrl,
        ),
        const SizedBox(height: 14),
        const _SectionIntro(
          number: '1',
          title: 'What needs to change?',
          subtitle:
              'Select only the verified information you actually need to update.',
        ),
        const SizedBox(height: 10),
        ..._VerifiedChangeType.values.map(
          (type) {
            final selected =
                selectedChanges.contains(type);

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: _ChangeSelectionCard(
                icon: changeIcon(type),
                title: changeTitle(type),
                subtitle: changeSubtitle(type),
                currentValue: currentValue(type),
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      selectedChanges.remove(type);
                    } else {
                      selectedChanges.add(type);
                    }
                  });
                },
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        const _SecurityInfoCard(
          text:
              'Your current approved profile stays visible to vendors until Admin approves the request.',
        ),
      ],
    );
  }

  Widget detailsStep() {
    final localities =
        SupplierCaragaLocations.localitiesFor(
      selectedProvince,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24,
      ),
      children: [
        _SelectedChangesSummary(
          labels: selectedChanges
              .map(changeTitle)
              .toList(),
        ),
        if (selectedChanges.contains(
          _VerifiedChangeType.storeName,
        )) ...[
          const SizedBox(height: 12),
          _FinalFormCard(
            number: '1',
            title: 'Business Identity',
            subtitle:
                'Enter the requested verified store name.',
            icon: Icons.storefront_outlined,
            child: TextField(
              controller: storeNameController,
              decoration: _inputDecoration(
                label: 'Requested store / business name',
                icon: Icons.storefront_outlined,
              ),
            ),
          ),
        ],
        if (selectedChanges.contains(
          _VerifiedChangeType.businessLocation,
        )) ...[
          const SizedBox(height: 12),
          _FinalFormCard(
            number: '2',
            title: 'Business Location',
            subtitle:
                'Update the address and map reference vendors will see after approval.',
            icon: Icons.location_on_outlined,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'province-$selectedProvince',
                  ),
                  initialValue:
                      selectedProvince.isEmpty
                          ? null
                          : selectedProvince,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Province',
                    icon: Icons.public_outlined,
                  ),
                  items: SupplierCaragaLocations
                      .provinces
                      .map(
                        (province) =>
                            DropdownMenuItem<String>(
                          value: province,
                          child: Text(province),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) {
                          setState(() {
                            selectedProvince =
                                value ?? '';
                            selectedLocality = '';
                            selectedLatitude = null;
                            selectedLongitude = null;
                          });
                        },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'locality-$selectedProvince-$selectedLocality',
                  ),
                  initialValue:
                      selectedLocality.isEmpty
                          ? null
                          : selectedLocality,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'City / Municipality',
                    icon: Icons.map_outlined,
                  ),
                  items: localities
                      .map(
                        (locality) =>
                            DropdownMenuItem<String>(
                          value: locality,
                          child: Text(locality),
                        ),
                      )
                      .toList(),
                  onChanged:
                      submitting ||
                              selectedProvince.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                selectedLocality =
                                    value ?? '';
                                selectedLatitude = null;
                                selectedLongitude = null;
                              });
                            },
                ),
                const SizedBox(height: 11),
                TextField(
                  controller: storeAddressController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    label: 'Store address / barangay',
                    icon: Icons.place_outlined,
                  ),
                ),
                const SizedBox(height: 11),
                _MapPinCard(
                  hasPin:
                      selectedLatitude != null &&
                          selectedLongitude != null,
                  onTap: submitting
                      ? null
                      : chooseBusinessPin,
                ),
              ],
            ),
          ),
        ],
        if (needsStorePhotoEvidence ||
            needsPermitEvidence) ...[
          const SizedBox(height: 12),
          _FinalFormCard(
            number: '3',
            title: 'Verification Evidence',
            subtitle:
                'Upload only the evidence needed for the selected protected changes.',
            icon: Icons.photo_library_outlined,
            child: Column(
              children: [
                if (needsStorePhotoEvidence)
                  _UploadEvidenceCard(
                    title: 'Current Store Photo',
                    subtitle: requestedStorePhotoUrl.isEmpty
                        ? 'Required. After approval, this becomes the main supplier/store profile image.'
                        : 'Ready for Admin review. Approval will make this the main supplier/store image.',
                    imageUrl: requestedStorePhotoUrl,
                    busy: uploadingStorePhoto,
                    requiredBadge: true,
                    onTap: submitting
                        ? null
                        : () => pickAndUploadPhoto(
                              permit: false,
                            ),
                  ),
                if (needsStorePhotoEvidence &&
                    needsPermitEvidence)
                  const SizedBox(height: 10),
                if (needsPermitEvidence) ...[
                  TextField(
                    controller: permitNumberController,
                    decoration: _inputDecoration(
                      label: 'Business permit number',
                      icon:
                          Icons.confirmation_number_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _UploadEvidenceCard(
                    title: 'Permit Evidence',
                    subtitle:
                        requestedPermitPhotoUrl.isEmpty
                            ? 'Required for the selected business identity / permit change.'
                            : 'Updated permit evidence ready for review.',
                    imageUrl: requestedPermitPhotoUrl,
                    busy: uploadingPermitPhoto,
                    requiredBadge: true,
                    onTap: submitting
                        ? null
                        : () => pickAndUploadPhoto(
                              permit: true,
                            ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _FinalFormCard(
          number: '4',
          title: 'Reason for Change',
          subtitle:
              'Tell Admin why this verified information needs to be updated.',
          icon: Icons.chat_bubble_outline_rounded,
          child: TextField(
            controller: reasonController,
            minLines: 3,
            maxLines: 5,
            maxLength: 240,
            decoration: _inputDecoration(
              label: 'Reason for request',
              icon: Icons.edit_note_rounded,
              hint:
                  'Example: We transferred to a new market stall.',
            ),
          ),
        ),
      ],
    );
  }

  Widget reviewStep() {
    final changes = submissionChangedFields();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24,
      ),
      children: [
        const _ReviewReadyHero(),
        const SizedBox(height: 12),
        _FinalFormCard(
          number: '1',
          title: 'Requested Changes',
          subtitle:
              'Review each change before sending it to Admin.',
          icon: Icons.fact_check_outlined,
          child: Column(
            children: [
              if (changes.contains('Store name'))
                _CurrentRequestedRow(
                  label: 'Store / business name',
                  currentValue: currentStoreName,
                  requestedValue:
                      storeNameController.text.trim(),
                ),
              if (changes.contains(
                'Business location',
              ))
                _CurrentRequestedRow(
                  label: 'Business location',
                  currentValue: currentLocation,
                  requestedValue: requestedLocation,
                ),
              if (changes.contains(
                'Business permit',
              ))
                _CurrentRequestedRow(
                  label: 'Business permit',
                  currentValue:
                      currentPermitNumber.isEmpty
                          ? 'Current permit on file'
                          : currentPermitNumber,
                  requestedValue:
                      permitNumberController.text.trim(),
                ),
            ],
          ),
        ),
        if (changes.contains('Store photo')) ...[
          const SizedBox(height: 12),
          _FinalFormCard(
            number: '2',
            title: 'Store Photo',
            subtitle:
                'The requested photo becomes the main supplier/store image only after approval.',
            icon: Icons.photo_camera_back_outlined,
            child: _ImageCompareRow(
              currentUrl: currentStorePhotoUrl,
              requestedUrl: requestedStorePhotoUrl,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _FinalFormCard(
          number: '3',
          title: 'Reason',
          subtitle:
              'This explanation will be visible to the reviewing administrator.',
          icon: Icons.chat_bubble_outline_rounded,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE1EAF1),
              ),
            ),
            child: Text(
              reasonController.text.trim(),
              style: const TextStyle(
                color: Color(0xFF435D71),
                fontSize: 10.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SecurityInfoCard(
          text:
              'Submitting does not change your public profile. Your current approved details stay live until Admin approves this request. Rejection leaves the approved profile unchanged.',
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FBFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCE7EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCE7EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _RequestTopBar(
              onBack: previousStep,
            ),
            _RequestProgress(
              currentStep: step,
            ),
            Expanded(
              child: loadingPrivateData
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : switch (step) {
                      0 => selectionStep(),
                      1 => detailsStep(),
                      _ => reviewStep(),
                    },
            ),
            _BottomActionBar(
              step: step,
              busy: submitting || uploadBusy,
              canContinue: selectedChanges.isNotEmpty,
              onBack: step == 0 ? null : previousStep,
              onContinue:
                  step == 2 ? submitRequest : nextStep,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTopBar extends StatelessWidget {
  const _RequestTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        9,
        14,
        10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2EBF2),
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF146BFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Verified Change',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Protected business changes require Admin approval',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3DC),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 12,
                  color: Color(0xFFA76F15),
                ),
                SizedBox(width: 4),
                Text(
                  'Admin review',
                  style: TextStyle(
                    color: Color(0xFFA76F15),
                    fontSize: 7.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestProgress extends StatelessWidget {
  const _RequestProgress({
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'Changes',
      'Details',
      'Review',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        11,
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (index) {
            final active = index <= currentStep;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (index > 0)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index <= currentStep
                                      ? const Color(0xFF146BFF)
                                      : const Color(0xFFE1EAF1),
                                ),
                              ),
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF146BFF)
                                    : const Color(0xFFEAF0F5),
                                shape: BoxShape.circle,
                              ),
                              child: active && index < currentStep
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFF8295A5),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                            if (index < labels.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index < currentStep
                                      ? const Color(0xFF146BFF)
                                      : const Color(0xFFE1EAF1),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: index == currentStep
                                ? const Color(0xFF146BFF)
                                : const Color(0xFF7B8FA3),
                            fontSize: 7.8,
                            fontWeight: index == currentStep
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApprovedStoreHero extends StatelessWidget {
  const _ApprovedStoreHero({
    required this.storeName,
    required this.location,
    required this.imageUrl,
  });

  final String storeName;
  final String location;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C446F),
            Color(0xFF0B75BC),
            Color(0xFF146BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20102C44),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 62,
              height: 62,
              color: Colors.white.withValues(
                alpha: 0.13,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 29,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 29,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'CURRENT APPROVED STORE',
                      style: TextStyle(
                        color: Color(0xFFD4EEFF),
                        fontSize: 7.6,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFBDF1D4),
                      size: 13,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFFE7F5FB),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE7F5FB),
                          fontSize: 8.7,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 29,
          height: 29,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF146BFF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 9,
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
}

class _ChangeSelectionCard extends StatelessWidget {
  const _ChangeSelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String currentValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFF2F8FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9CC6FF)
                  : const Color(0xFFE0E9F1),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF146BFF)
                      : const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF146BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF17354D),
                        fontSize: 11.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      currentValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4F687B),
                        fontSize: 8.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF146BFF)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF146BFF)
                        : const Color(0xFFB9C8D4),
                    width: 1.3,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedChangesSummary extends StatelessWidget {
  const _SelectedChangesSummary({
    required this.labels,
  });

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCFE3FF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: Color(0xFF146BFF),
                size: 17,
              ),
              SizedBox(width: 7),
              Text(
                'Selected verified changes',
                style: TextStyle(
                  color: Color(0xFF17354D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: labels
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(99),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF146BFF),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FinalFormCard extends StatelessWidget {
  const _FinalFormCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDDE8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B102C44),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF146BFF),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. $title',
                      style: const TextStyle(
                        color: Color(0xFF17354D),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.7,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MapPinCard extends StatelessWidget {
  const _MapPinCard({
    required this.hasPin,
    required this.onTap,
  });

  final bool hasPin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasPin
          ? const Color(0xFFF0FBF7)
          : const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasPin
                  ? const Color(0xFFBDE8D7)
                  : const Color(0xFFDDE7EE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasPin
                      ? const Color(0xFFDFF5EC)
                      : const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasPin
                      ? Icons.check_circle_rounded
                      : Icons.add_location_alt_rounded,
                  color: hasPin
                      ? const Color(0xFF16845C)
                      : const Color(0xFF146BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPin
                          ? 'Requested map pin selected'
                          : 'Choose requested map pin',
                      style: const TextStyle(
                        color: Color(0xFF17354D),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPin
                          ? 'Tap to review or reposition the requested location.'
                          : 'Open the Caraga map and place the new store reference.',
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8DA2B2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadEvidenceCard extends StatelessWidget {
  const _UploadEvidenceCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.busy,
    required this.requiredBadge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final bool busy;
  final bool requiredBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = imageUrl.isNotEmpty;

    return Material(
      color: const Color(0xFFF8FBFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ready
                  ? const Color(0xFFBFE7D8)
                  : const Color(0xFFDDE7EE),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 50,
                  height: 50,
                  color: ready
                      ? const Color(0xFFE8F8F2)
                      : const Color(0xFFEAF5FF),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : ready
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons.image_outlined,
                                  color:
                                      Color(0xFF146BFF),
                                );
                              },
                            )
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFF146BFF),
                            ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF17354D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (requiredBadge) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFFEEE8),
                              borderRadius:
                                  BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                color:
                                    Color(0xFFD2603D),
                                fontSize: 6.8,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ready
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: ready
                    ? const Color(0xFF16845C)
                    : const Color(0xFF8DA2B2),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewReadyHero extends StatelessWidget {
  const _ReviewReadyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D6853),
            Color(0xFF139B78),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.fact_check_rounded,
            color: Colors.white,
            size: 28,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Review before submitting',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Confirm that every requested value and uploaded evidence is correct.',
                  style: TextStyle(
                    color: Color(0xFFE2F7EF),
                    fontSize: 8.8,
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
}

class _CurrentRequestedRow extends StatelessWidget {
  const _CurrentRequestedRow({
    required this.label,
    required this.currentValue,
    required this.requestedValue,
  });

  final String label;
  final String currentValue;
  final String requestedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718698),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReviewValue(
                  label: 'CURRENT',
                  value: currentValue,
                  requested: false,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 16,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF9AACBA),
                  size: 15,
                ),
              ),
              Expanded(
                child: _ReviewValue(
                  label: 'REQUESTED',
                  value: requestedValue,
                  requested: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewValue extends StatelessWidget {
  const _ReviewValue({
    required this.label,
    required this.value,
    required this.requested,
  });

  final String label;
  final String value;
  final bool requested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: requested
                ? const Color(0xFF146BFF)
                : const Color(0xFF7B8FA3),
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF17354D),
            fontSize: 9.5,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ImageCompareRow extends StatelessWidget {
  const _ImageCompareRow({
    required this.currentUrl,
    required this.requestedUrl,
  });

  final String currentUrl;
  final String requestedUrl;

  Widget imageBox(
    String label,
    String url, {
    required bool requested,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: requested
                  ? const Color(0xFF146BFF)
                  : const Color(0xFF7B8FA3),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 105,
              width: double.infinity,
              color: const Color(0xFFEAF2F7),
              child: url.isEmpty
                  ? const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF8DA2B2),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF8DA2B2),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        imageBox(
          'CURRENT',
          currentUrl,
          requested: false,
        ),
        const SizedBox(width: 9),
        imageBox(
          'REQUESTED',
          requestedUrl,
          requested: true,
        ),
      ],
    );
  }
}

class _SecurityInfoCard extends StatelessWidget {
  const _SecurityInfoCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF0E0B5),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF9B721F),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF745A25),
                fontSize: 9.1,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.step,
    required this.busy,
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
  });

  final int step;
  final bool busy;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final finalStep = step == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE1EAF1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: busy ? null : onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF526B7E),
                  side: const BorderSide(
                    color: Color(0xFFD4E0E8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: busy ||
                        (!canContinue && step == 0)
                    ? null
                    : onContinue,
                icon: busy && finalStep
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        finalStep
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: Text(
                  finalStep
                      ? busy
                          ? 'Submitting...'
                          : 'Submit for Admin Review'
                      : 'Continue',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF146BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
