class OrderModel {
  final String orderId;
  final String supplierName;
  final String productName;
  final double quantity;
  final String quantityUnit;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final DateTime orderDate;

  const OrderModel({
    required this.orderId,
    required this.supplierName,
    required this.productName,
    required this.quantity,
    required this.quantityUnit,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.orderDate,
  });
}
