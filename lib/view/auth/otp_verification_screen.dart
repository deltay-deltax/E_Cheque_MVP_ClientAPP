import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? initialPhone;
  final VoidCallback? onVerified;
  const OtpVerificationScreen({super.key, this.initialPhone, this.onVerified});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _phoneController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  String? _verificationId;
  bool _sending = false;
  bool _verifying = false;
  String _error = '';

  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.text =
        widget.initialPhone ??
        (FirebaseAuth.instance.currentUser?.phoneNumber ?? '');
    // Prefill from Firestore if missing; then auto-send once
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_phoneController.text.trim().isEmpty) {
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            final data = snap.data();
            final dbPhone = (data?['phone'] as String?) ?? '';
            if (dbPhone.trim().isNotEmpty) {
              _phoneController.text = dbPhone.trim();
            }
          }
        } catch (_) {}
      }
      if (_phoneController.text.trim().isNotEmpty && !_sending) {
        _sendCode();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _codeControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending) return; // avoid duplicate concurrent requests
    var phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      // Default to India code if not provided
      phone = '+91${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Enter phone number');
      return;
    }
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Auto-retrieval on Android
          await _linkOrSignIn(credential);
        },
        verificationFailed: (e) {
          setState(() {
            _error = e.message ?? e.code;
            _sending = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _sending = false;
            _restartTimer();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verifyCode() async {
    if ((_verificationId ?? '').isEmpty) {
      setState(() => _error = 'Please request code first');
      return;
    }
    final code = _codeControllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = '';
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _linkOrSignIn(credential);
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _linkOrSignIn(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.linkWithCredential(credential);
        } catch (e) {
          // If already linked, update phone via re-auth/sign-in
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      setState(() => _verifying = false);

      // Delegate next steps to caller: they will navigate to Create/Confirm/Success PIN screens
      if (widget.onVerified != null) widget.onVerified!();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = List.generate(6, (i) {
      return SizedBox(
        width: 40,
        child: TextField(
          controller: _codeControllers[i],
          focusNode: _focusNodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF4F5FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCDD3E1)),
            ),
          ),
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) {
              _focusNodes[i + 1].requestFocus();
            } else if (v.isEmpty && i > 0) {
              // backspace navigation
              _focusNodes[i - 1].requestFocus();
              _codeControllers[i - 1].text = '';
            }
          },
        ),
      );
    });

    return WillPopScope(
      onWillPop: () async {
        _timer?.cancel();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: const BackButton(color: Colors.black87),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const SizedBox(height: 8),
            const Text(
              'We just sent an SMS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enter the security code we sent to '),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _sending ? null : () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...boxes
                    .expand((w) => [w, const SizedBox(width: 10)])
                    .toList()
                    .sublist(0, 11),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: _sending ? null : _sendCode,
                  icon: _sending
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sms),
                  label: Text(
                    _seconds > 0 ? 'Verify phone number (00:${_seconds.toString().padLeft(2, '0')})' : 'Verify phone number',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6653ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _verifying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
            // Resend controls hidden per product requirement
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
