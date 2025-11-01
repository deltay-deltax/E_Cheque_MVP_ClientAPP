import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../view_model/cheque_history_view_model.dart';

class ChequeCard extends StatelessWidget {
  final ChequeModel model;
  final bool showActions;
  final VoidCallback? onView;
  final Color? statusDotColor;

  const ChequeCard({
    required this.model,
    this.showActions = false,
    this.onView,
    this.statusDotColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (model.status) {
      case ChequeStatus.cleared:
        statusColor = AppColors.primaryGreen;
        statusText = "Cleared";
        break;
      case ChequeStatus.pending:
        statusColor = AppColors.primaryYellow;
        statusText = "Pending";
        break;
      case ChequeStatus.bounced:
        statusColor = Colors.grey;
        statusText = "Bounced";
        break;
      case ChequeStatus.rejected:
        statusColor = Colors.red;
        statusText = "Rejected";
        break;
      case ChequeStatus.stopped:
        statusColor = Colors.red;
        statusText = "Stopped";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: statusDotColor != null
            ? Border.all(color: statusDotColor!.withOpacity(0.9), width: 2.4)
            : null,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12.withOpacity(0.03),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.grey200,
            backgroundImage: model.avatarUrl != null
                ? NetworkImage(model.avatarUrl!)
                : null,
            child: model.avatarUrl == null
                ? Icon(
                    Icons.account_circle,
                    color: AppColors.primaryBlue,
                    size: 33,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              model.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  model.subText,
                  style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                ),
                const SizedBox(height: 7),
                Text(
                  "₹${model.amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color:
                        model.status == ChequeStatus.bounced ||
                            model.status == ChequeStatus.rejected
                        ? Colors.red
                        : AppColors.primaryGreen,
                  ),
                ),
                Text(
                  model.status == ChequeStatus.bounced ||
                          model.status == ChequeStatus.rejected
                      ? "Failed on ${model.dateText}"
                      : (model.status == ChequeStatus.pending
                            ? "Received on ${model.dateText}"
                            : (model.status == ChequeStatus.stopped
                                  ? "Stopped on ${model.dateText}"
                                  : "Credited on ${model.dateText}")),
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                ),
                if (showActions)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text(
                                model.status == ChequeStatus.pending
                                    ? "Accept"
                                    : (model.status == ChequeStatus.bounced
                                          ? "Contact"
                                          : "View Cheque"),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    model.status == ChequeStatus.pending
                                    ? AppColors.primaryGreen
                                    : (model.status == ChequeStatus.bounced
                                          ? Colors.grey
                                          : AppColors.primaryBlue),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: onView,
                              child: const Text("View Cheque"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onView,
                        child: Text("View Cheque"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
