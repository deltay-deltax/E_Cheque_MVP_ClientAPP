import 'package:echeque_mvp/services/user_service.dart';
import 'package:echeque_mvp/view/transaction_pin/enter_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/send_money_view_model.dart';
import '../../services/categories_service.dart';
import 'payment_processing_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendMoneyScreen extends StatelessWidget {
  final int initialAmount;
  final String? initialReceiver;
  const SendMoneyScreen({
    super.key,
    this.initialAmount = 0,
    this.initialReceiver,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SendMoneyViewModel()
        ..initialize(
          initialAmount: initialAmount,
          prefillReceiver: initialReceiver,
        ),
      child: Consumer<SendMoneyViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            title: const Text(
              "Send Money",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF222943),
                fontSize: 27,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                children: [
                  // Quick Send section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(23),
                    margin: const EdgeInsets.only(bottom: 25),
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(
                                0xFF456EEB,
                              ).withOpacity(0.27),
                              radius: 28,
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 31,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Quick Send",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                Text(
                                  "Send money to your favorite\ncontacts instantly",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: vm.quickAmounts.map((amt) {
                            final isSelected = vm.quickAmount == amt;
                            return GestureDetector(
                              onTap: () => vm.selectQuickAmount(amt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(0xFF0745C2)
                                      : Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(0xFF93B8F5)
                                        : Color(0xFF266CEB),
                                    width: 1.4,
                                  ),
                                ),
                                child: Text(
                                  "₹${amt}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Transfer Method
                  const Text(
                    "Transfer Method",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: vm.methods.asMap().entries.map((entry) {
                      final i = entry.key;
                      final method = entry.value;
                      final selected = method.isSelected;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => vm.selectMethod(i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? method.color
                                    : const Color(0xFFD6E3FA),
                                width: selected ? 1.6 : 1.0,
                              ),
                              boxShadow: [
                                if (selected)
                                  BoxShadow(
                                    color: method.color.withOpacity(0.07),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  method.icon,
                                  color: method.color,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF192A4D),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Send to",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 9),
                  if (vm.selectedMethod == 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5F8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: vm.contactSearchController,
                        decoration: InputDecoration(
                          hintText: "Enter UPI ID or phone ...",
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF818181),
                          ),
                        ),
                        onChanged: vm.updateContactSearch,
                      ),
                    ),
                  ],
                  if (vm.selectedMethod == 1 &&
                      vm.searchSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (_, i) {
                          final s = vm.searchSuggestions[i];
                          return ListTile(
                            leading: const Icon(Icons.person_search),
                            title: Text(s['label'] ?? ''),
                            subtitle: Text(s['value'] ?? ''),
                            onTap: () => vm.applySuggestion(s),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: vm.searchSuggestions.length,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (vm.topPayees.isNotEmpty) ...[
                    const Text(
                      "Top payees",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vm.topPayees
                          .take(5)
                          .map(
                            (p) => ActionChip(
                              avatar: const CircleAvatar(
                                child: Icon(Icons.person, size: 16),
                              ),
                              label: Text(p.label),
                              onPressed: () => vm.updateReceiver(p.value),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          spreadRadius: 1,
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Amount (₹)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Enter amount in ₹",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: vm.amountController,
                          onChanged: vm.updateAmount,
                        ),
                        const SizedBox(height: 12),
                        // Category dropdown
                        FutureBuilder<List<Category>>(
                          future: (() async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null || uid.isEmpty) return <Category>[];
                            // Ensure defaults exist, then load
                            await CategoriesService.instance
                                .ensureDefaultCategories(uid);
                            return CategoriesService.instance
                                .streamUserCategories(uid)
                                .first;
                          })(),
                          builder: (context, snap) {
                            var cats = snap.data ?? [];
                            if (cats.isEmpty) {
                              final now = Timestamp.now();
                              cats = [
                                Category(
                                  id: 'def_travel',
                                  userId: '',
                                  name: 'Travelling',
                                  color: '#2563EB',
                                  icon: 'flight',
                                  createdAt: now,
                                ),
                                Category(
                                  id: 'def_fashion',
                                  userId: '',
                                  name: 'Fashion',
                                  color: '#6653ED',
                                  icon: 'checkroom',
                                  createdAt: now,
                                ),
                                Category(
                                  id: 'def_food',
                                  userId: '',
                                  name: 'Food & Drink',
                                  color: '#10B981',
                                  icon: 'restaurant',
                                  createdAt: now,
                                ),
                                Category(
                                  id: 'def_house',
                                  userId: '',
                                  name: 'House',
                                  color: '#F59E0B',
                                  icon: 'home',
                                  createdAt: now,
                                ),
                              ];
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Category",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  value: vm.categoryId,
                                  items: [
                                    ...cats.map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ),
                                    ),
                                    const DropdownMenuItem(
                                      value: '__other__',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (id) {
                                    if (id == '__other__') {
                                      vm.setCategory(
                                        id: '__other__',
                                        name: 'Other',
                                      );
                                    } else {
                                      final c = cats.firstWhere(
                                        (e) => e.id == id,
                                        orElse: () => cats.isNotEmpty
                                            ? cats.first
                                            : Category(
                                                id: '',
                                                userId: '',
                                                name: '',
                                                color: '#2563EB',
                                                icon: 'category',
                                                createdAt: Timestamp.fromDate(
                                                  DateTime.now(),
                                                ),
                                              ),
                                      );
                                      vm.setCategory(id: c.id, name: c.name);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                        if (vm.selectedMethod == 1) ...[
                          const Text(
                            "Receiver (UPI ID / Phone)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: "e.g. name@bank or +91...",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: vm.receiverController,
                            onChanged: vm.updateReceiver,
                          ),
                        ] else ...[
                          const Text(
                            "Bank Name",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: "e.g. HDFC Bank",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: vm.updateBankName,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Account Number",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: "Enter account number",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: vm.updateBankAccount,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "IFSC Code",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: "e.g. HDFC0001234",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: vm.updateBankIfsc,
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          "Note (optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: "What is this for?",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: vm.updateNote,
                        ),
                        const SizedBox(height: 14),
                        if (vm.error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              vm.error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: vm.sending
                                ? null
                                : () async {
                                    if (vm.quickAmount <= 0) {
                                      vm.setError('Enter an amount');
                                      return;
                                    }

                                    // Centered confirmation dialog
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          title: const Text('Confirm Payment'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${vm.quickAmount}',
                                                    style: const TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEFF3FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      vm.selectedMethod == 1
                                                          ? 'Mobile Money'
                                                          : 'Bank Transfer',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              if (vm.selectedMethod == 1) ...[
                                                _kv(
                                                  'Receiver',
                                                  vm.receiver.isEmpty
                                                      ? '-'
                                                      : vm.receiver,
                                                ),
                                              ] else ...[
                                                _kv(
                                                  'Bank',
                                                  vm.bankName.isEmpty
                                                      ? '-'
                                                      : vm.bankName,
                                                ),
                                                _kv(
                                                  'Account',
                                                  vm.bankAccount.isEmpty
                                                      ? '-'
                                                      : vm.bankAccount,
                                                ),
                                                _kv(
                                                  'IFSC',
                                                  vm.bankIfsc.isEmpty
                                                      ? '-'
                                                      : vm.bankIfsc,
                                                ),
                                              ],
                                              if (vm.note.isNotEmpty)
                                                _kv('Note', vm.note),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2563EB,
                                                ),
                                              ),
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text(
                                                'Confirm',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirmed != true) return;

                                    final pin = await Navigator.of(context)
                                        .push<String>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const EnterPinScreen(),
                                          ),
                                        );
                                    if (pin == null) return;
                                    final ok = await UserService.instance
                                        .verifyTransactionPin(pin);
                                    if (!ok) {
                                      vm.setError('Invalid PIN');
                                      return;
                                    }
                                    // Navigate to the full-screen processing page
                                    if (!context.mounted) return;
                                    FocusScope.of(context).unfocus();
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PaymentProcessingScreen(vm: vm),
                                      ),
                                    );
                                  },
                            icon: vm.sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              vm.sending
                                  ? "Processing..."
                                  : (vm.sent
                                        ? "Paid"
                                        : "Send ₹${vm.quickAmount}"),
                            ),
                          ),
                        ),
                        if (vm.sent)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF22C55E),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Payment successful",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(k, style: const TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
