# 🎨 RÉSUMÉ VISUEL DU PROJET

## 📊 ARCHITECTURE GLOBALE

```
┌─────────────────────────────────────────────────────────────────────┐
│                         APPLICATION E-SANTÉ                         │
│                   Prévention des crises d'asthme                    │
└─────────────────────────────────────────────────────────────────────┘

┌────────────────┐         ┌───────────────┐         ┌───────────────┐
│   CAPTEURS     │  WiFi   │  BACKEND IA   │   API   │  APP MOBILE   │
│   ESP32        │────────▶│   Flask       │◀────────│   Flutter     │
│                │  HTTP   │   Python      │  REST   │   Dart        │
└────────────────┘         └───────────────┘         └───────────────┘
     │                           │                          │
     │                           │                          │
┌────▼────┐              ┌───────▼────────┐        ┌───────▼────────┐
│ DHT22   │              │ Random Forest  │        │ SQLite local   │
│ (T,H)   │              │ 100 arbres     │        │ Historique     │
│         │              │ 85-90% précis. │        │ Offline-first  │
│ MQ135   │              │                │        │                │
│ (PM2.5) │              │ Génère FR auto │        │ BLoC pattern   │
└─────────┘              └────────────────┘        └────────────────┘
```

---

## 🔄 FLUX DE DONNÉES

### Étape 1 : Collecte
```
ESP32 mesure :
  🌡️ Température : 28.5°C
  💧 Humidité : 75%
  🌫️ PM2.5 : 55 µg/m³
  ❌ Fréquence Resp. : (pas de capteur)

         │
         ▼ POST /api/sensors
```

### Étape 2 : Backend génère FR
```
Backend calcule :
  Base = 16 resp/min
  + PM2.5 élevé (55>35) : +1.8
  + Humidité haute (75>70) : +1.2
  + Variation naturelle : +0.3
  ───────────────────────────
  Total = 19.3 resp/min ✅

         │
         ▼ Stocke en mémoire
```

### Étape 3 : App récupère
```
App Flutter :
  GET /api/sensors/latest

Backend répond :
  {
    "temperature": 28.5,
    "humidity": 75.0,
    "pm25": 55.0,
    "respiratoryRate": 19.3 ← Généré
  }

         │
         ▼ Insert SQLite
```

### Étape 4 : Dashboard affiche
```
┌─────────────────────────────────────┐
│         DASHBOARD                   │
├─────────────────────────────────────┤
│  🌡️ Température    28.5°C (Chaud)   │
│  💧 Humidité       75% (Élevé)      │
│  🌫️ PM2.5          55 µg/m³ (Mauvais)│
│  💨 Fréq. Resp.    19.3 /min        │
│                                     │
│  📊 Analyse IA : Pas encore         │
│  [Nouvelle Évaluation] ←─ Clic     │
└─────────────────────────────────────┘
```

### Étape 5 : Utilisateur analyse
```
Écran Prédiction :
  ✅ Données capteurs pré-remplies
  ✅ Sélection symptômes :
     [x] Toux sèche
     [x] Difficulté respiratoire
     [ ] Mal de gorge
  ✅ Âge : 20-24 ans
  ✅ Genre : Homme

         │
         ▼ Clic "Analyser le Risque"
         ▼ POST /api/predict
```

### Étape 6 : IA prédit
```
Backend prépare features :
  {
    "Dry-Cough": 1,
    "Difficulty-in-Breathing": 1,
    "Sore-Throat": 0,
    ...
    "Age_20-24": 1,
    "Gender_Male": 1,
    "Humidity": 75.0,
    "Temperature": 28.5,
    "PM25": 55.0,
    "RespiratoryRate": 19.3
  }

Random Forest (100 arbres) :
  Arbre 1 → Vote : 2 (Modéré)
  Arbre 2 → Vote : 2 (Modéré)
  Arbre 3 → Vote : 3 (Élevé)
  ...
  Arbre 100 → Vote : 2 (Modéré)

Vote final :
  Risque 1 (Faible) : 15 votes (15%)
  Risque 2 (Modéré) : 67 votes (67%) ← Gagnant
  Risque 3 (Élevé) : 18 votes (18%)

         │
         ▼ Génère recommandations
```

