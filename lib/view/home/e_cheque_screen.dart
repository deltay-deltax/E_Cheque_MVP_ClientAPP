import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/cheque_view_model.dart';
import '../../view/widgets/custom_text_field.dart';
import '../../view/widgets/custom_file_upload_box.dart';
import '../../services/cheque_service.dart';
import 'cheque_history_screen.dart';

class EChequeScreen extends StatelessWidget {
  const EChequeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChequeViewModel(),
      child: Consumer<ChequeViewModel>(
        builder: (context, vm, _) {
          final payeeController = TextEditingController(text: vm.payee);
          final amountController = TextEditingController(text: vm.amount);
          final bankController = TextEditingController(text: vm.bankName);
          final notesController = TextEditingController(text: vm.notes);
          final dateController = TextEditingController(
            text: vm.date != null
                ? "${vm.date!.month.toString().padLeft(2, '0')}/${vm.date!.day.toString().padLeft(2, '0')}/${vm.date!.year}"
                : "",
          );

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
            body: Center(
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
                        controller: payeeController,
                        hintText: "Payee Name",
                        prefixIcon: Icons.person,
                        onTap: null,
                      ),
                      // Keep vm in sync
                      Builder(builder: (_) {
                        payeeController.addListener(() {
                          if (vm.payee != payeeController.text) {
                            vm.setPayee(payeeController.text);
                          }
                        });
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 19),
                      CustomTextField(
                        controller: amountController,
                        hintText: "Amount",
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.currency_rupee,
                        onTap: null,
                      ),
                      Builder(builder: (_) {
                        amountController.addListener(() {
                          if (vm.amount != amountController.text) {
                            vm.setAmount(amountController.text);
                          }
                        });
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 19),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: dateController,
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
                              }
                            },
                          ),
                        ],
                      ),
                      Builder(builder: (_) {
                        bankController.addListener(() {
                          if (vm.bankName != bankController.text) {
                            vm.setBankName(bankController.text);
                          }
                        });
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 19),
                      CustomTextField(
                        controller: notesController,
                        hintText: "Notes (Optional)",
                        prefixIcon: Icons.notes,
                        onTap: null,
                      ),
                      Builder(builder: (_) {
                        notesController.addListener(() {
                          if (vm.notes != notesController.text) {
                            vm.setNotes(notesController.text);
                          }
                        });
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 27),
                      Text(
                        "Digital Signature",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomFileUploadBox(
                        fileName: vm.signaturePath.isNotEmpty
                            ? vm.signaturePath
                            : null,
                        onUpload: () {
                          // TODO: Use file picker; for now keep filename text only
                          // vm.setSignaturePath(file.path.split('/').last);
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Basic validation
                            if (vm.payee.trim().isEmpty ||
                                vm.amount.trim().isEmpty ||
                                vm.bankName.trim().isEmpty ||
                                vm.date == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all required fields (payee, amount, date, bank).'),
                                ),
                              );
                              return;
                            }
                            try {
                              await ChequeService.instance.createCheque(
                                payee: vm.payee.trim(),
                                amount: vm.amount.trim(),
                                date: vm.date!,
                                bankName: vm.bankName.trim(),
                                notes: vm.notes.trim().isEmpty ? null : vm.notes.trim(),
                                signaturePath: vm.signaturePath,
                                status: 'pending',
                              );
                              if (!context.mounted) return;
                              // Navigate to history screen
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ChequeHistoryScreen(),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to submit cheque: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
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
          );
        },
      ),
    );
  }
}
