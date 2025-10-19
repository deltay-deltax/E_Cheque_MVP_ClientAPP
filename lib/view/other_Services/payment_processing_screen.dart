import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echeque_mvp/view_model/send_money_view_model.dart';
import 'package:echeque_mvp/view/home/home_screen.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final SendMoneyViewModel vm;
  const PaymentProcessingScreen({super.key, required this.vm});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure any open keyboard is dismissed when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
    // Trigger send when page loads, if not already triggered
    Future.microtask(() async {
      if (!widget.vm.sending && !widget.vm.sent) {
        await widget.vm.send();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SendMoneyViewModel>.value(
      value: widget.vm,
      child: Consumer<SendMoneyViewModel>(
        builder: (context, vm, _) {
          final isProcessing = vm.sending && !vm.sent;
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            body: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isProcessing
                    ? _ProcessingView()
                    : _SuccessView(vm: vm),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Processing your payment...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final SendMoneyViewModel vm;
  const _SuccessView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isMobile = vm.selectedMethod == 1;
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 84),
        const SizedBox(height: 12),
        const Text(
          'Payment Successful',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          '₹${vm.quickAmount}',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _line('Method', isMobile ? 'Mobile Money' : 'Bank Transfer'),
        if (isMobile) _line('To', vm.receiver.isEmpty ? '-' : vm.receiver) else ...[
          _line('Bank', vm.bankName.isEmpty ? '-' : vm.bankName),
          _line('Account', vm.bankAccount.isEmpty ? '-' : vm.bankAccount),
          _line('IFSC', vm.bankIfsc.isEmpty ? '-' : vm.bankIfsc),
        ],
        if ((vm.categoryName ?? '').isNotEmpty) _line('Category', vm.categoryName!),
        if (vm.note.isNotEmpty) _line('Note', vm.note),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Go to Home'),
          ),
        ),
      ],
    );
  }

  Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
