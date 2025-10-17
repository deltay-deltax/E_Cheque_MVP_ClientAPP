import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/categories_service.dart';
import '../../core/constants/app_colors.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameCtrl = TextEditingController();
  String _colorHex = '#2563EB';
  String _icon = 'category';
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Not signed in');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await CategoriesService.instance.addCategory(
        uid: uid,
        name: name,
        color: _colorHex,
        icon: _icon,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Add Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorChoices.map((h) => _ColorDot(
                hex: h,
                selected: _colorHex == h,
                onTap: () => setState(() => _colorHex = h),
              )).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _iconChoices.map((ic) => GestureDetector(
                onTap: () => setState(() => _icon = ic.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _icon == ic.key ? AppColors.primaryBlue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Icon(ic.value, color: _icon == ic.key ? AppColors.primaryBlue : Colors.black54),
                ),
              )).toList(),
            ),
            const Spacer(),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.hex, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color colorFromHex(String hex) {
      final v = hex.replaceAll('#', '');
      final parsed = int.tryParse(v, radix: 16) ?? 0x2563EB;
      return Color(0xFF000000 | parsed);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorFromHex(hex),
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.black : Colors.white, width: selected ? 2 : 1),
        ),
      ),
    );
  }
}

final _colorChoices = <String>[
  '#2563EB', '#6653ED', '#10B981', '#F59E0B', '#EF4444', '#0EA5E9',
];

final _iconChoices = <MapEntry<String, IconData>>[
  MapEntry('category', Icons.category),
  MapEntry('flight', Icons.flight),
  MapEntry('checkroom', Icons.checkroom),
  MapEntry('restaurant', Icons.fastfood),
  MapEntry('home', Icons.home),
];
