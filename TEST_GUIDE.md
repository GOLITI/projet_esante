# Guide de Test - Système de Prédiction d'Asthme

## 📋 Prérequis

### Backend Flask
1. **Démarrer le serveur Flask** (Terminal 1):
   ```bash
   cd asthme-ia
   python main.py
   ```
   Le serveur démarre sur http://127.0.0.1:5000

2. **Vérifier que le serveur fonctionne**:
   ```bash
   python test_flutter_compatibility.py
   ```
   Vous devriez voir: ✅ COMPATIBILITÉ: 100% OK!

### Application Flutter

1. **Configurer l'URL de l'API**:
   - Ouvrir `asthme_app/lib/data/datasources/api_client.dart`
   - Modifier `baseUrl`:
     - **Émulateur Android**: `http://10.0.2.2:5000`
     - **Téléphone physique**: `http://192.168.100.10:5000` (votre IP locale)
     - **iOS Simulator**: `http://localhost:5000`

2. **Lancer l'application Flutter**:
   ```bash
   cd asthme_app
   flutter run
   ```

## 🎯 Flux de Test Complet

### Étape 1: Inscription/Connexion
1. Lancer l'app Flutter
2. S'inscrire avec un nouveau compte ou se connecter
3. Arriver sur le dashboard

### Étape 2: Lancer une Évaluation
1. Sur le dashboard, cliquer sur le bouton **"Nouvelle Évaluation"** (violet)
2. Vous arrivez sur l'écran de collecte de données

### Étape 3: Remplir les Données

#### 📊 Données des Capteurs
- **Humidité**: 75% (exemple: environnement humide)
- **Température**: 24.5°C (exemple: température confortable)
- **PM2.5**: 45 µg/m³ (exemple: qualité d'air modérée)
- **Fréquence Respiratoire**: 22 respirations/min (exemple: légèrement élevée)

#### 🤒 Symptômes (cocher si présent)
- ✅ Fatigue
- ✅ Toux sèche
- ✅ Difficulté respiratoire
- ⬜ Mal de gorge
- ⬜ Douleurs
- ✅ Congestion nasale
- ⬜ Nez qui coule

#### 👤 Informations Démographiques
- **Tranche d'âge**: 20-24
- **Genre**: Homme

### Étape 4: Analyser le Risque
1. Cliquer sur **"Analyser le Risque"**
2. Voir l'animation de chargement
3. Résultat s'affiche dans une popup:
   - **Niveau de risque**: Faible/Modéré/Élevé
   - **Score**: Pourcentage (ex: 47%)
   - **Jauge circulaire** avec couleur (Vert/Orange/Rouge)
   - **Recommandations**: Liste de 5-8 conseils

### Étape 5: Vérifier le Stockage Local
Les données sont automatiquement sauvegardées dans SQLite:
- Données capteurs → Table `sensor_history`
- Résultat de prédiction → Table `predictions`

## 🧪 Scénarios de Test

### Test 1: Risque FAIBLE
```yaml
Capteurs:
  Humidité: 50%
  Température: 22°C
  PM2.5: 20 µg/m³
  Fréquence Respiratoire: 14 /min
Symptômes: Aucun coché
Résultat attendu: Risque Faible (vert, ~30%)
```

### Test 2: Risque MODÉRÉ
```yaml
Capteurs:
  Humidité: 65%
  Température: 24°C
  PM2.5: 40 µg/m³
  Fréquence Respiratoire: 18 /min
Symptômes: Toux sèche + Congestion nasale
Résultat attendu: Risque Modéré (orange, ~40-60%)
```

### Test 3: Risque ÉLEVÉ
```yaml
Capteurs:
  Humidité: 75%
  Température: 24.5°C
  PM2.5: 45 µg/m³
  Fréquence Respiratoire: 22 /min
Symptômes: Fatigue + Toux + Difficulté respiratoire + Congestion
Résultat attendu: Risque Élevé (rouge, >60%)
```

## ✅ Points de Vérification

### Backend
- [ ] Serveur Flask démarre sans erreur
- [ ] Test de compatibilité réussit
- [ ] Endpoint `/health` répond 200
- [ ] Endpoint `/api/predict` retourne le bon format JSON

### Frontend
- [ ] BLoC PredictionBloc créé sans erreur
- [ ] Écran PredictionScreen s'affiche correctement
- [ ] Formulaire valide les champs obligatoires
- [ ] Requête HTTP envoyée au format correct
- [ ] Résultat affiché dans la popup
- [ ] Données sauvegardées en SQLite

### Intégration
- [ ] Bouton "Nouvelle Évaluation" visible sur le dashboard
- [ ] Navigation vers PredictionScreen fonctionne
- [ ] Retour au dashboard après résultat
- [ ] Pas d'erreur dans les logs Flutter
- [ ] Pas d'erreur dans les logs Flask

## 🐛 Dépannage

### Erreur: "Connexion refusée"
**Problème**: Flutter ne peut pas joindre le serveur Flask
**Solution**: 
- Vérifier que Flask tourne (http://127.0.0.1:5000)
- Vérifier l'URL dans `api_client.dart` (10.0.2.2 pour émulateur)
- Désactiver le pare-feu temporairement

### Erreur: "Feature manquante"
**Problème**: Format de requête incorrect
**Solution**: 
- Vérifier que `api_client.dart` envoie le format structuré `{symptoms, demographics, sensors}`
- Relancer le serveur Flask

### Erreur: "User not authenticated"
**Problème**: Utilisateur non connecté
**Solution**: 
- Se déconnecter et se reconnecter
- Vérifier que AuthBloc est en état `AuthAuthenticated`

### Modèle non trouvé
**Problème**: `models/asthma_model.pkl` manquant
**Solution**:
```bash
cd asthme-ia
python train_model.py
```

## 📊 Logs Utiles

### Logs Flutter (Attendus)
```
📤 Envoi requête prédiction ML...
Symptoms: 7, Demographics: 2, Sensors: 4
✅ Prédiction reçue: Élevé (niveau 3)
✅ Prédiction réussie: Élevé (47.3%)
```

### Logs Flask (Attendus)
```
Modèle chargé depuis: models/asthma_model.pkl
127.0.0.1 - - [16/Jan/2026 20:18:50] "POST /api/predict HTTP/1.1" 200 -
```

## 🎉 Succès
Si tous les points de vérification sont OK, le système est **100% fonctionnel** !

Vous pouvez maintenant:
- Tester différents scénarios de risque
- Voir l'historique des prédictions (à implémenter)
- Afficher les stats dans le dashboard (à implémenter)

---

**Prochaines améliorations**:
1. Afficher l'historique des prédictions
2. Graphiques de tendance dans le dashboard
3. Notifications si risque élevé détecté
4. Connexion Bluetooth avec capteurs physiques
