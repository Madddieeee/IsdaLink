import 'package:flutter/material.dart';

class FishStockSubmitButton extends StatelessWidget {
  const FishStockSubmitButton({
    super.key,
    required this.isPosting,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isPosting;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canPublish = isEnabled && !isPosting;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 53,
          child: ElevatedButton.icon(
            onPressed: canPublish ? onPressed : null,
            icon: isPosting
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEnabled
                        ? Icons.publish_rounded
                        : Icons.fact_check_outlined,
                    size: 20,
                  ),
            label: Text(
              isPosting
                  ? 'Publishing Stock...'
                  : isEnabled
                      ? 'Publish Fish Stock'
                      : 'Complete Required Details',
              style: const TextStyle(
                fontSize: 14.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              disabledBackgroundColor:
                  const Color(0xFFDCE7EF),
              foregroundColor: Colors.white,
              disabledForegroundColor:
                  const Color(0xFF7B8FA3),
              elevation: canPublish ? 7 : 0,
              shadowColor: const Color(0x55146BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
