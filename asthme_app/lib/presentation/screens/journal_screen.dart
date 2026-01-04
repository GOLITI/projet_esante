import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildFilters(),
          const SizedBox(height: 30),
          _buildGraphCard(),
          const SizedBox(height: 20),
          _buildSymptomsCard(),
          const SizedBox(height: 20),
          _buildHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.book, color: Color(0xFFE040FB), size: 28),
            SizedBox(width: 8),
            Text(
              'Journal Clinique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE040FB),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Saisir', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterItem('24h', false),
        _buildFilterItem('7j', true),
        _buildFilterItem('30j', false),
      ],
    );
  }

  Widget _buildFilterItem(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: isSelected
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE040FB).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildGraphCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    'Graphique',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.trending_up, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildLegendItem('PM2.5', Colors.cyan),
              const SizedBox(width: 16),
              _buildLegendItem('CO', Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: GraphPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSymptomsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sick_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Symptômes Récents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSymptomItem(
            'Sifflements',
            'Aujourd\'hui, 14:30',
            'Modéré',
            Icons.air,
            Colors.yellow.shade50,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSymptomItem(
            'Dyspnée',
            'Hier, 09:15',
            'Léger',
            Icons.sentiment_dissatisfied,
            Colors.orange.shade50,
            Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          _buildSymptomItem(
            'Toux',
            'Il y a 2 jours',
            'Fréquent',
            Icons.coronavirus_outlined,
            Colors.red.shade50,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(String title, String date, String severity, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'Historique Crises',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCrisisItem(
            'Crise Sévère',
            '15 Oct 2025 - Pollution',
            'Sévère',
            Icons.notifications_active,
            Colors.red.shade50,
            Colors.red,
            true,
          ),
          const SizedBox(height: 12),
          _buildCrisisItem(
            'Crise Modérée',
            '28 Sep 2025 - Exercice',
            'Modéré',
            Icons.warning,
            Colors.orange.shade50,
            Colors.deepOrange,
            true,
          ),
          const SizedBox(height: 12),
          _buildCrisisItem(
            'Crise Légère',
            '12 Sep 2025 - Température',
            'Léger',
            Icons.bolt,
            Colors.yellow.shade50,
            Colors.amber.shade700,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisItem(String title, String subtitle, String severity, IconData icon, Color bg, Color color, bool showBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: showBorder ? Border(left: BorderSide(color: color, width: 4)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        border: Border.all(color: color.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    final path2 = Path();

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Vertical lines
    for (int i = 0; i <= 6; i++) {
      double x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw labels (simplified)
    const textStyle = TextStyle(color: Colors.grey, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Y axis labels
    final yLabels = ['600', '450', '300', '150', '0'];
    for (int i = 0; i < yLabels.length; i++) {
      textPainter.text = TextSpan(text: yLabels[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(-25, size.height * (i / 4) - 6));
    }

    // X axis labels
    final xLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Dim'];
    for (int i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(text: xLabels[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * (i / 5) - 10, size.height + 5));
    }

    // Curve 1 (Cyan)
    paint.color = Colors.cyan;
    path1.moveTo(0, size.height * 0.6);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width * 0.4, size.height * 0.6);
    path1.quadraticBezierTo(size.width * 0.6, size.height * 0.2, size.width * 0.8, size.height * 0.5);
    path1.lineTo(size.width, size.height * 0.55);
    
    // Fill for Curve 1
    final fillPaint1 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [Colors.cyan.withOpacity(0.2), Colors.cyan.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final fillPath1 = Path.from(path1)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(fillPath1, fillPaint1);
    canvas.drawPath(path1, paint);

    // Curve 2 (Purple)
    paint.color = Colors.purpleAccent;
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width * 0.5, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.85, size.width, size.height * 0.88);

    // Fill for Curve 2
    final fillPaint2 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [Colors.purpleAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath2 = Path.from(path2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath2, fillPaint2);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
