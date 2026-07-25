class AnalyticsData {
  const AnalyticsData({
    required this.completedOrders,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.topProducts,
    required this.stockAlerts,
    required this.dailySales,
    required this.simpleForecast,
    required this.seasonalForecast,
    required this.evaluation,
  });

  final int completedOrders;
  final double totalQuantity;
  final double totalRevenue;
  final List<ProductSalesSummary> topProducts;
  final List<StockAlertSummary> stockAlerts;
  final List<DailySalesPoint> dailySales;
  final double simpleForecast;
  final double seasonalForecast;
  final ForecastEvaluation evaluation;
}

class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productName,
    required this.emoji,
    required this.quantity,
    required this.revenue,
  });

  final String productName;
  final String emoji;
  final double quantity;
  final double revenue;
}

class StockAlertSummary {
  const StockAlertSummary({
    required this.productName,
    required this.supplierName,
    required this.emoji,
    required this.quantity,
    required this.quantityUnit,
    required this.lowStockLevel,
  });

  final String productName;
  final String supplierName;
  final String emoji;
  final double quantity;
  final String quantityUnit;
  final double lowStockLevel;
}

class DailySalesPoint {
  const DailySalesPoint({
    required this.date,
    required this.quantity,
    required this.revenue,
  });

  final DateTime date;
  final double quantity;
  final double revenue;
}

class ForecastEvaluation {
  const ForecastEvaluation({
    required this.mape,
    required this.mae,
    required this.hasEnoughData,
  });

  final double mape;
  final double mae;
  final bool hasEnoughData;
}
