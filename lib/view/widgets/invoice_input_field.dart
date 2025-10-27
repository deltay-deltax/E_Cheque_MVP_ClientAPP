import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvoiceInputField extends StatefulWidget {
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
  State<InvoiceInputField> createState() => _InvoiceInputFieldState();
}

class _InvoiceInputFieldState extends State<InvoiceInputField> {
  TextEditingController? _internal;

  TextEditingController get _ctrl => widget.controller ?? _internal!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internal = TextEditingController(text: widget.initialValue ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant InvoiceInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null) {
      if (_internal == null) _internal = TextEditingController();
      final newText = widget.initialValue ?? '';
      if (_internal!.text != newText && !_ctrl.selection.isValid) {
        _internal!.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kType = widget.type ?? TextInputType.text;
    return TextField(
      controller: _ctrl,
      keyboardType: kType,
      maxLines: widget.maxLines ?? 1,
      readOnly: widget.readOnly,
      inputFormatters: kType == TextInputType.number
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      onTap: () {
        widget.onTap?.call();
        // Move caret to end for natural typing
        final len = _ctrl.text.length;
        _ctrl.selection = TextSelection.collapsed(offset: len);
      },
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
