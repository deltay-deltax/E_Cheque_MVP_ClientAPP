import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:echeque_mvp/view/widgets/deposit_input_field.dart';
import 'package:echeque_mvp/services/receipt_service.dart';
import 'package:echeque_mvp/view/transaction_pin/enter_pin_screen.dart';
import 'package:echeque_mvp/view/receipt/receipt_pdf.dart';
import 'package:printing/printing.dart';

class ReceiptSlipScreen extends StatefulWidget {
  const ReceiptSlipScreen({super.key});

  @override
  State<ReceiptSlipScreen> createState() => _ReceiptSlipScreenState();
}

class _ReceiptSlipScreenState extends State<ReceiptSlipScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _amountWordsCtrl = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountWordsCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged(String v) {
    final amt = double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    _amountWordsCtrl.text = _toIndianWords(amt);
    setState(() {});
  }

  String _toIndianWords(double v) {
    if (v <= 0) return '';
    int rupees = v.floor();
    int paise = ((v - rupees) * 100).round();

    // Prefer "Twelve Hundred" style for values like 1200
    String rupeeWords;
    if (rupees >= 1000 && rupees < 2000 && rupees % 100 == 0) {
      rupeeWords = _intToIndianWords((rupees / 100).round()) + ' Hundred';
    } else {
      rupeeWords = _intToIndianWords(rupees).trim();
    }
    String result = rupeeWords.isEmpty ? '' : '${rupeeWords} Rupees';
    if (paise > 0) {
      result += ' and ${_intToIndianWords(paise)} Paise';
    }
    return result.isEmpty ? '' : result;
  }

  String _intToIndianWords(int n) {
    if (n == 0) return 'Zero';
    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String twoDigits(int x) {
      if (x < 20) return ones[x];
      final t = x ~/ 10;
      final o = x % 10;
      return (tens[t] + (o > 0 ? ' ${ones[o]}' : '')).trim();
    }

    String threeDigits(int x) {
      final h = x ~/ 100;
      final rem = x % 100;
      final hPart = h > 0 ? '${ones[h]} Hundred' : '';
      final rPart = rem > 0 ? (hPart.isNotEmpty ? ' ' : '') + twoDigits(rem) : '';
      return (hPart + rPart).trim();
    }

    final parts = <String>[];
    final crore = n ~/ 10000000; // 1,00,00,000
    n %= 10000000;
    final lakh = n ~/ 100000; // 1,00,000
    n %= 100000;
    final thousand = n ~/ 1000; // 1,000
    n %= 1000;
    final hundred = n; // last three digits

    if (crore > 0) parts.add('${twoDigits(crore)} Crore');
    if (lakh > 0) parts.add('${twoDigits(lakh)} Lakh');
    if (thousand > 0) parts.add('${twoDigits(thousand)} Thousand');
    if (hundred > 0) parts.add(threeDigits(hundred));

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: const Text(
          "Receipt",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReceiptListScreen()),
              );
            },
            child: const Text('View Receipts'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};
          final bank = (data['bank'] as Map<String, dynamic>?) ?? {};
          final acctNo = (bank['accountNumber']?.toString() ?? '');
          final holder =
              (bank['holderName']?.toString() ??
              (data['fullName']?.toString() ?? ''));
          final acctType = (bank['type']?.toString() ?? 'Savings');

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            children: [
              _SectionCard(
                title: "Receiptor Information",
                children: [
                  DepositInputField(
                    hint: "Account Holder",
                    controller: TextEditingController(text: holder),
                    readOnly: true,
                  ),
                  const SizedBox(height: 6),
                  DepositInputField(
                    hint: "Account No.",
                    controller: TextEditingController(text: acctNo),
                    readOnly: true,
                  ),
                  const SizedBox(height: 6),
                  DepositInputField(
                    hint: "Account Type",
                    controller: TextEditingController(text: acctType),
                    readOnly: true,
                  ),
                ],
              ),

              _SectionCard(
                title: "Receipt Amount in Figures",
                children: [
                  DepositInputField(
                    hint: "Amount",
                    controller: _amountCtrl,
                    type: TextInputType.number,
                    onChanged: _onAmountChanged,
                  ),
                  const SizedBox(height: 6),
                  DepositInputField(
                    hint: "Amount in Words",
                    controller: _amountWordsCtrl,
                    readOnly: true,
                    maxLines: 2,
                  ),
                ],
              ),

              _SectionCard(
                title: "Declaration",
                children: [
                  Row(
                    children: [
                      Text(
                        "I agree to the terms and conditions",
                        style: TextStyle(fontSize: 15),
                      ),
                      Spacer(),
                      Switch(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v),
                        activeColor: Color(0xFF2272E5),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_agreed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please agree to the terms to proceed')),
                      );
                      return;
                    }
                    final pin = await Navigator.of(context).push<String>(
                      MaterialPageRoute(builder: (_) => const EnterPinScreen()),
                    );
                    if (pin == null || pin.trim().length < 4) return;

                    final payload = {
                      'accountHolderName': holder,
                      'accountNo': acctNo,
                      'accountType': acctType,
                      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
                      'amountInWords': _amountWordsCtrl.text,
                    };
                    await ReceiptService.instance.createReceipt(payload);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt created successfully'),
                        ),
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ReceiptListScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2272E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Create Receipt",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class ReceiptPdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ReceiptPdfPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Preview')),
      body: PdfPreview(
        build: (format) => ReceiptPdf.build(data),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}

class ReceiptListScreen extends StatelessWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ReceiptService.instance.streamUserReceipts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No receipts'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = items[i];
              final title = (d['id'] as String?) ?? 'Receipt';
              final subtitle = (d['createdAt'] as String?) ?? '';
              return ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptPdfPreviewScreen(data: d),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    final bytes = await ReceiptPdf.build(d);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: '${title}-receipt.pdf',
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2272E5),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}
