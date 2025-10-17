import 'package:echeque_mvp/view/widgets/analytics_category_card.dart';
import 'package:echeque_mvp/view/widgets/analytics_summary_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/analytics_view_model.dart';
import '../../view_model/transactions_view_model.dart';
// ... imports as in your code above ...

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
        ChangeNotifierProvider(create: (_) => TransactionsViewModel()),
      ],
      child: Consumer2<AnalyticsViewModel, TransactionsViewModel>(
        builder: (context, analyticsVm, txVm, _) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: const Color(0xFFF7F9FC),
              appBar: AppBar(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                title: const Padding(
                  padding: EdgeInsets.only(left: 7, top: 7),
                  child: Text(
                    "Analytics",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Colors.black87,
                      letterSpacing: -.7,
                    ),
                  ),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0, top: 4),
                    child: Icon(
                      Icons.notifications,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        // Header & Top Cards
                        Stack(
                          children: [
                            Container(
                              height: 210,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(26),
                                  bottomRight: Radius.circular(26),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                // Total Transactions Card
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Transactions",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "₹${txVm.transactions.fold<double>(0, (s, t) => s + t.amount).toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 22,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 11),
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_upward,
                                                  size: 16,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: 32,
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: analyticsVm.monthIdx,
                                                icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                                items: List.generate(
                                                  analyticsVm.months.length,
                                                  (i) => DropdownMenuItem(
                                                    value: i,
                                                    child: Text(
                                                      i ==
                                                              analyticsVm
                                                                  .currentMonthIndex
                                                          ? 'This month'
                                                          : analyticsVm
                                                                .months[i],
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (i) {
                                                  if (i != null)
                                                    analyticsVm.setMonth(i);
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 60,
                                            height: 30,
                                            child: CustomPaint(
                                              painter: MiniGraphPainter(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const TabBar(
                                      indicatorColor: Color(0xFF2563EB),
                                      labelColor: Color(0xFF2563EB),
                                      unselectedLabelColor: Color(0xFF6B7280),
                                      tabs: [
                                        Tab(text: 'Insights'),
                                        Tab(text: 'Payee'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // UPI Transactions Graph (tab-dependent!)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            "UPI Transactions",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            "Last 7 days",
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Banner when no transactions in selected month
                                      if (((analyticsVm.dailySpends.isEmpty) || analyticsVm.dailySpends.every((v) => v == 0)) && analyticsVm.payeeTotals.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: const Text(
                                            'No transactions this month',
                                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      SizedBox(
                                        height: 120,
                                        child: Builder(
                                          builder: (context) {
                                            final TabController? tabController =
                                                DefaultTabController.of(
                                                  context,
                                                );
                                            final int tabIndex =
                                                tabController?.index ?? 0;
                                            if (tabIndex == 0) {
                                              // Insights tab: line chart of last 7 days
                                              final ds =
                                                  analyticsVm.dailySpends;
                                              final series = ds.length <= 7
                                                  ? ds
                                                  : ds.sublist(ds.length - 7);
                                              return CustomPaint(
                                                painter: BlueLineChartPainter(
                                                  series,
                                                ),
                                              );
                                            } else {
                                              // Payee tab: horizontal bar chart from Firestore payee totals
                                              final entries = analyticsVm
                                                  .payeeTotals
                                                  .entries
                                                  .toList();
                                              if (entries.isEmpty) {
                                                return Center(
                                                  child: Text(
                                                    'No payee',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                );
                                              }
                                              return CustomPaint(
                                                painter:
                                                    HorizontalBarChartPainter(
                                                      entries,
                                                    ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Tabs
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 420,
                          child: TabBarView(
                            children: [
                              ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 21,
                                      horizontal: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(29),
                                    ),
                                    child: Column(
                                      children: analyticsVm.categories
                                          .map(
                                            (cat) =>
                                                AnalyticsCategoryCard(cat: cat),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    child: SizedBox(
                                      height: 132,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        itemBuilder: (_, idx) => SizedBox(
                                          width: 130,
                                          child: AnalyticsSummaryBox(
                                            cat:
                                                analyticsVm.categories[idx %
                                                    analyticsVm
                                                        .categories
                                                        .length],
                                          ),
                                        ),
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 10),
                                        itemCount:
                                            analyticsVm.categories.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                children: const [
                                  PayeeItem(
                                    name: 'HDFC Bank',
                                    icon: Icons.account_balance,
                                  ),
                                  PayeeItem(
                                    name: 'RAJESH M',
                                    icon: Icons.person,
                                  ),
                                  PayeeItem(
                                    name: 'VEENA S',
                                    icon: Icons.person_outline,
                                  ),
                                  PayeeItem(name: 'API INFO', icon: Icons.link),
                                  PayeeItem(name: 'airtel', icon: Icons.wifi),
                                  PayeeItem(
                                    name: 'Other Payees',
                                    icon: Icons.receipt_long,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------ Payee item ------------------------
class PayeeItem extends StatelessWidget {
  final String name;
  final IconData icon;
  const PayeeItem({required this.name, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFF3FF),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ------------------------ Custom Painters ------------------------

class MiniGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final points = [
      Offset(0, size.height * .65),
      Offset(size.width * .2, size.height * .5),
      Offset(size.width * .4, size.height * .55),
      Offset(size.width * .6, size.height * .4),
      Offset(size.width * .8, size.height * .6),
      Offset(size.width, size.height * .55),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Blue line chart with dots (Insights)
class BlueLineChartPainter extends CustomPainter {
  final List<double> data;
  BlueLineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid: 3 lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final gridYs = [0.2, 0.5, 0.8];
    for (final gy in gridYs) {
      final pos = size.height * gy;
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    if (data.isEmpty) {
      // draw baseline
      canvas.drawLine(
        Offset(0, size.height * 0.85),
        Offset(size.width, size.height * 0.85),
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 0.8,
      );
      return;
    }

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);
    final n = data.length;

    List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final x = size.width * (i / (n - 1).clamp(1, double.infinity));
      final norm = (data[i] - minVal) / range;
      // invert y because canvas origin is top-left
      final y = size.height * (0.9 - norm * 0.7);
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    for (final p in points) {
      canvas.drawCircle(p, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BlueLineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

// Horizontal bar chart for Payee tab
class HorizontalBarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  HorizontalBarChartPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = size.height / entries.length * 0.6;
    final double labelGap = 65;
    final double chartWidth = size.width - labelGap - 10;
    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    // Grid and X axis labels
    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    for (int j = 0; j <= 8; j++) {
      final x = labelGap + chartWidth * (j / 8.0);
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 20), axisPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: j == 0 ? '0' : '${j}K',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 28, maxWidth: 34);
      tp.paint(canvas, Offset(x - 12, size.height - 18));
    }

    // Bars & labels
    for (int i = 0; i < entries.length; i++) {
      final value = entries[i].value;
      final top =
          i * (size.height / entries.length) +
          (size.height / entries.length - barHeight) / 2;
      final barLength = (value / maxValue) * chartWidth;

      // Bar
      final barRect = Rect.fromLTWH(labelGap, top, barLength, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2.5)),
        Paint()..color = const Color(0xFF72ABF9),
      );

      // Label
      final labelSpan = TextSpan(
        text: entries[i].key,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 12,
          overflow: TextOverflow.ellipsis,
        ),
      );
      final tp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: labelGap - 8);
      tp.paint(canvas, Offset(6, top + barHeight * 0.1));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
