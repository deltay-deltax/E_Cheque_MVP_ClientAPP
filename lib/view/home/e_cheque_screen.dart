import 'package:echeque_mvp/view/home/cheque_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/cheque_view_model.dart';
import '../../view/widgets/custom_text_field.dart';
import '../../services/cheque_service.dart';
import '../../services/user_service.dart';
import 'cheque_received_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../transaction_pin/enter_pin_screen.dart';

class EChequeScreen extends StatefulWidget {
  const EChequeScreen({super.key});

  @override
  State<EChequeScreen> createState() => _EChequeScreenState();
}

class _EChequeScreenState extends State<EChequeScreen> {
  late final TextEditingController _payeeController;
  late final TextEditingController _amountController;
  // Removed bank controller; bank name sourced from linked bank
  late final TextEditingController _notesController;
  late final TextEditingController _dateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _accountController;
  late final TextEditingController _signatureController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final vm = ChequeViewModel();
    _payeeController = TextEditingController(text: vm.payee);
    _amountController = TextEditingController(text: vm.amount);
    _notesController = TextEditingController(text: vm.notes);
    _dateController = TextEditingController(
      text: vm.date != null
          ? "${vm.date!.month.toString().padLeft(2, '0')}/${vm.date!.day.toString().padLeft(2, '0')}/${vm.date!.year}"
          : "",
    );
    _phoneController = TextEditingController();
    _accountController = TextEditingController();
    _signatureController = TextEditingController(text: vm.signaturePath);
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChequeViewModel(),
      child: Consumer<ChequeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.grey100,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: BackButton(color: Colors.black),
              centerTitle: true,
              title: Text(
                "E-Cheque",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 25,
                ),
              ),
            ),
            body: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.all(18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(31),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black12.withOpacity(0.03),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _payeeController,
                            hintText: "Payee Name",
                            prefixIcon: Icons.person,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _payeeController.addListener(() {
                                if (vm.payee != _payeeController.text) {
                                  vm.setPayee(_payeeController.text);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 19),
                          CustomTextField(
                            controller: _amountController,
                            hintText: "Amount",
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _amountController.addListener(() {
                                if (vm.amount != _amountController.text) {
                                  vm.setAmount(_amountController.text);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 19),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _dateController,
                                  hintText: "MM/DD/YYYY",
                                  prefixIcon: Icons.calendar_today_outlined,
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000, 1),
                                      lastDate: DateTime(2100, 12),
                                    );
                                    if (picked != null) {
                                      vm.setDate(picked);
                                      _dateController.text =
                                          "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  color: AppColors.grey600,
                                ),
                                onPressed: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000, 1),
                                    lastDate: DateTime(2100, 12),
                                  );
                                  if (picked != null) {
                                    vm.setDate(picked);
                                    _dateController.text =
                                        "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
                                  }
                                },
                              ),
                            ],
                          ),
                          // Bank name removed; taken from linked bank at submit
                          const SizedBox(height: 19),
                          CustomTextField(
                            controller: _phoneController,
                            hintText: "Receiver Phone (optional)",
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _phoneController.addListener(() {
                                if (vm.receiverPhone != _phoneController.text) {
                                  vm.setReceiverPhone(_phoneController.text);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 19),
                          CustomTextField(
                            controller: _accountController,
                            hintText: "Receiver Account Number (optional)",
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.numbers,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _accountController.addListener(() {
                                if (vm.receiverAccount !=
                                    _accountController.text) {
                                  vm.setReceiverAccount(
                                    _accountController.text,
                                  );
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 19),
                          CustomTextField(
                            controller: _notesController,
                            hintText: "Notes (Optional)",
                            prefixIcon: Icons.notes,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _notesController.addListener(() {
                                if (vm.notes != _notesController.text) {
                                  vm.setNotes(_notesController.text);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 27),
                          Text(
                            "Signature (type your name)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _signatureController,
                            hintText: "e.g. John Doe",
                            prefixIcon: Icons.draw,
                            onTap: null,
                          ),
                          Builder(
                            builder: (_) {
                              _signatureController.addListener(() {
                                if (vm.signaturePath !=
                                    _signatureController.text) {
                                  vm.setSignaturePath(
                                    _signatureController.text,
                                  );
                                }
                              });
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : () async {
                                      // Basic validation (bank name removed, auto-fetched)
                                      if (vm.payee.trim().isEmpty ||
                                          vm.amount.trim().isEmpty ||
                                          vm.date == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all required fields (payee, amount, date).',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      setState(() => _submitting = true);
                                      // Navigate to EnterPinScreen to capture PIN
                                      final pin = await Navigator.of(context)
                                          .push<String>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const EnterPinScreen(),
                                            ),
                                          );
                                      if (pin == null || pin.length != 4) {
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      if (pin.length != 4) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'PIN must be 4 digits',
                                            ),
                                          ),
                                        );
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      final verified = await UserService
                                          .instance
                                          .verifyTransactionPin(pin);
                                      if (!verified) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Incorrect PIN'),
                                          ),
                                        );
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      // Fetch issuer bank name from linked bank
                                      final uid = FirebaseAuth
                                          .instance
                                          .currentUser
                                          ?.uid;
                                      if (uid == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Not authenticated'),
                                          ),
                                        );
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      final userDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(uid)
                                          .get();
                                      final bankName =
                                          (userDoc.data()?['bank']?['bankName'])
                                              ?.toString() ??
                                          '';
                                      if (bankName.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please link your bank before issuing a cheque',
                                            ),
                                          ),
                                        );
                                        setState(() => _submitting = false);
                                        return;
                                      }
                                      try {
                                        await ChequeService.instance.createCheque(
                                          payee: vm.payee.trim(),
                                          amount: vm.amount.trim(),
                                          date: vm.date!,
                                          bankName: bankName,
                                          notes: vm.notes.trim().isEmpty
                                              ? null
                                              : vm.notes.trim(),
                                          // Reuse signaturePath field to store typed signature text
                                          signaturePath: vm.signaturePath,
                                          receiverPhone:
                                              vm.receiverPhone.trim().isEmpty
                                              ? null
                                              : vm.receiverPhone.trim(),
                                          receiverAccount:
                                              vm.receiverAccount.trim().isEmpty
                                              ? null
                                              : vm.receiverAccount.trim(),
                                          status: 'pending',
                                        );
                                        if (!context.mounted) return;
                                        // Navigate to received cheques screen
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ChequeHistoryScreen(),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to submit cheque: $e',
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted)
                                          setState(() => _submitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Submit Cheque",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_submitting)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: Container(color: Colors.black26),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
