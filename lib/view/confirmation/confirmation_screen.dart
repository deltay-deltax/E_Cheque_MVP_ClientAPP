import 'package:flutter/material.dart';
import 'package:echeque_mvp/core/constants/app_colors.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _KV('Savings balance', '₹10,000'),
      _KV('Fixed deposit', '₹20,000'),
      _KV('Gold loan', '₹30,000'),
      _KV('Debtors', '₹10,000'),
      _KV('Creditors', '₹5,000'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirmation',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.grey100,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Account Confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(items.length, (i) {
                final it = items[i];
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.k,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          it.v,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    if (i != items.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blueBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a confirmation summary for display purposes.',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KV {
  final String k;
  final String v;
  const _KV(this.k, this.v);
}
