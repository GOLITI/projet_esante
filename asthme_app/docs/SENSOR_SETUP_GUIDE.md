# Guide de Configuration des Capteurs IoT

## 📋 Résumé de l'Implémentation

### ✅ Ce qui a été créé :

1. **[sensor_data.dart](lib/data/models/sensor_data.dart)** - Modèle pour les données capteurs
2. **[sensor_collector_service.dart](lib/data/datasources/sensor_collector_service.dart)** - Service de collecte
3. **[api_client.dart](lib/data/datasources/api_client.dart)** - Client API pour prédiction ML
4. **[pubspec.yaml](pubspec.yaml)** - Dépendances ajoutées (health, geolocator, permission_handler)

---

## 🔧 Configuration Requise

### 1. Installer les dépendances

```bash
cd asthme_app
flutter pub get
```

### 2. Configuration Android

**android/app/src/main/AndroidManifest.xml** :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### 3. Configuration iOS

**ios/Runner/Info.plist** :

```xml
<key>NSHealthShareUsageDescription</key>
<string>Nous avons besoin d'accéder à votre fréquence cardiaque pour prédire le risque d'asthme</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Nous stockons vos données de santé</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous utilisons votre localisation pour obtenir la qualité de l'air</string>
```

---

## 🔑 Configuration des API

### OpenWeatherMap (GRATUIT)

1. Allez sur : https://openweathermap.org/api
2. Créez un compte gratuit
3. Obtenez votre clé API
4. Dans **sensor_collector_service.dart**, remplacez :

```dart
static const String _openWeatherApiKey = 'VOTRE_CLE_API_ICI';
```

### API Flask Backend

Dans **api_client.dart**, configurez l'URL :

```dart
// Pour émulateur Android
static const String baseUrl = 'http://10.0.2.2:5000';

// Pour appareil physique (même réseau WiFi)
// static const String baseUrl = 'http://192.168.1.X:5000';
```

---

## 📱 Utilisation dans votre App

### Exemple 1 : Collecte Simple

```dart
import 'package:asthme_app/data/datasources/sensor_collector_service.dart';
import 'package:asthme_app/data/models/sensor_data.dart';

class HealthMonitoringScreen extends StatefulWidget {
  @override
  _HealthMonitoringScreenState createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  final SensorDataCollectorService _sensorService = SensorDataCollectorService();
  SensorData? _sensorData;
  bool _isLoading = false;
  
  // Symptômes de l'utilisateur
  Map<String, int> symptoms = {
    'Tiredness': 0,
    'Dry-Cough': 0,
    'Difficulty-in-Breathing': 0,
    'Sore-Throat': 0,
    'Pains': 0,
    'Nasal-Congestion': 0,
    'Runny-Nose': 0,
  };
  
  Future<void> _collectSensorData() async {
    setState(() => _isLoading = true);
    
    final data = await _sensorService.collectAllSensorData(
      symptoms: symptoms,
    );
    
    setState(() {
      _sensorData = data;
      _isLoading = false;
    });
    
    if (data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Données collectées avec succès')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monitoring Santé')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Bouton de collecte
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _collectSensorData,
              icon: Icon(Icons.sensors),
              label: Text(_isLoading ? 'Collecte en cours...' : 'Collecter les données'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Affichage des données
            if (_sensorData != null) ...[
              _buildSensorCard(
                icon: Icons.favorite,
                title: 'Fréquence Cardiaque',
                value: '${_sensorData!.heartRate} bpm',
                subtitle: _sensorData!.heartRateStatus,
                color: Colors.red,
              ),
              _buildSensorCard(
                icon: Icons.thermostat,
                title: 'Température',
                value: '${_sensorData!.temperature}°C',
                subtitle: 'Estimée',
                color: Colors.orange,
              ),
              _buildSensorCard(
                icon: Icons.water_drop,
                title: 'Humidité',
                value: '${_sensorData!.humidity}%',
                subtitle: 'Ambiante',
                color: Colors.blue,
              ),
              _buildSensorCard(
                icon: Icons.air,
                title: 'Qualité de l\'air',
                value: 'AQI: ${_sensorData!.aqi.toInt()}',
                subtitle: _sensorData!.airQualityLevel,
                color: Colors.green,
              ),
              _buildSensorCard(
                icon: Icons.cloud,
                title: 'Particules Fines',
                value: '${_sensorData!.pm25.toStringAsFixed(1)} µg/m³',
                subtitle: 'PM2.5',
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
```

### Exemple 2 : Prédiction ML Complète

