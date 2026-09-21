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
      fontSize: 10.8,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF146BFF),
      fontSize: 10.8,
      fontWeight: FontWeight.w900,
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF9AADBC),
      fontSize: 10.8,
      fontWeight: FontWeight.w600,
    ),
    helperStyle: const TextStyle(
      color: Color(0xFF8299AA),
      fontSize: 9.1,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    errorStyle: const TextStyle(
      color: Color(0xFFD32F2F),
      fontSize: 9.2,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    prefixIcon: Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF146BFF), size: 18),
    ),
    suffixIcon: suffixIcon,
    prefixStyle: const TextStyle(
      color: Color(0xFF102C44),
      fontSize: 11.5,
      fontWeight: FontWeight.w900,
    ),
    suffixStyle: const TextStyle(
      color: Color(0xFF52677A),
      fontSize: 10,
      fontWeight: FontWeight.w800,
    ),
    filled: true,
    fillColor: const Color(0xFFF3F8FB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE1EBF2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF146BFF), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD32F2F)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.4),
    ),
  );
}
