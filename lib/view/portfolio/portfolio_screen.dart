import 'package:flutter/material.dart';
import 'package:echeque_mvp/core/constants/app_colors.dart';
import 'dart:ui' as ui; // Needed for TextPainter

// Main Screen
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No translations; static labels
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Added back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Details',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        // Added 'more' icon
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: AppColors.grey100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Stock Header Card
            const _StockHeaderCard(),
            const SizedBox(height: 16),

            // 2. Price and Chart Card
            const _PriceChartCard(),
            const SizedBox(height: 16),

            // 3. Key Statistics Section
            const _KeyStatisticsSection(),
            const SizedBox(height: 20),

            // 4. Buy Now Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//--- WIDGETS ---

// Widget for the top "ADS" header
class _StockHeaderCard extends StatelessWidget {
  const _StockHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // Placeholder for Adidas Logo
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.grey100,
            // You could use an Image.asset('path/to/adidas_logo.png') here
            child: Icon(
              Icons.business,
              color: Colors.black54,
            ), // Placeholder icon
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ADS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'From: Adidas AG (ADS)',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // "Holding" Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.blueBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Holding',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for the Price and Chart
class _PriceChartCard extends StatelessWidget {
  const _PriceChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          const Text(
            ' \$200.49',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // Trend
          Row(
            children: [
              const Text(
                'Trend is',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              const Text(
                '\$58.16 (45%)',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Year To Date Picker
              Row(
                children: [
                  const Text(
                    'Year To Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black87),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          const SizedBox(
            height: 250,
            child: _LineDemo(),
          ),
        ],
      ),
    );
  }
}

// Widget for the Key Statistics section
class _KeyStatisticsSection extends StatelessWidget {
  const _KeyStatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row with "See More"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Key Statistic',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See More',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // GridView
        GridView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2, // FIX: Adjusted from 2.4 to prevent overflow
          ),
          children: const [
            _Stat('Total Cash', '51,876 B'),
            _Stat('Market Cap', '261,199 B'),
            _Stat('Dividend (TTM)', '640.00'),
            _Stat('Dividend Yield', '9.92%'),
          ],
        ),
      ],
    );
  }
}

// Individual Stat Card
class _Stat extends StatelessWidget {
  final String title;
  final String value;
  const _Stat(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // For vertical alignment
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Helper method for consistent card styling
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black12.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

//--- CHART CUSTOM PAINTER ---

class _LineDemo extends StatelessWidget {
  const _LineDemo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(),
      child: Container(),
    );
  }
}

class _LinePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight =
        size.height - 40; // Allocate space for X-axis labels (months)
    final double chartWidth =
        size.width - 30; // Allocate space for Y-axis labels (values)
    const double leftPadding = 30; // Space for Y-axis labels
    const double bottomPadding = 20; // Space for X-axis labels

    // --- Draw Grid Lines ---
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Y-axis values
    final List<double> yValues = [0, 0.15, 0.35, 0.55];
    final List<String> yLabels = ['\$0', '\$0.15', '\$0.35', '\$0.55'];

    // Y-axis labels and horizontal grid lines
    for (int i = 0; i < yValues.length; i++) {
      final textSpan = TextSpan(
        text: yLabels[i],
        style: TextStyle(color: Colors.grey[600], fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: leftPadding - 5);

      // Calculate y position
      // Map yValue (0 to 0.55) to chart height (bottom to top)
      final double y =
          chartHeight - (yValues[i] / 0.55) * chartHeight + bottomPadding;

      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));

      // Draw horizontal grid line
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);
    }

    // X-axis labels (months)
    final List<String> xLabels = ['May', 'Jun', 'Jul', 'Aug', 'Sep'];
    // Adjust points to be within the new chart boundaries
    // These values are tuned to match the screenshot's curves
    final List<Offset> points = [
      Offset(
        leftPadding + chartWidth * 0.0,
        chartHeight * 0.7 + bottomPadding,
      ), // May
      Offset(
        leftPadding + chartWidth * 0.25,
        chartHeight * 0.35 + bottomPadding,
      ), // Jun
      Offset(
        leftPadding + chartWidth * 0.50,
        chartHeight * 0.55 + bottomPadding,
      ), // Jul
      Offset(
        leftPadding + chartWidth * 0.75,
        chartHeight * 0.30 + bottomPadding,
      ), // Aug
      Offset(
        leftPadding + chartWidth * 1.0,
        chartHeight * 0.15 + bottomPadding,
      ), // Sep
    ];

    // Draw X-axis labels
    for (int i = 0; i < xLabels.length; i++) {
      final textSpan = TextSpan(
        text: xLabels[i],
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      final x = points[i].dx - textPainter.width / 2;
      // Ensure first and last labels don't go off-screen
      final double clampedX = x.clamp(0.0, size.width - textPainter.width);
      textPainter.paint(
        canvas,
        Offset(clampedX, size.height - textPainter.height),
      );
    }

    // --- Draw the Line Graph ---
    final linePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];

        // Control points for a smooth cubic bezier curve
        final c1x = p1.dx + (p2.dx - p1.dx) * 0.5;
        final c1y = p1.dy;
        final c2x = p1.dx + (p2.dx - p1.dx) * 0.5;
        final c2y = p2.dy;

        path.cubicTo(c1x, c1y, c2x, c2y, p2.dx, p2.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // --- Draw the July Marker ---
    final int julyIndex = 2; // Index for July in the points list
    final Offset julyPoint = points[julyIndex];

    // Dashed vertical line
    final dashPaint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = julyPoint.dy + 8; // Start just below the dot
    while (startY < (chartHeight + bottomPadding)) {
      // Draw down to the bottom
      canvas.drawLine(
        Offset(julyPoint.dx, startY),
        Offset(julyPoint.dx, startY + dashHeight),
        dashPaint,
      );
      startY += (dashHeight + dashSpace);
    }

    // Dot on the July point
    final dotPaint = Paint()..color = AppColors.primaryBlue;
    canvas.drawCircle(julyPoint, 5, dotPaint);

    // Inner white dot
    final innerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(julyPoint, 2.5, innerDotPaint);

    // Value label for July
    final julyValueTextSpan = TextSpan(
      text: '\$173.5',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
    final julyValueTextPainter = TextPainter(
      text: julyValueTextSpan,
      textDirection: ui.TextDirection.ltr,
    );
    julyValueTextPainter.layout();

    // Position the text above the July point
    final Offset textOffset = Offset(
      julyPoint.dx - julyValueTextPainter.width / 2,
      julyPoint.dy -
          julyValueTextPainter.height -
          10, // 10 pixels above the dot
    );
    julyValueTextPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
