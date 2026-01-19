import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_database.dart';

/// Service pour collecter automatiquement les données capteurs depuis le backend
/// et les sauvegarder dans la base de données locale
class AutoSensorCollector {
  static final AutoSensorCollector instance = AutoSensorCollector._();
  AutoSensorCollector._();

  Timer? _collectionTimer;
  bool _isRunning = false;
  String _backendUrl = 'http://192.168.137.174:5000';
  int _consecutiveErrors = 0;
  static const int maxConsecutiveErrors = 3;

  /// Démarrer la collecte automatique
  /// [intervalSeconds] - Intervalle entre chaque collecte (par défaut: 30 secondes)
  void startAutoCollection({int intervalSeconds = 30}) {
    if (_isRunning) {
      print('⚠️  La collecte automatique est déjà en cours');
      return;
    }

    print('🔄 Démarrage de la collecte automatique (toutes les $intervalSeconds secondes)');
    _isRunning = true;

    // Première collecte immédiate
    _collectSensorData();

    // Collecte périodique
    _collectionTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) => _collectSensorData(),
    );
  }

  /// Arrêter la collecte automatique
  void stopAutoCollection() {
    if (_collectionTimer != null) {
      _collectionTimer!.cancel();
      _collectionTimer = null;
      _isRunning = false;
      print('⏸️  Collecte automatique arrêtée');
    }
  }

  /// Configurer l'URL du backend
  void setBackendUrl(String url) {
    _backendUrl = url;
    print('📡 URL backend configurée: $_backendUrl');
  }

  /// Collecter les données capteurs depuis le backend
  Future<void> _collectSensorData() async {
    try {
      print('📡 Récupération des données capteurs depuis le backend...');

      final response = await http.get(
        Uri.parse('$_backendUrl/api/sensors/latest'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final sensorData = data['data'];

          // Conversion sécurisée des valeurs
          final humidity = _toDouble(sensorData['humidity']);
          final temperature = _toDouble(sensorData['temperature']);
          final pm25 = _toDouble(sensorData['pm25']);
          final respiratoryRate = _toDouble(sensorData['respiratoryRate']);

          // Vérifier que les données sont valides
          if (humidity == 0.0 && temperature == 0.0 && pm25 == 0.0 && respiratoryRate == 0.0) {
            print('⚠️  Aucune donnée capteur valide reçue (toutes à 0)');
            return;
          }

          // Sauvegarder dans la base de données
          final db = await LocalDatabase.instance.database;
          await db.insert('sensor_history', {
            'user_id': 1, // TODO: Utiliser le vrai user_id
            'humidity': humidity,
            'temperature': temperature,
            'pm25': pm25,
            'respiratory_rate': respiratoryRate,
            'timestamp': DateTime.now().toIso8601String(),
          });

          print('✅ Données capteurs sauvegardées:');
          print('   - Humidité: $humidity%');
          print('   - Température: $temperature°C');
          print('   - PM2.5: $pm25 µg/m³');
          print('   - Fréquence respiratoire: $respiratoryRate/min');
          
          // Réinitialiser le compteur d'erreurs
          _consecutiveErrors = 0;
        } else {
          print('⚠️  Pas de données disponibles: ${data['message']}');
        }
      } else if (response.statusCode == 404) {
        print('⚠️  Aucune donnée capteur disponible sur le backend');
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        _consecutiveErrors++;
      }
    } catch (e) {
      _consecutiveErrors++;
      if (e.toString().contains('TimeoutException')) {
        print('⏱️  Timeout lors de la collecte (backend trop lent ou inaccessible)');
      } else {
        print('❌ Erreur lors de la collecte: $e');
      }
      
      // Si trop d'erreurs consécutives, arrêter temporairement la collecte
      if (_consecutiveErrors >= maxConsecutiveErrors) {
        print('⚠️  Trop d\'erreurs consécutives ($_consecutiveErrors). Collecte automatique désactivée.');
        print('💡 Vérifiez que le backend Flask est accessible sur $_backendUrl');
        stopAutoCollection();
      }
    }
  }

  /// Convertir une valeur en double de manière sécurisée
  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Obtenir le statut de la collecte
  bool get isRunning => _isRunning;
}
