import 'package:flutter/material.dart';

InputDecoration
postStockInputDecoration({
  required String label,
  required IconData icon,
  String? suffixText,
}) {
  return InputDecoration(
    labelText: label,
    suffixText: suffixText,
    labelStyle: const TextStyle(
      color: Color(
        0xFF7B8FA3,
      ),
      fontSize: 13,
    ),
    prefixIcon: Icon(
      icon,
      color: const Color(
        0xFF146BFF,
      ),
    ),
    filled: true,
    fillColor: const Color(
      0xFFF4F8FB,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        18,
      ),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        18,
      ),
      borderSide: const BorderSide(
        color: Color(
          0xFF146BFF,
        ),
        width: 1.4,
      ),
    ),
  );
}
