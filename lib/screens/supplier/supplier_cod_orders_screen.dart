import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_order_card.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_orders_header.dart';
import 'package:isdalink/screens/supplier/cod_orders/widgets/supplier_orders_status_cards.dart';
import 'package:isdalink/services/supplier_order_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

enum SupplierOrderFilter {
  all,
  pending,
  accepted,
  delivered,
  cancelled,
}

class SupplierCodOrdersScreen extends StatefulWidget {
  const SupplierCodOrdersScreen({
    super.key,
    this.initialOrderId = '',
  });

  final String initialOrderId;

  @override
  State<SupplierCodOrdersScreen> createState() =>
      _SupplierCodOrdersScreenState();
}

class _SupplierCodOrdersScreenState
    extends State<SupplierCodOrdersScreen> {
  final searchController = TextEditingController();
  final orderService = const SupplierOrderService();

  final busyOrderIds = <String>{};
  final expandedOrderIds = <String>{};

  SupplierOrderFilter selectedFilter =
      SupplierOrderFilter.all;
  int streamRevision = 0;

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

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

  String normalizedStatus(
    Map<String, dynamic> data,
  ) {
    final status = firstString(
      data,
      const [
        'orderStatus',
        'status',
      ],
      fallback: 'Pending',
    ).toLowerCase();

    if (status == 'completed') {
      return 'delivered';
    }

    return status;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filteredDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) {
    final query =
        searchController.text.trim().toLowerCase();

    return documents.where(
      (
        document,
      ) {
        final data = document.data();
        final productName = firstString(
          data,
          const [
            'productName',
            'fishName',
          ],
          fallback: 'Fish Product',
        ).toLowerCase();
        final vendorName = firstString(
          data,
          const [
            'vendorName',
            'buyerName',
            'customerName',
          ],
          fallback: 'Registered Vendor',
        ).toLowerCase();
        final orderNumber = firstString(
          data,
          const [
            'orderNumber',
            'referenceNumber',
          ],
          fallback: document.id,
        ).toLowerCase();

        final matchesSearch = query.isEmpty ||
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
      },
    ).toList();
  }

  int countFilter({
    required List<
        QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
    required SupplierOrderFilter filter,
  }) {
    if (filter == SupplierOrderFilter.all) {
      return documents.length;
    }

    return documents.where(
      (
        document,
      ) {
        final status = normalizedStatus(
          document.data(),
        );

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
      },
    ).length;
  }

  String filterLabel(
    SupplierOrderFilter filter,
  ) {
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

  IconData filterIcon(
    SupplierOrderFilter filter,
  ) {
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

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
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

  void setBusy(
    String documentId,
    bool busy,
  ) {
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
      builder: (
        dialogContext,
      ) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              21,
              20,
              18,
            ),
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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 10.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF52677A),
                          side: const BorderSide(
                            color: Color(0xFFB9CBD7),
                          ),
                          minimumSize: const Size.fromHeight(47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: destructive
                              ? const Color(0xFFD94A45)
                              : color,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(47),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
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

  Future<double?> chooseFulfilledQuantity(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final requestedQuantity =
        OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );
    final quantityUnit = firstString(
      data,
      const [
        'quantityUnit',
        'unit',
      ],
      fallback: 'unit',
    );
    final productName = firstString(
      data,
      const [
        'productName',
        'fishName',
      ],
      fallback: 'Fish Product',
    );

    if (requestedQuantity <= 0) {
      return null;
    }

    final requestedWhole =
        requestedQuantity.round();
    var selectedQuantity = requestedWhole;

    final result = await showDialog<int>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final returnedQuantity =
                requestedWhole - selectedQuantity;
            final partial =
                selectedQuantity < requestedWhole;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 23,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(25),
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
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF3FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF146BFF),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Accept COD Order',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$productName requested: '
                      '${OrderHelpers.formatNumber(requestedQuantity)} '
                      '$quantityUnit',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 10.6,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FB),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              const Color(0xFFDDE8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'FULFILLED QUANTITY',
                            style: TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 8.4,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                onPressed:
                                    selectedQuantity > 1
                                        ? () {
                                            setDialogState(
                                              () {
                                                selectedQuantity--;
                                              },
                                            );
                                          }
                                        : null,
                                icon: const Icon(
                                  Icons.remove_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  Text(
                                    '$selectedQuantity',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFF102C44),
                                      fontSize: 28,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    quantityUnit,
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFF7B8FA3),
                                      fontSize: 9.5,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              IconButton.filled(
                                onPressed:
                                    selectedQuantity <
                                            requestedWhole
                                        ? () {
                                            setDialogState(
                                              () {
                                                selectedQuantity++;
                                              },
                                            );
                                          }
                                        : null,
                                icon: const Icon(
                                  Icons.add_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: partial
                            ? const Color(0xFFFFF6E9)
                            : const Color(0xFFEAF8F2),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Text(
                        partial
                            ? '$returnedQuantity $quantityUnit will be returned to stock. '
                                'The vendor will pay only for the fulfilled quantity.'
                            : 'The full requested quantity will be fulfilled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: partial
                              ? const Color(0xFFB86500)
                              : const Color(0xFF147D64),
                          fontSize: 9.4,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF52677A),
                              side: const BorderSide(
                                color:
                                    Color(0xFFB9CBD7),
                              ),
                              minimumSize:
                                  const Size.fromHeight(47),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Go Back',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                selectedQuantity,
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF146BFF),
                              foregroundColor:
                                  Colors.white,
                              minimumSize:
                                  const Size.fromHeight(47),
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              partial
                                  ? 'Accept Partial'
                                  : 'Accept Full',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w900,
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
      },
    );

    return result?.toDouble();
  }

  Future<void> updateOrderStatus({
    required QueryDocumentSnapshot<Map<String, dynamic>>
        document,
    required String newStatus,
    required String paymentStatus,
  }) async {
    if (busyOrderIds.contains(document.id)) {
      return;
    }

    final data = document.data();
    final productName = firstString(
      data,
      const [
        'productName',
        'fishName',
      ],
      fallback: 'this fish product',
    );

    late final String title;
    late final String message;
    late final String confirmLabel;
    late final IconData icon;
    late final Color color;
    late final bool destructive;

    switch (newStatus.toLowerCase()) {
      case 'accepted':
        title = 'Accept this COD order?';
        message =
            'Confirm that you can fulfill the requested $productName quantity. The vendor will be notified.';
        confirmLabel = 'Accept Order';
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
        title = 'Cancel this COD order?';
        message =
            'The vendor will be notified and any reserved stock will be returned to the supplier inventory.';
        confirmLabel = 'Cancel Order';
        icon = Icons.cancel_outlined;
        color = const Color(0xFFD94A45);
        destructive = true;
        break;
      default:
        return;
    }

    double? acceptedFulfilledQuantity;

    if (newStatus.toLowerCase() == 'accepted') {
      acceptedFulfilledQuantity =
          await chooseFulfilledQuantity(
        document,
      );

      if (!mounted ||
          acceptedFulfilledQuantity == null) {
        return;
      }
    } else {
      final confirmed =
          await confirmStatusChange(
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

    setBusy(
      document.id,
      true,
    );

    try {
      await orderService.updateOrderStatus(
        documentId: document.id,
        newStatus: newStatus,
        paymentStatus: paymentStatus,
        fulfilledQuantity:
            acceptedFulfilledQuantity,
      );

      if (!mounted) {
        return;
      }

      final requestedQuantity =
          OrderHelpers.getDoubleValue(
        data,
        'quantity',
      );
      final acceptedPartial =
          newStatus.toLowerCase() == 'accepted' &&
              acceptedFulfilledQuantity != null &&
              acceptedFulfilledQuantity <
                  requestedQuantity;

      final successMessage =
          newStatus.toLowerCase() == 'cancelled'
              ? 'Order cancelled. Reserved stock and vendor notification were processed.'
              : newStatus.toLowerCase() == 'delivered'
                  ? 'Delivery and COD payment were recorded successfully.'
                  : acceptedPartial
                      ? 'Partial fulfillment accepted. The unfulfilled quantity was returned to stock and the vendor was notified.'
                      : 'Order accepted in full. The vendor was notified.';

      showMessage(successMessage);
    } on FirebaseException {
      showMessage(
        'Unable to update this COD order. Check your connection and try again.',
        isError: true,
      );
    } on StateError catch (error) {
      showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while updating this COD order.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setBusy(
          document.id,
          false,
        );
      }
    }
  }

  void clearSearchAndFilters() {
    searchController.clear();

    setState(() {
      selectedFilter = SupplierOrderFilter.all;
    });
  }

  Widget controlsCard({
    required List<
        QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00152A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search vendor, product, or order reference',
              hintStyle: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF146BFF),
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: searchController.clear,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF2F7FB),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFFE1EBF2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF146BFF),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SupplierOrderFilter.values.length,
              separatorBuilder: (
                context,
                index,
              ) {
                return const SizedBox(width: 7);
              },
              itemBuilder: (
                context,
                index,
              ) {
                final filter =
                    SupplierOrderFilter.values[index];
                final selected =
                    selectedFilter == filter;
                final count = countFilter(
                  documents: documents,
                  filter: filter,
                );

                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    filterIcon(filter),
                    size: 16,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF52677A),
                  ),
                  label: Text(
                    '${filterLabel(filter)} $count',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF52677A),
                      fontSize: 9.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onSelected: (
                    _,
                  ) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  backgroundColor:
                      const Color(0xFFF2F7FB),
                  selectedColor:
                      const Color(0xFF146BFF),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF146BFF)
                        : const Color(0xFFDCE7EF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget queueTitle(
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        0,
        2,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Order Queue',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Only COD orders assigned to this supplier account are shown.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count ${count == 1 ? 'order' : 'orders'}',
              style: const TextStyle(
                color: Color(0xFF146BFF),
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
    required List<
        QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  }) {
    final visibleDocuments = filteredDocuments(
      documents,
    );
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
      key: ValueKey(
        'supplier-orders-$streamRevision',
      ),
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SupplierOrdersHeader(
          documents: documents,
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                controlsCard(
                  documents: documents,
                ),
                queueTitle(
                  visibleDocuments.length,
                ),
                if (visibleDocuments.isEmpty)
                  SupplierOrdersEmptyCard(
                    filtered: documents.isNotEmpty &&
                        (selectedFilter !=
                                SupplierOrderFilter.all ||
                            searchController.text
                                .trim()
                                .isNotEmpty),
                    onClearFilters:
                        clearSearchAndFilters,
                  )
                else
                  ...visibleDocuments.map(
                    (
                      document,
                    ) {
                      return SupplierOrderCard(
                        document: document,
                        highlighted:
                            document.id == initialOrderId,
                        expanded:
                            expandedOrderIds.contains(
                          document.id,
                        ),
                        isBusy: busyOrderIds.contains(
                          document.id,
                        ),
                        onToggle: () {
                          setState(() {
                            if (expandedOrderIds.contains(
                              document.id,
                            )) {
                              expandedOrderIds.remove(
                                document.id,
                              );
                            } else {
                              expandedOrderIds.add(
                                document.id,
                              );
                            }
                          });
                        },
                        onAccept: () {
                          updateOrderStatus(
                            document: document,
                            newStatus: 'Accepted',
                            paymentStatus:
                                'To be paid on delivery',
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
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingBody() {
    return CustomScrollView(
      slivers: [
        SupplierOrdersHeader(
          documents: const [],
          onBack: () {
            Navigator.pop(context);
          },
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            28,
          ),
          sliver: SliverToBoxAdapter(
            child: SupplierOrdersLoadingCard(),
          ),
        ),
      ],
    );
  }

  Widget errorBody() {
    return CustomScrollView(
      slivers: [
        SupplierOrdersHeader(
          documents: const [],
          onBack: () {
            Navigator.pop(context);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            28,
          ),
          sliver: SliverToBoxAdapter(
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
      backgroundColor: Color(0xFFF4F8FB),
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
  Widget build(
    BuildContext context,
  ) {
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
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(streamRevision),
          stream: orderService.ordersStream(
            user.uid,
          ),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              return errorBody();
            }

            if (!snapshot.hasData) {
              return loadingBody();
            }

            final documents = OrderHelpers.sortDocuments(
              snapshot.data!.docs,
            );

            return content(
              documents: documents,
            );
          },
        ),
      ),
    );
  }
}
