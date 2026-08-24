import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';

class CaragaLocationResult {
  const CaragaLocationResult({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class CaragaLocationPickerScreen
    extends
        StatefulWidget {
  const CaragaLocationPickerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.initialLatitude,
    this.initialLongitude,
    this.province,
    this.locality,
    this.instructionText =
        'Tap the map where the supplier store is located. '
        'The pin is a location reference only and does not calculate routes.',
    this.markerTitle = 'Store reference point',
    this.confirmButtonLabel = 'Confirm Business Location',
    this.readOnly = false,
  });

  final String title;
  final String subtitle;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? province;
  final String? locality;
  final String instructionText;
  final String markerTitle;
  final String confirmButtonLabel;
  final bool readOnly;

  @override
  State<
    CaragaLocationPickerScreen
  >
  createState() => _CaragaLocationPickerScreenState();
}

class _CaragaLocationPickerScreenState
    extends
        State<
          CaragaLocationPickerScreen
        > {
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();

    final latitude = widget.initialLatitude;
    final longitude = widget.initialLongitude;

    if (latitude !=
            null &&
        longitude !=
            null &&
        isInsideCaragaMapArea(
          LatLng(
            latitude,
            longitude,
          ),
        )) {
      selectedLocation = LatLng(
        latitude,
        longitude,
      );
    }
  }

  bool isInsideCaragaMapArea(
    LatLng location,
  ) {
    return CaragaMapDefaults.contains(location);
  }

  LatLng initialTarget() {
    return CaragaMapDefaults.targetFor(
      latitude: selectedLocation?.latitude,
      longitude: selectedLocation?.longitude,
      province: widget.province,
      locality: widget.locality,
    );
  }

  double initialZoom() {
    return CaragaMapDefaults.zoomFor(
      hasSavedPin: selectedLocation != null,
      locality: widget.locality,
    );
  }

  void selectLocation(
    LatLng location,
  ) {
    if (widget.readOnly) {
      return;
    }

    if (!isInsideCaragaMapArea(
      location,
    )) {
      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(
              0xFFD94A45,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                15,
              ),
            ),
            content: const Text(
              'Choose a reference point inside the Caraga map area.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      return;
    }

    setState(
      () {
        selectedLocation = location;
      },
    );
  }

  void confirmLocation() {
    final location = selectedLocation;

    if (widget.readOnly) {
      Navigator.pop(
        context,
      );
      return;
    }

    if (location ==
        null) {
      return;
    }

    Navigator.pop(
      context,
      CaragaLocationResult(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final location = selectedLocation;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                16,
                11,
                16,
                13,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(
                      0xFFE1EBF2,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: const Color(
                      0xFFEAF3FF,
                    ),
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(
                            0xFF146BFF,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Color(
                              0xFF102C44,
                            ),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Color(
                              0xFF7B8FA3,
                            ),
                            fontSize: 9.5,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget(),
                      zoom: initialZoom(),
                    ),
                    cameraTargetBounds: CameraTargetBounds(
                      CaragaMapDefaults.bounds,
                    ),
                    minMaxZoomPreference: const MinMaxZoomPreference(
                      7.6,
                      19,
                    ),
                    mapType: MapType.normal,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    onTap: widget.readOnly
                        ? null
                        : selectLocation,
                    markers:
                        location ==
                            null
                        ? const <
                            Marker
                          >{}
                        : {
                            Marker(
                              markerId: const MarkerId(
                                'selected_location',
                              ),
                              position: location,
                              draggable: !widget.readOnly,
                              onDragEnd: widget.readOnly
                                  ? null
                                  : selectLocation,
                              infoWindow: InfoWindow(
                                title: widget.markerTitle,
                              ),
                            ),
                          },
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.96,
                          ),
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFDCE8F1,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(
                                0x1A00152A,
                              ),
                              blurRadius: 14,
                              offset: Offset(
                                0,
                                6,
                              ),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              color: Color(
                                0xFF146BFF,
                              ),
                              size: 20,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                widget.instructionText,
                                style: const TextStyle(
                                  color: Color(
                                    0xFF52677A,
                                  ),
                                  fontSize: 9.7,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                15,
                12,
                15,
                14,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(
                      0xFFE1EBF2,
                    ),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          location ==
                              null
                          ? const Color(
                              0xFFF4F8FB,
                            )
                          : const Color(
                              0xFFE8F8F2,
                            ),
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          location ==
                                  null
                              ? Icons.location_searching_rounded
                              : Icons.location_on_rounded,
                          color:
                              location ==
                                  null
                              ? const Color(
                                  0xFF7B8FA3,
                                )
                              : const Color(
                                  0xFF147D64,
                                ),
                          size: 19,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            location ==
                                    null
                                ? 'No location pin selected yet.'
                                : 'Selected: '
                                      '${location.latitude.toStringAsFixed(6)}, '
                                      '${location.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color:
                                  location ==
                                      null
                                  ? const Color(
                                      0xFF657C8E,
                                    )
                                  : const Color(
                                      0xFF147D64,
                                    ),
                              fontSize: 9.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: ElevatedButton.icon(
                      onPressed: widget.readOnly
                          ? confirmLocation
                          : location ==
                                null
                          ? null
                          : confirmLocation,
                      icon: Icon(
                        widget.readOnly
                            ? Icons.close_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        widget.readOnly
                            ? 'Close Map'
                            : widget.confirmButtonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF146BFF,
                        ),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFD6E1EA,
                        ),
                        disabledForegroundColor: const Color(
                          0xFF8BA0B1,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
