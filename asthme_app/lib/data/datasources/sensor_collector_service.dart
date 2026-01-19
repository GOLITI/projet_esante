import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sensor_data.dart';

/// Service pour collecter les données environnementales depuis OpenWeatherMap
/// Collecte: Humidité, PM2.5, AQI
class SensorDataCollectorService {
  
  // ✅ Clé API OpenWeatherMap configurée
  // Obtenir une clé gratuite sur: https://openweathermap.org/api
  static const String _openWeatherApiKey = 'dbe661438c559366daf85410e176682b';
  
  /// Demander les permissions de localisation
  Future<bool> requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
  
  /// Récupérer les données environnementales depuis OpenWeatherMap
  /// Retourne: humidité, PM2.5, AQI
  Future<SensorData?> collectEnvironmentalData() async {
    try {
      // 1. Vérifier les permissions de localisation
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        print('❌ Permissions de localisation refusées');
        return null;
      }
      
      // 2. Obtenir la position GPS
      print('📍 Récupération de la position GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('✅ Position: ${position.latitude}, ${position.longitude}');
      
      // 3. API Air Pollution (PM2.5 + AQI)
      final pollutionUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/air_pollution?'
        'lat=${position.latitude}&lon=${position.longitude}&appid=$_openWeatherApiKey',
      );
      
      print('🌐 Appel API Air Pollution...');
      final pollutionResponse = await http.get(pollutionUrl);
      
      // 4. API Weather (Humidity)
      final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?'
        'lat=${position.latitude}&lon=${position.longitude}&appid=$_openWeatherApiKey',
      );
      
      print('🌐 Appel API Weather...');
      final weatherResponse = await http.get(weatherUrl);
      
      // 5. Vérifier les réponses
      if (pollutionResponse.statusCode == 200 && weatherResponse.statusCode == 200) {
        final pollutionData = json.decode(pollutionResponse.body);
        final weatherData = json.decode(weatherResponse.body);
        
        // Extraire les données
        final humidity = (weatherData['main']['humidity'] as num).toDouble();
        final pm25 = (pollutionData['list'][0]['components']['pm2_5'] as num).toDouble();
        final aqi = (pollutionData['list'][0]['main']['aqi'] as num).toDouble();
        
        print('✅ Données collectées:');
        print('   - Humidité: $humidity%');
        print('   - PM2.5: $pm25 µg/m³');
        print('   - AQI: $aqi');
        
        return SensorData(
          humidity: humidity,
          temperature: 22.0, // Température ambiante par défaut
          pm25: pm25,
          respiratoryRate: 0.0, // 0 si pas de capteur de fréquence respiratoire
          timestamp: DateTime.now(),
        );
      } else {
        print('❌ Erreur API:');
        print('   - Pollution: ${pollutionResponse.statusCode}');
        print('   - Weather: ${weatherResponse.statusCode}');
        
        if (pollutionResponse.statusCode == 401 || weatherResponse.statusCode == 401) {
          print('⚠️  Clé API invalide ou manquante !');
          print('💡 Obtenez une clé gratuite sur: https://openweathermap.org/api');
        }
        
        return null;
      }
      
    } catch (e) {
      print('❌ Erreur collecte données environnementales: $e');
      return null;
    }
  }
  
  /// Tester la collecte des données
  Future<void> testDataCollection() async {
    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║                                                           ║');
    print('║       🧪 TEST COLLECTE DONNÉES ENVIRONNEMENTALES         ║');
    print('║                                                           ║');
    print('╚═══════════════════════════════════════════════════════════╝\n');
    
    final data = await collectEnvironmentalData();
    
    if (data != null) {
      print('\n✅ SUCCÈS !');
      print('─────────────────────────────────────────────────────────');
      print('Humidité:  ${data.humidity}%');
      print('Température: ${data.temperature}°C');
      print('PM2.5:     ${data.pm25} µg/m³ (${data.pm25Level})');
      print('Fréquence Resp.: ${data.respiratoryRate}/min (${data.respiratoryRateLevel})');
      print('Timestamp: ${data.timestamp}');
      print('Valid:     ${data.isValid}');
      print('─────────────────────────────────────────────────────────\n');
    } else {
      print('\n❌ ÉCHEC de la collecte');
      print('─────────────────────────────────────────────────────────');
      print('Vérifiez:');
      print('1. Votre clé API OpenWeatherMap');
      print('2. Votre connexion Internet');
      print('3. Les permissions de localisation');
      print('─────────────────────────────────────────────────────────\n');
    }
  }
}
