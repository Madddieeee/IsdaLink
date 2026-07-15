import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_section_card.dart';

class SupplierActivationInfoCard
    extends
        StatelessWidget {
  const SupplierActivationInfoCard({
    super.key,
    required this.businessNameController,
    required this.marketLocationController,
    required this.contactNumberController,
    required this.selectedSupplierType,
    required this.onSupplierTypeChanged,
  });

  final TextEditingController businessNameController;
  final TextEditingController marketLocationController;
  final TextEditingController contactNumberController;
  final String selectedSupplierType;
  final ValueChanged<
    String
  >
  onSupplierTypeChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SupplierActivationSectionCard(
      title: 'Supplier Information',
      subtitle: 'Set up the basic profile shown to vendors.',
      icon: Icons.badge,
      child: Column(
        children: [
          TextField(
            controller: businessNameController,
            decoration: SupplierActivationInputDecorations.inputDecoration(
              label: 'Business or Supplier Name',
              icon: Icons.storefront,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: marketLocationController,
            decoration: SupplierActivationInputDecorations.inputDecoration(
              label: 'Market Location / Service Area',
              icon: Icons.location_on,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: contactNumberController,
            keyboardType: TextInputType.phone,
            decoration: SupplierActivationInputDecorations.inputDecoration(
              label: 'Contact Number',
              icon: Icons.phone,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          DropdownButtonFormField<
            String
          >(
            initialValue: selectedSupplierType,
            decoration: SupplierActivationInputDecorations.inputDecoration(
              label: 'Supplier Type',
              icon: Icons.category,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Fish Supplier',
                child: Text(
                  'Fish Supplier',
                ),
              ),
              DropdownMenuItem(
                value: 'Fish Vendor',
                child: Text(
                  'Fish Vendor',
                ),
              ),
              DropdownMenuItem(
                value: 'Fish Trading Business',
                child: Text(
                  'Fish Trading Business',
                ),
              ),
            ],
            onChanged:
                (
                  value,
                ) {
                  if (value !=
                      null) {
                    onSupplierTypeChanged(
                      value,
                    );
                  }
                },
          ),
        ],
      ),
    );
  }
}
