import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:echeque_mvp/view/transaction_pin/enter_pin_screen.dart';

class StopChequeScreen extends StatefulWidget {
  const StopChequeScreen({super.key});

  @override
  State<StopChequeScreen> createState() => _StopChequeScreenState();
}

class _StopChequeScreenState extends State<StopChequeScreen> {
  bool _calling = false;

  Future<void> _confirmAndStop(
    String issuerUid,
    String chequeId,
    String chequeNo,
    double amount,
    String? payee,
  ) async {
    // Step 1: confirmation dialog with centered card
    debugPrint('[StopCheque] confirm dialog for cheque=$chequeId');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFFFECEC),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Confirm Stop Cheque',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payee ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            backgroundColor: const Color(0xFFFEF2F2),
                            label: Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Chip(
                            backgroundColor: Colors.blue.shade50,
                            label: Text(
                              'Cheque #$chequeNo',
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to stop this cheque? This action cannot be undone.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: AppColors.darkText,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Stop Cheque'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    // Step 2: PIN entry screen and verification
    debugPrint('[StopCheque] navigating to EnterPinScreen for cheque=$chequeId');
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const EnterPinScreen(),
        fullscreenDialog: true,
      ),
    );
    if (pin == null || pin.trim().length < 4) {
      debugPrint('[StopCheque] PIN entry cancelled/invalid for cheque=$chequeId');
      return;
    }

    setState(() => _calling = true);
    try {
      debugPrint('[StopCheque] calling stopCheque CF for cheque=$chequeId');
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('stopCheque');
      await callable.call({
        'issuerUid': issuerUid,
        'chequeId': chequeId,
        'pin': pin.trim(),
      });
      debugPrint('[StopCheque] CF success for cheque=$chequeId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cheque stopped successfully')),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[StopCheque][CF_ERROR] code=${e.code} message=${e.message} details=${e.details}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to stop cheque')),
      );
    } catch (e) {
      debugPrint('[StopCheque][ERROR] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop cheque')),
      );
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Stop Cheques',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.grey100,
      body: uid == null
          ? const Center(child: Text('Not signed in'))
          : Stack(
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('cheques')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    final docs = (snap.data?.docs ?? const [])
                        .where((d) => (d.data()['status']?.toString().toLowerCase() ?? '') == 'pending')
                        .toList();
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No cheques available to stop'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final status = (d['status']?.toString().toLowerCase() ?? 'pending');
                        final pending = status == 'pending';
                        final stopped = status == 'stopped';
                        final chequeId = docs[i].id;
                        final chequeNo = (d['chequeNo'] ?? '') as String;
                        final payee = d['payee']?.toString();
                        final amount = (d['amount'] is num)
                            ? (d['amount'] as num).toDouble()
                            : double.tryParse('${d['amount']}') ?? 0.0;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payee ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${amount.toStringAsFixed(2)}  •  Cheque #$chequeNo',
                                      style: const TextStyle(color: AppColors.mutedText),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (pending)
                                ElevatedButton(
                                  onPressed: _calling
                                      ? null
                                      : () => _confirmAndStop(uid, chequeId, chequeNo, amount, payee),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Stop'),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: stopped
                                        ? Colors.red.withOpacity(0.12)
                                        : AppColors.grey200.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: TextStyle(
                                      color: stopped ? Colors.red : AppColors.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                if (_calling)
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
    );
  }
}
