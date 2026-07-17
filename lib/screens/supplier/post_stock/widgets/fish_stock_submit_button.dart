import 'package:flutter/material.dart';

class FishStockSubmitButton
    extends
        StatelessWidget {
  const FishStockSubmitButton({
    super.key,
    required this.isPosting,
    required this.onPressed,
  });

  final bool isPosting;
  final VoidCallback onPressed;

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
            onPressed: isPosting
                ? null
                : onPressed,
            icon: isPosting
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.add_box,
                  ),
            label: Text(
              isPosting
                  ? 'Saving to Firebase...'
                  : 'Post Fish Stock',
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
