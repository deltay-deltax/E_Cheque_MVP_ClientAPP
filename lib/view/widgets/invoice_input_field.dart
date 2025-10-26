import 'package:flutter/material.dart';

class InvoiceInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType? type;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const InvoiceInputField({
    required this.hint,
    this.controller,
    this.type,
    this.maxLines,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.initialValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines ?? 1,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 17),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 18,
          ),
          isDense: true,
        ),
      );
    }
    return TextFormField(
      initialValue: initialValue,
      keyboardType: type,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 18,
        ),
        isDense: true,
      ),
    );
  }
}
