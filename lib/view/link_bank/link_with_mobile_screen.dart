import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/bank_link_view_model.dart';
import '../../core/routes/app_routes.dart';
import '../../services/bank_service.dart';
import '../../services/user_service.dart';

class LinkWithMobileScreen extends StatelessWidget {
  const LinkWithMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return ChangeNotifierProvider(
      create: (_) => BankLinkViewModel(),
      child: Consumer<BankLinkViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.white,
            leading: BackButton(color: Colors.black),
            title: Text(
              "Link Mobile Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 21,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 38),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.blueBackground,
                  child: Icon(
                    Icons.phone_iphone,
                    size: 44,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Enter your mobile number",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "We'll use this number to link to your bank accounts.",
                  style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 33),
                TextField(
                  controller: controller,
                  onChanged: vm.setMobileNumber,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "+1 (555) 987-6543",
                    hintStyle: TextStyle(
                      fontSize: 17,
                      color: AppColors.mutedText,
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 18,
                    ),
                  ),
                  style: TextStyle(fontSize: 18),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 3, right: 3),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "By continuing, you agree to our ",
                          style: TextStyle(color: Colors.black, fontSize: 15),
                          children: [
                            TextSpan(
                              text: "Terms of Service",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: " and "),
                            TextSpan(
                              text: "Privacy Policy.",
                              style: TextStyle(
                                color: Colors.deepPurple,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            final phone = vm.mobileNumber.trim();
                            if (phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter mobile number')),
                              );
                              return;
                            }
                            try {
                              final data = await BankService.instance.findByPhone(phone);
                              if (data == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No bank user found for this mobile number')),
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
                            "Continue",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
