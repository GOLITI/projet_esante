import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

/// Client API pour communiquer avec le backend Flask (prédiction ML)
class ApiClient {
  // ⚠️ Remplacez par l'URL de votre API Flask
  // En local: http://10.0.2.2:5000 (émulateur Android) ou http://localhost:5000
  // En production: https://votre-api.com
  // Réseau local: http://192.168.100.10:5000 (IP actuelle du serveur)
  static const String baseUrl = 'http://192.168.100.10:5000';
  
  final http.Client _httpClient;
  
  ApiClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();
  
  /// Test de connexion à l'API
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur connexion API: $e');
      return false;
    }
  }
  
  /// Prédire le risque d'asthme
  /// ⚠️ N'envoie QUE les symptômes + demographics
  /// Les données capteurs sont automatiquement récupérées depuis l'ESP32 par le backend
  Future<Map<String, dynamic>?> predictAsthmaRisk({
    required Map<String, int> symptoms,
    required Map<String, dynamic> demographics,
  }) async {
    try {
      // Format structuré attendu par l'API Flask
      // ⚠️ PAS de 'sensors' - le backend utilise les données ESP32
      final requestBody = {
        'symptoms': symptoms,         // 7 symptômes (0 ou 1)
        'demographics': demographics, // age, gender
      };
      
      print('📤 Envoi requête prédiction ML...');
      print('Symptoms: ${symptoms.length}, Demographics: ${demographics.length}');
      print('⚡ Les données capteurs seront fournies automatiquement par l\'ESP32');
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // L'API retourne: {success, risk_level, risk_label, risk_score, probabilities, recommendations, sensor_data_used}
        if (result['success'] == true) {
          print('✅ Prédiction reçue: ${result['risk_label']} (niveau ${result['risk_level']})');
          if (result['sensor_data_used'] != null) {
            print('📡 Données capteurs ESP32 utilisées: T=${result['sensor_data_used']['temperature']}°C, PM2.5=${result['sensor_data_used']['pm25']}');
          }
          return result;
        } else {
          print('❌ Erreur prédiction: ${result['error']}');
          return null;
        }
      } else if (response.statusCode == 503) {
        print('⚠️ Capteurs ESP32 non disponibles - attendez que l\'ESP32 envoie des données');
        return null;
      } else {
        print('❌ Erreur API ${response.statusCode}: ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('❌ Erreur requête prédiction: $e');
      return null;
    }
  }
  
  /// Inscription utilisateur
  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('❌ Erreur inscription: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur requête inscription: $e');
      return null;
    }
  }
  
  /// Connexion utilisateur
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Erreur connexion: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur requête connexion: $e');
      return null;
    }
  }
  
  void dispose() {
    _httpClient.close();
  }
}
