import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/bank_service.dart';
import '../services/notification_service.dart';

class TransferMethod {
  final String label;
  final IconData icon;
  final Color color;
  final String cost;
  final bool isSelected;
  TransferMethod(
    this.label,
    this.icon,
    this.color,
    this.cost, {
    this.isSelected = false,
  });
}

class RecentContact {
  final String initials;
  final String name;
  final String phone;
  final Color avatarColor;
  final bool favorite;

  RecentContact(
    this.initials,
    this.name,
    this.phone,
    this.avatarColor, {
    this.favorite = false,
  });
}

class SendMoneyViewModel extends ChangeNotifier {
  int quickAmount = 0;
  int selectedMethod = 0;
  String contactSearch = '';
  String receiver = '';
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController contactSearchController = TextEditingController();
  String bankName = '';
  String bankAccount = '';
  String bankIfsc = '';
  String note = '';
  String error = '';
  bool sending = false;
  bool sent = false;
  final TextEditingController amountController = TextEditingController();
  String? categoryId;
  String? categoryName;

  final List<int> quickAmounts = [50, 100, 200, 500, 1000, 2000];

  List<TransferMethod> get methods => [
    TransferMethod(
      "Bank Transfer",
      Icons.account_balance,
      Color(0xFF2563EB),
      "Free",
      isSelected: selectedMethod == 0,
    ),
    TransferMethod(
      "Mobile Money",
      Icons.phone_android,
      Color(0xFF10B981),
      "\$0.99",
      isSelected: selectedMethod == 1,
    ),
  ];

  // Top payees chips and search suggestions
  List<_PayeeChip> topPayees = [];
  List<Map<String, String>> searchSuggestions = [];

  SendMoneyViewModel() {
    _loadTopPayees();
  }

  void initialize({int initialAmount = 0, String? prefillReceiver}) {
    if (initialAmount > 0) quickAmount = initialAmount;
    if (prefillReceiver != null && prefillReceiver.isNotEmpty) {
      receiver = prefillReceiver;
      receiverController.text = prefillReceiver;
    }
    notifyListeners();
  }

  void applySuggestion(Map<String, String> s) {
    final val = s['value'] ?? '';
    if (val.isNotEmpty) {
      updateReceiver(val);
      contactSearch = '';
      try { contactSearchController.text = ''; } catch (_) {}
      searchSuggestions = [];
      notifyListeners();
    }
  }

  List<RecentContact> get recentContacts => [
    RecentContact(
      "JS",
      "John Smith",
      "+1 (555) 123-4567",
      Color(0xFF2563EB),
      favorite: true,
    ),
    RecentContact(
      "SJ",
      "Sarah Johnson",
      "+1 (555) 987-6543",
      Color(0xFF22C55E),
      favorite: true,
    ),
  ];

