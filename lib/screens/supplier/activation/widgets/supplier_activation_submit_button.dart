import 'package:flutter/material.dart';

class SupplierActivationSubmitButton
    extends
        StatelessWidget {
  const SupplierActivationSubmitButton({
    super.key,
    required this.onPressed,
    required this.isSubmitting,
  });

  final VoidCallback onPressed;
  final bool isSubmitting;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(
              0x14000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isSubmitting
                ? null
                : onPressed,
            icon: isSubmitting
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.send,
                  ),
            label: Text(
              isSubmitting
                  ? 'Submitting Application...'
                  : 'Submit Supplier Application',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF146BFF,
              ),
              disabledBackgroundColor: const Color(
                0xFF7B8FA3,
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