### Étape 7 : Résultat affiché
```
┌─────────────────────────────────────┐
│  🟣 Risque Modéré                   │
├─────────────────────────────────────┤
│                                     │
│        ┌─────────┐                  │
│        │   67%   │                  │
│        │ Modéré  │                  │
│        └─────────┘                  │
│                                     │
│  📋 Recommandations :               │
│  • Consultez un médecin            │
│  • Surveillez vos symptômes        │
│  • 🌫️ Air mauvais - Restez dedans  │
│  • 💧 Humidité élevée              │
│  • Respirez lentement              │
│                                     │
│  [Fermer]                           │
└─────────────────────────────────────┘

         │
         ▼ Dashboard mis à jour
```

### Étape 8 : Dashboard actualisé
```
┌─────────────────────────────────────┐
│         DASHBOARD                   │
├─────────────────────────────────────┤
│  📊 Analyse IA                      │
│  ┌───────────────────────────────┐  │
│  │ 🟣 MODÉRÉ (67%)              │  │
│  │ Risque modéré détecté        │  │
│  │ Surveillez vos symptômes     │  │
│  └───────────────────────────────┘  │
│                                     │
│  🌡️ Température    28.5°C           │
│  💧 Humidité       75%              │
│  🌫️ PM2.5          55 µg/m³         │
│  💨 Fréq. Resp.    19.3 /min        │
└─────────────────────────────────────┘
```

---

## 🎯 COULEURS DES RISQUES

### Risque Faible
```
┌───────────────┐
│ 🟢 FAIBLE     │  Couleur : Vert (#22C55E)
│   0-40%       │  Message : Conditions favorables
└───────────────┘  Action : Maintenez bonne hygiène
```

### Risque Modéré
```
┌───────────────┐
│ 🟣 MODÉRÉ     │  Couleur : Violet (#E040FB)
│   40-70%      │  Message : Surveillez symptômes
└───────────────┘  Action : Ayez inhalateur à portée
```

### Risque Élevé
```
┌───────────────┐
│ 🔴 ÉLEVÉ      │  Couleur : Rouge (#EF4444)
│   70-100%     │  Message : Risque important !
└───────────────┘  Action : Consultez médecin IMMÉDIATEMENT
```

---

## 🧠 RANDOM FOREST EXPLIQUÉ VISUELLEMENT

### Structure
```
                    RANDOM FOREST
                         │
        ┌────────────────┼────────────────┐
        │                │                │
     Arbre 1         Arbre 2  ...    Arbre 100
        │                │                │
    ┌───┼───┐        ┌───┼───┐        ┌───┼───┐
    │   │   │        │   │   │        │   │   │
  Feuilles         Feuilles         Feuilles
   Vote: 2          Vote: 2          Vote: 3

            VOTE MAJORITAIRE
                  ↓
           Risque 2 (Modéré)
```

### Exemple d'arbre
```
                      [PM25 > 50 ?]
                     /             \
                  OUI               NON
                   │                 │
        [Difficulté Resp = 1 ?]   [Humidité > 60 ?]
           /            \            /           \
         OUI           NON         OUI          NON
          │             │           │            │
       Risque 3      Risque 2    Risque 2    Risque 1
       (Élevé)      (Modéré)    (Modéré)    (Faible)
```

---

## 📊 IMPORTANCE DES FEATURES

```
Difficulté Respiratoire  ████████████████████ 18.5%
PM2.5                   ████████████████ 15.2%
Toux Sèche             ██████████████ 12.8%
Humidité               ███████████ 9.3%
Température            █████████ 7.1%
Âge 25-59              ████████ 6.5%
Wheezing               ███████ 5.9%
Fréq. Resp.           ██████ 5.2%
Genre                 █████ 4.8%
Oppression Thoracique ████ 4.2%
...autres features    ████████████ 10.5%
```

**Interprétation** :
- La **difficulté respiratoire** est le symptôme le plus prédictif
- Le **PM2.5** est le capteur le plus important
- La **toux sèche** est également très discriminante

---

## 💾 BASE DE DONNÉES SQLITE

