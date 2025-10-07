import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/bank_link_view_model.dart';
import '../../core/routes/app_routes.dart';
import '../../services/bank_service.dart';
import '../../services/user_service.dart';

class BankAddModalScreen extends StatelessWidget {
  const BankAddModalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BankLinkViewModel(),
      child: Consumer<BankLinkViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.1),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.91,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 28,
                            color: Colors.black54,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.blueBackground,
                            child: Icon(
                              Icons.account_balance,
                              size: 44,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Bank Information",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    _BankTextField(
                      label: "Account holder's Name",
                      hint: "Name as registered with the bank",
                      onChanged: vm.setAccHolderName,
                    ),
                    _BankTextField(
                      label: "Bank Account Number",
                      hint: "Your unique account identifier",
                      onChanged: vm.setAccNumber,
                    ),
                    _BankTextField(
                      label: "ISFC Code",
                      hint: "The bank's code for transferring funds.",
                      onChanged: vm.setIfsc,
                    ),
                    _BankTextField(
                      label: "Bank Name",
                      hint: "Name of the bank where the account is",
                      onChanged: vm.setBankName,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Account Type",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: vm.accType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          child: Text("Saving Account"),
                          value: "Saving Account",
                        ),
                        DropdownMenuItem(
                          child: Text("Current Account"),
                          value: "Current Account",
                        ),
                      ],
                      onChanged: vm.setAccType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grey100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          final acc = vm.accNumber.trim();
                          if (acc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter account number')),
                            );
                            return;
                          }
                          try {
                            final data = await BankService.instance.findByAccount(acc);
                            if (data == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No bank user found for this account number')),
                              );
                              return;
                            }
                            await UserService.instance.linkBankToUser(data);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bank details linked. Set your transaction PIN.')),
                            );
                            Navigator.pushNamed(context, AppRoutes.pinCreate);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Add Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BankTextField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  const _BankTextField({
    required this.label,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 5),
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 16, color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 13,
              ),
            ),
            style: TextStyle(fontSize: 17),
          ),
        ],
      ),
    );
  }
}
