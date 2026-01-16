import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';

/// Service pour collecter les données depuis Arduino/ESP32 via Bluetooth BLE
class BluetoothSensorService {
  
  // Configuration BLE
  static const String _deviceNamePrefix = 'AsthmaESP32'; // Nom de votre ESP32
  static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String _characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  
  // État
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sensorCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _characteristicSubscription;
  
  // Données
  SensorData? _latestData;
  SensorData? get latestData => _latestData;
  
  // Streams
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  
  bool get isConnected => _connectedDevice != null;
  
  /// Vérifier si Bluetooth est activé
  Future<bool> isBluetoothEnabled() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        print('❌ Bluetooth BLE non supporté sur cet appareil');
        return false;
      }
      
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        print('⚠️ Bluetooth désactivé');
        return false;
      }
      
      return true;
    } catch (e) {
      print('❌ Erreur vérification Bluetooth: $e');
      return false;
    }
  }
  
  /// Scanner les appareils BLE disponibles
  Future<List<BluetoothDevice>> scanDevices({Duration timeout = const Duration(seconds: 10)}) async {
    final devices = <BluetoothDevice>[];
    
    try {
      print('🔍 Scan BLE démarré...');
      
      // Écouter les résultats du scan
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final device = result.device;
          final name = device.platformName;
          
          // Filtrer par nom (commence par "AsthmaESP32" ou autre)
          if (name.isNotEmpty && name.contains(_deviceNamePrefix)) {
            if (!devices.contains(device)) {
              devices.add(device);
              print('✅ Trouvé: $name (${device.remoteId})');
            }
          }
        }
      });
      
      // Démarrer le scan
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Attendre la fin
      await Future.delayed(timeout);
      
      print('🔍 Scan terminé: ${devices.length} appareil(s) trouvé(s)');
      
    } catch (e) {
      print('❌ Erreur scan BLE: $e');
    } finally {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
    }
    
    return devices;
  }
  
  /// Connecter à un appareil BLE
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔌 Connexion à ${device.platformName}...');
      
      // Se connecter
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      
      print('✅ Connecté à ${device.platformName}');
      _connectionStateController.add(true);
      
      // Découvrir les services
      await _discoverServices(device);
      
      return true;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _connectionStateController.add(false);
      return false;
    }
  }
  
  /// Découvrir les services et caractéristiques
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      print('🔎 Découverte des services...');
      
      final services = await device.discoverServices();
      
      for (var service in services) {
        print('   Service: ${service.uuid}');
        
        // Trouver notre service de capteurs
        if (service.uuid.toString() == _serviceUuid) {
          for (var characteristic in service.characteristics) {
            print('      Caractéristique: ${characteristic.uuid}');
            
            // Trouver la caractéristique des données capteurs
            if (characteristic.uuid.toString() == _characteristicUuid) {
              _sensorCharacteristic = characteristic;
              
              // S'abonner aux notifications
              await _subscribeToNotifications(characteristic);
              
              print('✅ Abonné aux notifications capteurs');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erreur découverte services: $e');
    }
  }
  
  /// S'abonner aux notifications de la caractéristique
  Future<void> _subscribeToNotifications(BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.setNotifyValue(true);
      
      _characteristicSubscription = characteristic.lastValueStream.listen((value) {
        _onDataReceived(value);
      });
    } catch (e) {
      print('❌ Erreur abonnement notifications: $e');
    }
  }
  
  /// Callback quand des données sont reçues
  void _onDataReceived(List<int> data) {
    try {
      // Convertir bytes en JSON
      final jsonStr = utf8.decode(data);
      final jsonData = json.decode(jsonStr);
      
      // Parser les données
      final sensorData = SensorData(
        humidity: (jsonData['humidity'] as num).toDouble(),
        temperature: (jsonData['temperature'] as num).toDouble(),
        pm25: (jsonData['pm25'] as num).toDouble(),
        respiratoryRate: (jsonData['respiratoryRate'] as num).toDouble(),
        timestamp: DateTime.now(),
      );
      
      _latestData = sensorData;
      _sensorDataController.add(sensorData);
      
      print('📊 Données BLE reçues: H=${sensorData.humidity}%, T=${sensorData.temperature}°C');
    } catch (e) {
      print('❌ Erreur parsing données BLE: $e');
    }
  }
  
  /// Lire les données une fois (sans notification)
  Future<SensorData?> readSensorData() async {
    if (_sensorCharacteristic == null) {
      print('❌ Caractéristique non disponible');
      return null;
    }
    
    try {
      final value = await _sensorCharacteristic!.read();
      _onDataReceived(value);
      return _latestData;
    } catch (e) {
      print('❌ Erreur lecture BLE: $e');
      return null;
    }
  }
  
  /// Déconnecter
  Future<void> disconnect() async {
    try {
      _characteristicSubscription?.cancel();
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        print('🔌 Déconnecté');
      }
      
      _connectedDevice = null;
      _sensorCharacteristic = null;
      _connectionStateController.add(false);
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }
  
  /// Nettoyer les ressources
  void dispose() {
    disconnect();
    _scanSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _connectionStateController.close();
    _sensorDataController.close();
  }
}

/*
═══════════════════════════════════════════════════════════════════════════
CODE ARDUINO/ESP32 POUR BLUETOOTH BLE
═══════════════════════════════════════════════════════════════════════════

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <DHT.h>
#include <ArduinoJson.h>

// UUIDs - DOIVENT correspondre au code Flutter
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Capteurs
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

class ServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("✅ Client BLE connecté");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("🔌 Client BLE déconnecté");
    BLEDevice::startAdvertising();
  }
};

void setup() {
  Serial.begin(115200);
  dht.begin();
  
  // Initialiser BLE
  BLEDevice::init("AsthmaESP32");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  // Créer service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Créer caractéristique
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pCharacteristic->addDescriptor(new BLE2902());
  
  // Démarrer service
  pService->start();
  
  // Démarrer advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  
  Serial.println("🔵 BLE prêt - En attente de connexion...");
}

void loop() {
  if (deviceConnected) {
    // Lire capteurs
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    float pm25 = readPM25(); // À implémenter
    float respRate = readRespiratoryRate(); // À implémenter
    
    // Créer JSON
    StaticJsonDocument<200> doc;
    doc["humidity"] = humidity;
    doc["temperature"] = temperature;
    doc["pm25"] = pm25;
    doc["respiratoryRate"] = respRate;
    
    String jsonString;
    serializeJson(doc, jsonString);
    
    // Envoyer notification
    pCharacteristic->setValue(jsonString.c_str());
    pCharacteristic->notify();
    
    Serial.println("📤 Données envoyées: " + jsonString);
  }
  
  delay(2000);
}

float readPM25() { return 35.0; }
float readRespiratoryRate() { return 16.0; }

═══════════════════════════════════════════════════════════════════════════
*/
