import 'package:flutter/material.dart';

class ExpenseDropdownTile extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String imageUrl;
  final String? label;
  final IconData Function(String name)? iconFor;

  const ExpenseDropdownTile({
    required this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.imageUrl = '',
    this.iconFor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFEFF3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        labelText: label,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE5E7EB)),
                    ),
                    alignment: Alignment.center,
                    child: iconFor != null
                        ? Icon(iconFor!(e), color: Colors.black54, size: 18)
                        : (imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                              )
                            : const Icon(Icons.image, color: Colors.grey)),
                  ),
                  Text(e, style: TextStyle(fontSize: 18, color: Colors.black)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
