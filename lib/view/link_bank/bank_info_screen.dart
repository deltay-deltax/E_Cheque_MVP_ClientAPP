import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class BankInfoScreen extends StatelessWidget {
  const BankInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.black),
        title: Text(
          "Bank Information",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 19),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.blueBackground,
              child: Icon(
                Icons.account_balance,
                size: 44,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 35),
            Text(
              "No bank account added yet.",
              style: TextStyle(fontSize: 17, color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Add your bank account to start receiving payments.",
              style: TextStyle(fontSize: 17, color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.linkWithMobile),
                icon: Icon(Icons.phone_iphone, color: Colors.white),
                label: Text(
                  "Link with Mobile Number",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.bankAdd),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Link with Bank Account",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Why Add Your Bank Info?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.darkText,
                ),
              ),
            ),
            const SizedBox(height: 22),
            ...[
              {
                "title": "Receive Payments Securely",
                "desc": "Get paid directly to your bank account.",
              },
              {
                "title": "Fast & Automatic Transfers",
                "desc": "No more waiting for manual payouts.",
              },
              {
                "title": "Encrypted & Safe",
                "desc": "Your financial information is always protected.",
              },
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["title"]!,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            item["desc"]!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
