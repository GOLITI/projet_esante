import '../datasources/api_client.dart';
import '../datasources/local_database.dart';
import '../models/sensor_data.dart';

/// Repository pour gérer les prédictions d'asthme
class PredictionRepository {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;

  PredictionRepository({
    ApiClient? apiClient,
    LocalDatabase? localDatabase,
  })  : _apiClient = apiClient ?? ApiClient(),
        _localDatabase = localDatabase ?? LocalDatabase.instance;

  /// Faire une prédiction de risque d'asthme
  /// 
  /// Retourne un Map avec les résultats de la prédiction:
  /// - success: bool
  /// - risk_level: int (1, 2, 3)
  /// - risk_label: String ("Faible", "Modéré", "Élevé")
  /// - risk_score: double (0.0-1.0)
  /// - probabilities: Map<String, double>
  /// - recommendations: List<String>
  Future<Map<String, dynamic>?> predictAsthmaRisk({
    required int userId,
    required Map<String, int> symptoms,
    required String age,
    required String gender,
    required SensorData sensorData,
  }) async {
    try {
      // 1. Sauvegarder les données capteurs en local
      final sensorDataId = await _localDatabase.insertSensorData(
        userId,
        sensorData,
      );

      // 2. Appeler l'API de prédiction
      final demographics = {
        'age': age,
        'gender': gender,
      };

      final result = await _apiClient.predictAsthmaRisk(
        symptoms: symptoms,
        demographics: demographics,
        sensorData: sensorData,
      );

      if (result == null || result['success'] != true) {
        print('❌ Échec de la prédiction ML');
        return null;
      }

      // 3. Sauvegarder la prédiction en local
      await _localDatabase.insertPrediction(
        userId: userId,
        sensorDataId: sensorDataId,
        riskLevel: result['risk_label'], // "Faible", "Modéré", "Élevé"
        riskProbability: result['risk_score'],
        symptoms: symptoms.toString(), // Convertir Map en String pour stockage
      );

      print('✅ Prédiction réussie: ${result['risk_label']} (${(result['risk_score'] * 100).toStringAsFixed(1)}%)');
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de la prédiction: $e');
      return null;
    }
  }

  /// Obtenir l'historique des prédictions
  Future<List<Map<String, dynamic>>> getPredictionHistory(int userId, {int limit = 20}) async {
    try {
      return await _localDatabase.getPredictionHistory(userId, limit: limit);
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Obtenir les statistiques de risque
  Future<Map<String, int>> getRiskStats(int userId, {int days = 30}) async {
    try {
      return await _localDatabase.getRiskStats(userId, days: days);
    } catch (e) {
      print('❌ Erreur lors de la récupération des stats: $e');
      return {};
    }
  }

  /// Tester la connexion à l'API
  Future<bool> testApiConnection() async {
    try {
      return await _apiClient.testConnection();
    } catch (e) {
      print('❌ Erreur de connexion API: $e');
      return false;
    }
  }
}