```dart
import 'package:asthme_app/data/datasources/sensor_collector_service.dart';
import 'package:asthme_app/data/datasources/api_client.dart';
import 'package:asthme_app/data/models/sensor_data.dart';

class AsthmaPredictionScreen extends StatefulWidget {
  @override
  _AsthmaPredictionScreenState createState() => _AsthmaPredictionScreenState();
}

class _AsthmaPredictionScreenState extends State<AsthmaPredictionScreen> {
  final SensorDataCollectorService _sensorService = SensorDataCollectorService();
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  
  // Données utilisateur (à récupérer du profil)
  final int userAge = 25;
  final String userGender = 'M';
  
  // Symptômes
  Map<String, int> symptoms = {
    'Tiredness': 1,
    'Dry-Cough': 1,
    'Difficulty-in-Breathing': 1,
    'Sore-Throat': 0,
    'Pains': 0,
    'Nasal-Congestion': 1,
    'Runny-Nose': 0,
  };
  
  Future<void> _predictRisk() async {
    setState(() => _isLoading = true);
    
    // 1. Collecter les données capteurs
    final sensorData = await _sensorService.collectAllSensorData(
      symptoms: symptoms,
    );
    
    if (sensorData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur collecte des données')),
      );
      setState(() => _isLoading = false);
      return;
    }
    
    // 2. Préparer les données démographiques
    final demographics = {
      'Age_0-9': userAge < 10 ? 1 : 0,
      'Age_10-19': userAge >= 10 && userAge < 20 ? 1 : 0,
      'Age_20-24': userAge >= 20 && userAge < 25 ? 1 : 0,
      'Age_25-59': userAge >= 25 && userAge < 60 ? 1 : 0,
      'Age_60+': userAge >= 60 ? 1 : 0,
      'Gender_Female': userGender == 'F' ? 1 : 0,
      'Gender_Male': userGender == 'M' ? 1 : 0,
    };
    
    // 3. Envoyer à l'API pour prédiction
    final result = await _apiClient.predictAsthmaRisk(
      symptoms: symptoms,
      demographics: demographics,
      sensorData: sensorData,
    );
    
    setState(() {
      _predictionResult = result;
      _isLoading = false;
    });
    
    if (result != null && result['success'] == true) {
      _showResultDialog(result);
    }
  }
  
  void _showResultDialog(Map<String, dynamic> result) {
    final riskLabel = result['risk_label'];
    final riskScore = (result['risk_score'] * 100).toStringAsFixed(1);
    final recommendations = result['recommendations'] as List;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultat de la Prédiction'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Niveau de risque: $riskLabel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Confiance: $riskScore%'),
              SizedBox(height: 16),
              Text('Recommandations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...recommendations.map((rec) => Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('• $rec'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prédiction Asthme')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _predictRisk,
                icon: Icon(Icons.analytics),
                label: Text('Analyser le risque'),
              ),
      ),
    );
  }
}
```

---

## ⚠️ Points Importants

### Température Corporelle

La **température corporelle est ESTIMÉE** selon les symptômes car la plupart des montres fitness (dont HD Fit Pro) ne mesurent pas la température corporelle.

Si votre montre mesure la température, modifiez `estimateBodyTemperature()` dans `sensor_collector_service.dart`.

### Sources des Données

| Donnée | Source | Méthode |
|--------|--------|---------|
| **Heart_Rate** ❤️ | Montre HD Fit Pro | Package `health` → Lit depuis Health/Google Fit |
| **Humidity** 💧 | OpenWeatherMap API | Position GPS → API météo |
| **PM25** 🌫️ | OpenWeatherMap API | Position GPS → API pollution |
| **AQI** 🌍 | OpenWeatherMap API | Position GPS → API pollution |
| **Temperature** 🌡️ | Estimation | Basée sur symptômes (fièvre) |

---

## 🧪 Test de la Fonctionnalité

### 1. Tester la montre

```dart
final heartRate = await _sensorService.getHeartRateFromWatch();
print('FC: $heartRate bpm');
```

### 2. Tester l'API météo

```dart
final envData = await _sensorService.getEnvironmentalData();
print(envData);
```

### 3. Tester l'API ML

```dart
final isConnected = await _apiClient.testConnection();
print('API connectée: $isConnected');
```

---

## 📝 Configuration Finale

1. ✅ Installer dépendances : `flutter pub get`
2. ✅ Configurer permissions Android/iOS
3. ✅ Obtenir clé OpenWeatherMap
4. ✅ Connecter montre à l'app officielle (H Band)
5. ✅ Lancer backend Flask : `python main.py`
6. ✅ Tester l'app Flutter

**Tout est prêt ! Le système de collecte de données IoT est fonctionnel.** 🎉
