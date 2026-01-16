# 📊 Architecture Finale - Application Asthme

## 🎯 Capteurs Physiques (4 capteurs)

| Capteur | Type | Unité | Plage normale |
|---------|------|-------|---------------|
| **Humidité** | Environnemental | % | 0-100% |
| **Température** | Ambiante | °C | -50 à 60°C |
| **PM2.5** | Pollution | µg/m³ | 0-500 µg/m³ |
| **Fréquence Respiratoire** | Physiologique | /min | 5-60 respirations/min |

## 🏗️ Architecture Technique

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                       │
│                       (sur téléphone)                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SQLite LOCAL (asthme_app.db)                            │
│     ├── Authentification utilisateur                         │
│     ├── Profils utilisateurs (avec âge)                      │
│     ├── Historique des capteurs                             │
│     └── Historique des prédictions                          │
│                                                              │
│  2. Collecte Capteurs PHYSIQUES                             │
│     ├── Humidité → Capteur DHT22 / BME280                   │
│     ├── Température → Capteur DHT22 / BME280                │
│     ├── PM2.5 → Capteur SDS011 / PMS5003                    │
│     └── Fréquence Resp. → Capteur de respiration            │
│                                                              │
│  3. Interface Utilisateur                                    │
│     ├── Login/Register (SQLite local)                        │
│     ├── Dashboard avec données capteurs                      │
│     ├── Formulaire symptômes                                 │
│     └── Affichage prédictions                               │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ HTTP POST /api/predict
                   │ {symptoms, demographics, sensors}
                   │
┌──────────────────▼──────────────────────────────────────────┐
│              BACKEND FLASK (Python)                          │
│                 (sur PC/serveur)                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. API Flask (port 5000)                                    │
│     └── /api/predict → Prédictions ML                       │
│                                                              │
│  2. Modèle ML (Random Forest)                                │
│     ├── models/asthma_model.pkl                             │
│     ├── Précision: 93.72%                                    │
│     └── Features: 19 (7 symptômes + 7 démo + 4 capteurs + 1)│
│                                                              │
│  3. SQLite Backend (asthme_backend.db) - OPTIONNEL          │
│     └── Historique global des prédictions (si nécessaire)   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Données Envoyées au Backend

### Format JSON pour `/api/predict` :

```json
{
  "symptoms": {
    "Wheezing": 1,
    "Coughing": 0,
    "ShortnessOfBreath": 1,
    "ChestTightness": 0,
    "NightSymptoms": 1,
    "ExerciseSenseSymptoms": 0,
    "Fatigue": 1
  },
  "demographics": {
    "Age": 25,
    "Gender": 1,
    "BMI": 24.5,
    "Smoking": 0,
    "PhysicalActivity": 3,
    "DietQuality": 4,
    "SleepQuality": 3,
    "PollutionExposure": 2,
    "PollenExposure": 1,
    "DustExposure": 1,
    "PetAllergy": 0,
    "FamilyHistoryAsthma": 1,
    "HistoryOfAllergies": 0,
    "EczemaHistory": 0,
    "HayFever": 1,
    "GastroesophagealReflux": 0,
    "LungFunctionFEV1": 85.0,
    "LungFunctionFVC": 90.0
  },
  "sensors": {
    "Humidity": 65.0,
    "Temperature": 22.5,
    "PM25": 35.2,
    "RespiratoryRate": 18.0
  }
}
```

### Réponse du Backend :

```json
{
  "prediction": 1,
  "risk_level": "High",
  "risk_probability": 0.87,
  "message": "Risque élevé d'asthme détecté"
}
```

## 🔄 Flux de Fonctionnement

### 1. Inscription / Connexion
```
Utilisateur → Formulaire → SQLite LOCAL → Login réussi
```

### 2. Collecte des Données
```
Capteurs Physiques → Flutter → Affichage en temps réel → SQLite LOCAL (historique)
```

### 3. Prédiction
```
1. Utilisateur remplit symptômes
2. Flutter collecte : Symptômes + Profil (SQLite) + Capteurs actuels
3. Flutter → POST → Backend Flask
4. Backend → Modèle Random Forest → Prédiction
5. Backend → JSON Response → Flutter
6. Flutter → Affichage résultat + Sauvegarde SQLite LOCAL
```

## 🗄️ Schéma Base de Données (SQLite LOCAL)

### Table `users`
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

### Table `sensor_history`
```sql
CREATE TABLE sensor_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  humidity REAL NOT NULL,
  temperature REAL NOT NULL,
  pm25 REAL NOT NULL,
  respiratory_rate REAL NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

### Table `predictions`
```sql
CREATE TABLE predictions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  sensor_data_id INTEGER NOT NULL,
  risk_level TEXT NOT NULL,
  risk_probability REAL NOT NULL,
  symptoms TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id),
  FOREIGN KEY (sensor_data_id) REFERENCES sensor_history (id)
);
```

### Table `user_profile`
```sql
CREATE TABLE user_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,
  age INTEGER NOT NULL,
  gender TEXT,
  bmi REAL,
  smoking INTEGER,
  physical_activity INTEGER,
  -- ... autres champs démographiques
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

## 📱 Interface de Connexion Capteurs

### Option 1: Simulation (développement)
```dart
// Données de test
SensorData.defaultValues() → H:50%, T:22°C, PM2.5:25, RR:16/min
```

### Option 2: Capteurs Réels (production)
```dart
// À implémenter selon vos capteurs physiques
// Connexion via Bluetooth, Wi-Fi, ou USB OTG
```

## 🚀 Démarrage

### Backend Flask
```bash
cd asthme-ia
python main.py
# Serveur sur http://localhost:5000
```

### Application Flutter
```bash
cd asthme_app
flutter run
# Choisir appareil Android/iOS
```

## ✅ Avantages de cette Architecture

1. **✅ Authentification locale** → Pas de serveur requis pour login
2. **✅ Données persistantes** → Historique conservé sur téléphone
3. **✅ Fonctionne offline** → Collecte capteurs + historique même sans internet
4. **✅ Backend léger** → Seulement pour prédictions ML
5. **✅ Évolutif** → Facile d'ajouter de nouveaux capteurs
6. **✅ Sécurisé** → Données personnelles restent locales
7. **✅ Capteurs physiques** → Architecture prête pour vrais capteurs

## 🔧 Prochaines Étapes

1. ✅ Backend Flask configuré (SQLite)
2. ✅ Modèle SensorData mis à jour (4 capteurs)
3. ✅ Base de données locale mise à jour
4. ⏳ Implémenter collecte depuis capteurs physiques
5. ⏳ Tester intégration Flutter → Backend
6. ⏳ Interface utilisateur pour visualisation capteurs
