import 'package:flutter/material.dart';

InputDecoration postStockInputDecoration({
  required String label,
  required IconData icon,
  String? hintText,
  String? prefixText,
  String? suffixText,
  String? helperText,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixText: prefixText,
    suffixText: suffixText,
    helperText: helperText,
    errorText: errorText,
    errorMaxLines: 2,
    labelStyle: const TextStyle(
      color: Color(0xFF7B8FA3),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF146BFF),
      fontWeight: FontWeight.w900,
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF9AADBC),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    helperStyle: const TextStyle(
      color: Color(0xFF8299AA),
      fontSize: 9.6,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    errorStyle: const TextStyle(
      color: Color(0xFFD32F2F),
      fontSize: 10,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    prefixIcon: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4FD),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF146BFF),
        size: 20,
      ),
    ),
    suffixIcon: suffixIcon,
    prefixStyle: const TextStyle(
      color: Color(0xFF102C44),
      fontSize: 13,
      fontWeight: FontWeight.w900,
    ),
    suffixStyle: const TextStyle(
      color: Color(0xFF52677A),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
    filled: true,
    fillColor: const Color(0xFFF2F7FB),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 15,
      vertical: 17,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFE1EBF2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFF146BFF),
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFD32F2F),
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFD32F2F),
        width: 1.5,
      ),
    ),
  );
}
