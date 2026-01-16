import 'package:flutter/material.dart';
import 'package:asthme_app/data/datasources/sensor_collector_service.dart';
import 'package:asthme_app/data/models/sensor_data.dart';

class TestSensorsScreen extends StatefulWidget {
  const TestSensorsScreen({super.key});

  @override
  State<TestSensorsScreen> createState() => _TestSensorsScreenState();
}

class _TestSensorsScreenState extends State<TestSensorsScreen> {
  final SensorDataCollectorService _collector = SensorDataCollectorService();
  SensorData? _lastData;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _testCollection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastData = null;
    });

    try {
      // Demander les permissions
      final hasPermission = await _collector.requestLocationPermissions();
      if (!hasPermission) {
        setState(() {
          _errorMessage = '❌ Permission de localisation refusée';
          _isLoading = false;
        });
        return;
      }

      // Collecter les données
      final data = await _collector.collectEnvironmentalData();
      
      setState(() {
        _lastData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Capteurs Environnementaux'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.cloud, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Test OpenWeatherMap API',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Collecte: Humidité, PM2.5, AQI',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCollection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Collecte en cours...' : 'Collecter les données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            if (_lastData != null) ...[
              const Text(
                '✅ Données collectées:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDataCard(
                icon: Icons.water_drop,
                title: 'Humidité',
                value: '${_lastData!.humidity.toStringAsFixed(1)}%',
                color: Colors.blue,
              ),
              _buildDataCard(
                icon: Icons.air,
                title: 'PM2.5',
                value: '${_lastData!.pm25.toStringAsFixed(1)} µg/m³',
                subtitle: _lastData!.pm25Level,
                color: _getPM25Color(_lastData!.pm25),
              ),
              _buildDataCard(
                icon: Icons.air,
                title: 'Fréquence Respiratoire',
                value: '${_lastData!.respiratoryRate.toStringAsFixed(1)}',
                subtitle: _lastData!.respiratoryRateLevel,
                color: _getRespiratoryRateColor(_lastData!.respiratoryRate),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Validation:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastData!.isValid
                            ? '✅ Données valides'
                            : '⚠️ Données invalides',
                        style: TextStyle(
                          color: _lastData!.isValid ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🕐 ${_lastData!.timestamp.toLocal()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getPM25Color(double pm25) {
    if (pm25 <= 12) return Colors.green;
    if (pm25 <= 35.4) return Colors.yellow;
    if (pm25 <= 55.4) return Colors.orange;
    return Colors.red;
  }

  Color _getRespiratoryRateColor(double rate) {
    if (rate < 12) return Colors.blue; // Bradypnée
    if (rate <= 20) return Colors.green; // Normal
    if (rate <= 24) return Colors.orange; // Légèrement élevé
    return Colors.red; // Tachypnée
  }
}
