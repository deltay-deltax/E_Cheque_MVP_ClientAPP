import 'package:echeque_mvp/view/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/transactions_view_model.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionsViewModel(),
      child: Consumer<TransactionsViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FC),
            elevation: 0,
            title: const Text(
              "Transactions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 29,
                color: Color(0xFF16202C),
              ),
            ),
            centerTitle: true,
            leading: BackButton(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.black, size: 29),
                onPressed: () {},
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search transactions...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF818181),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: vm.search,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      text: "All",
                      isSelected: vm.selectedType == TransactionType.all,
                      onTap: () => vm.setType(TransactionType.all),
                    ),
                    _FilterChip(
                      text: "Income",
                      isSelected: vm.selectedType == TransactionType.income,
                      onTap: () => vm.setType(TransactionType.income),
                    ),
                    _FilterChip(
                      text: "Expense",
                      isSelected: vm.selectedType == TransactionType.expense,
                      onTap: () => vm.setType(TransactionType.expense),
                    ),
                    _FilterChip(
                      text: "Pending",
                      isSelected: vm.selectedType == TransactionType.pending,
                      onTap: () => vm.setType(TransactionType.pending),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${vm.filteredTransactions.length} transactions",
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "₹${vm.totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF16202C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (vm.filteredTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    'No transactions',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else
                ...vm.filteredTransactions
                    .map((t) => TransactionCard(tx: t))
                    .toList(),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6653ED) : Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF16202C),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
