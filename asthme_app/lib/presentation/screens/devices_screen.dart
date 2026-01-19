import 'package:flutter/material.dart';
import '../../../data/datasources/local_database.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Map<String, dynamic>> _sensorHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSensorDevices();
  }

  Future<void> _loadSensorDevices() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await LocalDatabase.instance.database;
      
      // Charger les dernières données de capteurs (dernières 24h)
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final result = await db.rawQuery('''
        SELECT * FROM sensor_history 
        WHERE user_id = 1 AND timestamp > ?
        ORDER BY timestamp DESC
      ''', [oneDayAgo.toIso8601String()]);
      
      setState(() {
        _sensorHistory = result;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement appareils: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_sensorHistory.isEmpty)
                  _buildEmptyState()
                else
                  ..._buildDeviceCards(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.sensors, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Aucun appareil connecté',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez les boutons WiFi ou BLE\nsur l\'écran Prédiction',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceCards() {
    // Grouper par source (dernier appareil utilisé)
    final latestSensor = _sensorHistory.first;
    final timestamp = DateTime.parse(latestSensor['timestamp'] as String);
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    String lastSync;
    if (diff.inMinutes < 1) {
      lastSync = 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      lastSync = 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      lastSync = 'Il y a ${diff.inHours}h';
    } else {
      lastSync = 'Il y a ${diff.inDays}j';
    }

    final isActive = diff.inMinutes < 15; // Actif si données < 15 min

    return [
      _buildSensorCard(
        name: 'Capteur ESP32',
        lastSync: lastSync,
        isActive: isActive,
        humidity: latestSensor['humidity'] as double,
        temperature: latestSensor['temperature'] as double,
        pm25: latestSensor['pm25'] as double,
        respiratoryRate: latestSensor['respiratory_rate'] as double,
      ),
      const SizedBox(height: 16),
      _buildDataCount(),
    ];
  }

  Widget _buildSensorCard({
    required String name,
    required String lastSync,
    required bool isActive,
    required double humidity,
    required double temperature,
    required double pm25,
    required double respiratoryRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.sensors, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.bluetooth, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            lastSync,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? Colors.green.shade200 : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: isActive ? Colors.green.shade600 : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade800 : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.water_drop,
                  label: 'Humidité',
                  value: '${humidity.toStringAsFixed(1)}%',
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.thermostat,
                  label: 'Temp.',
                  value: '${temperature.toStringAsFixed(1)}°C',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.air,
                  label: 'PM2.5',
                  value: '${pm25.toStringAsFixed(0)} µg',
                  color: Colors.brown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.favorite,
                  label: 'Resp.',
                  value: '${respiratoryRate.toStringAsFixed(0)}/min',
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.blueGrey, height: 1.2, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.purple.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Données collectées',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_sensorHistory.length} enregistrement${_sensorHistory.length > 1 ? 's' : ''} (24h)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_sensorHistory.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade900,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.bluetooth, color: Color(0xFFE040FB), size: 28),
            SizedBox(width: 8),
            Text(
              'Mes Appareils',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE040FB),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Utilisez les boutons WiFi ou BLE sur l\'écran Prédiction pour connecter vos capteurs.'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade800,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
