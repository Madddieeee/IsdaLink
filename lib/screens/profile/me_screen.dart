import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/config/cloudinary_config.dart';
import 'package:isdalink/screens/analytics/supplier_analytics_screen.dart';
import 'package:isdalink/screens/profile/manage_profile_screen.dart';
import 'package:isdalink/screens/profile/region_location_screen.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/activation/supplier_activation_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_dashboard_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/user_profile_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final UserProfileService profileService = const UserProfileService();
  final CloudinaryUploadService cloudinaryUploadService =
      const CloudinaryUploadService();
  final ImagePicker imagePicker = ImagePicker();

  bool isUploadingProfileImage = false;
  bool approvalDialogScheduled = false;

  void openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> logout() async {
    await profileService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> uploadProfilePhoto(bool isApprovedSupplier) async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );

      if (image == null) {
        return;
      }

      setState(() {
        isUploadingProfileImage = true;
      });

      final imageUrl = await cloudinaryUploadService.uploadImage(
        image,
        folder: CloudinaryConfig.profileFolder,
      );

      await profileService.updateProfileImageUrl(
        imageUrl: imageUrl,
        isApprovedSupplier: isApprovedSupplier,
      );

      showMessage('Profile photo updated successfully.');
    } catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback: 'The profile photo could not be updated. Please try again.',
          allowBusinessMessage: true,
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingProfileImage = false;
        });
      }
    }
  }

  Future<void> removeProfilePhoto(bool isApprovedSupplier) async {
    try {
      setState(() {
        isUploadingProfileImage = true;
      });

      await profileService.removeProfileImageUrl(
        isApprovedSupplier: isApprovedSupplier,
      );

      showMessage('Profile photo removed.');
    } catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback: 'The profile photo could not be removed. Please try again.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingProfileImage = false;
        });
      }
    }
  }

  void showProfilePhotoOptions({
    required String profileImageUrl,
    required bool isApprovedSupplier,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F8FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9DDEA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                _ProfileAvatar(
                  imageUrl: profileImageUrl,
                  isSupplier: isApprovedSupplier,
                  isUploading: false,
                  onTap: () {},
                  size: 86,
                  showCameraBadge: false,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Update the photo shown on your IsdaLink account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _ProfilePhotoAction(
                  icon: Icons.photo_library_outlined,
                  title: 'Upload New Photo',
                  subtitle: 'Choose an image from your gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    uploadProfilePhoto(isApprovedSupplier);
                  },
                ),
                if (profileImageUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ProfilePhotoAction(
                    icon: Icons.delete_outline,
                    title: 'Remove Photo',
                    subtitle: 'Use the default account icon again',
                    isDanger: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      removeProfilePhoto(isApprovedSupplier);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> markSupplierApprovalSeen() async {
    final user = profileService.currentUser;

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'supplierApprovalSeen': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void maybeShowSupplierApprovalDialog(Map<String, dynamic>? profileData) {
    if (profileData == null || approvalDialogScheduled) {
      return;
    }

    final role = profileService
        .getStringValue(profileData, 'role', 'vendor')
        .toLowerCase();

    final supplierStatus = profileService
        .getStringValue(profileData, 'supplierStatus', 'not_applicable')
        .toLowerCase();

    final approved = role == 'supplier' || supplierStatus == 'approved';
    final alreadySeen = profileData['supplierApprovalSeen'] == true;

    if (!approved || alreadySeen) {
      return;
    }

    approvalDialogScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await markSupplierApprovalSeen();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF0875D1)],
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Supplier Approved',
                    style: TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Your existing account now has supplier tools while keeping all vendor functions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0875D1),
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: Color(0xFF0875D1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Later',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            openScreen(const SupplierDashboardScreen());
                          },
                          icon: const Icon(
                            Icons.dashboard_customize_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Open Supplier Center',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0875D1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
    });
  }

  String firstAvailableText(
    Map<String, dynamic>? data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = profileService.getStringValue(data, key, '');

      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  Widget loadedBody(Map<String, dynamic>? profileData) {
    maybeShowSupplierApprovalDialog(profileData);

    final user = profileService.currentUser;
    final uid = user?.uid ?? '';

    final fallbackName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'IsdaLink User';

    final name = profileService.getStringValue(
      profileData,
      'name',
      fallbackName,
    );

    final email = profileService.getStringValue(
      profileData,
      'email',
      user?.email ?? 'No email available',
    );

    final profileImageUrl = profileService.getStringValue(
      profileData,
      'profileImageUrl',
      user?.photoURL ?? '',
    );

    final location = firstAvailableText(profileData, const [
      'location',
      'marketLocation',
      'address',
      'region',
    ], 'Caraga Region');

    final role = profileService
        .getStringValue(profileData, 'role', 'vendor')
        .toLowerCase();

    final supplierStatus = profileService
        .getStringValue(profileData, 'supplierStatus', 'not_applicable')
        .toLowerCase();

    final isApprovedSupplier =
        role == 'supplier' || supplierStatus == 'approved';
    final isPendingSupplier = supplierStatus == 'pending';
    final isRejectedSupplier = supplierStatus == 'rejected';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _AccountCenterHeader(
          name: name,
          email: email,
          location: location,
          profileImageUrl: profileImageUrl,
          isApprovedSupplier: isApprovedSupplier,
          isPendingSupplier: isPendingSupplier,
          isRejectedSupplier: isRejectedSupplier,
          isUploadingProfileImage: isUploadingProfileImage,
          onBack: () => Navigator.pop(context),
          onProfilePhotoTap: () => showProfilePhotoOptions(
            profileImageUrl: profileImageUrl,
            isApprovedSupplier: isApprovedSupplier,
          ),
          onManageProfile: () => openScreen(const ManageProfileScreen()),
          onSupplierCenter: () {
            if (isApprovedSupplier) {
              openScreen(const SupplierDashboardScreen());
            } else {
              openScreen(const SupplierActivationScreen());
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            children: [
              if (uid.isNotEmpty)
                _VendorOrdersOverviewCard(
                  uid: uid,
                  onOpenOrders: () => openScreen(const MyOrdersScreen()),
                ),
              const SizedBox(height: 13),
              if (isApprovedSupplier && uid.isNotEmpty) ...[
                _SupplierCenterCard(
                  uid: uid,
                  onOpenDashboard: () =>
                      openScreen(const SupplierDashboardScreen()),
                  onPostStock: () => openScreen(const PostFishStockScreen()),
                  onProducts: () =>
                      openScreen(const SupplierManageProductsScreen()),
                  onOrders: () => openScreen(const SupplierCodOrdersScreen()),
                  onAnalytics: () =>
                      openScreen(const SupplierAnalyticsScreen()),
                ),
                const SizedBox(height: 13),
              ],
              _AccountSettingsCard(
                onAccountInformation: () =>
                    openScreen(const ManageProfileScreen()),
                onRegionAndLocation: () =>
                    openScreen(const RegionLocationScreen()),
                onHelp: () => showMessage(
                  'Help and support content will be available here.',
                ),
                onLogout: logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = profileService.profileStream();

    if (stream == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: loadedBody(null),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _MeLoadingBody();
          }

          return loadedBody(snapshot.data?.data());
        },
      ),
    );
  }
}

class _AccountCenterHeader extends StatelessWidget {
  const _AccountCenterHeader({
    required this.name,
    required this.email,
    required this.location,
    required this.profileImageUrl,
    required this.isApprovedSupplier,
    required this.isPendingSupplier,
    required this.isRejectedSupplier,
    required this.isUploadingProfileImage,
    required this.onBack,
    required this.onProfilePhotoTap,
    required this.onManageProfile,
    required this.onSupplierCenter,
  });

  static const String _coverAsset =
      'assets/images/order_center_caraga_header.png';

  final String name;
  final String email;
  final String location;
  final String profileImageUrl;
  final bool isApprovedSupplier;
  final bool isPendingSupplier;
  final bool isRejectedSupplier;
  final bool isUploadingProfileImage;
  final VoidCallback onBack;
  final VoidCallback onProfilePhotoTap;
  final VoidCallback onManageProfile;
  final VoidCallback onSupplierCenter;

  String get accountLabel {
    if (isApprovedSupplier) return 'Approved Supplier';
    if (isPendingSupplier) return 'Application Pending';
    if (isRejectedSupplier) return 'Review Application';
    return 'Become a Supplier';
  }

  IconData get accountIcon {
    if (isApprovedSupplier) return Icons.verified_rounded;
    if (isPendingSupplier) return Icons.hourglass_top_rounded;
    if (isRejectedSupplier) return Icons.info_outline_rounded;
    return Icons.storefront_rounded;
  }

  Color get accountColor {
    if (isPendingSupplier) return const Color(0xFFE76F12);
    if (isRejectedSupplier) return const Color(0xFFC93636);
    return const Color(0xFF087DD1);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    // Match Order Center exactly so moving between both screens feels stable.
    final coverHeight = topPadding + 178;
    final panelHeight = isApprovedSupplier ? 150.0 : 214.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: SizedBox(
        height: coverHeight + panelHeight - 26,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: coverHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _coverAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF075489), Color(0xFF079AC7)],
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x5C001E38), Color(0xC900294A)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _HeaderCircleButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: onBack,
                              tooltip: 'Back',
                            ),
                            const Spacer(),
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/isdalink_logo.png',
                                width: 92,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Text(
                                  'IsdaLink',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'MY ACCOUNT',
                          style: TextStyle(
                            color: Color(0xFFD7EEFA),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Account Center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: coverHeight - 26,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F8FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1900213D),
                      blurRadius: 20,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileAvatar(
                          imageUrl: profileImageUrl,
                          isSupplier: isApprovedSupplier,
                          isUploading: isUploadingProfileImage,
                          onTap: onProfilePhotoTap,
                          size: 78,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF062A49),
                                        fontSize: 18,
                                        height: 1.08,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 30,
                                    child: OutlinedButton.icon(
                                      onPressed: onManageProfile,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                      ),
                                      label: const Text('Edit'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF087DD1,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF87C6EA),
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6D8497),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 7,
                                runSpacing: 5,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accountColor.withAlpha(18),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          accountIcon,
                                          color: accountColor,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          accountLabel,
                                          style: TextStyle(
                                            color: accountColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF70899D),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 155,
                                        ),
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF70899D),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isApprovedSupplier) ...[
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: onSupplierCenter,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD8E8F1),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  accountIcon,
                                  color: accountColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    accountLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF0A2D4B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF087DD1),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorOrdersOverviewCard extends StatelessWidget {
  const _VendorOrdersOverviewCard({
    required this.uid,
    required this.onOpenOrders,
  });

  final String uid;
  final VoidCallback onOpenOrders;

  bool isActive(String status) {
    final value = status.toLowerCase();
    return value == 'pending' || value == 'accepted';
  }

  bool isCompleted(String status) {
    final value = status.toLowerCase();
    return value == 'completed' || value == 'delivered';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final documents = snapshot.data?.docs ?? [];
        final active = documents.where((document) {
          final status = (document.data()['orderStatus'] ?? 'pending')
              .toString();
          return isActive(status);
        }).length;
        final completed = documents.where((document) {
          final status = (document.data()['orderStatus'] ?? 'pending')
              .toString();
          return isCompleted(status);
        }).length;

        return _SectionCard(
          title: 'My Orders',
          icon: Icons.receipt_long_rounded,
          actionLabel: 'View Orders',
          onActionTap: onOpenOrders,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _OverviewValue(
                  value: '$active',
                  label: 'Active',
                  icon: Icons.pending_actions_rounded,
                ),
                const _MetricDivider(),
                _OverviewValue(
                  value: '$completed',
                  label: 'Completed',
                  icon: Icons.task_alt_rounded,
                ),
                const _MetricDivider(),
                _OverviewValue(
                  value: '${documents.length}',
                  label: 'Total',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupplierCenterCard extends StatelessWidget {
  const _SupplierCenterCard({
    required this.uid,
    required this.onOpenDashboard,
    required this.onPostStock,
    required this.onProducts,
    required this.onOrders,
    required this.onAnalytics,
  });

  final String uid;
  final VoidCallback onOpenDashboard;
  final VoidCallback onPostStock;
  final VoidCallback onProducts;
  final VoidCallback onOrders;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('supplierId', isEqualTo: uid)
          .snapshots(),
      builder: (context, orderSnapshot) {
        final orders = orderSnapshot.data?.docs ?? [];
        final pending = orders.where((document) {
          final status = (document.data()['orderStatus'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'pending';
        }).length;
        final active = orders.where((document) {
          final status = (document.data()['orderStatus'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'pending' || status == 'accepted';
        }).length;
        final completed = orders.where((document) {
          final status = (document.data()['orderStatus'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'completed' || status == 'delivered';
        }).length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('fishStocks')
              .where('supplierId', isEqualTo: uid)
              .snapshots(),
          builder: (context, stockSnapshot) {
            final stocks = stockSnapshot.data?.docs ?? [];
            final activeStocks = stocks.where((document) {
              final data = document.data();
              final status = (data['status'] ?? 'available')
                  .toString()
                  .toLowerCase();
              final quantityValue = data['quantity'];
              final quantity = quantityValue is num
                  ? quantityValue.toDouble()
                  : double.tryParse(quantityValue?.toString() ?? '') ?? 0;
              return status != 'unavailable' && quantity > 0;
            }).length;

            return _SectionCard(
              title: 'Supplier Tools',
              icon: Icons.storefront_rounded,
              actionLabel: 'Dashboard',
              onActionTap: onOpenDashboard,
              child: Column(
                children: [
                  if (pending > 0) ...[
                    Material(
                      color: const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        onTap: onOrders,
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: const Color(0xFFFF7A1A).withAlpha(55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A1A),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$pending pending COD order'
                                  '${pending == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Color(0xFF102C44),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFFF7A1A),
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardShortcut(
                          icon: Icons.add_box_outlined,
                          label: 'Post Stock',
                          onTap: onPostStock,
                        ),
                      ),
                      Expanded(
                        child: _DashboardShortcut(
                          icon: Icons.inventory_2_outlined,
                          label: 'Products',
                          onTap: onProducts,
                        ),
                      ),
                      Expanded(
                        child: _DashboardShortcut(
                          icon: Icons.receipt_long_outlined,
                          label: 'COD Orders',
                          badge: pending,
                          onTap: onOrders,
                        ),
                      ),
                      Expanded(
                        child: _DashboardShortcut(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          onTap: onAnalytics,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8FC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _OverviewValue(
                          value: '$activeStocks',
                          label: 'Stocks',
                          icon: Icons.inventory_outlined,
                        ),
                        const _MetricDivider(),
                        _OverviewValue(
                          value: '$active',
                          label: 'Active COD',
                          icon: Icons.pending_actions_rounded,
                        ),
                        const _MetricDivider(),
                        _OverviewValue(
                          value: '$completed',
                          label: 'Completed',
                          icon: Icons.task_alt_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AccountSettingsCard extends StatelessWidget {
  const _AccountSettingsCard({
    required this.onAccountInformation,
    required this.onRegionAndLocation,
    required this.onHelp,
    required this.onLogout,
  });

  final VoidCallback onAccountInformation;
  final VoidCallback onRegionAndLocation;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account Settings',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Account Information',
            onTap: onAccountInformation,
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Region and Location',
            onTap: onRegionAndLocation,
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help and Support',
            onTap: onHelp,
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: const Color(0xFFD32F2F),
            showDivider: false,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE1ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00152A),
            blurRadius: 13,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FD),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF0875D1), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onActionTap != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0875D1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0875D1), size: 16),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 8.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 43, color: const Color(0xFFDDE9F1));
  }
}

class _DashboardShortcut extends StatelessWidget {
  const _DashboardShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FD),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: const Color(0xFF0875D1), size: 21),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -4,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 19,
                          minHeight: 19,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D38),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF52677A),
                  fontSize: 8.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF0875D1),
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: color.withAlpha(17),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color == const Color(0xFFD32F2F)
                                ? color
                                : const Color(0xFF102C44),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF9FB0BC),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 50, color: Color(0xFFE6EEF3)),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.isSupplier,
    required this.isUploading,
    required this.onTap,
    this.size = 72,
    this.showCameraBadge = true,
  });

  final String imageUrl;
  final bool isSupplier;
  final bool isUploading;
  final VoidCallback onTap;
  final double size;
  final bool showCameraBadge;

  bool get hasImage {
    final value = imageUrl.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24001226),
                    blurRadius: 13,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: isUploading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0875D1),
                          ),
                        ),
                      )
                    : hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return _AvatarFallback(isSupplier: isSupplier);
                        },
                      )
                    : _AvatarFallback(isSupplier: isSupplier),
              ),
            ),
            if (showCameraBadge)
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0875D1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.isSupplier});

  final bool isSupplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF8FC),
      child: Icon(
        isSupplier ? Icons.storefront_rounded : Icons.person_rounded,
        color: const Color(0xFF0875D1),
        size: 36,
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(24),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoAction extends StatelessWidget {
  const _ProfilePhotoAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFD32F2F) : const Color(0xFF0875D1);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(17),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeLoadingBody extends StatelessWidget {
  const _MeLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF0875D1),
        ),
      ),
    );
  }
}
