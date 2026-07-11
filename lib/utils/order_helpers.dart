import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderHelpers {
  static Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'all':
        return const Color(
          0xFF102C44,
        );
      case 'pending':
        return const Color(
          0xFFFF7A1A,
        );
      case 'accepted':
        return const Color(
          0xFF146BFF,
        );
      case 'delivered':
        return const Color(
          0xFF2E7D32,
        );
      case 'cancelled':
        return const Color(
          0xFFD32F2F,
        );
      default:
        return const Color(
          0xFF7B8FA3,
        );
    }
  }

  static IconData statusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.list_alt;
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }

  static String filterDescription(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'All COD order records from your account.';
      case 'pending':
        return 'Orders waiting for supplier response.';
      case 'accepted':
        return 'Orders approved by the supplier.';
      case 'delivered':
        return 'Completed COD orders.';
      case 'cancelled':
        return 'Declined or cancelled orders.';
      default:
        return 'Order records.';
    }
  }

  static String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  static double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }

  static String formatNumber(
    double value,
  ) {
    if (value %
            1 ==
        0) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      2,
    );
  }

  static String formatDateFromData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final value = data['createdAt'];

    if (value
        is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    return 'Just now';
  }

  static int createdAtMillis(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final value = document.data()['createdAt'];

    if (value
        is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  static List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  sortDocuments(
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
    final sortedDocuments = [
      ...documents,
    ];

    sortedDocuments.sort(
      (
        a,
        b,
      ) =>
          createdAtMillis(
            b,
          ).compareTo(
            createdAtMillis(
              a,
            ),
          ),
    );

    return sortedDocuments;
  }

  static int countByStatus(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
    String status,
  ) {
    if (status.toLowerCase() ==
        'all') {
      return documents.length;
    }

    return documents.where(
      (
        document,
      ) {
        final orderStatus = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return orderStatus.toLowerCase() ==
            status.toLowerCase();
      },
    ).length;
  }

  static List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  filterOrders({
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
    required String selectedFilter,
  }) {
    if (selectedFilter.toLowerCase() ==
        'all') {
      return documents;
    }

    return documents.where(
      (
        document,
      ) {
        final orderStatus = getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        );

        return orderStatus.toLowerCase() ==
            selectedFilter.toLowerCase();
      },
    ).toList();
  }
}
