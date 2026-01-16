import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/presentation/blocs/prediction/prediction_bloc.dart';
import 'package:asthme_app/presentation/blocs/prediction/prediction_event.dart';
import 'package:asthme_app/presentation/blocs/prediction/prediction_state.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_state.dart';
import 'package:asthme_app/data/datasources/arduino_sensor_service.dart';
import 'package:asthme_app/data/datasources/bluetooth_sensor_service.dart';
import 'package:asthme_app/presentation/screens/bluetooth_scan_screen.dart';

/// Écran de collecte des données capteurs et prédiction
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _arduinoService = ArduinoSensorService();
  bool _isCollectingSensors = false;

  // Contrôleurs pour les capteurs (vides par défaut)
  final _humidityController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _pm25Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();

  // Symptômes (0 ou 1)
  final Map<String, int> _symptoms = {
    'Tiredness': 0,
    'Dry-Cough': 0,
    'Difficulty-in-Breathing': 0,
    'Sore-Throat': 0,
    'Pains': 0,
    'Nasal-Congestion': 0,
    'Runny-Nose': 0,
  };

  // Démographie
  String _selectedAge = '20-24';
  String _selectedGender = 'Male';

  final List<String> _ageGroups = ['0-9', '10-19', '20-24', '25-59', '60+'];
  final List<String> _genders = ['Male', 'Female'];

  @override
  void dispose() {
    _humidityController.dispose();
    _temperatureController.dispose();
    _pm25Controller.dispose();
    _respiratoryRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nouvelle Évaluation'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<PredictionBloc, PredictionState>(
        listener: (context, state) {
          if (state is PredictionSuccess) {
            _showResultDialog(context, state);
          } else if (state is PredictionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PredictionBloc, PredictionState>(
          builder: (context, state) {
            if (state is PredictionLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Analyse en cours...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('📊 Données des Capteurs'),
                    _buildSensorInputs(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('🤒 Symptômes'),
                    _buildSymptomsSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('👤 Informations Démographiques'),
                    _buildDemographicsSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildSensorInputs() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Boutons pour récupérer les données
            Row(
              children: [
                Expanded(child: _buildArduinoButton()),
                const SizedBox(width: 8),
                Expanded(child: _buildBluetoothButton()),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSensorField(
              controller: _humidityController,
              label: 'Humidité (%)',
              icon: Icons.water_drop,
              suffix: '%',
              hint: '0-100',
            ),
            const SizedBox(height: 12),
            _buildSensorField(
              controller: _temperatureController,
              label: 'Température (°C)',
              icon: Icons.thermostat,
              suffix: '°C',
              hint: '-10 à 50',
            ),
            const SizedBox(height: 12),
            _buildSensorField(
              controller: _pm25Controller,
              label: 'PM2.5 (µg/m³)',
              icon: Icons.air,
              suffix: 'µg/m³',
              hint: '0-500',
            ),
            const SizedBox(height: 12),
            _buildSensorField(
              controller: _respiratoryRateController,
              label: 'Fréquence Respiratoire',
              icon: Icons.air,
              suffix: '/min',
              hint: '8-30',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArduinoButton() {
    return ElevatedButton.icon(
      onPressed: _isCollectingSensors ? null : _fetchArduinoData,
      icon: _isCollectingSensors
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.wifi, size: 18),
      label: const Text('WiFi', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _buildBluetoothButton() {
    return ElevatedButton.icon(
      onPressed: _isCollectingSensors ? null : _openBluetoothScan,
      icon: const Icon(Icons.bluetooth, size: 18),
      label: const Text('BLE', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Future<void> _openBluetoothScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BluetoothScanScreen(),
      ),
    );

    if (result != null && result is BluetoothSensorService) {
      // Récupérer les données depuis le service BLE connecté
      final sensorData = await result.readSensorData();
      
      if (sensorData != null) {
        setState(() {
          _humidityController.text = sensorData.humidity.toStringAsFixed(1);
          _temperatureController.text = sensorData.temperature.toStringAsFixed(1);
          _pm25Controller.text = sensorData.pm25.toStringAsFixed(1);
          _respiratoryRateController.text = sensorData.respiratoryRate.toStringAsFixed(1);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Données BLE récupérées !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchArduinoData() async {
    setState(() => _isCollectingSensors = true);

    try {
      // Configurer l'URL Arduino (à adapter selon votre réseau)
      // Exemple: 192.168.100.50 si votre Arduino est à cette adresse
      _arduinoService.setServerUrl('http://192.168.100.50:80');

      // Tester la connexion
      final isConnected = await _arduinoService.testConnection();
      
      if (!isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Arduino non accessible. Vérifiez l\'adresse IP et le WiFi.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Récupérer les données
      final sensorData = await _arduinoService.fetchSensorData();

      if (sensorData != null) {
        // Remplir les champs avec les données Arduino
        setState(() {
          _humidityController.text = sensorData.humidity.toStringAsFixed(1);
          _temperatureController.text = sensorData.temperature.toStringAsFixed(1);
          _pm25Controller.text = sensorData.pm25.toStringAsFixed(1);
          _respiratoryRateController.text = sensorData.respiratoryRate.toStringAsFixed(1);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Données Arduino récupérées !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Échec récupération données Arduino'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCollectingSensors = false);
    }
  }

  Widget _buildSensorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixText: suffix,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer une valeur';
        }
        if (double.tryParse(value) == null) {
          return 'Valeur invalide';
    );
  }

  Widget _buildSensorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixText: suffix,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer une valeur';
        }
        if (double.tryParse(value) == null) {
          return 'Valeur invalide';
        }
        return null;
      },
    );
  }

  Widget _buildSymptomsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _symptoms.keys.map((symptom) {
            return CheckboxListTile(
              title: Text(_getSymptomLabel(symptom)),
              value: _symptoms[symptom] == 1,
              onChanged: (value) {
                setState(() {
                  _symptoms[symptom] = value == true ? 1 : 0;
                });
              },
              activeColor: Colors.deepPurple,
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getSymptomLabel(String key) {
    final labels = {
      'Tiredness': 'Fatigue',
      'Dry-Cough': 'Toux sèche',
      'Difficulty-in-Breathing': 'Difficulté respiratoire',
      'Sore-Throat': 'Mal de gorge',
      'Pains': 'Douleurs',
      'Nasal-Congestion': 'Congestion nasale',
      'Runny-Nose': 'Nez qui coule',
    };
    return labels[key] ?? key;
  }

  Widget _buildDemographicsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAge,
              decoration: InputDecoration(
                labelText: 'Tranche d\'âge',
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _ageGroups.map((age) {
                return DropdownMenuItem(value: age, child: Text(age));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAge = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Genre',
                prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender == 'Male' ? 'Homme' : 'Femme'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _submitPrediction(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics),
            SizedBox(width: 8),
            Text(
              'Analyser le Risque',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _submitPrediction(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    context.read<PredictionBloc>().add(
          SubmitPredictionEvent(
            userId: int.parse(authState.user.id),
            symptoms: _symptoms,
            age: _selectedAge,
            gender: _selectedGender,
            humidity: double.parse(_humidityController.text),
            temperature: double.parse(_temperatureController.text),
            pm25: double.parse(_pm25Controller.text),
            respiratoryRate: double.parse(_respiratoryRateController.text),
          ),
        );
  }

  void _showResultDialog(BuildContext context, PredictionSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Text(state.riskEmoji),
            const SizedBox(width: 8),
            Text('Risque ${state.riskLabel}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jauge de risque
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: state.riskScore,
                        strokeWidth: 15,
                        backgroundColor: Colors.grey.shade200,
                        color: _getRiskColor(state.riskLevel),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(state.riskScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getRiskColor(state.riskLevel),
                            ),
                          ),
                          Text(
                            state.riskLabel,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '📋 Recommandations:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...state.recommendations.take(5).map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(rec)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Retour au dashboard
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
