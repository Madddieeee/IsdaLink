import 'package:flutter/material.dart';

class ProductDescriptionCard
    extends
        StatelessWidget {
  const ProductDescriptionCard({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Description',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            description,
            style: const TextStyle(
              color: Color(
                0xFF52677A,
              ),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          ),
          const Row(
            children: [
              Icon(
                Icons.payments,
                color: Color(
                  0xFF146BFF,
                ),
                size: 20,
              ),
              SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  'Payment Method: Cash on Delivery only',
                  style: TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
