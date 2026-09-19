import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/analytics/supplier_analytics_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/profile/supplier_profile_screen.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/supplier_notification_service.dart';
import 'package:isdalink/utils/stock_state.dart';
import 'package:isdalink/utils/app_error_message.dart';

class SupplierDashboardScreen
    extends
        StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  SupplierNotificationService get supplierNotificationService => const SupplierNotificationService();

  double numberValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];
    if (value
        is num) {
      return value.toDouble();
    }
    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  String stringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value =
        data[key]?.toString().trim() ??
        '';
    return value.isEmpty
        ? fallback
        : value;
  }

  int createdAtMillis(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final value = document.data()['createdAt'];
    return value
            is Timestamp
        ? value.millisecondsSinceEpoch
        : 0;
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  sortStocks(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    int priority(
      Map<
        String,
        dynamic
      >
      data,
    ) {
      if (isOutOfStock(
        data,
      )) {
        return 0;
      }
      if (isLowStock(
        data,
      )) {
        return 1;
      }
      if (isAvailable(
        data,
      )) {
        return 2;
      }
      return 3;
    }

    final result = [
      ...documents,
    ];
    result.sort(
      (
        a,
        b,
      ) {
        final priorityCompare =
            priority(
              a.data(),
            ).compareTo(
              priority(
                b.data(),
              ),
            );
        if (priorityCompare !=
            0) {
          return priorityCompare;
        }
        return createdAtMillis(
          b,
        ).compareTo(
          createdAtMillis(
            a,
          ),
        );
      },
    );
    return result;
  }

  double thresholdFor(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final saved = numberValue(
      data,
      'lowStockLevel',
    );
    if (saved >
        0) {
      return saved;
    }

    final reference =
        numberValue(
              data,
              'referenceStockQuantity',
            ) >
            0
        ? numberValue(
            data,
            'referenceStockQuantity',
          )
        : numberValue(
            data,
            'quantity',
          );
    final percentage =
        numberValue(
              data,
              'lowStockPercentage',
            ) >
            0
        ? numberValue(
            data,
            'lowStockPercentage',
          )
        : 20;
    return reference *
        percentage /
        100;
  }

  bool isHidden(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return StockState.isIntentionallyHidden(
      data,
    );
  }

  bool isOutOfStock(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return !isHidden(
          data,
        ) &&
        numberValue(
              data,
              'quantity',
            ) <=
            0;
  }

  bool isLowStock(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final quantity = numberValue(
      data,
      'quantity',
    );
    return !isHidden(
          data,
        ) &&
        quantity >
            0 &&
        quantity <=
            thresholdFor(
              data,
            );
  }

  bool isAvailable(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return !isHidden(
          data,
        ) &&
        numberValue(
              data,
              'quantity',
            ) >
            thresholdFor(
              data,
            );
  }

  String formatNumber(
    double value,
  ) {
    return value %
                1 ==
            0
        ? value.toStringAsFixed(
            0,
          )
        : value.toStringAsFixed(
            1,
          );
  }

  String formatPrice(
    double value,
  ) {
    final raw =
        value %
                1 ==
            0
        ? value.toStringAsFixed(
            0,
          )
        : value
              .toStringAsFixed(
                2,
              )
              .replaceFirst(
                RegExp(
                  r'0+$',
                ),
                '',
              )
              .replaceFirst(
                RegExp(
                  r'\.$',
                ),
                '',
              );
    final parts = raw.split(
      '.',
    );
    final whole = parts.first;
    final buffer = StringBuffer();

    for (
      var index = 0;
      index <
          whole.length;
      index++
    ) {
      if (index >
              0 &&
          (whole.length -
                      index) %
                  3 ==
              0) {
        buffer.write(
          ',',
        );
      }
      buffer.write(
        whole[index],
      );
    }

    return parts.length >
            1
        ? '${buffer.toString()}.${parts[1]}'
        : buffer.toString();
  }

  String productImageUrl(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    const keys =
        <
          String
        >[
          'imageUrl',
          'productImageUrl',
          'photoUrl',
          'fishImageUrl',
          'image',
        ];

    for (final key in keys) {
      final value =
          data[key]?.toString().trim() ??
          '';
      if (value.startsWith(
            'http://',
          ) ||
          value.startsWith(
            'https://',
          )) {
        return value;
      }
    }

    return '';
  }

  String profileImageUrl(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final value = data['profileImageUrl']?.toString().trim() ?? '';
    return value.startsWith('https://') ? value : '';
  }

  String coverImageUrl(
    Map<String, dynamic> data,
  ) {
    if (data['coverImageSetByOwner'] != true) {
      return '';
    }

    final value = data['coverImageUrl']?.toString().trim() ?? '';
    return value.startsWith('https://') ? value : '';
  }

  String supplierLocation(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final approvedStoreLocation = stringValue(
      data,
      'storeLocation',
      '',
    );

    if (approvedStoreLocation.isNotEmpty) {
      return approvedStoreLocation;
    }

    final parts =
        <
              String
            >[
              stringValue(
                data,
                'storeAddress',
                '',
              ),
              stringValue(
                data,
                'storeCityMunicipality',
                '',
              ),
              stringValue(
                data,
                'storeProvince',
                '',
              ),
              'Caraga Region',
            ]
            .where(
              (
                value,
              ) => value.trim().isNotEmpty,
            )
            .toList();

    if (parts.length >
        1) {
      return parts.join(
        ', ',
      );
    }

    return stringValue(
      data,
      'location',
      'Caraga Region',
    );
  }

  Supplier supplierFromProfile(
    Map<
      String,
      dynamic
    >
    data,
    User user,
  ) {
    final supplierName = stringValue(
      data,
      'supplierName',
      stringValue(
        data,
        'storeName',
        stringValue(
          data,
          'businessName',
          user.displayName ??
              'Registered Supplier',
        ),
      ),
    );

    return Supplier(
      name: supplierName,
      location: supplierLocation(
        data,
      ),
      contactNumber: stringValue(
        data,
        'phone',
        stringValue(
          data,
          'contactNumber',
          'No contact number',
        ),
      ),
      description: stringValue(
        data,
        'description',
        'Registered fish supplier in the IsdaLink platform.',
      ),
      rating: numberValue(
        data,
        'rating',
      ),
      reviews: numberValue(
        data,
        'reviews',
      ).round(),
      products: const [],
      profileImageUrl: profileImageUrl(
        data,
      ),
      coverImageUrl: coverImageUrl(data),
      accountCreatedAt: data['accountCreatedAt'] is Timestamp
          ? (data['accountCreatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  void openSupplierProfile(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierProfileScreen(),
      ),
    );
  }

  Future<
    void
  >
  openOwnStore(
    BuildContext context,
  ) async {
    final user = currentUser;

    if (user ==
        null) {
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            user.uid,
          )
          .get();

      if (!context.mounted) {
        return;
      }

      if (!profile.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Your supplier profile could not be found yet.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final supplier = supplierFromProfile(
        profile.data() ??
            <
              String,
              dynamic
            >{},
        user,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (
                _,
              ) => SupplierDetailsScreen(
                supplier: supplier,
                supplierId: user.uid,
                isOwnerView: true,
              ),
        ),
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMessage.from(
              error,
              fallback: 'Unable to open your supplier store right now. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget storeManagementCard(
    BuildContext context, {
    required Map<
      String,
      dynamic
    >
    profileData,
    required int unreadProfileChanges,
  }) {
    final user = currentUser;
    final storeName =
        user ==
            null
        ? 'Your Supplier Store'
        : stringValue(
            profileData,
            'supplierName',
            stringValue(
              profileData,
              'storeName',
              stringValue(
                profileData,
                'businessName',
                user.displayName ??
                    'Your Supplier Store',
              ),
            ),
          );
    final imageUrl = profileImageUrl(
      profileData,
    );
    final initial =
        storeName
            .trim()
            .isEmpty
        ? 'S'
        : storeName
              .trim()
              .substring(
                0,
                1,
              )
              .toUpperCase();

    Widget storeImage() {
      if (imageUrl.isEmpty) {
        return Container(
          color: const Color(
            0xFFEAF8FC,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(
                0xFF0875D1,
              ),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (
              _,
              _,
              _,
            ) => Container(
              color: const Color(
                0xFFEAF8FC,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(
                    0xFF0875D1,
                  ),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        12,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(
              0xFFF4FBFE,
            ),
            Color(
              0xFFF8FBFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFFD7EAF3,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0B00152A,
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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              16,
            ),
            child: SizedBox(
              width: 54,
              height: 54,
              child: storeImage(),
            ),
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'YOUR STORE',
                      style: TextStyle(
                        color: Color(
                          0xFF6F8798,
                        ),
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(
                        0xFF11A87A,
                      ),
                      size: 13,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                const Text(
                  'Public store identity and business profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(
                      0xFF71889A,
                    ),
                    fontSize: 9.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          _StoreActionButton(
            icon: Icons.storefront_outlined,
            label: 'View',
            onTap: () => openOwnStore(
              context,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          _StoreActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            showDot:
                unreadProfileChanges >
                0,
            accent:
                unreadProfileChanges >
                    0
                ? const Color(
                    0xFF11A87A,
                  )
                : const Color(
                    0xFF0875D1,
                  ),
            onTap: () => openSupplierProfile(
              context,
            ),
          ),
        ],
      ),
    );
  }

  void openPostFishStock(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const PostFishStockScreen(),
      ),
    );
  }

  void openManageProducts(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierManageProductsScreen(),
      ),
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierAnalyticsScreen(),
      ),
    );
  }

  void openOrders(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierCodOrdersScreen(),
      ),
    );
  }

  void safeBack(
    BuildContext context,
  ) {
    if (Navigator.canPop(
      context,
    )) {
      Navigator.pop(
        context,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const HomeScreen(),
      ),
    );
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  stockStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .where(
          'supplierId',
          isEqualTo: uid,
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  orderStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .where(
          'supplierId',
          isEqualTo: uid,
        )
        .snapshots();
  }

  Stream<
    DocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  supplierProfileStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .doc(
          uid,
        )
        .snapshots();
  }

  int activeOrders(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return documents.where(
      (
        document,
      ) {
        final status = stringValue(
          document.data(),
          'orderStatus',
          'pending',
        ).toLowerCase();
        return status ==
                'pending' ||
            status ==
                'accepted';
      },
    ).length;
  }

  int pendingOrders(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    return documents.where(
      (
        document,
      ) {
        return stringValue(
              document.data(),
              'orderStatus',
              'pending',
            ).toLowerCase() ==
            'pending';
      },
    ).length;
  }

  Widget header({
    required BuildContext context,
    required int activeListings,
    required int activeCod,
    required int stockAlerts,
  }) {
    final topPadding = MediaQuery.paddingOf(
      context,
    ).top;

    return AnnotatedRegion<
      SystemUiOverlayStyle
    >(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(
          0xFF06355F,
        ),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          topPadding +
              8,
          18,
          20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF06355F,
              ),
              Color(
                0xFF0875D1,
              ),
              Color(
                0xFF176CFF,
              ),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(
              30,
            ),
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -44,
              top: -38,
              child: _HeaderDecoration(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withAlpha(
                        32,
                      ),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => safeBack(
                          context,
                        ),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPPLIER CENTER',
                            style: TextStyle(
                              color: Color(
                                0xFFCCF4FF,
                              ),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.15,
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Supplier Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Manage fish stock, COD orders, and supplier analytics from one place.',
                  style: TextStyle(
                    color: Color(
                      0xFFDDEFFC,
                    ),
                    fontSize: 11.3,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      22,
                    ),
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha(
                        28,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _HeaderMetric(
                        icon: Icons.inventory_2_outlined,
                        value: '$activeListings',
                        label: 'Active Listings',
                        onTap: () => openManageProducts(
                          context,
                        ),
                      ),
                      const _HeaderDivider(),
                      _HeaderMetric(
                        icon: Icons.receipt_long_outlined,
                        value: '$activeCod',
                        label: 'Active Orders',
                        onTap: () => openOrders(
                          context,
                        ),
                      ),
                      const _HeaderDivider(),
                      _HeaderMetric(
                        icon: Icons.notifications_active_outlined,
                        value: '$stockAlerts',
                        label: 'Stock Alerts',
                        onTap: () => openManageProducts(
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget profileChangeNotificationPanel({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    notifications,
  }) {
    final unread = supplierNotificationService.unreadProfileChangeNotifications(
      notifications,
    );

    if (unread.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = unread.first.data();
    final status = stringValue(
      latest,
      'status',
      'approved',
    ).toLowerCase();
    final approved =
        status ==
        'approved';
    final color = approved
        ? const Color(
            0xFF16845C,
          )
        : const Color(
            0xFFB53A36,
          );
    final background = approved
        ? const Color(
            0xFFECF8F4,
          )
        : const Color(
            0xFFFFEEEE,
          );
    final title = stringValue(
      latest,
      'title',
      approved
          ? 'Verified profile change approved'
          : 'Verified profile change needs revision',
    );
    final message = stringValue(
      latest,
      'message',
      approved
          ? 'Your approved changes are now live.'
          : 'Open your supplier profile to review the Admin note.',
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0E00152A,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  approved
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier Profile Notification',
                      style: TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Review the result, then acknowledge it in your profile.',
                      style: TextStyle(
                        color: Color(
                          0xFF71889A,
                        ),
                        fontSize: 9.3,
                        height: 1.25,
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
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    99,
                  ),
                ),
                child: Text(
                  unread.length >
                          9
                      ? '9+ NEW'
                      : '${unread.length} NEW',
                  style: TextStyle(
                    color: color,
                    fontSize: 7.8,
                    letterSpacing: 0.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          const Divider(
            height: 1,
            color: Color(
              0xFFE1ECE7,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _AlertRow(
            icon: approved
                ? Icons.check_circle_outline_rounded
                : Icons.edit_note_rounded,
            color: color,
            title: title,
            subtitle: message,
            actionLabel: 'View Profile',
            onTap: () => openSupplierProfile(
              context,
            ),
          ),
        ],
      ),
    );
  }

  Widget stockNotificationPanel({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    notifications,
  }) {
    final unread = supplierNotificationService.unreadStockNotifications(
      notifications,
    );

    if (unread.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = unread
        .take(
          2,
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFFFFFBF4,
            ),
            Color(
              0xFFF4FAFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFFFFE2B8,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0E00152A,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFEFE1,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(
                    0xFFFF7A1A,
                  ),
                  size: 20,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Notifications',
                      style: TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'New automatic alerts from your published listings.',
                      style: TextStyle(
                        color: Color(
                          0xFF71889A,
                        ),
                        fontSize: 9.3,
                        height: 1.25,
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
                  color: const Color(
                    0xFFFFE9D5,
                  ),
                  borderRadius: BorderRadius.circular(
                    99,
                  ),
                ),
                child: Text(
                  unread.length >
                          9
                      ? '9+ NEW'
                      : '${unread.length} NEW',
                  style: const TextStyle(
                    color: Color(
                      0xFFC45C00,
                    ),
                    fontSize: 7.8,
                    letterSpacing: 0.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          const Divider(
            height: 1,
            color: Color(
              0xFFE8EEF2,
            ),
          ),
          ...visible.map(
            (
              notification,
            ) {
              final data = notification.data();
              final title = stringValue(
                data,
                'title',
                'Stock Alert',
              );
              final message = stringValue(
                data,
                'message',
                'A fish listing reached its stock alert level.',
              );
              final stockStatus = stringValue(
                data,
                'stockStatus',
                'lowStock',
              ).toLowerCase();
              final critical =
                  stockStatus ==
                  'outofstock';

              return Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ),
                child: _AlertRow(
                  icon: critical
                      ? Icons.error_outline_rounded
                      : Icons.inventory_2_outlined,
                  color: critical
                      ? const Color(
                          0xFFD94135,
                        )
                      : const Color(
                          0xFFFF7A1A,
                        ),
                  title: title,
                  subtitle: message,
                  actionLabel: 'Review Stock',
                  onTap: () => openManageProducts(
                    context,
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 8,
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => supplierNotificationService.markNotificationsRead(
                unread,
              ),
              icon: const Icon(
                Icons.done_all_rounded,
                size: 17,
              ),
              label: const Text(
                'Mark Stock Notifications as Read',
                style: TextStyle(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF0875D1,
                ),
                backgroundColor: const Color(
                  0xFFEAF7FD,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget alertPanel({
    required BuildContext context,
    required int pending,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    alerts,
  }) {
    if (pending ==
            0 &&
        alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final outCount = alerts
        .where(
          (
            doc,
          ) => isOutOfStock(
            doc.data(),
          ),
        )
        .length;
    final lowCount =
        alerts.length -
        outCount;

    String stockTitle;
    String stockSubtitle;

    if (alerts.length ==
        1) {
      final data = alerts.first.data();
      final name = stringValue(
        data,
        'productName',
        'Fish Product',
      );
      final quantity = numberValue(
        data,
        'quantity',
      );
      final threshold = thresholdFor(
        data,
      );
      final unit = stringValue(
        data,
        'quantityUnit',
        'kilo',
      );

      if (isOutOfStock(
        data,
      )) {
        stockTitle = '$name is out of stock';
        stockSubtitle = '0 $unit remaining · Restock this listing.';
      } else {
        stockTitle = '$name reached its stock alert';
        stockSubtitle = '${formatNumber(quantity)} $unit remaining · Alert level: ${formatNumber(threshold)} $unit';
      }
    } else {
      stockTitle = '${alerts.length} stock alerts';
      stockSubtitle = '$lowCount low stock · $outCount out of stock';
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1ECF2,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0E00152A,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (pending >
              0)
            _AlertRow(
              icon: Icons.notifications_active_rounded,
              color: const Color(
                0xFFD94135,
              ),
              title: '$pending pending COD order${pending == 1 ? '' : 's'}',
              subtitle: 'Review and respond to new vendor orders.',
              actionLabel: 'Review Orders',
              onTap: () => openOrders(
                context,
              ),
            ),
          if (pending >
                  0 &&
              alerts.isNotEmpty)
            const Divider(
              height: 20,
              color: Color(
                0xFFE5EDF2,
              ),
            ),
          if (alerts.isNotEmpty)
            _AlertRow(
              icon: Icons.inventory_2_outlined,
              color:
                  outCount >
                      0
                  ? const Color(
                      0xFFD94135,
                    )
                  : const Color(
                      0xFFFF7A1A,
                    ),
              title: stockTitle,
              subtitle: stockSubtitle,
              actionLabel: 'Review Stock',
              onTap: () => openManageProducts(
                context,
              ),
            ),
        ],
      ),
    );
  }

  Widget toolsGrid({
    required BuildContext context,
    required int activeCod,
    required int stockAlerts,
    required bool hasOutOfStock,
  }) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            const spacing = 11.0;
            final cardWidth =
                (constraints.maxWidth -
                    spacing) /
                2;
            final textScale =
                MediaQuery.textScalerOf(
                      context,
                    )
                    .scale(
                      1,
                    )
                    .clamp(
                      1.0,
                      2.0,
                    );
            final cardHeight =
                112 +
                ((textScale -
                        1) *
                    40);

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio:
                  cardWidth /
                  cardHeight,
              children: [
                _ToolCard(
                  icon: Icons.add_box_outlined,
                  title: 'Post Stock',
                  subtitle: 'Create a new fish listing.',
                  onTap: () => openPostFishStock(
                    context,
                  ),
                ),
                _ToolCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products',
                  subtitle: 'Manage stock and alert levels.',
                  badge: stockAlerts,
                  badgeColor: hasOutOfStock
                      ? const Color(
                          0xFFD94135,
                        )
                      : const Color(
                          0xFFFF8A24,
                        ),
                  onTap: () => openManageProducts(
                    context,
                  ),
                ),
                _ToolCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'COD Orders',
                  subtitle: 'Review incoming vendor orders.',
                  badge: activeCod,
                  badgeColor: const Color(
                    0xFFD94135,
                  ),
                  onTap: () => openOrders(
                    context,
                  ),
                ),
                _ToolCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Supplier Analytics',
                  subtitle: 'Forecasts and stock insights.',
                  onTap: () => openAnalytics(
                    context,
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget stockCard(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
    BuildContext context,
  ) {
    final data = document.data();
    final quantity = numberValue(
      data,
      'quantity',
    );
    final unit = stringValue(
      data,
      'quantityUnit',
      'kilo',
    );
    final name = stringValue(
      data,
      'productName',
      'Fish Product',
    );
    final emoji = stringValue(
      data,
      'emoji',
      '🐟',
    );
    final imageUrl = productImageUrl(
      data,
    );
    final price = numberValue(
      data,
      'price',
    );
    final hidden = isHidden(
      data,
    );
    final out = isOutOfStock(
      data,
    );
    final low = isLowStock(
      data,
    );
    final status = hidden
        ? 'Hidden'
        : out
        ? 'Out of Stock'
        : low
        ? 'Low Stock'
        : 'Available';
    final color = hidden
        ? const Color(
            0xFF71889A,
          )
        : out
        ? const Color(
            0xFFD94135,
          )
        : low
        ? const Color(
            0xFFFF7A1A,
          )
        : const Color(
            0xFF2E7D32,
          );

    Widget fallbackImage() {
      return Container(
        color: const Color(
          0xFFEAF8FC,
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize: 27,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: InkWell(
          onTap: () => openManageProducts(
            context,
          ),
          borderRadius: BorderRadius.circular(
            20,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: const Color(
                  0xFFE1ECF2,
                ),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    17,
                  ),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: imageUrl.isEmpty
                        ? fallbackImage()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  _,
                                  _,
                                  _,
                                ) => fallbackImage(),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(
                                  0xFF102C44,
                                ),
                                fontSize: 13.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(
                                18,
                              ),
                              borderRadius: BorderRadius.circular(
                                99,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 8.6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '₱${formatPrice(price)} / $unit',
                        style: const TextStyle(
                          color: Color(
                            0xFF0875D1,
                          ),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        hidden
                            ? 'Hidden from vendor marketplace'
                            : out
                            ? 'Out of stock · Restock this listing'
                            : low
                            ? 'Low stock · ${formatNumber(quantity)} $unit left'
                            : '${formatNumber(quantity)} $unit available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: out
                              ? const Color(
                                  0xFFD94135,
                                )
                              : low
                              ? const Color(
                                  0xFFC66A12,
                                )
                              : const Color(
                                  0xFF526B7F,
                                ),
                          fontSize: 9.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                IconButton(
                  tooltip: 'Manage stock',
                  onPressed: () => openManageProducts(
                    context,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(
                      0xFF0875D1,
                    ),
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dashboardBody({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    stocks,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    orders,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    notifications,
    required Map<
      String,
      dynamic
    >
    profileData,
  }) {
    final sortedStocks = sortStocks(
      stocks,
    );
    final activeListings = sortedStocks.where(
      (
        doc,
      ) {
        final data = doc.data();
        return !isHidden(
              data,
            ) &&
            numberValue(
                  data,
                  'quantity',
                ) >
                0;
      },
    ).length;
    final alerts = sortedStocks.where(
      (
        doc,
      ) {
        return isLowStock(
              doc.data(),
            ) ||
            isOutOfStock(
              doc.data(),
            );
      },
    ).toList();
    final activeCod = activeOrders(
      orders,
    );
    final pending = pendingOrders(
      orders,
    );
    final hasOutOfStock = alerts.any(
      (
        doc,
      ) => isOutOfStock(
        doc.data(),
      ),
    );
    final unreadProfileChanges = supplierNotificationService.unreadProfileChangeNotifications(
      notifications,
    );

    return Column(
      children: [
        header(
          context: context,
          activeListings: activeListings,
          activeCod: activeCod,
          stockAlerts: alerts.length,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              32,
            ),
            children: [
              profileChangeNotificationPanel(
                context: context,
                notifications: notifications,
              ),
              stockNotificationPanel(
                context: context,
                notifications: notifications,
              ),
              alertPanel(
                context: context,
                pending: pending,
                alerts: alerts,
              ),
              storeManagementCard(
                context,
                profileData: profileData,
                unreadProfileChanges: unreadProfileChanges.length,
              ),
              const _SectionHeading(
                title: 'Quick Actions',
                subtitle: 'Daily tools for managing your supplier operations.',
              ),
              const SizedBox(
                height: 8,
              ),
              toolsGrid(
                context: context,
                activeCod: activeCod,
                stockAlerts: alerts.length,
                hasOutOfStock: hasOutOfStock,
              ),
              const SizedBox(
                height: 18,
              ),
              _SectionHeading(
                title: 'Current Stock',
                subtitle: 'Live listing health, with stock alerts shown first.',
                trailing:
                    sortedStocks.length >
                        5
                    ? 'View all'
                    : '${sortedStocks.length} listing${sortedStocks.length == 1 ? '' : 's'}',
                onTrailingTap:
                    sortedStocks.length >
                        5
                    ? () => openManageProducts(
                        context,
                      )
                    : null,
              ),
              const SizedBox(
                height: 10,
              ),
              if (sortedStocks.isEmpty)
                const _EmptyStockCard()
              else
                ...sortedStocks
                    .take(
                      5,
                    )
                    .map(
                      (
                        doc,
                      ) => stockCard(
                        doc,
                        context,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingBody(
    BuildContext context,
  ) {
    return Column(
      children: [
        header(
          context: context,
          activeListings: 0,
          activeCod: 0,
          stockAlerts: 0,
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(
                0xFF0875D1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user ==
        null) {
      return const Scaffold(
        backgroundColor: Color(
          0xFFF4F8FB,
        ),
        body: Center(
          child: Text(
            'Please log in first to view the Supplier Dashboard.',
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (
            didPop,
            result,
          ) {
            if (!didPop) {
              safeBack(
                context,
              );
            }
          },
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF4F8FB,
        ),
        body:
            StreamBuilder<
              QuerySnapshot<
                Map<
                  String,
                  dynamic
                >
              >
            >(
              stream: stockStream(
                user.uid,
              ),
              builder:
                  (
                    context,
                    stockSnapshot,
                  ) {
                    if (stockSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            24,
                          ),
                          child: Text(
                            AppErrorMessage.from(
                              stockSnapshot.error!,
                              fallback: 'Unable to load your supplier dashboard right now. Please try again.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(
                                0xFF52677A,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!stockSnapshot.hasData) {
                      return loadingBody(
                        context,
                      );
                    }

                    return StreamBuilder<
                      QuerySnapshot<
                        Map<
                          String,
                          dynamic
                        >
                      >
                    >(
                      stream: orderStream(
                        user.uid,
                      ),
                      builder:
                          (
                            context,
                            orderSnapshot,
                          ) {
                            final orders =
                                orderSnapshot.data?.docs ??
                                <
                                  QueryDocumentSnapshot<
                                    Map<
                                      String,
                                      dynamic
                                    >
                                  >
                                >[];

                            return StreamBuilder<
                              QuerySnapshot<
                                Map<
                                  String,
                                  dynamic
                                >
                              >
                            >(
                              stream: supplierNotificationService.notificationsStream(
                                user.uid,
                              ),
                              builder:
                                  (
                                    context,
                                    notificationSnapshot,
                                  ) {
                                    final notifications =
                                        notificationSnapshot.data?.docs ??
                                        <
                                          QueryDocumentSnapshot<
                                            Map<
                                              String,
                                              dynamic
                                            >
                                          >
                                        >[];

                                    return StreamBuilder<
                                      DocumentSnapshot<
                                        Map<
                                          String,
                                          dynamic
                                        >
                                      >
                                    >(
                                      stream: supplierProfileStream(
                                        user.uid,
                                      ),
                                      builder:
                                          (
                                            context,
                                            profileSnapshot,
                                          ) {
                                            return dashboardBody(
                                              context: context,
                                              stocks: stockSnapshot.data!.docs,
                                              orders: orders,
                                              notifications: notifications,
                                              profileData:
                                                  profileSnapshot.data?.data() ??
                                                  <
                                                    String,
                                                    dynamic
                                                  >{},
                                            );
                                          },
                                    );
                                  },
                            );
                          },
                    );
                  },
            ),
      ),
    );
  }
}

class _StoreActionButton
    extends
        StatelessWidget {
  const _StoreActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = const Color(
      0xFF0875D1,
    ),
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final bool showDot;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: accent.withAlpha(
        14,
      ),
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: SizedBox(
          width: 45,
          height: 45,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: accent,
                      size: 17,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: accent,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDot)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(
                        0xFF11A87A,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderDecoration
    extends
        StatelessWidget {
  const _HeaderDecoration();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(
            18,
          ),
        ),
      ),
      child: Center(
        child: Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(
                18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric
    extends
        StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            14,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFFDDEFFC,
                    ),
                    fontSize: 8.7,
                    fontWeight: FontWeight.w700,
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

class _HeaderDivider
    extends
        StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 1,
      height: 43,
      color: Colors.white.withAlpha(
        28,
      ),
    );
  }
}

class _AlertRow
    extends
        StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? actionLabel;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        15,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(
                18,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(
                      0xFF71889A,
                    ),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          if (actionLabel !=
              null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withAlpha(
                  16,
                ),
                borderRadius: BorderRadius.circular(
                  99,
                ),
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: color,
                  fontSize: 8.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _ToolCard
    extends
        StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = const Color(
      0xFFFF4D3D,
    ),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  final Color badgeColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: const Color(
                0xFFE1ECF2,
              ),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEAF8FD,
                      ),
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(
                        0xFF0875D1,
                      ),
                      size: 19,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF71889A,
                      ),
                      fontSize: 8.7,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (badge >
                  0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(
                        99,
                      ),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading
    extends
        StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(
                    0xFF8194A4,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing !=
            null)
          Material(
            color: const Color(
              0xFFE8F8FD,
            ),
            borderRadius: BorderRadius.circular(
              99,
            ),
            child: InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(
                99,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailing!,
                      style: const TextStyle(
                        color: Color(
                          0xFF0875D1,
                        ),
                        fontSize: 9.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (onTrailingTap !=
                        null) ...[
                      const SizedBox(
                        width: 4,
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(
                          0xFF0875D1,
                        ),
                        size: 13,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyStockCard
    extends
        StatelessWidget {
  const _EmptyStockCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFFE1ECF2,
          ),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(
              0xFF0875D1,
            ),
            size: 30,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No stock posts yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            'Post fish stock to start receiving vendor COD orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF71889A,
              ),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
