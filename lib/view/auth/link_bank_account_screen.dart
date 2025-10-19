import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LinkBankAccountScreen extends StatefulWidget {
  const LinkBankAccountScreen({super.key});

  @override
  State<LinkBankAccountScreen> createState() => _LinkBankAccountScreenState();
}

class _LinkBankAccountScreenState extends State<LinkBankAccountScreen> {
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _balance = TextEditingController();
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _bankName.dispose();
    _accountNumber.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final bankName = _bankName.text.trim();
    final account = _accountNumber.text.trim();
    final bal = double.tryParse(_balance.text.trim().isEmpty ? '0' : _balance.text.trim()) ?? 0.0;
    if (bankName.isEmpty || account.isEmpty) {
      setState(() => _error = 'Enter bank name and account number');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'bank': {
          'bankName': bankName,
          'accountNumber': account,
          'balance': bal,
        }
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Bank Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _bankName, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _accountNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            const Text('Initial Balance (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _balance, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
