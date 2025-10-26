import 'package:flutter/material.dart';

class DepositInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType? type;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const DepositInputField({
    required this.hint,
    this.controller,
    this.type,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
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
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFF7F9FC),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Color(0xFFE0E0E0))
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 13),
          isDense: true,
        ),
      );
    }
    return TextFormField(
      initialValue: initialValue,
      keyboardType: type,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF7F9FC),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 13),
        isDense: true,
      ),
    );
  }
}