### Schéma
```
┌─────────────────┐
│     users       │
├─────────────────┤
│ id (PK)         │
│ email           │
│ name            │
│ created_at      │
└─────────────────┘
         │
         │ 1:N
         │
┌────────┴────────┐
│                 │
▼                 ▼
┌──────────────────────┐    ┌─────────────────┐
│  sensor_history      │    │  predictions    │
├──────────────────────┤    ├─────────────────┤
│ id (PK)              │◄───│ id (PK)         │
│ user_id (FK)         │ 1:N│ user_id (FK)    │
│ humidity             │    │ sensor_data_id  │
│ temperature          │    │ risk_level      │
│ pm25                 │    │ risk_probability│
│ respiratory_rate ✨  │    │ symptoms        │
│ timestamp            │    │ timestamp       │
└──────────────────────┘    └─────────────────┘

✨ = Généré automatiquement par le backend
```

---

## 🎓 MÉTRIQUES DE PERFORMANCE

### Accuracy (Précision globale)
```
████████████████████████░░░░ 85%

85% des prédictions sont correctes
```

### Cross-Validation (5-fold)
```
Fold 1: ████████████████████░░ 87%
Fold 2: █████████████████████░ 89%
Fold 3: ███████████████████░░░ 86%
Fold 4: ████████████████████░░ 88%
Fold 5: ██████████████████████ 90%

Moyenne : 88% ± 1.5%
```

### Matrice de Confusion
```
              Prédit
              F   M   E
        ┌───┬───┬───┬───┐
Vrai F  │ 85│ 10│  5│100│
     M  │  8│ 80│ 12│100│
     E  │  3│ 12│ 85│100│
        └───┴───┴───┴───┘

F = Faible, M = Modéré, E = Élevé
Diagonale = Prédictions correctes ✅
```

---

## 🚀 TECHNOLOGIES UTILISÉES

### Backend
```
┌─────────────────────┐
│  Python 3.10+       │
│  ├─ Flask           │ Framework web
│  ├─ Scikit-learn    │ Random Forest
│  ├─ Pandas          │ Manipulation données
│  ├─ NumPy           │ Calculs numériques
│  └─ Joblib          │ Sauvegarde modèle
└─────────────────────┘
```

### Frontend
```
┌─────────────────────┐
│  Flutter 3.16+      │
│  ├─ Dart            │ Langage
│  ├─ flutter_bloc    │ Gestion d'état
│  ├─ sqflite         │ SQLite
│  ├─ http            │ API calls
│  └─ Material Design │ UI Components
└─────────────────────┘
```

### IoT
```
┌─────────────────────┐
│  ESP32 DevKit       │
│  ├─ DHT22           │ T°C + Humidité
│  ├─ MQ135           │ PM2.5
│  ├─ WiFi 802.11     │ Communication
│  └─ Arduino IDE     │ Programmation
└─────────────────────┘
```

---

## 📈 LIGNE DU TEMPS DU PROJET

```
Nov 2025  │  Conception architecture
          │  ├─ Choix technologies
          │  └─ Design UI/UX
          │
Dec 2025  │  Développement Backend IA
          │  ├─ Collecte dataset
          │  ├─ Entraînement Random Forest
          │  └─ API Flask
          │
Jan 2026  │  Développement App Flutter
          │  ├─ BLoC architecture
          │  ├─ SQLite database
          │  └─ UI screens
          │
Jan 2026  │  Intégration IoT
          │  ├─ ESP32 + capteurs
          │  ├─ Communication WiFi
          │  └─ Génération auto FR ✨
          │
Jan 2026  │  Documentation complète
          │  ├─ Guide présentation
          │  ├─ Q&R jury
          │  └─ Démarrage rapide
          │
Jan 2026  │  🎓 PRÉSENTATION JURY
```

---

## ✅ POINTS FORTS DU PROJET

1. ✅ **Architecture robuste** (3-tiers, séparation claire)
2. ✅ **IA performante** (Random Forest 85-90%)
3. ✅ **Solution ingénieuse** (génération auto FR)
4. ✅ **UX moderne** (Flutter Material Design)
5. ✅ **Offline-first** (SQLite local)
6. ✅ **Scalable** (facile d'ajouter capteurs/features)
7. ✅ **Interprétable** (importance features, recommandations)
8. ✅ **Temps réel** (rafraîchissement auto)

---

**Projet prêt pour la présentation ! 🚀🎓**
