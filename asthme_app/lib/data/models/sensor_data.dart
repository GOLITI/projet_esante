/// Modèle pour les données capteurs PHYSIQUES
/// Capteurs: Humidité, Température ambiante, PM2.5, Fréquence respiratoire
class SensorData {
  final double humidity;              // Humidité ambiante (%)
  final double temperature;           // Température ambiante (°C)
  final double pm25;                  // Particules fines (µg/m³)
  final double respiratoryRate;       // Fréquence respiratoire (respirations/min)
  final DateTime timestamp;           // Horodatage de la collecte

  SensorData({
    required this.humidity,
    required this.temperature,
    required this.pm25,
    required this.respiratoryRate,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convertir en JSON pour l'API backend
  Map<String, dynamic> toJson() {
    return {
      'Humidity': humidity,
      'Temperature': temperature,
      'PM25': pm25,
      'RespiratoryRate': respiratoryRate,
    };
  }

  /// Créer depuis JSON  
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      humidity: (json['Humidity'] ?? json['humidity'] as num).toDouble(),
      temperature: (json['Temperature'] ?? json['temperature'] as num).toDouble(),
      pm25: (json['PM25'] ?? json['pm25'] as num).toDouble(),
      respiratoryRate: (json['RespiratoryRate'] ?? json['respiratory_rate'] as num).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Créer des données par défaut (pour fallback/test)
  factory SensorData.defaultValues() {
    return SensorData(
      humidity: 50.0,
      temperature: 22.0,
      pm25: 25.0,
      respiratoryRate: 16.0,
    );
  }

  /// Copie avec modifications
  SensorData copyWith({
    double? humidity,
    double? temperature,
    double? pm25,
    double? respiratoryRate,
    DateTime? timestamp,
  }) {
    return SensorData(
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      pm25: pm25 ?? this.pm25,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SensorData(H: ${humidity}%, T: ${temperature}°C, PM2.5: ${pm25} µg/m³, RR: ${respiratoryRate}/min)';
  }

  /// Vérifier si les données sont dans des plages normales
  bool get isValid {
    return humidity >= 0 && humidity <= 100 &&
           temperature >= -50 && temperature <= 60 &&
           pm25 >= 0 && pm25 <= 500 &&
           respiratoryRate >= 5 && respiratoryRate <= 60;
  }

  /// Obtenir le niveau de température ambiante
  String get temperatureLevel {
    if (temperature < 15) return 'Froid';
    if (temperature <= 25) return 'Confortable';
    if (temperature <= 35) return 'Chaud';
    return 'Très chaud';
  }
  
  /// Obtenir le niveau de pollution PM2.5
  String get pm25Level {
    if (pm25 <= 12) return 'Bon';
    if (pm25 <= 35) return 'Modéré';
    if (pm25 <= 55) return 'Mauvais pour groupes sensibles';
    if (pm25 <= 150) return 'Mauvais';
    return 'Très mauvais';
  }

  /// Obtenir le niveau de fréquence respiratoire
  String get respiratoryRateLevel {
    if (respiratoryRate < 12) return 'Bradypnée (lente)';
    if (respiratoryRate <= 20) return 'Normale';
    if (respiratoryRate <= 25) return 'Légèrement élevée';
    return 'Tachypnée (rapide)';
  }
}
