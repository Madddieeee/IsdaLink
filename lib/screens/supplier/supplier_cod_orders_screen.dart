import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_order_card.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_orders_header.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_orders_status_cards.dart';
import 'package:isdalink/services/supplier_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/app_error_message.dart';

enum SupplierOrderFilter { all, pending, accepted, delivered, cancelled }

class SupplierCodOrdersScreen extends StatefulWidget {
  const SupplierCodOrdersScreen({super.key, this.initialOrderId = ''});

  final String initialOrderId;

  @override
  State<SupplierCodOrdersScreen> createState() =>
      _SupplierCodOrdersScreenState();
}

class _SupplierCodOrdersScreenState extends State<SupplierCodOrdersScreen> {
  final searchController = TextEditingController();
  final orderService = const SupplierOrderService();

  final busyOrderIds = <String>{};
  final expandedOrderIds = <String>{};

  SupplierOrderFilter selectedFilter = SupplierOrderFilter.all;
  int streamRevision = 0;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    searchController.addListener(refreshSearch);

    final initialOrderId = widget.initialOrderId.trim();

    if (initialOrderId.isNotEmpty) {
      expandedOrderIds.add(initialOrderId);
    }
  }

  @override
  void dispose() {
    searchController.removeListener(refreshSearch);
    searchController.dispose();
    super.dispose();
  }

  void refreshSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  String firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String normalizedStatus(Map<String, dynamic> data) {
    final status = firstString(data, const [
      'orderStatus',
      'status',
    ], fallback: 'Pending').toLowerCase();

    if (status == 'completed') {
      return 'delivered';
    }

    return status;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final query = searchController.text.trim().toLowerCase();

    return documents.where((document) {
      final data = document.data();
      final productName = firstString(data, const [
        'productName',
        'fishName',
      ], fallback: 'Fish Product').toLowerCase();
      final vendorName = firstString(data, const [
        'vendorName',
        'buyerName',
        'customerName',
      ], fallback: 'Registered Vendor').toLowerCase();
      final orderNumber = firstString(data, const [
        'orderNumber',
        'referenceNumber',
      ], fallback: document.id).toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          productName.contains(query) ||
          vendorName.contains(query) ||
          orderNumber.contains(query);

      if (!matchesSearch) {
        return false;
      }

      final status = normalizedStatus(data);

      switch (selectedFilter) {
        case SupplierOrderFilter.all:
          return true;
        case SupplierOrderFilter.pending:
          return status == 'pending';
        case SupplierOrderFilter.accepted:
          return status == 'accepted';
        case SupplierOrderFilter.delivered:
          return status == 'delivered';
        case SupplierOrderFilter.cancelled:
          return status == 'cancelled';
      }
    }).toList();
  }

  int countFilter({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required SupplierOrderFilter filter,
  }) {
    if (filter == SupplierOrderFilter.all) {
      return documents.length;
    }

    return documents.where((document) {
      final status = normalizedStatus(document.data());

      switch (filter) {
        case SupplierOrderFilter.pending:
          return status == 'pending';
        case SupplierOrderFilter.accepted:
          return status == 'accepted';
        case SupplierOrderFilter.delivered:
          return status == 'delivered';
        case SupplierOrderFilter.cancelled:
          return status == 'cancelled';
        case SupplierOrderFilter.all:
          return true;
      }
    }).length;
  }

  String filterLabel(SupplierOrderFilter filter) {
    switch (filter) {
      case SupplierOrderFilter.all:
        return 'All';
      case SupplierOrderFilter.pending:
        return 'Pending';
      case SupplierOrderFilter.accepted:
        return 'Accepted';
      case SupplierOrderFilter.delivered:
        return 'Delivered';
      case SupplierOrderFilter.cancelled:
        return 'Cancelled';
    }
  }

  IconData filterIcon(SupplierOrderFilter filter) {
    switch (filter) {
      case SupplierOrderFilter.all:
        return Icons.receipt_long_outlined;
      case SupplierOrderFilter.pending:
        return Icons.schedule_rounded;
      case SupplierOrderFilter.accepted:
        return Icons.inventory_2_outlined;
      case SupplierOrderFilter.delivered:
        return Icons.local_shipping_outlined;
      case SupplierOrderFilter.cancelled:
        return Icons.cancel_outlined;
    }
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          backgroundColor: isError
              ? const Color(0xFFD94A45)
              : const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void setBusy(String documentId, bool busy) {
    setState(() {
      if (busy) {
        busyOrderIds.add(documentId);
      } else {
        busyOrderIds.remove(documentId);
      }
    });
  }

  Future<bool> confirmStatusChange({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Color color,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 11),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 10.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF52677A),
                          side: const BorderSide(color: Color(0xFFB9CBD7)),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            destructive ? 'Keep Order' : 'Go Back',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: destructive
                              ? const Color(0xFFD94A45)
                              : color,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            confirmLabel,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
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

    return result ?? false;
  }

  Future<void> updateOrderStatus({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required String newStatus,
    required String paymentStatus,
  }) async {
    if (busyOrderIds.contains(document.id)) {
      return;
    }

    final data = document.data();
    final productName = firstString(data, const [
      'productName',
      'fishName',
    ], fallback: 'this fish product');
    final tawadRequested = data['tawadRequested'] == true;

    late final String title;
    late final String message;
    late final String confirmLabel;
    late final IconData icon;
    late final Color color;
    late final bool destructive;

    switch (newStatus.toLowerCase()) {
      case 'accepted':
        title = tawadRequested
            ? 'Accept this Tawad offer?'
            : 'Accept this COD order?';
        message = tawadRequested
            ? 'The $productName order will use the vendor\'s offered unit price. The vendor will be notified.'
            : 'Confirm that you can fulfill the requested $productName quantity. The vendor will be notified.';
        confirmLabel = tawadRequested ? 'Accept Tawad' : 'Accept Order';
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF146BFF);
        destructive = false;
        break;
      case 'delivered':
        title = 'Confirm delivery and payment?';
        message =
            'Use this only after the fish order is delivered and its Cash on Delivery payment has been received.';
        confirmLabel = 'Confirm Delivery';
        icon = Icons.local_shipping_rounded;
        color = const Color(0xFF147D64);
        destructive = false;
        break;
      case 'cancelled':
        title = tawadRequested
            ? 'Decline this Tawad offer?'
            : 'Cancel this order?';
        message = tawadRequested
            ? 'This cancels the whole order, returns reserved stock, and notifies the vendor.'
            : 'This cancels the order, returns reserved stock, and notifies the vendor.';
        confirmLabel = tawadRequested ? 'Decline Tawad' : 'Cancel Order';
        icon = Icons.cancel_outlined;
        color = const Color(0xFFD94A45);
        destructive = true;
        break;
      default:
        return;
    }

    double? acceptedFulfilledQuantity;

    if (newStatus.toLowerCase() == 'accepted') {
      final requestedQuantity = OrderHelpers.getDoubleValue(data, 'quantity');
      final quantityUnit = firstString(data, const [
        'quantityUnit',
        'unit',
      ], fallback: 'unit');
      final confirmed = await confirmStatusChange(
        title: title,
        message:
            '${OrderHelpers.formatNumber(requestedQuantity)} $quantityUnit of $productName will be confirmed. '
            '${tawadRequested ? 'The accepted Tawad price will be used. ' : ''}'
            'The vendor will be notified.',
        confirmLabel: confirmLabel,
        icon: icon,
        color: color,
        destructive: false,
      );

      if (!mounted || !confirmed) {
        return;
      }
      acceptedFulfilledQuantity = requestedQuantity;
    } else {
      final confirmed = await confirmStatusChange(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        icon: icon,
        color: color,
        destructive: destructive,
      );

      if (!mounted || !confirmed) {
        return;
      }
    }

    setBusy(document.id, true);

    try {
      await orderService.updateOrderStatus(
        documentId: document.id,
        newStatus: newStatus,
        paymentStatus: paymentStatus,
        fulfilledQuantity: acceptedFulfilledQuantity,
      );

      if (!mounted) {
        return;
      }

      final successMessage = newStatus.toLowerCase() == 'cancelled'
          ? 'Order cancelled. Reserved stock and vendor notification were processed.'
          : newStatus.toLowerCase() == 'delivered'
          ? 'Delivery and COD payment were recorded successfully.'
          : 'Order accepted. The vendor was notified.';

      showMessage(successMessage);
    } on FirebaseException catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback: 'Unable to update this COD order. Please try again.',
        ),
        isError: true,
      );
    } on StateError catch (error) {
      showMessage(error.message, isError: true);
    } catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback:
              'Something went wrong while updating this COD order. Please try again.',
          allowBusinessMessage: true,
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setBusy(document.id, false);
      }
    }
  }

  void clearSearchAndFilters() {
    searchController.clear();

    setState(() {
      selectedFilter = SupplierOrderFilter.all;
    });
  }

  Widget statusFilterChip({
    required SupplierOrderFilter filter,
    required int count,
  }) {
    final selected = selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0875D1) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0875D1)
                  : const Color(0xFFD9E6EE),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1F0875D1),
                      blurRadius: 9,
                      offset: Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filterIcon(filter),
                size: 17,
                color: selected ? Colors.white : const Color(0xFF5B6F80),
              ),
              const SizedBox(width: 6),
              Text(
                filterLabel(filter),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF415768),
                  fontSize: 10.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0xFFF0F5F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF52677A),
                    fontSize: 9.2,
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

  Widget bodyShell({required Widget child}) {
    return Container(
      color: const Color(0xFF0A5B84),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
        child: child,
      ),
    );
  }

  Widget controlsCard({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Search vendor, fish, or order number',
              hintStyle: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 10.9,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0875D1),
                size: 22,
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: searchController.clear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Color(0xFF5D7385),
                      ),
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE1EBF2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF0875D1),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Order status',
            style: TextStyle(
              color: Color(0xFF6F8598),
              fontSize: 10.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SupplierOrderFilter.values.map((filter) {
              return statusFilterChip(
                filter: filter,
                count: countFilter(documents: documents, filter: filter),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget queueTitle(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Open an order to view details and update its status.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count ${count == 1 ? 'order' : 'orders'}',
              style: const TextStyle(
                color: Color(0xFF0875D1),
                fontSize: 8.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget content({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    final visibleDocuments = filteredDocuments(documents);
    final initialOrderId = widget.initialOrderId.trim();

    if (initialOrderId.isNotEmpty) {
      final targetIndex = visibleDocuments.indexWhere(
        (document) => document.id == initialOrderId,
      );

      if (targetIndex > 0) {
        final target = visibleDocuments.removeAt(targetIndex);
        visibleDocuments.insert(0, target);
      }
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      key: ValueKey('supplier-orders-$streamRevision'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SupplierOrdersHeader(
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverToBoxAdapter(
          child: bodyShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                controlsCard(documents: documents),
                queueTitle(visibleDocuments.length),
                if (visibleDocuments.isEmpty)
                  SupplierOrdersEmptyCard(
                    filtered:
                        documents.isNotEmpty &&
                        (selectedFilter != SupplierOrderFilter.all ||
                            searchController.text.trim().isNotEmpty),
                    onClearFilters: clearSearchAndFilters,
                  )
                else
                  ...visibleDocuments.map((document) {
                    return SupplierOrderCard(
                      document: document,
                      highlighted: document.id == initialOrderId,
                      expanded: expandedOrderIds.contains(document.id),
                      isBusy: busyOrderIds.contains(document.id),
                      onToggle: () {
                        setState(() {
                          if (expandedOrderIds.contains(document.id)) {
                            expandedOrderIds.remove(document.id);
                          } else {
                            expandedOrderIds.add(document.id);
                          }
                        });
                      },
                      onAccept: () {
                        updateOrderStatus(
                          document: document,
                          newStatus: 'Accepted',
                          paymentStatus: 'To be paid on delivery',
                        );
                      },
                      onCancel: () {
                        updateOrderStatus(
                          document: document,
                          newStatus: 'Cancelled',
                          paymentStatus: 'Cancelled',
                        );
                      },
                      onMarkDelivered: () {
                        updateOrderStatus(
                          document: document,
                          newStatus: 'Delivered',
                          paymentStatus: 'Paid',
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody() {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SupplierOrdersHeader(
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverToBoxAdapter(
          child: bodyShell(child: const SupplierOrdersLoadingCard()),
        ),
      ],
    );
  }

  Widget errorBody() {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SupplierOrdersHeader(
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverToBoxAdapter(
          child: bodyShell(
            child: SupplierOrdersErrorCard(
              onRetry: () {
                setState(() {
                  streamRevision++;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget loggedOutBody() {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FAFC),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please log in first to review incoming COD orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD94A45),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return loggedOutBody();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(streamRevision),
          stream: orderService.ordersStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return errorBody();
            }

            if (!snapshot.hasData) {
              return loadingBody();
            }

            final documents = OrderHelpers.sortDocuments(snapshot.data!.docs);

            return content(documents: documents);
          },
        ),
      ),
    );
  }
}
