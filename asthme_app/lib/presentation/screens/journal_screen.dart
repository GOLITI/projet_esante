import 'package:flutter/material.dart';
import '../../../data/datasources/local_database.dart';
import 'clinical_journal_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    try {
      final db = await LocalDatabase.instance.database;
      final result = await db.rawQuery('''
        SELECT 
          p.id,
          p.risk_level,
          p.risk_probability,
          p.symptoms,
          p.timestamp,
          s.humidity,
          s.temperature,
          s.pm25,
          s.respiratory_rate
        FROM predictions p
        LEFT JOIN sensor_history s ON p.sensor_data_id = s.id
        WHERE p.user_id = 1
        ORDER BY p.timestamp DESC
        LIMIT 20
      ''');
      setState(() {
        _predictions = result;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement prédictions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(context),
          const SizedBox(height: 16),
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

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFFE040FB)),
      onPressed: () {
        // Revenir à l'écran principal du DashboardScreen
        // On ne peut pas utiliser Navigator.pop() car on n'est pas dans une route séparée
        // L'utilisateur devra cliquer sur l'icône Home dans la navbar
      },
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClinicalJournalScreen()),
              ).then((_) => _loadPredictions());
            },
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem('Humidité', Colors.blue),
              _buildLegendItem('Température', Colors.orange),
              _buildLegendItem('PM2.5', Colors.red),
              _buildLegendItem('Fréq. Resp.', Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: GraphPainter(
                      predictions: _predictions,
                    ),
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_predictions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aucune donnée disponible.\nCliquez sur "Saisir" pour ajouter une prédiction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ..._predictions.map((pred) {
              final symptoms = pred['symptoms'] as String? ?? 'Aucun';
              final translatedSymptoms = _translateSymptoms(symptoms);
              final timestamp = DateTime.parse(pred['timestamp'] as String);
              // Convertir risk_level de String vers int
              final riskLevel = int.tryParse(pred['risk_level'].toString()) ?? 0;
              final riskProb = pred['risk_probability'] as double;
              
              final timeAgo = _getTimeAgo(timestamp);
              final severity = _getSeverityFromRisk(riskLevel);
              final icon = _getIconFromRisk(riskLevel);
              final bgColor = _getBgColorFromRisk(riskLevel);
              final iconColor = _getIconColorFromRisk(riskLevel);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildSymptomItem(
                  translatedSymptoms,
                  timeAgo,
                  '$severity (${(riskProb * 100).toStringAsFixed(0)}%)',
                  icon,
                  bgColor,
                  iconColor,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? "s" : ""}';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  String _translateSymptoms(String symptoms) {
    // Si c'est un JSON, le parser
    if (symptoms.trim().startsWith('{')) {
      try {
        // Extraire les symptômes actifs (valeur = 1)
        final activeSymptoms = <String>[];
        
        // Dictionnaire de traduction
        final translations = {
          'Tiredness': 'Fatigue',
          'Dry-Cough': 'Toux sèche',
          'Difficulty-in-Breathing': 'Difficulté respiratoire',
          'Sore-Throat': 'Mal de gorge',
          'Pains': 'Douleurs',
          'Nasal-Congestion': 'Congestion nasale',
          'Runny-Nose': 'Nez qui coule',
        };
        
        // Parser les symptômes
        translations.forEach((key, value) {
          if (symptoms.contains('$key: 1') || symptoms.contains('"$key":1') || symptoms.contains('"$key": 1')) {
            activeSymptoms.add(value);
          }
        });
        
        if (activeSymptoms.isEmpty) {
          return 'Aucun symptôme';
        }
        
        return activeSymptoms.join(', ');
      } catch (e) {
        return 'Données symptômes';
      }
    }
    
    // Sinon, traduction simple
    final translations = {
      'tiredness': 'Fatigue',
      'dry cough': 'Toux sèche',
      'difficulty breathing': 'Difficulté respiratoire',
      'sore throat': 'Mal de gorge',
      'pains': 'Douleurs',
      'nasal congestion': 'Congestion nasale',
      'runny nose': 'Nez qui coule',
      'Aucun symptôme': 'Aucun symptôme',
    };

    String translated = symptoms;
    translations.forEach((en, fr) {
      translated = translated.replaceAll(en, fr);
    });
    
    return translated;
  }

  String _getSeverityFromRisk(int riskLevel) {
    switch (riskLevel) {
      case -1: return 'Journal manuel';
      case 1: return 'Faible';
      case 2: return 'Modéré';
      case 3: return 'Élevé';
      default: return 'Inconnu';
    }
  }

  IconData _getIconFromRisk(int riskLevel) {
    switch (riskLevel) {
      case -1: return Icons.edit_note;
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.warning_amber_outlined;
      case 3: return Icons.coronavirus_outlined;
      default: return Icons.help_outline;
    }
  }

  Color _getBgColorFromRisk(int riskLevel) {
    switch (riskLevel) {
      case -1: return Colors.blue.shade50;
      case 1: return Colors.green.shade50;
      case 2: return Colors.orange.shade50;
      case 3: return Colors.red.shade50;
      default: return Colors.grey.shade50;
    }
  }

  Color _getIconColorFromRisk(int riskLevel) {
    switch (riskLevel) {
      case -1: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildSymptomItem(String title, String date, String severity, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_predictions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aucune crise enregistrée.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ..._predictions.where((p) {
              final riskLevelStr = p['risk_level'].toString();
              final riskLevelInt = int.tryParse(riskLevelStr) ?? 0;
              return riskLevelInt >= 2;
            }).map((pred) {
              final timestamp = DateTime.parse(pred['timestamp'] as String);
              // Convertir risk_level de String vers int
              final riskLevel = int.tryParse(pred['risk_level'].toString()) ?? 0;
              final riskProb = pred['risk_probability'] as double;
              final symptoms = pred['symptoms'] as String? ?? 'Non spécifié';
              
              final severity = _getSeverityFromRisk(riskLevel);
              final icon = _getCrisisIcon(riskLevel);
              final bgColor = _getBgColorFromRisk(riskLevel);
              final iconColor = _getIconColorFromRisk(riskLevel);
              
              final dateStr = '${timestamp.day} ${_getMonthName(timestamp.month)} ${timestamp.year}';
              final subtitle = '$dateStr - $symptoms';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildCrisisItem(
                  'Crise $severity',
                  subtitle,
                  severity,
                  icon,
                  bgColor,
                  iconColor,
                  true,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  IconData _getCrisisIcon(int riskLevel) {
    switch (riskLevel) {
      case 2: return Icons.warning;
      case 3: return Icons.notifications_active;
      default: return Icons.bolt;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
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
  final List<Map<String, dynamic>> predictions;

  GraphPainter({required this.predictions});

  @override
  void paint(Canvas canvas, Size size) {
    if (predictions.isEmpty) {
      // Afficher un message si pas de données
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Aucune donnée disponible',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

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

    // Prendre les 7 dernières prédictions
    final dataPoints = predictions.take(7).toList().reversed.toList();
    final count = dataPoints.length;

    if (count < 2) return;

    // Extraire les données
    final humidityData = <double>[];
    final temperatureData = <double>[];
    final pm25Data = <double>[];
    final respRateData = <double>[];

    for (var pred in dataPoints) {
      humidityData.add((pred['humidity'] as num?)?.toDouble() ?? 0.0);
      temperatureData.add((pred['temperature'] as num?)?.toDouble() ?? 0.0);
      pm25Data.add((pred['pm25'] as num?)?.toDouble() ?? 0.0);
      respRateData.add((pred['respiratory_rate'] as num?)?.toDouble() ?? 0.0);
    }

    // Normaliser les données pour le graphique (0 à 1)
    List<double> normalize(List<double> data) {
      if (data.isEmpty) return [];
      final max = data.reduce((a, b) => a > b ? a : b);
      final min = data.reduce((a, b) => a < b ? a : b);
      if (max == min) return List.filled(data.length, 0.5);
      return data.map((v) => (v - min) / (max - min)).toList();
    }

    final normHumidity = normalize(humidityData);
    final normTemp = normalize(temperatureData);
    final normPm25 = normalize(pm25Data);
    final normRespRate = normalize(respRateData);

    // Dessiner les courbes
    void drawCurve(List<double> data, Color color, double opacity) {
      final path = Path();
      final fillPath = Path();

      for (int i = 0; i < data.length; i++) {
        final x = size.width * (i / (count - 1));
        final y = size.height * (1 - data[i]);

        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, size.height);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      // Compléter le remplissage
      fillPath.lineTo(size.width * ((data.length - 1) / (count - 1)), size.height);
      fillPath.close();

      // Remplissage avec gradient
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      // Ligne
      paint.color = color;
      canvas.drawPath(path, paint);

      // Points
      for (int i = 0; i < data.length; i++) {
        final x = size.width * (i / (count - 1));
        final y = size.height * (1 - data[i]);
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
        canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
      }
    }

    // Dessiner toutes les courbes
    drawCurve(normHumidity, Colors.blue, 0.15);
    drawCurve(normTemp, Colors.orange, 0.15);
    drawCurve(normPm25, Colors.red, 0.15);
    drawCurve(normRespRate, Colors.green, 0.15);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
