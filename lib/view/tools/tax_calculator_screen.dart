import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echeque_mvp/localization/translation_provider.dart';
import '../../core/constants/app_colors.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _incomeCtrl = TextEditingController();
  final _deductionCtrl = TextEditingController();

  double? _taxable;
  double? _tax;

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _deductionCtrl.dispose();
    super.dispose();
  }

  void _compute() {
    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0.0;
    final deductions =
        double.tryParse(_deductionCtrl.text.replaceAll(',', '')) ?? 0.0;
    final taxable = (income - deductions).clamp(0, double.infinity).toDouble();

    // Simple India-like slab (illustrative only)
    double tax = 0.0;
    double remaining = taxable;

    double take(double slab, double rate) {
      final amt = remaining > slab ? slab : remaining;
      remaining -= amt;
      return amt * rate;
    }

    // 0 - 2.5L => 0%
    take(250000, 0.0);
    // 2.5L - 5L => 5%
    tax += take(250000, 0.05);
    // 5L - 10L => 20%
    tax += take(500000, 0.20);
    // >10L => 30%
    if (remaining > 0) tax += remaining * 0.30;

    setState(() {
      _taxable = taxable;
      _tax = tax;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TranslationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tp.t('Tax Calculator')),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.grey100,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tp.t('Annual Income'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deductionCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tp.t('Deductions (80C, HRA, etc.)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _compute,
              child: Text(tp.t('Calculate')),
            ),
          ),
          if (_taxable != null) ...[
            const SizedBox(height: 16),
            _ResultRow(
              label: tp.t('Taxable Income'),
              value: '₹${_taxable!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            _ResultRow(
              label: tp.t('Estimated Tax'),
              value: '₹${_tax!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            Text(
              tp.t(
                'Note: This is an approximate calculation for guidance only.',
              ),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
