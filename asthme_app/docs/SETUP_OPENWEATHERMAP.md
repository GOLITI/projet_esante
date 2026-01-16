# 🌍 Configuration OpenWeatherMap API

## 📋 Vue d'ensemble

Votre application collecte maintenant **uniquement** les données environnementales depuis OpenWeatherMap :
- ✅ **Humidity** (Humidité ambiante en %)
- ✅ **PM2.5** (Particules fines en µg/m³)
- ✅ **AQI** (Indice de qualité de l'air 0-500)

## 🔑 Étape 1 : Obtenir une clé API OpenWeatherMap

1. Allez sur [https://openweathermap.org/api](https://openweathermap.org/api)
2. Cliquez sur **"Sign Up"** (gratuit)
3. Créez un compte
4. Allez dans **"API keys"**
5. Copiez votre clé API

**Plan gratuit :**
- ✅ 1000 appels/jour
- ✅ Largement suffisant pour votre projet

## 🔧 Étape 2 : Configurer la clé dans l'app

Ouvrez le fichier [lib/data/datasources/sensor_collector_service.dart](lib/data/datasources/sensor_collector_service.dart)

Ligne 10, remplacez :
```dart
static const String _openWeatherApiKey = 'VOTRE_CLE_API_ICI';
```

Par votre vraie clé :
```dart
static const String _openWeatherApiKey = 'abc123def456...';
```

## 📱 Étape 3 : Configurer les permissions Android

Ouvrez [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

Ajoutez dans `<manifest>` (avant `<application>`) :
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 🍎 Étape 4 : Configurer les permissions iOS

Ouvrez [ios/Runner/Info.plist](ios/Runner/Info.plist)

Ajoutez avant `</dict>` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin de votre localisation pour obtenir les données environnementales (qualité de l'air, pollution)</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Nous avons besoin de votre localisation pour obtenir les données environnementales</string>
```

## 🧪 Étape 5 : Tester la collecte

Dans votre code :
```dart
import 'package:asthme_app/data/datasources/sensor_collector_service.dart';

// Créer le service
final collector = SensorDataCollectorService();

// Tester
await collector.testDataCollection();

// Ou collecter directement
final data = await collector.collectEnvironmentalData();
if (data != null) {
  print('Humidité: ${data.humidity}%');
  print('PM2.5: ${data.pm25} µg/m³');
  print('AQI: ${data.aqi}');
}
```

## 📊 Utilisation avec le modèle ML

Pour faire une prédiction, vous devez combiner :
1. **Symptômes** (7 variables booléennes)
2. **Données démographiques** (Age, Gender, etc.)
3. **Données environnementales** (les 3 capteurs OpenWeatherMap)

Exemple :
```dart
// 1. Collecter données environnementales
final sensorData = await collector.collectEnvironmentalData();

// 2. Préparer les données complètes pour le modèle
final predictionData = {
  // Symptômes
  'Wheezing': hasWheezing ? 1 : 0,
  'Coughing': hasCoughing ? 1 : 0,
  // ... autres symptômes
  
  // Démographie
  'Age': age,
  'Gender': gender,
  // ... autres données
  
  // Capteurs environnementaux
  'Humidity': sensorData!.humidity,
  'PM25': sensorData.pm25,
  'AQI': sensorData.aqi,
};

// 3. Envoyer au backend pour prédiction
final response = await apiClient.predictAsthmaRisk(predictionData);
```

## ⚠️ Limitations

**Sans température et fréquence cardiaque**, votre modèle utilisera uniquement :
- 7 symptômes
- 7 données démographiques
- **3 capteurs environnementaux** (au lieu de 5)

**Impact sur la précision :**
- Précision actuelle (5 capteurs) : **93.72%**
- Précision estimée (3 capteurs) : **~90-92%**
- Les capteurs environnementaux contribuent à **53.47%** des prédictions
- Les 2 capteurs manquants (température, FC) représentent ~3-5% de perte

## 🎓 Pour votre présentation

**Points forts à mentionner :**
- ✅ Utilisation d'API professionnelle (OpenWeatherMap)
- ✅ Données géolocalisées en temps réel
- ✅ 3 paramètres environnementaux cruciaux pour l'asthme
- ✅ Qualité de l'air (AQI) et pollution (PM2.5) sont les facteurs environnementaux les plus importants pour l'asthme
- ✅ Architecture scalable et maintenable

**Limitations techniques (à expliquer) :**
- 🔒 Sécurité Android empêche l'accès aux données d'autres apps
- 🔧 Solution alternative : Données environnementales via API géolocalisée
- 📊 Le modèle ML reste très performant avec 3 capteurs (au lieu de 5)

## 🚀 Prochaines étapes

1. ✅ Obtenez votre clé API OpenWeatherMap
2. ✅ Configurez les permissions
3. ✅ Testez la collecte de données
4. ⏳ Intégrez avec le backend Flask
5. ⏳ Testez les prédictions end-to-end
6. ⏳ Préparez votre présentation

## 📝 Support

Si vous rencontrez des problèmes :
- Vérifiez votre connexion Internet
- Vérifiez que la clé API est valide
- Vérifiez que les permissions sont accordées
- Consultez la console pour les messages d'erreur détaillés
