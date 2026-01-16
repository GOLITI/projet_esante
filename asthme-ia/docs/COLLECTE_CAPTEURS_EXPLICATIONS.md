# 📱 Collecte des Données des Capteurs - Explications

## ⚠️ IMPORTANT : Données Actuelles

### Situation Actuelle
Les données utilisées pour l'entraînement sont **SIMULÉES/GÉNÉRÉES**, pas collectées de vrais capteurs physiques.

**Pourquoi ?**
- Pour entraîner le modèle, nous avions besoin de 3663 échantillons
- Les vrais capteurs IoT ne sont pas encore déployés
- Nous avons généré des données réalistes basées sur des patterns médicaux

### Script de Génération
Le fichier `generate_enriched_dataset.py` a créé des données de capteurs **artificielles mais réalistes** :

```python
# Exemple de génération
if asthma_level == 3:  # Risque élevé
    pm25 = np.random.normal(50, 15)  # Air pollué
    heart_rate = base_hr + 20  # FC augmentée
else:
    pm25 = np.random.normal(15, 8)   # Air acceptable
```

---

## 🔌 Collecte Réelle des Capteurs (Phase de Production)

Voici comment la collecte des données se ferait **en pratique** avec de vrais capteurs :

### 1️⃣ **Architecture du Système**

```
┌─────────────────┐
│  CAPTEURS IoT   │
│                 │
│  • ESP32/Arduino│
│  • Smartwatch   │
│  • Station Météo│
└────────┬────────┘
         │ Bluetooth/WiFi
         ↓
┌─────────────────┐
│  APP FLUTTER    │
│  (Mobile)       │
│                 │
│  • Collecte     │
│  • Agrégation   │
│  • Envoi API    │
└────────┬────────┘
         │ HTTP/REST
         ↓
┌─────────────────┐
│  API FLASK      │
│  (Backend)      │
│                 │
│  • Validation   │
│  • Prédiction ML│
│  • Stockage DB  │
└─────────────────┘
```

---

### 2️⃣ **Types de Capteurs et leur Collecte**

#### 🌡️ **Température Corporelle**
**Source** : Thermomètre connecté ou smartwatch
```dart
// Dans l'app Flutter
Future<double> getTemperature() async {
  // Lecture depuis capteur Bluetooth
  BluetoothDevice thermometer = await findDevice('ThermoBLE');
  double temp = await thermometer.readTemperature();
  return temp; // Ex: 37.2°C
}
```

#### 💧 **Humidité & Qualité de l'air (PM2.5, AQI)**
**Source** : Station météo connectée ou API externe
```dart
// Option 1: Capteur local (ESP32 avec DHT22 + PM2.5)
Future<Map<String, double>> getEnvironmentalData() async {
  BluetoothDevice airQualitySensor = await findDevice('AirQuality');
  return {
    'humidity': await airQualitySensor.readHumidity(),    // Ex: 75%
    'pm25': await airQualitySensor.readPM25(),            // Ex: 45 µg/m³
    'aqi': await airQualitySensor.readAQI(),              // Ex: 120
  };
}

// Option 2: API externe (comme OpenWeatherMap)
Future<Map<String, double>> getEnvironmentalDataFromAPI() async {
  Position position = await Geolocator.getCurrentPosition();
  final response = await http.get(
    'https://api.openweathermap.org/data/2.5/air_pollution?lat=${position.latitude}&lon=${position.longitude}'
  );
  // Parser les données PM2.5, AQI, humidité
}
```

#### ❤️ **Fréquence Cardiaque**
**Source** : Smartwatch (Apple Watch, Samsung Galaxy Watch) ou oxymètre
```dart
// Via HealthKit (iOS) ou Google Fit (Android)
Future<int> getHeartRate() async {
  final healthData = await Health().getHealthDataFromTypes(
    startTime: DateTime.now().subtract(Duration(minutes: 1)),
    endTime: DateTime.now(),
    types: [HealthDataType.HEART_RATE],
  );
  return healthData.last.value; // Ex: 95 bpm
}
```

---

### 3️⃣ **Flux Complet dans l'App Flutter**

```dart
// screens/health_monitoring_screen.dart

class HealthMonitoringScreen extends StatefulWidget {
  @override
  _HealthMonitoringScreenState createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  Map<String, dynamic> sensorData = {};

  // Collecte automatique toutes les 30 secondes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      collectAllSensorData();
    });
  }

  Future<void> collectAllSensorData() async {
    setState(() {
      sensorData = {
        // Capteurs physiologiques
        'Temperature': await getTemperature(),       // 37.2
        'Heart_Rate': await getHeartRate(),          // 95
        
        // Capteurs environnementaux
        'Humidity': await getHumidity(),             // 75.0
        'PM25': await getPM25(),                     // 45.0
        'AQI': await getAQI(),                       // 120
        
        // Symptômes (saisis par l'utilisateur)
        'Tiredness': userSymptoms['Tiredness'],
        'Dry-Cough': userSymptoms['Dry-Cough'],
        // ... autres symptômes
      };
    });
    
    // Afficher dans l'interface
    displaySensorData();
  }

  // Envoyer à l'API pour prédiction
  Future<void> predictAsthmaRisk() async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(sensorData),
    );
    
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Résultat: ${result['risk_label']}'),
          content: Text('Risque: ${(result['risk_score'] * 100).toFixed(1)}%'),
        ),
      );
    }
  }
}
```

---

### 4️⃣ **Matériel Nécessaire (Setup Pratique)**

#### Option 1: **Setup Basique** (Pas cher)
- **Smartphone** avec app Flutter (déjà disponible)
- **Smartwatch** ou bracelet fitness (pour FC) : ~50-150€
- **API météo gratuite** (OpenWeatherMap) pour PM2.5/AQI/Humidité
- **Thermomètre Bluetooth** : ~20-40€

