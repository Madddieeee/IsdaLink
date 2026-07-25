import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SupplierMapScreen extends StatelessWidget {
  const SupplierMapScreen({
    super.key,
    required this.supplierName,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  final String supplierName;
  final String location;
  final double latitude;
  final double longitude;

  @override
  Widget build(
    BuildContext context,
  ) {
    final supplierPosition = LatLng(
      latitude,
      longitude,
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: supplierPosition,
              zoom: 15.5,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('supplier-store-location'),
                position: supplierPosition,
                infoWindow: InfoWindow(
                  title: supplierName,
                  snippet: location,
                ),
              ),
            },
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 48,
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF102C44),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Supplier Store Location',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Color(0xFF146BFF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplierName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Color(0xFF146BFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
