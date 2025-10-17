import 'package:echeque_mvp/view/widgets/expense_dropdown_tile.dart';
import 'package:echeque_mvp/view/widgets/expense_invoice_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/expense_view_model.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseViewModel(),
      child: Consumer<ExpenseViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color.fromARGB(255, 244, 238, 238),
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            leading: BackButton(color: Colors.white),
            title: const Text(
              "Add Expense",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(
                top: 45,
                bottom: 19,
                left: 15,
                right: 15,
              ),
              padding: const EdgeInsets.all(22),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Text(
                    "NAME",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ExpenseDropdownTile(
                    value: vm.selectedName,
                    items: vm.expenseNames,
                    iconFor: vm.iconForCategoryName,
                    imageUrl:
                        "",
                    onChanged: (value) {
                      if (value != null) vm.setSelectedName(value);
                    },
                  ),
                  const SizedBox(height: 13),
                  Text(
                    "WRITE NAME",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    decoration: InputDecoration(
                      fillColor: Color(0xFFF7F7F7),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Enter name",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    style: TextStyle(fontSize: 18, color: Colors.black),
                    onChanged: vm.setWriteName,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    "AMOUNT",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vm.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            // Allow only digits and one decimal point
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            hintText: '0.00',
                          ),
                          style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (val) {
                            // Prevent multiple decimals
                            final parts = val.split('.');
                            if (parts.length > 2) {
                              final fixed = parts[0] + '.' + parts.sublist(1).join('');
                              vm.setAmount(fixed);
                            } else {
                              vm.setAmount(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTap: vm.clearAmount,
                        child: Text(
                          "Clear",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    "DATE",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          "${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][vm.selectedDate.weekday % 7]}, "
                          "${vm.selectedDate.day.toString().padLeft(2, '0')} "
                          "${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][vm.selectedDate.month - 1]} "
                          "${vm.selectedDate.year}",
                    ),
                    decoration: InputDecoration(
                      fillColor: Color(0xFFF7F7F7),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Pick a date",
                      hintStyle: TextStyle(
                        fontSize: 17,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          color: Colors.grey[700],
                        ),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: vm.selectedDate,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) vm.setDate(picked);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    "INVOICE",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ExpenseInvoiceBox(onAddInvoice: vm.addInvoice),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await vm.saveExpense();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense saved')),
                          );
                        }
                      },
                      child: const Text(
                        'Save Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
