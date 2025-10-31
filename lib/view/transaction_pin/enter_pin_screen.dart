import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/pin_view_model.dart';
import '../widgets/pin_entry_view.dart';

class EnterPinScreen extends StatefulWidget {
  final String? issuerUid;
  final String? chequeId;
  const EnterPinScreen({super.key, this.issuerUid, this.chequeId});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  bool _loading = false;

  Future<void> _onComplete(String pin) async {
    if (pin.trim().length < 4) return;
    final issuerUid = widget.issuerUid;
    final chequeId = widget.chequeId;
    // If no context provided, just return the PIN string to caller
    if (issuerUid == null || chequeId == null) {
      Navigator.of(context).pop(pin.trim());
      return;
    }

    setState(() => _loading = true);
    try {
      debugPrint('[EnterPin] calling stopCheque for cheque=$chequeId');
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('stopCheque');
      await callable.call({
        'issuerUid': issuerUid,
        'chequeId': chequeId,
        'pin': pin.trim(),
      });
      debugPrint('[EnterPin] success for cheque=$chequeId');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Success'),
          content: const Text('Cheque has been stopped successfully.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[EnterPin][CF_ERROR] code=${e.code} message=${e.message} details=${e.details}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to stop cheque')));
    } catch (e) {
      debugPrint('[EnterPin][ERROR] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to stop cheque')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PinViewModel>(
      create: (_) => PinViewModel()..setCurrentStep(0),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.white,
            body: Consumer<PinViewModel>(
              builder: (context, vm, _) {
                return PinEntryView(
                  vm: vm,
                  title: "Enter your PIN",
                  message: "Enter your 4-digit PIN to authorize stop cheque.",
                  showForgot: true,
                  onComplete: _onComplete,
                );
              },
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}
