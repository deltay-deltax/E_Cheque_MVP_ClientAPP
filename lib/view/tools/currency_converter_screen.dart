import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echeque_mvp/localization/translation_provider.dart';
import '../../core/constants/app_colors.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountCtrl = TextEditingController();
  String _from = 'INR';
  String _to = 'USD';
  double? _result;

  final _rates = <String, double>{
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.0095,
    'AED': 0.044,
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _convert() {
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;
    final inInr = amt / (_rates[_from] ?? 1.0);
    final out = inInr * (_rates[_to] ?? 1.0);
    setState(() => _result = out);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TranslationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tp.t('Currency Converter')),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.grey100,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tp.t('Amount'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _CurrencyPicker(label: tp.t('From'), value: _from, onChanged: (v){ setState(()=>_from=v); })),
              const SizedBox(width: 10),
              Expanded(child: _CurrencyPicker(label: tp.t('To'), value: _to, onChanged: (v){ setState(()=>_to=v); })),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _convert,
              child: Text(tp.t('Convert')),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${tp.t('Result')}: ${_to} ${_result!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tp.t('Rates are indicative and for demo only.'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _CurrencyPicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const ['INR','USD','EUR','GBP','AED'];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v){ if(v!=null) onChanged(v); },
        ),
      ),
    );
  }
}
