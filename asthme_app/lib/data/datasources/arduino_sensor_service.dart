import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

/// Service pour collecter les données depuis Arduino/ESP32
/// Supporte WiFi (HTTP) et Bluetooth BLE
class ArduinoSensorService {
  
  // URL du serveur Arduino/ESP32 sur le réseau local
  // Remplacez par l'adresse IP de votre Arduino
  String _serverUrl = 'http://192.168.100.50:80'; // Exemple
  
  // État de connexion
  bool _isConnected = false;
  SensorData? _latestData;
  
  // Stream pour diffuser les données en temps réel
  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  
  // Timer pour polling périodique (mode WiFi)
  Timer? _pollingTimer;
  
  /// Configurer l'URL du serveur Arduino
  void setServerUrl(String url) {
    _serverUrl = url;
    print('📡 URL Arduino configurée: $_serverUrl');
  }
  
  /// Obtenir les dernières données collectées
  SensorData? get latestData => _latestData;
  bool get isConnected => _isConnected;
  
  // ============================================================================
  // MODE 1: WiFi HTTP - Récupération via requêtes HTTP
  // ============================================================================
  
  /// Tester la connexion au serveur Arduino
  Future<bool> testConnection() async {
    try {
      print('🔌 Test connexion Arduino sur $_serverUrl...');
      
      final response = await http.get(
        Uri.parse('$_serverUrl/health'),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print('✅ Arduino connecté !');
        _isConnected = true;
        return true;
      } else {
        print('❌ Arduino non accessible (code: ${response.statusCode})');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      print('❌ Erreur connexion Arduino: $e');
      _isConnected = false;
      return false;
    }
  }
  
  /// Récupérer les données des capteurs (une fois)
  Future<SensorData?> fetchSensorData() async {
    try {
      print('📡 Requête données capteurs Arduino...');
      
      final response = await http.get(
        Uri.parse('$_serverUrl/sensors'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parser les données selon le format de votre Arduino
        // Format attendu: {"humidity": 65.5, "temperature": 22.3, "pm25": 35.2, "respiratoryRate": 16.0}
        final sensorData = SensorData(
          humidity: (data['humidity'] as num).toDouble(),
          temperature: (data['temperature'] as num).toDouble(),
          pm25: (data['pm25'] as num).toDouble(),
          respiratoryRate: (data['respiratoryRate'] as num).toDouble(),
          timestamp: DateTime.now(),
        );
        
        _latestData = sensorData;
        _sensorDataController.add(sensorData);
        
        print('✅ Données reçues: H=${sensorData.humidity}%, T=${sensorData.temperature}°C, PM2.5=${sensorData.pm25}, FR=${sensorData.respiratoryRate}');
        
        return sensorData;
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur récupération données: $e');
      return null;
    }
  }
  
  /// Démarrer la collecte automatique (polling toutes les X secondes)
  void startAutoCollection({int intervalSeconds = 5}) {
    stopAutoCollection(); // Arrêter l'ancien timer si existant
    
    print('🔄 Démarrage collecte automatique (toutes les ${intervalSeconds}s)');
    
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) async {
        await fetchSensorData();
      },
    );
    
    // Première collecte immédiate
    fetchSensorData();
  }
  
  /// Arrêter la collecte automatique
  void stopAutoCollection() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      print('⏸️  Collecte automatique arrêtée');
    }
  }
  
  // ============================================================================
  // MODE 2: Bluetooth BLE - Réception via notifications BLE
  // ============================================================================
  
  /// Connecter à Arduino via Bluetooth BLE
  /// Note: Nécessite flutter_blue_plus package
  Future<void> connectBLE(String deviceName) async {
    try {
      print('🔵 Recherche Arduino BLE: $deviceName');
      
      // TODO: Implémenter avec flutter_blue_plus
      // 1. Scanner les appareils BLE
      // 2. Trouver l'appareil avec le bon nom
      // 3. Se connecter
      // 4. Découvrir les services/caractéristiques
      // 5. S'abonner aux notifications
      
      print('⚠️  Bluetooth BLE non encore implémenté');
      print('💡 Pour l\'instant, utilisez le mode WiFi HTTP');
    } catch (e) {
      print('❌ Erreur BLE: $e');
    }
  }
  
  /// Callback appelé quand des données BLE sont reçues
  void onBLEDataReceived(List<int> data) {
    try {
      // Parser les bytes selon le protocole de votre Arduino
      final jsonStr = utf8.decode(data);
      final jsonData = json.decode(jsonStr);
      
      final sensorData = SensorData(
        humidity: (jsonData['humidity'] as num).toDouble(),
        temperature: (jsonData['temperature'] as num).toDouble(),
        pm25: (jsonData['pm25'] as num).toDouble(),
        respiratoryRate: (jsonData['respiratoryRate'] as num).toDouble(),
        timestamp: DateTime.now(),
      );
      
      _latestData = sensorData;
      _sensorDataController.add(sensorData);
      
      print('✅ Données BLE reçues');
    } catch (e) {
      print('❌ Erreur parsing BLE: $e');
    }
  }
  
  // ============================================================================
  // SIMULATION pour tests sans Arduino
  // ============================================================================
  
  /// Générer des données de test (pour développement)
  SensorData generateMockData() {
    final data = SensorData(
      humidity: 50.0 + (DateTime.now().second % 30),
      temperature: 20.0 + (DateTime.now().second % 10),
      pm25: 20.0 + (DateTime.now().second % 50),
      respiratoryRate: 14.0 + (DateTime.now().second % 8),
      timestamp: DateTime.now(),
    );
    
    _latestData = data;
    _sensorDataController.add(data);
    
    return data;
  }
  
  /// Nettoyer les ressources
  void dispose() {
    stopAutoCollection();
    _sensorDataController.close();
  }
}

