import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';

class VendorDeliveryMapCard extends StatelessWidget {
  const VendorDeliveryMapCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.locality,
    required this.onTap,
    this.height = 142,
  });

  final double? latitude;
  final double? longitude;
  final String province;
  final String locality;
  final VoidCallback onTap;
  final double height;

  bool get hasPin {
    final latitudeValue = latitude;
    final longitudeValue = longitude;

    if (latitudeValue == null || longitudeValue == null) {
      return false;
    }

    return CaragaMapDefaults.containsForSelection(
      LatLng(latitudeValue, longitudeValue),
      province: province,
      locality: locality,
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = CaragaMapDefaults.targetFor(
      latitude: latitude,
      longitude: longitude,
      province: province,
      locality: locality,
    );

    return Semantics(
      button: true,
      label: hasPin
          ? 'Update saved delivery location'
          : 'Set delivery location on map',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasPin
                    ? const Color(0xFF62CFAE)
                    : const Color(0xFFB8DFFF),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: GoogleMap(
                      key: ValueKey(
                        'vendor-delivery-$latitude-$longitude-$province-$locality',
                      ),
                      initialCameraPosition: CameraPosition(
                        target: position,
                        zoom: CaragaMapDefaults.zoomFor(
                          hasSavedPin: hasPin,
                          province: province,
                          locality: locality,
                        ),
                      ),
                      markers: hasPin
                          ? {
                              Marker(
                                markerId: const MarkerId(
                                  'vendor_delivery_location',
                                ),
                                position: position,
                              ),
                            }
                          : const <Marker>{},
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      rotateGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      trafficEnabled: false,
                      indoorViewEnabled: false,
                      buildingsEnabled: true,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F00152A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasPin
                                  ? Icons.edit_location_alt_outlined
                                  : Icons.add_location_alt_outlined,
                              color: const Color(0xFF0875D1),
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hasPin ? 'Update' : 'Set pin',
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 9,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xEFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasPin
                                  ? Icons.location_on_rounded
                                  : Icons.map_outlined,
                              color: hasPin
                                  ? const Color(0xFF147D64)
                                  : const Color(0xFF0875D1),
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                hasPin
                                    ? 'Saved delivery location'
                                    : 'Tap to place your delivery pin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF31536D),
                                  fontSize: 9.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_full_rounded,
                              color: Color(0xFF657C8E),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
