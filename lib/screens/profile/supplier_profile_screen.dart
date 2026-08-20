import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupplierProfileScreen extends StatelessWidget {
  const SupplierProfileScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String stringValue(
    Map<String, dynamic>? data,
    String key, [
    String fallback = '',
  ]) {
    final value = data?[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  List<String> supportedUnits(
    Map<String, dynamic>? data,
  ) {
    final raw = data?['supportedUnits'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map(
          (value) => value.toString().trim(),
        )
        .where(
          (value) => value.isNotEmpty,
        )
        .toList();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(
          0xFFF4F8FB,
        ),
        body: Center(
          child: Text(
            'No signed-in account.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: SafeArea(
        child: StreamBuilder<
          DocumentSnapshot<
            Map<
              String,
              dynamic
            >
          >
        >(
          stream: FirebaseFirestore.instance
              .collection(
                'supplierProfiles',
              )
              .doc(
                user.uid,
              )
              .snapshots(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const _SupplierProfileLoading();
            }

            final data = snapshot.data?.data();

            if (data == null) {
              return _SupplierProfileUnavailable(
                onBack: () => Navigator.pop(
                  context,
                ),
              );
            }

            final status = stringValue(
              data,
              'status',
              'approved',
            ).toLowerCase();

            final isApproved =
                status == 'approved' ||
                status == 'active';

            if (!isApproved) {
              return _SupplierProfileUnavailable(
                onBack: () => Navigator.pop(
                  context,
                ),
              );
            }

            final storeName = stringValue(
              data,
              'storeName',
              stringValue(
                data,
                'businessName',
                'Fish Supplier',
              ),
            );

            final ownerName = stringValue(
              data,
              'ownerName',
              user.displayName ??
                  'Supplier owner',
            );

            final contactNumber = stringValue(
              data,
              'contactNumber',
              stringValue(
                data,
                'phone',
                'Not provided',
              ),
            );

            final location = stringValue(
              data,
              'storeLocation',
              stringValue(
                data,
                'location',
                'Location not available',
              ),
            );

            final province = stringValue(
              data,
              'storeProvince',
            );

            final city = stringValue(
              data,
              'storeCityMunicipality',
            );

            final primaryMarketArea =
                stringValue(
              data,
              'primaryMarketArea',
              stringValue(
                data,
                'serviceArea',
                'Not specified',
              ),
            );

            final description = stringValue(
              data,
              'description',
              'No store description added yet.',
            );

            final profileImageUrl =
                stringValue(
              data,
              'profileImageUrl',
              stringValue(
                data,
                'storePhotoUrl',
              ),
            );

            final units = supportedUnits(
              data,
            );

            return Column(
              children: [
                _SupplierProfileTopBar(
                  onBack: () => Navigator.pop(
                    context,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      28,
                    ),
                    children: [
                      _SupplierIdentityCard(
                        storeName: storeName,
                        location: location,
                        imageUrl:
                            profileImageUrl,
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _ProfileSectionCard(
                        title:
                            'Business Information',
                        subtitle:
                            'Approved supplier details',
                        icon: Icons
                            .storefront_rounded,
                        children: [
                          _ProfileInfoRow(
                            icon: Icons
                                .person_outline_rounded,
                            label: 'Owner',
                            value: ownerName,
                          ),
                          _ProfileInfoRow(
                            icon: Icons
                                .phone_outlined,
                            label:
                                'Contact number',
                            value:
                                contactNumber,
                          ),
                          const _ProfileInfoRow(
                            icon: Icons
                                .payments_outlined,
                            label:
                                'Payment method',
                            value: 'COD',
                          ),
                          _ProfileInfoRow(
                            icon: Icons
                                .inventory_2_outlined,
                            label:
                                'Selling units',
                            value: units.isEmpty
                                ? 'Not specified'
                                : units.join(
                                    ', ',
                                  ),
                            showDivider:
                                false,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _ProfileSectionCard(
                        title:
                            'Business Location',
                        subtitle:
                            'Current approved store area',
                        icon: Icons
                            .location_on_rounded,
                        children: [
                          _ProfileInfoRow(
                            icon: Icons
                                .place_outlined,
                            label:
                                'Store location',
                            value: location,
                          ),
                          _ProfileInfoRow(
                            icon: Icons
                                .map_outlined,
                            label:
                                'City / Municipality',
                            value: city.isEmpty
                                ? 'Not specified'
                                : city,
                          ),
                          _ProfileInfoRow(
                            icon: Icons
                                .public_outlined,
                            label: 'Province',
                            value:
                                province.isEmpty
                                    ? 'Not specified'
                                    : province,
                          ),
                          _ProfileInfoRow(
                            icon: Icons
                                .groups_2_outlined,
                            label:
                                'Primary market area',
                            value:
                                primaryMarketArea,
                            showDivider:
                                false,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      _ProfileSectionCard(
                        title: 'Store Profile',
                        subtitle:
                            'How your store is presented',
                        icon: Icons
                            .description_outlined,
                        children: [
                          _ProfileDescription(
                            text: description,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      const _VerifiedInfoCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupplierProfileTopBar
    extends StatelessWidget {
  const _SupplierProfileTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
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
            color: Color(
              0xFFE2EBF2,
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
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: onBack,
              borderRadius:
                  BorderRadius.circular(
                14,
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
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Profile',
                  style: TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Your approved business information',
                  style: TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 9.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFE9F8F2,
              ),
              borderRadius:
                  BorderRadius.circular(
                99,
              ),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(
                    0xFF1C9B6C,
                  ),
                  size: 13,
                ),
                SizedBox(
                  width: 4,
                ),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: Color(
                      0xFF147650,
                    ),
                    fontSize: 8.5,
                    fontWeight:
                        FontWeight.w900,
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

class _SupplierIdentityCard
    extends StatelessWidget {
  const _SupplierIdentityCard({
    required this.storeName,
    required this.location,
    required this.imageUrl,
  });

  final String storeName;
  final String location;
  final String imageUrl;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF0A5E9E,
            ),
            Color(
              0xFF177FD0,
            ),
            Color(
              0xFF12A6CC,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x24125C89,
            ),
            blurRadius: 20,
            offset: Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: Colors.white
                    .withValues(
                  alpha: 0.35,
                ),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons
                          .storefront_rounded,
                      color: Colors.white,
                      size: 32,
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
                          Icons
                              .storefront_rounded,
                          color:
                              Colors.white,
                          size: 32,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'FISH SUPPLIER',
                  style: TextStyle(
                    color: Color(
                      0xFFC9F4FF,
                    ),
                    fontSize: 8.5,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 1,
                      ),
                      child: Icon(
                        Icons
                            .location_on_rounded,
                        color: Color(
                          0xFFEAF7FC,
                        ),
                        size: 13,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow
                            .ellipsis,
                        style:
                            const TextStyle(
                          color: Color(
                            0xFFEAF7FC,
                          ),
                          fontSize: 9.5,
                          height: 1.25,
                          fontWeight:
                              FontWeight.w700,
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

class _ProfileSectionCard
    extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFFE0EAF1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0C102C44,
            ),
            blurRadius: 16,
            offset: Offset(
              0,
              7,
            ),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 19,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 9.2,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 11,
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow
    extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(
                  color: Color(
                    0xFFEDF2F6,
                  ),
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF0F7FC,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(
                0xFF4D7C9C,
              ),
              size: 16,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 8.6,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 11.4,
                    height: 1.3,
                    fontWeight:
                        FontWeight.w800,
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

class _ProfileDescription
    extends StatelessWidget {
  const _ProfileDescription({
    required this.text,
  });

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF5FAFD,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1ECF3,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(
            0xFF516B7E,
          ),
          fontSize: 10.8,
          height: 1.45,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}

class _VerifiedInfoCard
    extends StatelessWidget {
  const _VerifiedInfoCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFECF8F4,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(
            0xFFCDEBDF,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: Color(
              0xFF16845C,
            ),
            size: 19,
          ),
          SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              'This page shows the supplier information currently approved for your IsdaLink store profile.',
              style: TextStyle(
                color: Color(
                  0xFF3D6E5B,
                ),
                fontSize: 9.8,
                height: 1.4,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierProfileLoading
    extends StatelessWidget {
  const _SupplierProfileLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        _SupplierProfileTopBar(
          onBack: () =>
              Navigator.pop(
            context,
          ),
        ),
        const Expanded(
          child: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _SupplierProfileUnavailable
    extends StatelessWidget {
  const _SupplierProfileUnavailable({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        _SupplierProfileTopBar(
          onBack: onBack,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(
                  22,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  border: Border.all(
                    color:
                        const Color(
                      0xFFE0EAF1,
                    ),
                  ),
                ),
                child: const Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .storefront_outlined,
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      size: 36,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      'Supplier profile unavailable',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 6,
                    ),
                    Text(
                      'An approved supplier profile is required to view this page.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 10.5,
                        height: 1.4,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
