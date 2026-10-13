import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/admin/admin_supplier_detail_screen.dart';
import 'package:isdalink/screens/admin/supplier_change_request_review_screen.dart';
import 'package:isdalink/screens/admin/widgets/admin_change_request_card.dart';
import 'package:isdalink/screens/admin/widgets/admin_overview_card.dart';
import 'package:isdalink/screens/admin/widgets/admin_section_title.dart';
import 'package:isdalink/screens/admin/widgets/admin_status_cards.dart';
import 'package:isdalink/screens/admin/widgets/admin_supplier_cards.dart';
import 'package:isdalink/screens/auth/login_screen.dart';
import 'package:isdalink/services/admin_dashboard_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

enum AdminSupplierFilter { pending, approved, declined }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final service = const AdminDashboardService();
  final searchController = TextEditingController();
  AdminSupplierFilter filter = AdminSupplierFilter.pending;
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Log out of Admin?',
          style: TextStyle(
            color: Color(0xFF102C44),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'You will return to the IsdaLink login screen.',
          style: TextStyle(color: Color(0xFF52677A), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await service.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(showBackButton: false),
      ),
      (_) => false,
    );
  }

  Future<bool> approve(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      await service.approveSupplier(doc);
      message('Supplier approved. Supplier tools are now available.');
      return true;
    } catch (e) {
      message(
        AppErrorMessage.from(
          e,
          fallback: 'Unable to approve this application.',
          allowBusinessMessage: true,
        ),
        error: true,
      );
      return false;
    }
  }

  Future<String?> rejectionReason() async {
    var draft = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, update) {
          final reason = draft.trim();
          final valid = reason.length >= 5 && reason.length <= 500;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Decline Application',
              style: TextStyle(
                color: Color(0xFF102C44),
                fontWeight: FontWeight.w900,
              ),
            ),
            content: TextField(
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) => update(() => draft = value),
              decoration: InputDecoration(
                labelText: 'Reason for decline',
                hintText: 'Explain what the applicant needs to correct.',
                helperText: 'Required. Minimum 5 characters.',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF6FAFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: valid
                    ? () => Navigator.pop(dialogContext, reason)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Decline'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> reject(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final reason = await rejectionReason();
    if (reason == null) return false;
    try {
      await service.rejectSupplier(doc, rejectionReason: reason);
      message('Application declined. The applicant was notified.');
      return true;
    } catch (e) {
      message(
        AppErrorMessage.from(
          e,
          fallback: 'Unable to decline this application.',
          allowBusinessMessage: true,
        ),
        error: true,
      );
      return false;
    }
  }

  Map<String, dynamic> userFor(
    QueryDocumentSnapshot<Map<String, dynamic>> supplier,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
  ) {
    final uid = service.getStringValue(supplier.data(), 'uid', supplier.id);
    for (final user in users) {
      if (user.id == uid) return user.data();
    }
    return const {};
  }

  void openSupplier(
    QueryDocumentSnapshot<Map<String, dynamic>> supplier,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    String status,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSupplierDetailScreen(
          supplierData: supplier.data(),
          userData: userFor(supplier, users),
          status: status,
          onApprove: status == 'pending' ? () => approve(supplier) : null,
          onReject: status == 'pending' ? () => reject(supplier) : null,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> searched(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return records;
    return records.where((doc) {
      final data = doc.data();
      final text = [
        data['supplierName'],
        data['storeName'],
        data['businessName'],
        data['ownerName'],
        data['location'],
        data['storeLocation'],
        data['email'],
        data['phone'],
      ].whereType<Object>().join(' ').toLowerCase();
      return text.contains(needle);
    }).toList();
  }

  Widget dashboard({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> suppliers,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> changes,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stocks,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
  }) {
    final pending = service.pendingSuppliers(suppliers);
    final approved = service.approvedSuppliers(suppliers);
    final declined = service.rejectedSuppliers(suppliers);
    final profileChanges = service.pendingChangeRequests(changes);
    final selected = switch (filter) {
      AdminSupplierFilter.pending => pending,
      AdminSupplierFilter.approved => approved,
      AdminSupplierFilter.declined => declined,
    };
    final visible = searched(selected);
    final status = switch (filter) {
      AdminSupplierFilter.pending => 'pending',
      AdminSupplierFilter.approved => 'approved',
      AdminSupplierFilter.declined => 'rejected',
    };

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        _AdminHeaderSliver(onLogout: logout),
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFF0A5B84),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1800152A),
                    blurRadius: 22,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminSummaryMetrics(
                    users: users.length,
                    suppliers: approved.length,
                    pending: pending.length + profileChanges.length,
                    orders: orders.length,
                  ),
                  const SizedBox(height: 14),
                  _AttentionCard(
                    applications: pending.length,
                    changes: profileChanges.length,
                  ),
                  const SizedBox(height: 22),
                  const AdminSectionTitle(
                    title: 'Supplier Records',
                    subtitle:
                        'Review and open supplier applications by status.',
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 14),
                  _FilterBar(
                    selected: filter,
                    pending: pending.length,
                    approved: approved.length,
                    declined: declined.length,
                    onSelected: (value) => setState(() => filter = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: 'Search supplier or owner',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFDCE7EF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (visible.isEmpty)
                    AdminEmptyCard(
                      icon: query.isEmpty
                          ? Icons.inbox_outlined
                          : Icons.search_off_rounded,
                      title: query.isEmpty
                          ? 'No ${filter.name} suppliers'
                          : 'No matching suppliers',
                      subtitle: query.isEmpty
                          ? 'Supplier records with this status will appear here.'
                          : 'Try another supplier, owner, or location.',
                    )
                  else
                    ...visible.map(
                      (supplier) => SupplierRecordCard(
                        document: supplier,
                        status: status,
                        onTap: () => openSupplier(supplier, users, status),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const AdminSectionTitle(
                    title: 'Verified Profile Changes',
                    subtitle:
                        'Review protected updates from approved suppliers.',
                    icon: Icons.manage_accounts_outlined,
                  ),
                  const SizedBox(height: 14),
                  if (profileChanges.isEmpty)
                    const AdminEmptyCard(
                      icon: Icons.verified_user_outlined,
                      title: 'No profile change requests',
                      subtitle:
                          'Pending verified-profile changes will appear here.',
                    )
                  else
                    ...profileChanges.map(
                      (doc) => AdminChangeRequestCard(
                        document: doc,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupplierChangeRequestReviewScreen(
                              supplierId: doc.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const AdminSectionTitle(
                    title: 'System Overview',
                    subtitle: 'Current marketplace and account records.',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 14),
                  AdminOverviewCard(
                    usersCount: users.length,
                    suppliersCount: suppliers.length,
                    stocksCount: stocks.length,
                    ordersCount: orders.length,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.usersStream,
      builder: (context, users) =>
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.supplierProfilesStream,
            builder: (context, suppliers) =>
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: service.fishStocksStream,
                  builder: (context, stocks) =>
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: service.ordersStream,
                        builder: (context, orders) =>
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: service.supplierChangeRequestsStream,
                              builder: (context, changes) {
                                final all = <AsyncSnapshot>[
                                  users,
                                  suppliers,
                                  stocks,
                                  orders,
                                  changes,
                                ];
                                for (final item in all) {
                                  if (item.hasError) {
                                    return AdminErrorBody(error: item.error!);
                                  }
                                }
                                if (all.any((item) => !item.hasData)) {
                                  return const AdminLoadingBody();
                                }
                                return Scaffold(
                                  backgroundColor: const Color(0xFFF4F8FB),
                                  body: dashboard(
                                    users: users.data!.docs,
                                    suppliers: suppliers.data!.docs,
                                    changes: changes.data!.docs,
                                    stocks: stocks.data!.docs,
                                    orders: orders.data!.docs,
                                  ),
                                );
                              },
                            ),
                      ),
                ),
          ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.pending,
    required this.approved,
    required this.declined,
    required this.onSelected,
  });
  final AdminSupplierFilter selected;
  final int pending;
  final int approved;
  final int declined;
  final ValueChanged<AdminSupplierFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(AdminSupplierFilter, String, int)>[
      (AdminSupplierFilter.pending, 'Pending', pending),
      (AdminSupplierFilter.approved, 'Approved', approved),
      (AdminSupplierFilter.declined, 'Declined', declined),
    ];
    return Row(
      children: items.map((item) {
        final active = selected == item.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item.$1 == AdminSupplierFilter.declined ? 0 : 7,
            ),
            child: InkWell(
              onTap: () => onSelected(item.$1),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF146BFF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF146BFF)
                        : const Color(0xFFDCE7EF),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.$3}',
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF102C44),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFFDCEBFF)
                            : const Color(0xFF71869A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.applications, required this.changes});
  final int applications;
  final int changes;

  @override
  Widget build(BuildContext context) {
    final total = applications + changes;
    final clear = total == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: clear ? Colors.white : const Color(0xFF102C44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: clear ? const Color(0xFFDCE7EF) : const Color(0xFF102C44),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: clear
                  ? const Color(0xFFEAF8F2)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              clear ? Icons.task_alt_rounded : Icons.notifications_none_rounded,
              color: clear ? const Color(0xFF16845C) : Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clear
                      ? 'All caught up'
                      : '$total item${total == 1 ? '' : 's'} need review',
                  style: TextStyle(
                    color: clear ? const Color(0xFF102C44) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  clear
                      ? 'No supplier verification work is pending.'
                      : '$applications applications • $changes profile changes',
                  style: TextStyle(
                    color: clear
                        ? const Color(0xFF71869A)
                        : const Color(0xFFDCE9F5),
                    fontSize: 11,
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

class _AdminHeaderSliver extends StatelessWidget {
  const _AdminHeaderSliver({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    const expandedHeight = 184.0;
    const toolbarHeight = 52.0;
    final collapsedHeight = topPadding + toolbarHeight;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF073E69),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF073E69),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final range = expandedHeight - collapsedHeight;
          final progress = range <= 0
              ? 0.0
              : ((constraints.maxHeight - collapsedHeight) / range)
                    .clamp(0.0, 1.0)
                    .toDouble();
          final compactOpacity = (1 - progress * 2.25)
              .clamp(0.0, 1.0)
              .toDouble();
          final expandedOpacity = ((progress - 0.16) / 0.84)
              .clamp(0.0, 1.0)
              .toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/isdalink_main_header.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06355F),
                        Color(0xFF0875D1),
                        Color(0xFF12A7D1),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Color(0x5C001E38), Color(0xC900294A)],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: compactOpacity,
                            child: const Text(
                              'Admin Dashboard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                          child: InkWell(
                            onTap: onLogout,
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: IgnorePointer(
                  ignoring: progress < 0.30,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMIN CONTROL CENTER',
                          style: TextStyle(
                            color: Color(0xFFD2F4FB),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.55,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Review suppliers and monitor IsdaLink operations.',
                          style: TextStyle(
                            color: Color(0xFFE2F4FA),
                            fontSize: 10.5,
                            height: 1.30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSummaryMetrics extends StatelessWidget {
  const _AdminSummaryMetrics({
    required this.users,
    required this.suppliers,
    required this.pending,
    required this.orders,
  });

  final int users;
  final int suppliers;
  final int pending;
  final int orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E052C4F),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          children: [
            _AdminMetric(
              icon: Icons.people_outline_rounded,
              value: '$users',
              label: 'Users',
            ),
            _AdminMetric(
              icon: Icons.storefront_outlined,
              value: '$suppliers',
              label: 'Suppliers',
            ),
            _AdminMetric(
              icon: Icons.pending_actions_outlined,
              value: '$pending',
              label: 'Pending',
            ),
            _AdminMetric(
              icon: Icons.receipt_long_outlined,
              value: '$orders',
              label: 'Orders',
              divider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.divider = true,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: divider
              ? const Border(right: BorderSide(color: Color(0xFFE7EEF3)))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0875D1), size: 19),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF71869A),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