/*
═══════════════════════════════════════════════════════════════════════════
INSTRUCTIONS POUR CONFIGURER VOTRE ARDUINO/ESP32
═══════════════════════════════════════════════════════════════════════════

MATÉRIEL NÉCESSAIRE:
- ESP32 (recommandé) ou ESP8266
- Capteur DHT22 (humidité + température)
- Capteur PM2.5 (SDS011 ou PMS5003)
- Capteur respiration (peut être simulé avec accéléromètre ou capteur de pression)

CODE ARDUINO/ESP32 (Serveur HTTP):

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>

// Configuration WiFi
const char* ssid = "VotreWiFi";
const char* password = "VotreMotDePasse";

// Configuration capteurs
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

WebServer server(80);

void setup() {
  Serial.begin(115200);
  dht.begin();
  
  // Connexion WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\nWiFi connecté!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP()); // Notez cette adresse !
  
  // Routes HTTP
  server.on("/health", handleHealth);
  server.on("/sensors", handleSensors);
  
  server.begin();
  Serial.println("Serveur HTTP démarré");
}

void loop() {
  server.handleClient();
}

void handleHealth() {
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleSensors() {
  // Lire les capteurs
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  float pm25 = readPM25(); // À implémenter
  float respRate = readRespiratoryRate(); // À implémenter
  
  // Créer JSON
  String json = "{";
  json += "\"humidity\":" + String(humidity) + ",";
  json += "\"temperature\":" + String(temperature) + ",";
  json += "\"pm25\":" + String(pm25) + ",";
  json += "\"respiratoryRate\":" + String(respRate);
  json += "}";
  
  // Autoriser CORS
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}

float readPM25() {
  // TODO: Implémenter lecture capteur PM2.5
  return 35.0; // Valeur simulée
}

float readRespiratoryRate() {
  // TODO: Implémenter lecture capteur respiration
  return 16.0; // Valeur simulée
}
```

ÉTAPES:
1. Téléversez le code sur votre ESP32
2. Notez l'adresse IP affichée dans le Serial Monitor
3. Dans Flutter, appelez: service.setServerUrl('http://192.168.X.X:80')
4. Testez avec: service.testConnection()
5. Collectez avec: service.fetchSensorData()

═══════════════════════════════════════════════════════════════════════════
*/
