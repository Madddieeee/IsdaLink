class TawadEligibility {
  const TawadEligibility._();

  static bool isQualifyingOrder(Map<String, dynamic> orderData) {
    final orderStatus = orderData['orderStatus']
        ?.toString()
        .trim()
        .toLowerCase();
    final paymentStatus = orderData['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    return (orderStatus == 'delivered' || orderStatus == 'completed') &&
        paymentStatus == 'paid';
  }
}
