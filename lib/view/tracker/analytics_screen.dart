import 'package:echeque_mvp/view/widgets/analytics_category_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echeque_mvp/localization/translation_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../view_model/analytics_view_model.dart';
import '../../view_model/transactions_view_model.dart';
import '../home/home_screen.dart';
import '../chat/chat_screen.dart';
import '../home/profile_screen.dart';
import '../widgets/transaction_card.dart';

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
          // Prefetch common visible strings for quicker switching
          final tp = context.read<TranslationProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            tp.translateVisible([
              'Analytics',
              'Insights',
              'Payees',
              'Transactions',
              'Total Transactions',
              'This month',
              'No data found',
              'No payees',
              'Search transactions... ',
              'All',
              'Income',
              'Expense',
              'Pending',
              'transactions',
              'All Transactions',
              'No transactions found',
              'Home',
              'Chat',
              'Analytics',
              'Profile',
            ]);
          });
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: const Color(0xFFF7F9FC),
              appBar: AppBar(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                title: Padding(
                  padding: EdgeInsets.only(left: 7, top: 7),
                  child: Text(
                    tp.t('Analytics'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: -.7,
                    ),
                  ),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.notifications,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ],
                bottom: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: tp.t('Insights')),
                    Tab(text: tp.t('Payees')),
                    Tab(text: tp.t('Transactions')),
                  ],
                ),
              ),

              // ------------------ Body ------------------
              body: TabBarView(
                children: [
                  // ------------------ INSIGHTS TAB ------------------
                  ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    children: [
                      // Top transaction summary card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tp.t('Total Transactions'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${analyticsVm.monthSpendTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 5),
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
                                        i == analyticsVm.currentMonthIndex
                                            ? tp.t('This month')
                                            : analyticsVm.months[i],
                                      ),
                                    ),
                                  ),
                                  onChanged: (i) {
                                    if (i != null) {
                                      analyticsVm.setMonth(i);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Analytics content: always show categories (defaults appear with 0 before any transactions)
                      ...[
                        SizedBox(
                          height: 200,
                          child: Builder(
                            builder: (_) {
                              final cats = analyticsVm.categories;
                              final values = cats
                                  .map((c) => c.amount.toDouble())
                                  .toList();
                              final colors = cats.map((c) => c.color).toList();
                              return CustomPaint(
                                painter: PieChartPainter(
                                  values: values,
                                  colors: colors,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: analyticsVm.categories.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: c.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${c.label} • ${c.percent}% • ₹${c.amount}',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: analyticsVm.categories
                                .map((cat) => AnalyticsCategoryCard(cat: cat))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ------------------ PAYEES TAB ------------------
                  Builder(
                    builder: (_) {
                      if (!analyticsVm.hasDataForMonth) {
                        return Center(
                          child: Text(
                            tp.t('No data found'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      final entries = analyticsVm.payeeTotals.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            tp.t('No payees'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          "₹${analyticsVm.monthSpendTotal.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 22,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 5),
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
                                SizedBox(
                                  height: 52,
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
                                            i == analyticsVm.currentMonthIndex
                                                ? 'This month'
                                                : analyticsVm.months[i],
                                          ),
                                        ),
                                      ),
                                      onChanged: (i) {
                                        if (i != null) {
                                          analyticsVm.setMonth(i);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 200,
                            child: CustomPaint(
                              painter: HorizontalBarChartPainter(entries),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...entries.map(
                            (e) => PayeeItem(
                              name:
                                  '${e.key}  ·  ₹${e.value.toStringAsFixed(2)}',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ------------------ TRANSACTIONS TAB ------------------
                  // ------------------ TRANSACTIONS TAB ------------------
                  Builder(
                    builder: (_) {
                      //
                      // --- THIS IS THE CORRECTED LOGIC ---
                      //

                      // --- Transactions list UI (chart removed) ---
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: tp.t('Search transactions... '),
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
                            onChanged: txVm.search,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 54,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _TxFilterChip(
                                  text: tp.t('All'),
                                  isSelected:
                                      txVm.selectedType == TransactionType.all,
                                  onTap: () =>
                                      txVm.setType(TransactionType.all),
                                ),
                                _TxFilterChip(
                                  text: tp.t('Income'),
                                  isSelected:
                                      txVm.selectedType ==
                                      TransactionType.income,
                                  onTap: () =>
                                      txVm.setType(TransactionType.income),
                                ),
                                _TxFilterChip(
                                  text: tp.t('Expense'),
                                  isSelected:
                                      txVm.selectedType ==
                                      TransactionType.expense,
                                  onTap: () =>
                                      txVm.setType(TransactionType.expense),
                                ),
                                _TxFilterChip(
                                  text: tp.t('Pending'),
                                  isSelected:
                                      txVm.selectedType ==
                                      TransactionType.pending,
                                  onTap: () =>
                                      txVm.setType(TransactionType.pending),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${txVm.filteredTransactions.length} ' +
                                    tp.t('transactions'),
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                              () {
                                final filteredTotal = txVm.filteredTransactions
                                    .fold<double>(
                                      0,
                                      (sum, t) =>
                                          sum +
                                          (t.incoming ? t.amount : -t.amount),
                                    );
                                return Text(
                                  '₹${filteredTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF16202C),
                                  ),
                                );
                              }(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tp.t('All Transactions'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (txVm.filteredTransactions.isEmpty &&
                              txVm.transactions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Text(
                                  tp.t('No transactions found'),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else ...[
                            ...(txVm.filteredTransactions.isEmpty
                                    ? txVm.transactions
                                    : txVm.filteredTransactions)
                                .map((t) => TransactionCard(tx: t)),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 2,
                selectedItemColor: AppColors.primaryBlue,
                unselectedItemColor: AppColors.grey600,
                backgroundColor: AppColors.white,
                onTap: (idx) {
                  if (idx == 2) return;
                  switch (idx) {
                    case 0:
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                      break;
                    case 1:
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => ChatScreen()));
                      break;
                    case 3:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                      break;
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: tp.t('Home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.chat),
                    label: tp.t('Chat'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.analytics),
                    label: tp.t('Analytics'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person),
                    label: tp.t('Profile'),
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

// ------------------------ Pie Chart Painter ------------------------
class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 2;
    double startRads = -3.14159 / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 3.14159 * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius
        ..color = i < colors.length ? colors[i] : const Color(0xFF90CAF9);
      final arcRect = Rect.fromCircle(center: center, radius: radius / 2);
      canvas.drawArc(arcRect, startRads, sweep, false, paint);
      startRads += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

// ------------------------ Horizontal Bar Chart Painter ------------------------
class HorizontalBarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  HorizontalBarChartPainter(this.entries);

  String _format(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final double barHeight = size.height / entries.length * 0.6;
    final double labelGap = 90;
    final double chartWidth = size.width - labelGap - 10;
    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    const ticks = 5;
    for (int j = 0; j <= ticks; j++) {
      final x = labelGap + chartWidth * (j / ticks);
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 20), axisPaint);
      final tickVal = maxValue * (j / ticks);
      final tp = TextPainter(
        text: TextSpan(
          text: _format(tickVal),
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: 80);
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 18));
    }

    for (int i = 0; i < entries.length; i++) {
      final value = entries[i].value;
      final top =
          i * (size.height / entries.length) +
          (size.height / entries.length - barHeight) / 2;
      final barLength = maxValue == 0 ? 0 : (value / maxValue) * chartWidth;

      final barRect = Rect.fromLTWH(
        labelGap.toDouble(),
        top.toDouble(),
        barLength.toDouble(),
        barHeight.toDouble(),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2.5)),
        Paint()..color = const Color(0xFF72ABF9),
      );

      final nameTp = TextPainter(
        text: TextSpan(
          text: entries[i].key,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: labelGap - 8);
      nameTp.paint(canvas, Offset(6, top + barHeight * 0.1));

      final valTp = TextPainter(
        text: TextSpan(
          text: _format(value),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: 80);
      valTp.paint(
        canvas,
        Offset(labelGap + barLength + 4, top + barHeight * 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ------------------------ Net Line Chart Painter ------------------------
class NetLineChartPainter extends CustomPainter {
  final List<double> values; // positive = income, negative = expense
  final double strokeWidth;
  final double dotRadius;
  NetLineChartPainter(
    this.values, {
    this.strokeWidth = 2.0,
    this.dotRadius = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final padding = 12.0;
    final chartRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // Determine Y range symmetric around zero to emphasize up/down
    double maxAbs = 0;
    for (final v in values) {
      final a = v.abs();
      if (a > maxAbs) maxAbs = a;
    }
    if (maxAbs <= 0) maxAbs = 1;

    // Draw horizontal grid (5 lines)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..strokeWidth = 1;
    const ticks = 4;
    for (int i = 0; i <= ticks; i++) {
      final y = chartRect.top + chartRect.height * (i / ticks);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    // Zero baseline
    final zeroY = chartRect.center.dy;
    canvas.drawLine(
      Offset(chartRect.left, zeroY),
      Offset(chartRect.right, zeroY),
      Paint()
        ..color = Colors.grey.withOpacity(0.6)
        ..strokeWidth = 1.2,
    );

    // Build points
    final dx = chartRect.width / (values.length - 1).clamp(1, double.infinity);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left + dx * i;
      final norm = (values[i] / (maxAbs * 1.2)).clamp(-1.0, 1.0);
      final y = zeroY - norm * (chartRect.height / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw points
    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left + dx * i;
      final norm = (values[i] / (maxAbs * 1.2)).clamp(-1.0, 1.0);
      final y = zeroY - norm * (chartRect.height / 2);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NetLineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _TxFilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _TxFilterChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
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
