import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'journal_screen.dart';
import 'devices_screen.dart';
import 'resources_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'prediction_screen.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_state.dart';
import '../../../data/datasources/local_database.dart';
import '../../../data/datasources/api_client.dart';
import '../../../data/models/sensor_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2; // Default to Home
  
  // Données dynamiques
  Map<String, dynamic>? _latestPrediction;
  Map<String, dynamic>? _latestSensorData;
  bool _isLoadingData = true;
  Timer? _autoRefreshTimer;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Démarrer le rafraîchissement automatique toutes les 10 secondes
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (_isAnalyzing) return; // Éviter les appels multiples
    
    setState(() => _isLoadingData = true);
    
    try {
      final db = await LocalDatabase.instance.database;
      
      // Charger les dernières données de capteurs
      final sensors = await db.rawQuery('''
        SELECT * FROM sensor_history 
        WHERE user_id = 1
        ORDER BY timestamp DESC 
        LIMIT 1
      ''');
      
      if (sensors.isNotEmpty) {
        final newSensorData = sensors.first;
        
        // Vérifier si les données capteurs ont changé
        bool sensorsChanged = _latestSensorData == null ||
            newSensorData['humidity'] != _latestSensorData!['humidity'] ||
            newSensorData['temperature'] != _latestSensorData!['temperature'] ||
            newSensorData['pm25'] != _latestSensorData!['pm25'] ||
            newSensorData['respiratory_rate'] != _latestSensorData!['respiratory_rate'];
        
        _latestSensorData = newSensorData;
        
        // Si les données ont changé, lancer une analyse automatique
        if (sensorsChanged) {
          print('📊 Nouvelles données capteurs détectées, analyse en cours...');
          await _performAutomaticAnalysis();
        }
      }
      
      // Charger la dernière prédiction (uniquement les valeurs valides 1-3)
      final predictions = await db.rawQuery('''
        SELECT * FROM predictions 
        WHERE user_id = 1 AND risk_level BETWEEN 1 AND 3
        ORDER BY timestamp DESC 
        LIMIT 1
      ''');
      
      if (predictions.isNotEmpty) {
        _latestPrediction = predictions.first;
      }
      
      setState(() => _isLoadingData = false);
    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
      setState(() => _isLoadingData = false);
    }
  }

  /// Effectuer une analyse automatique quand les données capteurs changent
  Future<void> _performAutomaticAnalysis() async {
    if (_isAnalyzing || _latestSensorData == null) return;
    
    setState(() => _isAnalyzing = true);
    
    try {
      // Créer un objet SensorData à partir des données de la DB
      // Utiliser des symptômes par défaut pour l'analyse automatique
      // ⚠️ Noms EXACTS attendus par l'API Flask (avec tirets et majuscules)
      final symptoms = {
        'Tiredness': 0,
        'Dry-Cough': 0,
        'Difficulty-in-Breathing': 0,
        'Sore-Throat': 0,
        'Pains': 0,
        'Nasal-Congestion': 0,
        'Runny-Nose': 0,
      };
      
      // Format EXACT attendu par l'API Flask
      final demographics = {
        'age': '25-59', // Catégories: '0-9', '10-19', '20-24', '25-59', '60+'
        'gender': 'Male', // 'Male' ou 'Female'
      };
      
      // Appeler l'API pour la prédiction
      // ⚡ Les données capteurs seront automatiquement fournies par l'ESP32
      final apiClient = ApiClient();
      final result = await apiClient.predictAsthmaRisk(
        symptoms: symptoms,
        demographics: demographics,
      );
      
      if (result != null && result['success'] == true) {
        // Sauvegarder la prédiction dans la DB
        final db = await LocalDatabase.instance.database;
        
        // Conversion sécurisée des valeurs de l'API
        final riskLevel = (result['risk_level'] is String)
            ? int.tryParse(result['risk_level']) ?? 0
            : (result['risk_level'] as num).toInt();
        final riskScore = (result['risk_score'] is String)
            ? double.tryParse(result['risk_score']) ?? 0.0
            : (result['risk_score'] as num).toDouble();
        
        await db.insert('predictions', {
          'user_id': 1,
          'sensor_data_id': _latestSensorData!['id'],
          'risk_level': riskLevel,
          'risk_probability': riskScore,
          'symptoms': '{}',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        print('✅ Analyse automatique effectuée : ${result['risk_label']}');
        
        // Recharger les données pour afficher la nouvelle prédiction
        await _loadDashboardData();
      }
    } catch (e) {
      print('❌ Erreur analyse automatique: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si on n'est pas sur l'écran d'accueil, revenir à l'accueil
        if (_selectedIndex != 2) {
          setState(() {
            _selectedIndex = 2;
          });
          return false; // Ne pas quitter l'app
        }
        // Si on est sur l'accueil, quitter l'app
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Light grey background
        body: SafeArea(
          child: Stack(
            children: [
              _buildBody(),
              // Custom Bottom Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNavigationBar(),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const JournalScreen();
      case 1:
        return const DevicesScreen();
      case 2:
        return _buildHomeContent();
      case 3:
        return const ResourcesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeContent(); // Placeholder for other tabs
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for bottom nav
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildNewAssessmentButton(),
          const SizedBox(height: 20),
          _buildRealTimeAI(),
          const SizedBox(height: 16),
          _buildAirAlert(),
          const SizedBox(height: 16),
          _buildCrisisRisk(),
          const SizedBox(height: 16),
          _buildPreventionAI(),
          const SizedBox(height: 16),
          _buildSensors(),
          const SizedBox(height: 16),
          _buildAIAdvice(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Récupérer le nom de l'utilisateur depuis l'état d'authentification
        String userName = 'Utilisateur';
        if (state is AuthAuthenticated) {
          userName = state.user.name;
        }
        
        // Formater la date actuelle en français (sans localisation)
        final now = DateTime.now();
        final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
        final mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
        final jour = jours[now.weekday - 1];
        final moisNom = mois[now.month - 1];
        final formattedDate = '$jour, ${now.day} $moisNom ${now.year}';
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Small Logo
                Image.asset(
                  'assets/images/icons/logo.jpeg',
                  height: 30,
                  errorBuilder: (c, e, s) => const Icon(Icons.local_hospital, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour $userName',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, color: Colors.purple),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewAssessmentButton() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Naviguer vers l'écran de prédiction
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PredictionScreen()),
            );
            // Rafraîchir le dashboard au retour
            _loadDashboardData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nouvelle Évaluation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Analyser votre risque d\'asthme',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeAI() {
    if (_isLoadingData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_latestPrediction == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Aucune évaluation récente.\\nCliquez sur "Nouvelle Évaluation" pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final riskLevel = (_latestPrediction!['risk_level'] is String)
        ? int.tryParse(_latestPrediction!['risk_level']) ?? 0
        : (_latestPrediction!['risk_level'] as num).toInt();
    final riskProb = ((_latestPrediction!['risk_probability'] is String)
        ? double.tryParse(_latestPrediction!['risk_probability']) ?? 0.0
        : (_latestPrediction!['risk_probability'] as num).toDouble()) * 100;
    
    String severity;
    Color badgeColor;
    Color messageBackgroundColor;
    String message;
    
    switch (riskLevel) {
      case 1:
        severity = 'Faible';
        badgeColor = const Color(0xFF22C55E); // Vert
        messageBackgroundColor = const Color(0xFFE8F5E9); // Vert très clair
        message = 'Risque faible de crise. Conditions favorables pour vos activités.';
        break;
      case 2:
        severity = 'Modéré';
        badgeColor = const Color(0xFFE040FB); // Rose/Magenta
        messageBackgroundColor = const Color(0xFFF3E5F5); // Mauve très clair
        message = 'Risque modéré détecté. Surveillez vos symptômes et ayez votre inhalateur à portée.';
        break;
      case 3:
        severity = 'Élevé';
        badgeColor = const Color(0xFFEF4444); // Rouge
        messageBackgroundColor = const Color(0xFFFFEBEE); // Rouge très clair
        message = 'Risque élevé ! Évitez les efforts physiques et restez vigilant.';
        break;
      default:
        severity = 'Inconnu';
        badgeColor = Colors.grey;
        messageBackgroundColor = Colors.grey.shade100;
        message = 'Données insuffisantes.';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône IA
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Titre et badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IA en Temps Réel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D0055),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${riskProb.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: messageBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF2D0055),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirAlert() {
    if (_latestSensorData == null) {
      return const SizedBox.shrink();
    }

    final pm25 = (_latestSensorData!['pm25'] is String)
        ? double.tryParse(_latestSensorData!['pm25']) ?? 0.0
        : (_latestSensorData!['pm25'] as num).toDouble();
    String alertLevel;
    Color alertColor;
    Color backgroundColor;
    
    if (pm25 < 12) {
      alertLevel = 'Bon';
      alertColor = Colors.green;
      backgroundColor = Colors.green.shade50;
    } else if (pm25 < 35) {
      alertLevel = 'Modéré';
      alertColor = Colors.orange.shade700;
      backgroundColor = const Color(0xFFFFF4E6); // Beige/orange clair
    } else if (pm25 < 55) {
      alertLevel = 'Attention';
      alertColor = Colors.orange.shade700;
      backgroundColor = const Color(0xFFFFF4E6);
    } else {
      alertLevel = 'Danger';
      alertColor = Colors.red;
      backgroundColor = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: alertColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.warning_amber_rounded, color: alertColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerte Air',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    children: [
                      const TextSpan(
                        text: 'PM',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: '2.5',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ': ${pm25.toStringAsFixed(0)} µg/m³'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: alertColor),
            ),
            child: Text(
              alertLevel,
              style: TextStyle(
                color: alertColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisRisk() {
    if (_latestPrediction == null) {
      // Afficher un message si aucune prédiction n'existe
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Risque de Crise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D0055),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucune analyse disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur "Nouvelle Évaluation"\npour analyser votre risque',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final riskProb = (_latestPrediction!['risk_probability'] is String)
        ? double.tryParse(_latestPrediction!['risk_probability']) ?? 0.0
        : (_latestPrediction!['risk_probability'] as num).toDouble();
    final riskLevel = (_latestPrediction!['risk_level'] is String)
        ? int.tryParse(_latestPrediction!['risk_level']) ?? 0
        : (_latestPrediction!['risk_level'] as num).toInt();
    
    String severity;
    Color severityColor;
    
    switch (riskLevel) {
      case 1:
        severity = 'Faible';
        severityColor = Colors.green;
        break;
      case 2:
        severity = 'Modéré';
        severityColor = Colors.orange;
        break;
      case 3:
        severity = 'Élevé';
        severityColor = Colors.red;
        break;
      default:
        severity = 'Inconnu';
        severityColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Risque de Crise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D0055),
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: CircularProgressIndicator(
                  value: riskProb,
                  strokeWidth: 14,
                  backgroundColor: Colors.grey.shade200,
                  color: severityColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(riskProb * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Données capteurs en temps réel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZonesToAvoid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.map_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Zones à Éviter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildZoneItem(
          'Centre-ville',
          'Pollution élevée',
          'Élevé',
          Colors.red.shade50,
          Colors.red,
          Icons.directions_car,
        ),
      ],
    );
  }

  Widget _buildZoneItem(String title, String subtitle, String badge, Color bg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.brown.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: color, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventionAI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préventions IA',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Basées sur vos données en temps réel',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreventionItem(1, 'Évitez les zones à forte pollution. Portez un masque anti-pollution si sortie nécessaire.', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPreventionItem(int number, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensors() {
    if (_latestSensorData == null) {
      return const SizedBox.shrink();
    }

    // Conversion sécurisée depuis la base de données (peut être String ou num)
    final humidity = (_latestSensorData!['humidity'] is String) 
        ? double.tryParse(_latestSensorData!['humidity']) ?? 0.0
        : (_latestSensorData!['humidity'] as num).toDouble();
    final temperature = (_latestSensorData!['temperature'] is String)
        ? double.tryParse(_latestSensorData!['temperature']) ?? 0.0
        : (_latestSensorData!['temperature'] as num).toDouble();
    final pm25 = (_latestSensorData!['pm25'] is String)
        ? double.tryParse(_latestSensorData!['pm25']) ?? 0.0
        : (_latestSensorData!['pm25'] as num).toDouble();
    final respRate = (_latestSensorData!['respiratory_rate'] is String)
        ? double.tryParse(_latestSensorData!['respiratory_rate']) ?? 0.0
        : (_latestSensorData!['respiratory_rate'] as num).toDouble();

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.satellite_alt, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Capteurs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text('Direct', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSensorCard('PM2.5', pm25.toStringAsFixed(0), Icons.air, Colors.orange.shade100, Colors.brown)),
            const SizedBox(width: 12),
            Expanded(child: _buildSensorCard('Humidité', '${humidity.toStringAsFixed(1)}%', Icons.water_drop_outlined, Colors.cyan.shade50, Colors.cyan)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSensorCard('Température', '${temperature.toStringAsFixed(1)}°', Icons.thermostat, Colors.purple.shade50, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildSensorCard('Rythme', respRate.toStringAsFixed(0), Icons.favorite, Colors.pink.shade50, Colors.pink)),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(String label, String value, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAIAdvice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Conseil IA',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.description_outlined, 'Journal', 0),
          _buildNavItem(Icons.bluetooth, 'Appareils', 1),
          _buildHomeNavItem(),
          _buildNavItem(Icons.book_outlined, 'Ressources', 3),
          _buildNavItem(Icons.person_outline, 'Profil', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? const Color(0xFFE040FB) : Colors.grey.shade400,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFE040FB) : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeNavItem() {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = 2;
        });
      },
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
