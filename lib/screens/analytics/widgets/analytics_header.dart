import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';

class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({
    super.key,
    required this.isSupplierMode,
    required this.hasSupplierAccess,
    required this.completedOrders,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.onBack,
    required this.onModeChanged,
  });

  final bool isSupplierMode;
  final bool hasSupplierAccess;
  final int completedOrders;
  final double totalQuantity;
  final double totalRevenue;
  final VoidCallback onBack;
  final ValueChanged<bool> onModeChanged;

  String get title => isSupplierMode ? 'Supplier Analytics' : 'Vendor Analytics';

  String get subtitle {
    return isSupplierMode
        ? 'Sales analytics from completed COD orders received by this supplier account.'
        : 'Purchase analytics from completed COD orders made by this vendor account.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102C44), Color(0xFF146BFF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFDCE9F5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (hasSupplierAccess) ...[
            const SizedBox(height: 15),
            AnalyticsModeSelector(
              isSupplierMode: isSupplierMode,
              onModeChanged: onModeChanged,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              AnalyticsStatCard(value: '$completedOrders', label: 'Completed', icon: Icons.receipt_long),
              AnalyticsStatCard(value: formatAnalyticsNumber(totalQuantity), label: 'Quantity', icon: Icons.scale),
              AnalyticsStatCard(value: formatCurrency(totalRevenue), label: isSupplierMode ? 'Sales' : 'Amount', icon: Icons.analytics),
            ],
          ),
        ],
      ),
    );
  }
}

class AnalyticsModeSelector extends StatelessWidget {
  const AnalyticsModeSelector({super.key, required this.isSupplierMode, required this.onModeChanged});

  final bool isSupplierMode;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: AnalyticsModeButton(label: 'Vendor View', isSelected: !isSupplierMode, onTap: () => onModeChanged(false))),
          Expanded(child: AnalyticsModeButton(label: 'Supplier View', isSelected: isSupplierMode, onTap: () => onModeChanged(true))),
        ],
      ),
    );
  }
}

class AnalyticsModeButton extends StatelessWidget {
  const AnalyticsModeButton({super.key, required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF146BFF) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class AnalyticsStatCard extends StatelessWidget {
  const AnalyticsStatCard({super.key, required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(36)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFDCE9F5), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
