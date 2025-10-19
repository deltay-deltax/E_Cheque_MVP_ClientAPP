import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const String adminEmail = 'admin@gmail.com';

  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController(); // e.g., user_001
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountTypeCtrl = TextEditingController(text: 'savings');
  final _bankNameCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountTypeCtrl.dispose();
    _bankNameCtrl.dispose();
    _branchCtrl.dispose();
    _ifscCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me?.email != adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authorized')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final bankUsers = FirebaseFirestore.instance.collection('bankUsers');
      final uid = _uidCtrl.text.trim();
      final bal = double.tryParse(_balanceCtrl.text.trim()) ?? 0.0;
      final data = {
        'uid': uid,
        'fullName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'accountNumber': _accountNumberCtrl.text.trim(),
        'accountType': _accountTypeCtrl.text.trim(),
        'bankName': _bankNameCtrl.text.trim(),
        'branch': _branchCtrl.text.trim(),
        'ifsc': _ifscCtrl.text.trim(),
        'balance': bal,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await bankUsers.doc(uid).set(data, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('bankUsers/$uid saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isAdmin = me?.email == adminEmail;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Bank Users'),
        backgroundColor: AppColors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isAdmin ? _buildForm() : _notAuthorized(),
    );
  }

  Widget _notAuthorized() {
    return const Center(child: Text('Not authorized'));
  }

  Widget _buildForm() {
    return AbsorbPointer(
      absorbing: _submitting,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_uidCtrl, 'UID (e.g., user_001)', validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              _field(_fullNameCtrl, 'Full Name'),
              _field(_emailCtrl, 'Email'),
              _field(_phoneCtrl, 'Phone'),
              _field(_accountNumberCtrl, 'Account Number'),
              _field(_accountTypeCtrl, 'Account Type'),
              _field(_bankNameCtrl, 'Bank Name'),
              _field(_branchCtrl, 'Branch'),
              _field(_ifscCtrl, 'IFSC'),
              _field(_balanceCtrl, 'Balance (number)', keyboard: TextInputType.number),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save bank user'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {String? Function(String?)? validator, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