  void selectQuickAmount(int value) {
    quickAmount = value;
    final txt = value.toString();
    if (amountController.text != txt) {
      amountController.text = txt;
      amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: amountController.text.length),
      );
    }
    notifyListeners();
  }

  void selectMethod(int idx) {
    selectedMethod = idx;
    notifyListeners();
  }

  void updateContactSearch(String val) {
    contactSearch = val;
    _searchBankUsers(val);
    notifyListeners();
  }

  void updateReceiver(String val) {
    receiver = val;
    if (receiverController.text != val) {
      receiverController.text = val;
      receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: receiverController.text.length),
      );
    }
    notifyListeners();
  }

  void updateBankName(String val) {
    bankName = val;
    notifyListeners();
  }

  void updateBankAccount(String val) {
    bankAccount = val;
    notifyListeners();
  }

  void updateBankIfsc(String val) {
    bankIfsc = val;
    notifyListeners();
  }

  void updateNote(String val) {
    note = val;
    notifyListeners();
  }

  void setCategory({required String id, required String name}) {
    categoryId = id;
    categoryName = name;
    notifyListeners();
  }

  void setError(String message) {
    error = message;
    sent = false;
    sending = false;
    notifyListeners();
  }

  void updateAmount(String s) {
    final v = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    quickAmount = v;
    notifyListeners();
  }

  Future<void> send() async {
    if (sending) return;
    error = '';
    sent = false;
    final amount = quickAmount;
    if (amount <= 0) {
      error = 'Enter an amount';
      notifyListeners();
      return;
    }
    if (selectedMethod == 1) {
      if (receiver.trim().isEmpty) {
        error = 'Enter UPI ID or phone';
        notifyListeners();
        return;
      }
    } else {
      if (bankName.trim().isEmpty || bankAccount.trim().isEmpty || bankIfsc.trim().isEmpty) {
        error = 'Enter bank name, account and IFSC';
        notifyListeners();
        return;
      }
    }
    sending = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('not_authenticated');

      final db = FirebaseFirestore.instance;
      final txCol = db.collection('transactions');

      // Resolve receiver: for mobile, by UPI/phone; for bank transfer, by account
      String? receiverUid;
      if (selectedMethod == 1) {
        receiverUid = await _resolveReceiverUid(receiver);
      } else {
        if (bankAccount.trim().isNotEmpty) {
          try {
            final bank = await BankService.instance.findByAccount(bankAccount.trim());
            final email = bank?['email'] as String?;
            if (email != null && email.isNotEmpty) {
              final users = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (users.docs.isNotEmpty) receiverUid = users.docs.first.id;
            }
          } catch (_) {}
        }
      }

      // Only create the sender's debit transaction; server function will handle balances and receiver credit.
      final now = FieldValue.serverTimestamp();
      final isMobile = selectedMethod == 1;
      final sourceLabel = isMobile ? 'mpay' : 'bank';
      // Fetch sender's account number to include in details for server-side mapping
      String? fromAccount;
      try {
        final userDoc = await db.collection('users').doc(uid).get();
        fromAccount = (userDoc.data()?['bank']?['accountNumber'])?.toString();
      } catch (_) {}
      final details = isMobile
          ? {
              'upiOrPhone': receiver,
              if (fromAccount != null && fromAccount.isNotEmpty) 'fromAccount': fromAccount,
            }
          : {
              'toBankName': bankName,
              'toAccount': bankAccount,
              'toIfsc': bankIfsc,
              if (fromAccount != null && fromAccount.isNotEmpty) 'fromAccount': fromAccount,
            };
      await txCol.add({
        'userId': uid,
        'direction': 'debit',
        'amount': amount,
        'chequeId': '',
        'chequeNo': '',
        'counterpartyUid': receiverUid,
        'bankName': isMobile ? '' : bankName,
        'at': now,
        'source': sourceLabel,
        'method': isMobile ? 'mobile' : 'bank_transfer',
        'status': 'Completed',
        'note': note.isNotEmpty
            ? note
            : (isMobile ? 'Mpay to $receiver' : 'Bank transfer to $bankName ($bankAccount)'),
        'payeeName': isMobile ? receiver : (bankName.isNotEmpty ? bankName : 'Bank Transfer'),
        'details': details,
        if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
        if (categoryName != null && categoryName!.isNotEmpty) 'categoryName': categoryName,
      });

      // Notifications
      try {
        await NotificationService.instance.send(
          toUid: uid,
          type: 'tx_sent',
          title: 'Payment sent',
          body: 'You paid ₹$amount ${isMobile ? 'to $receiver' : 'via bank transfer'}',
          data: {
            'amount': amount,
            'method': isMobile ? 'mobile' : 'bank_transfer',
          },
        );
        if (receiverUid != null && receiverUid.isNotEmpty && receiverUid != uid) {
          await NotificationService.instance.send(
            toUid: receiverUid,
            type: 'tx_received',
            title: 'Payment received',
            body: 'You received ₹$amount',
            data: {
              'amount': amount,
              'fromUid': uid,
            },
          );
        }
      } catch (_) {}

      sent = true;
    } catch (e) {
      error = e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<String?> _resolveReceiverUid(String input) async {
    try {
      String? email;
      String trimmed = input.trim();
      final digitsOnly = RegExp(r'^\+?\d{8,15} ? ?');
      if (trimmed.contains('@') && !trimmed.contains('@upi')) {
        email = trimmed;
      } else if (digitsOnly.hasMatch(trimmed)) {
        final bank = await BankService.instance.findByPhone(trimmed);
        email = bank?["email"] as String?;
      }
      if (email == null || email.isEmpty) return null;
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (users.docs.isEmpty) return null;
      return users.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadTopPayees() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .where('direction', isEqualTo: 'debit')
          .orderBy('at', descending: true)
          .limit(200)
          .get();
      final Map<String, int> counts = {};
      final Map<String, String> labels = {};
      for (final d in snap.docs) {
        final data = d.data();
        final payee = (data['payeeName'] as String?)?.trim();
        final to = (data['details'] as Map<String, dynamic>?)?['upiOrPhone'] as String?;
        final key = (to?.isNotEmpty == true ? to! : (payee?.isNotEmpty == true ? payee! : ''));
        if (key.isEmpty) continue;
        counts.update(key, (v) => v + 1, ifAbsent: () => 1);
        labels[key] = payee?.isNotEmpty == true ? payee! : key;
      }
      final entries = counts.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      final list = entries
          .map((e) => _PayeeChip(label: labels[e.key] ?? e.key, value: e.key))
          .toList();
      topPayees = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _searchBankUsers(String q) async {
    try {
      final term = q.trim();
      if (term.isEmpty) {
        searchSuggestions = [];
        notifyListeners();
        return;
      }
      List<Map<String, dynamic>> results = [];
      if (term.contains('@')) {
        results = await BankService.instance.searchByUpiPrefix(term, limit: 5);
      } else {
        results = await BankService.instance.searchByPhonePrefix(term, limit: 5);
      }
      searchSuggestions = results
          .map((r) => {
                'label': (r['name'] as String?) ?? (r['phone'] as String? ?? r['upi'] as String? ?? ''),
                'value': (term.contains('@') ? (r['upi'] as String?) : (r['phone'] as String?)) ?? '',
              })
          .where((m) => m['value']!.isNotEmpty)
          .toList();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

}

class _PayeeChip {
  final String label;
  final String value;
  _PayeeChip({required this.label, required this.value});
}
