import 'package:echeque_mvp/view_model/quick_action_tile.dart';
import 'package:echeque_mvp/view/invoice/invoice_fill_screen.dart';
import 'package:echeque_mvp/view/deposit/deposit_fill_screen.dart';
import 'package:echeque_mvp/view/receipt/receipt_fill_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/quick_actions_view_model.dart';

class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuickActionsViewModel(),
      child: Consumer<QuickActionsViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: BackButton(color: Colors.black),
            title: Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 27,
                letterSpacing: -1.2,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 11),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: vm.actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 18,
                crossAxisSpacing: 7,
                childAspectRatio: 0.87,
              ),
              itemBuilder: (context, i) {
                final a = vm.actions[i];
                return QuickActionTile(
                  icon: a.icon,
                  bgColor: a.bgColor,
                  iconColor: a.iconColor,
                  title: a.title,
                  onTap: () {
                    if (a.title.trim().toLowerCase().startsWith('invoice')) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NewInvoiceScreen(),
                        ),
                      );
                    } else if (a.title.toLowerCase().contains('deposit')) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DepositSlipScreen(),
                        ),
                      );
                    } else if (a.title.toLowerCase().contains('receipt')) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReceiptSlipScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