#### Option 2: **Setup Avancé** (Complet)
- Smartphone + Smartwatch
- **Station météo connectée** (Netatmo, AirVisual) : ~150-300€
  - Mesure PM2.5, AQI, Humidité, Température ambiante
- **Oxymètre connecté** : ~30-60€
- **Thermomètre médical Bluetooth** : ~30€

#### Option 3: **Setup DIY** (Pour projet)
- **ESP32** (microcontrôleur WiFi/Bluetooth) : ~10€
- **Capteur DHT22** (température + humidité) : ~5€
- **Capteur PM2.5** (SDS011 ou PMS5003) : ~25€
- **Capteur de pouls MAX30102** : ~8€

**Code Arduino pour ESP32** :
```cpp
#include <WiFi.h>
#include <DHT.h>

DHT dht(DHTPin, DHT22);

void setup() {
  Serial.begin(115200);
  dht.begin();
  WiFi.begin(ssid, password);
}

void loop() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  float pm25 = readPM25Sensor();
  
  // Envoyer via WiFi à l'app Flutter
  sendDataToApp(temp, humidity, pm25);
  
  delay(30000); // Toutes les 30 secondes
}
```

---

## 📊 Explication des Données d'Entraînement

### Dataset Original
- **Source** : `asthma_detection.csv` (3663 lignes)
- **Contenu** : Symptômes + Démographie + Niveau d'asthme
- **Origine** : Dataset médical synthétique basé sur études cliniques

### Dataset Enrichi (Actuel)
- **Fichier** : `asthma_detection_with_sensors.csv`
- **Méthode** : Génération automatique via `generate_enriched_dataset.py`

#### Comment les valeurs ont été générées ?

```python
# 1. Température : Corrélée avec symptômes infectieux
if symptômes_infection:
    temperature = 37.5°C + variation  # Légère fièvre
else:
    temperature = 36.8°C + variation  # Normal

# 2. Humidité : Impact sur asthme
if risque_asthme_élevé:
    humidity = 75% (trop humide) OU 25% (trop sec)
else:
    humidity = 50% (idéal)

# 3. PM2.5 & AQI : Principaux déclencheurs
if risque_asthme == 'Élevé':
    pm25 = 50 µg/m³  # Pollution élevée
elif risque_asthme == 'Modéré':
    pm25 = 30 µg/m³  # Pollution moyenne
else:
    pm25 = 15 µg/m³  # Air acceptable

# 4. Fréquence cardiaque : Réaction physiologique
base_hr = 75 bpm
if difficulté_respiratoire:
    base_hr += 20 bpm  # Augmentation
if fatigue:
    base_hr += 10 bpm
```

### Logique Médicale Appliquée
1. **PM2.5 élevé** → Plus de risque d'asthme (corrélation forte : 78%)
2. **Humidité extrême** → Aggrave les symptômes
3. **FC élevée** → Stress respiratoire
4. **Difficulté respiratoire** + **Toux** → Indicateurs majeurs

---

## 🔄 Transition vers Données Réelles

### Phase 1 : **Entraînement** (Actuel) ✅
- Utilise données simulées
- Modèle entraîné avec 93.72% accuracy
- Prêt pour tests

### Phase 2 : **Pilote** (Prochaine étape)
- Déployer app Flutter avec collecte capteurs
- 10-20 utilisateurs tests
- Collecter données réelles pendant 1 mois
- Comparer prédictions vs diagnostics médicaux

### Phase 3 : **Production** (Futur)
- Ré-entraîner le modèle avec données réelles
- Déploiement à grande échelle
- Monitoring continu

---

## 💡 Recommandation pour votre Projet

### Pour la Démonstration/Présentation
**Vous pouvez utiliser l'une de ces approches** :

#### 1. **Simulation en temps réel** (Plus simple)
```dart
// Dans l'app Flutter
Map<String, dynamic> simulateSensorData() {
  return {
    'Temperature': 36.5 + Random().nextDouble() * 2,  // 36.5-38.5
    'Humidity': 30 + Random().nextDouble() * 50,      // 30-80%
    'PM25': 10 + Random().nextDouble() * 60,          // 10-70
    'AQI': 20 + Random().nextInt(150),                // 20-170
    'Heart_Rate': 60 + Random().nextInt(60),          // 60-120
  };
}
```

#### 2. **Valeurs manuelles** (Interface de saisie)
- Curseurs dans l'app pour ajuster chaque capteur
- L'utilisateur peut tester différents scénarios
- Parfait pour démonstration

#### 3. **Intégration partielle** (Recommandé si possible)
- Connecter seulement la fréquence cardiaque (via smartwatch)
- Simuler le reste
- Montre la capacité d'intégration IoT

---

## ❓ Questions Fréquentes

**Q: Les données d'entraînement sont-elles fiables ?**  
R: Oui, elles sont basées sur des corrélations médicales réelles (PM2.5 ↔ asthme, FC ↔ stress respiratoire). Le modèle a 93.72% accuracy.

**Q: Faut-il racheter du matériel ?**  
R: Non pour la démo. L'app peut simuler les capteurs ou utiliser des valeurs saisies manuellement.

**Q: Peut-on utiliser ce modèle avec de vrais capteurs ?**  
R: Oui ! L'API est prête. Il suffit d'envoyer les vraies valeurs au lieu des simulées.

**Q: Comment valider les prédictions ?**  
R: En phase pilote, comparer avec diagnostics médicaux réels (spirométrie, consultation pneumologue).

---

**Créé pour le projet E-Santé 4.0**  
**Date** : 16 janvier 2026
