import 'package:echeque_mvp/view/widgets/deposit_input_field.dart';
import 'package:echeque_mvp/view_model/deposit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echeque_mvp/services/deposit_service.dart';
import 'package:echeque_mvp/view/deposit/deposit_pdf.dart';
import 'package:printing/printing.dart';
import 'package:echeque_mvp/view/transaction_pin/enter_pin_screen.dart';

class DepositSlipScreen extends StatelessWidget {
  const DepositSlipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DepositSlipViewModel(),
      child: Consumer<DepositSlipViewModel>(
        builder: (context, vm, _) {
          final slipNoController = TextEditingController(text: vm.slipNo);
          final slipDateController = TextEditingController(
            text: vm.slipDate == null
                ? "Select Date"
                : "${vm.slipDate!.toLocal()}".split(' ')[0],
          );
          // using initialValue fields to prevent cursor jump issues

          return Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            appBar: AppBar(
              backgroundColor: Color(0xFFF7F9FC),
              elevation: 0,
              title: const Text(
                "Deposit Slip",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
              leading: BackButton(color: Colors.black),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DepositListScreen(),
                      ),
                    );
                  },
                  child: const Text('View Deposits'),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              children: [
                // Deposit Details
                _SectionCard(
                  title: "Deposit Details",
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DepositInputField(
                            hint: "",
                            controller: slipNoController,
                            readOnly: true,
                          ),
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: DepositInputField(
                            hint: "Select Date",
                            controller: slipDateController,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                _SectionCard(
                  title: "Depositor Information",
                  children: [
                    DepositInputField(
                      hint: "Enter Name",
                      initialValue: vm.depositorName,
                      onChanged: (v) => vm.setField(depositorName: v),
                    ),
                    SizedBox(height: 6),
                    DepositInputField(
                      hint: "Enter Contact",
                      initialValue: vm.depositorContact,
                      onChanged: (v) => vm.setField(depositorContact: v),
                    ),
                    SizedBox(height: 6),
                    DepositInputField(
                      hint: "Enter Address",
                      initialValue: vm.depositorAddress,
                      onChanged: (v) => vm.setField(depositorAddress: v),
                    ),
                  ],
                ),

                _SectionCard(
                  title: "Account Information",
                  children: [
                    DepositInputField(
                      hint: "Enter Account Holder Name",
                      initialValue: vm.accountHolderName,
                      onChanged: (v) => vm.setField(accountHolderName: v),
                    ),
                    SizedBox(height: 6),
                    DepositInputField(
                      hint: "Account No.",
                      initialValue: vm.accountNo,
                      onChanged: (v) => vm.setField(accountNo: v),
                    ),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: vm.accountType,
                      items: ["Savings", "Current"]
                          .map(
                            (s) => DropdownMenuItem(child: Text(s), value: s),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF7F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 13,
                        ),
                      ),
                      onChanged: (v) => vm.setAccountType(v ?? "Savings"),
                    ),
                  ],
                ),

                _SectionCard(
                  title: "Cash Breakdown",
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Denomination",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          child: Text("Count", style: TextStyle(fontSize: 15)),
                        ),
                        Expanded(
                          child: Text("Total", style: TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                    ...[2000, 500, 200, 100].map(
                      (denom) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "₹$denom",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DepositInputField(
                                hint: "0",
                                initialValue: (vm.cashBreakdown[denom] ?? 0)
                                    .toString(),
                                type: TextInputType.number,
                                onChanged: (v) {
                                  final count = int.tryParse(v) ?? 0;
                                  vm.updateCash(denom, count);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '₹${(denom * (vm.cashBreakdown[denom] ?? 0)).toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                _SectionCard(
                  title: "Deposit Amount in Figures",
                  children: [
                    DepositInputField(
                      hint: "Amount (auto)",
                      controller: TextEditingController(
                        text: vm.cashBreakdownTotal.toStringAsFixed(2),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 5),
                    DepositInputField(
                      hint: "Amount in Words",
                      controller: TextEditingController(text: vm.amountInWords),
                      readOnly: true,
                      maxLines: 2,
                    ),
                  ],
                ),

                _SectionCard(
                  title: "Purpose of Deposit",
                  children: [
                    ...vm.depositPurposeOptions.map(
                      (label) => CheckboxListTile(
                        dense: true,
                        value: vm.selectedPurposes.contains(label),
                        onChanged: (v) => vm.selectPurpose(label),
                        title: Text(label, style: TextStyle(fontSize: 15)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
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
                          value: vm.agreed,
                          onChanged: vm.agree,
                          activeColor: Color(0xFF2272E5),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 6),

                Container(
                  margin: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: ElevatedButton(
                      onPressed: () async {
                        final pin = await Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const EnterPinScreen()),
                        );
                        if (pin == null || pin.trim().length < 4) return;
                        final data = {
                          'slipNo': vm.slipNo,
                          'slipDate': vm.slipDate?.toIso8601String() ?? '',
                          'depositorName': vm.depositorName,
                          'depositorContact': vm.depositorContact,
                          'depositorAddress': vm.depositorAddress,
                          'accountHolderName': vm.accountHolderName,
                          'accountNo': vm.accountNo,
                          'accountType': vm.accountType,
                          'cashBreakdown': vm.cashBreakdown.map(
                            (k, v) => MapEntry(k.toString(), v),
                          ),
                          'cashBreakdownTotal': vm.cashBreakdownTotal
                              .toStringAsFixed(2),
                          'depositAmount': vm.cashBreakdownTotal
                              .toStringAsFixed(2),
                          'amountInWords': vm.amountInWords,
                          'selectedPurposes': vm.selectedPurposes,
                          'agreed': vm.agreed,
                          'enteredPinLength': pin.trim().length,
                        };
                        await DepositService.instance.createDeposit(data);
                        vm.reset();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deposit created successfully')),
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const DepositListScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2272E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Create & Download (Customer)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DepositPdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DepositPdfPreviewScreen({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Preview')),
      body: PdfPreview(
        build: (format) => DepositPdf.build(data, bankCopy: false),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}

class DepositListScreen extends StatelessWidget {
  const DepositListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposits')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DepositService.instance.streamUserDeposits(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No deposits'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = items[i];
              final title = (d['slipNo'] as String?) ?? d['id'];
              return ListTile(
                title: Text(title),
                subtitle: Text((d['slipDate'] as String?) ?? ''),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DepositPdfPreviewScreen(data: d)),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    final bytes = await DepositPdf.build(d, bankCopy: false);
                    await Printing.sharePdf(bytes: bytes, filename: '${title}-customer.pdf');
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
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF2272E5),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}
