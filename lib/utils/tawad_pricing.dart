class TawadPricing {
  const TawadPricing._();

  static double? parseOfferedUnitPrice(String value) {
    final normalized = value.trim().replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  static String? validationMessage({
    required bool requested,
    required double listedUnitPrice,
    required double? offeredUnitPrice,
  }) {
    if (!requested) return null;
    if (offeredUnitPrice == null || offeredUnitPrice <= 0) {
      return 'Enter a valid Tawad price greater than zero.';
    }
    if (listedUnitPrice <= 0 || !listedUnitPrice.isFinite) {
      return 'The listed price is not valid for Tawad.';
    }
    if (offeredUnitPrice >= listedUnitPrice) {
      return 'Your Tawad price must be lower than the listed price.';
    }
    final scaledPrice = offeredUnitPrice * 100;
    if ((scaledPrice - scaledPrice.roundToDouble()).abs() > 0.000001) {
      return 'Use no more than two decimal places for the Tawad price.';
    }
    return null;
  }

  static double pendingDisplayUnitPrice({
    required bool requested,
    required double listedUnitPrice,
    required double? offeredUnitPrice,
  }) {
    return requested && offeredUnitPrice != null
        ? offeredUnitPrice
        : listedUnitPrice;
  }

  static double acceptedUnitPrice(Map<String, dynamic> orderData) {
    final requested = orderData['tawadRequested'] == true;
    final offer = orderData['tawadOfferedUnitPrice'];
    final listed = orderData['unitPrice'];
    if (requested && offer is num) return offer.toDouble();
    return listed is num ? listed.toDouble() : 0;
  }
}
