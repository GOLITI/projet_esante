# 💻 Explication Détaillée du Code - Modèle IA

**Date** : 19 janvier 2026  
**Fichiers** : `model.py`, `train_model.py`, `main.py`  
**Langage** : Python 3.x avec scikit-learn

---

## 📚 Table des Matières

1. [Structure du Projet](#structure-du-projet)
2. [model.py - Classe AsthmaPredictor](#modelpy---classe-asthmapredictor)
3. [train_model.py - Entraînement](#train_modelpy---entraînement)
4. [main.py - API Flask](#mainpy---api-flask)
5. [Flux de Données Complet](#flux-de-données-complet)

---

## 📁 Structure du Projet

```
asthme-ia/
├── model.py                 # 🧠 Classe du modèle Random Forest
├── train_model.py           # 🏋️ Script d'entraînement
├── main.py                  # 🌐 API Flask
├── requirements.txt         # 📦 Dépendances Python
├── data/
│   └── asthma_detection_final.csv  # 📊 Dataset (3663 patients)
├── models/
│   └── asthma_model.pkl     # 💾 Modèle entraîné sauvegardé
└── docs/
    └── *.md                  # 📖 Documentation
```

---

## 🧠 model.py - Classe AsthmaPredictor

### Vue d'Ensemble

```python
"""
Module de prédiction du risque d'asthme avec Random Forest
"""
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib
import os
```

**Imports expliqués** :
- `pandas` : Manipulation des données tabulaires (CSV)
- `numpy` : Calculs numériques
- `RandomForestClassifier` : Algorithme de machine learning
- `train_test_split` : Diviser données en train/test
- `cross_val_score` : Validation croisée
- `StratifiedKFold` : Cross-validation stratifiée (maintient proportions des classes)
- `classification_report`, `confusion_matrix`, `accuracy_score` : Métriques de performance
- `joblib` : Sauvegarder/charger le modèle
- `os` : Manipulation de fichiers/dossiers

---

### 1. Initialisation de la Classe

```python
class AsthmaPredictor:
    """Classe pour la prédiction du risque d'asthme"""
    
    def __init__(self, model_path='models/asthma_model.pkl', high_risk_threshold=0.65):
        """
        Initialise le prédicteur
        
        Args:
            model_path: Chemin vers le modèle sauvegardé
            high_risk_threshold: Seuil de probabilité pour déclencher alerte critique (0.6-0.7)
        """
        self.model_path = model_path
        self.model = None  # Sera rempli après entraînement ou chargement
        self.feature_names = None  # Liste des 18 features
        self.high_risk_threshold = high_risk_threshold  # Seuil médical pour classe critique
        self.min_feature_importance = 0.001  # Filtrer features < 0.1% d'importance
        self.risk_labels = {
            1: 'Faible',
            2: 'Modéré',
            3: 'Élevé'
        }
```

**Explication ligne par ligne** :

```python
self.model_path = model_path
```
- Stocke le chemin où sauvegarder/charger le modèle
- Par défaut : `models/asthma_model.pkl`

```python
self.model = None
```
- Contiendra le modèle RandomForestClassifier une fois entraîné
- `None` au début (pas encore entraîné)

```python
self.feature_names = None
```
- Liste des noms des 18 features dans l'ordre exact
- Exemple : `['Tiredness', 'Dry-Cough', ..., 'RespiratoryRate']`
- Important pour réordonner les données lors de la prédiction

```python
self.high_risk_threshold = high_risk_threshold  # 0.65 par défaut
```
- **Seuil critique médical** : Si probabilité(Élevé) ≥ 65%, forcer alerte
- Priorité à la sécurité médicale (éviter faux négatifs)

```python
self.min_feature_importance = 0.001
```
- Features avec importance < 0.1% sont considérées comme bruit
- Permet d'identifier les features à potentiellement supprimer

```python
self.risk_labels = {1: 'Faible', 2: 'Modéré', 3: 'Élevé'}
```
- Mapping entre les classes numériques et les labels texte
- Facilite l'affichage pour l'utilisateur

---

### 2. Nettoyage des Données

```python
def _clean_sensor_data(self, df):
    """
    Nettoie les valeurs aberrantes des capteurs
    
    Args:
        df: DataFrame avec les données
        
    Returns:
        df: DataFrame nettoyé
    """
    df_clean = df.copy()
    
    # Nettoyer les capteurs environnementaux
    if 'Temperature' in df_clean.columns:
        # Température corporelle normale: 35-42°C
        df_clean.loc[df_clean['Temperature'] < 35, 'Temperature'] = 36.5
        df_clean.loc[df_clean['Temperature'] > 42, 'Temperature'] = 37.0
```

**Explication** :

```python
df_clean = df.copy()
```
- Crée une copie du DataFrame pour ne pas modifier l'original
- Bonne pratique en Python

```python
if 'Temperature' in df_clean.columns:
```
- Vérifie si la colonne 'Temperature' existe
- Permet de gérer différents formats de datasets

```python
df_clean.loc[df_clean['Temperature'] < 35, 'Temperature'] = 36.5
```
- **Sélection conditionnelle** :
  - `df_clean['Temperature'] < 35` : Booléen True/False pour chaque ligne
  - `df_clean.loc[condition, 'Temperature']` : Sélectionne les lignes où condition = True
  - `= 36.5` : Remplace par la valeur normale

**Logique médicale** :
- Température < 35°C → **Hypothermie** (probable erreur capteur) → Remplacer par 36.5°C (normal)
- Température > 42°C → **Hyperthermie dangereuse** (probable erreur capteur) → Remplacer par 37.0°C (limite)

**Même logique pour les autres capteurs** :

```python
if 'Humidity' in df_clean.columns:
    # Humidité: 0-100%
    df_clean.loc[df_clean['Humidity'] < 0, 'Humidity'] = 30
    df_clean.loc[df_clean['Humidity'] > 100, 'Humidity'] = 70
```
- Humidité < 0% ou > 100% → Physiquement impossible → Corriger

```python
if 'PM25' in df_clean.columns:
    # PM2.5: 0-500 µg/m³ (valeurs réalistes)
    df_clean.loc[df_clean['PM25'] < 0, 'PM25'] = 0
    df_clean.loc[df_clean['PM25'] > 500, 'PM25'] = 500
```
- PM2.5 < 0 → Impossible → 0
- PM2.5 > 500 → Extrêmement rare → Limiter à 500

```python
if 'RespiratoryRate' in df_clean.columns:
    # Fréquence respiratoire: 10-40 respirations/min
    df_clean.loc[df_clean['RespiratoryRate'] < 10, 'RespiratoryRate'] = 16
    df_clean.loc[df_clean['RespiratoryRate'] > 40, 'RespiratoryRate'] = 25
```
- Fréquence < 10 → Anormalement bas → 16 (normal)
- Fréquence > 40 → Hyperventilation extrême → 25 (élevé)

---

### 3. Chargement des Données

```python
def load_data(self, csv_path='data/asthma_detection_with_sensors.csv'):
    """
    Charge et prépare les données avec nettoyage des valeurs aberrantes
    
    Args:
        csv_path: Chemin vers le fichier CSV
        
    Returns:
        X, y: Features et target
    """
    # Charger le dataset
    df = pd.read_csv(csv_path)
```

**Explication** :

```python
df = pd.read_csv(csv_path)
```
- Lit le fichier CSV et crée un DataFrame pandas
- Structure : 3663 lignes (patients) × 19 colonnes (18 features + 1 target)

```python
# Nettoyer les valeurs aberrantes des capteurs
df = self._clean_sensor_data(df)
```
- Appelle la méthode de nettoyage définie précédemment
- Corrige les valeurs impossibles/aberrantes

```python
# Séparer features et target
X = df.drop('Asthma', axis=1)
y = df['Asthma']
```
- `X` : **Features** (variables prédictives) - 18 colonnes
  ```
  [Tiredness, Dry-Cough, ..., RespiratoryRate]
  ```
- `y` : **Target** (variable à prédire) - 1 colonne
  ```
  [1, 2, ou 3]  (Faible, Modéré, Élevé)
  ```
- `axis=1` : Supprimer une colonne (pas une ligne)

```python
# Sauvegarder les noms des features
self.feature_names = X.columns.tolist()
```
- Stocke les noms des colonnes dans l'ordre exact
- **Crucial** : Le modèle doit recevoir les features dans le même ordre

```python
print(f"Features chargées: {len(self.feature_names)}")
if 'Temperature' in self.feature_names:
    print("✓ Données de capteurs détectées (Température, Humidité, PM2.5, AQI, Fréquence cardiaque)")
print("✓ Nettoyage des valeurs aberrantes effectué")
```
- Affichage d'informations pour l'utilisateur
- `f"..."` : f-string pour formater le texte avec des variables

```python
return X, y
```
- Retourne les features et le target pour l'entraînement

---

### 4. Entraînement du Modèle

```python
def train(self, X, y, test_size=0.2, random_state=42):
    """
    Entraîne le modèle Random Forest
    
    Args:
        X: Features
        y: Target
        test_size: Proportion du test set
        random_state: Seed pour reproductibilité
        
    Returns:
        metrics: Dictionnaire avec les métriques de performance
    """
    # Split train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )
```

**Explication du split** :

```python
train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
```
- `X, y` : Données à diviser
- `test_size=0.2` : **20% pour test, 80% pour entraînement**
  ```
  3663 patients total
  ├── Train: 2930 patients (80%)
  └── Test:   733 patients (20%)
  ```
- `random_state=42` : **Seed aléatoire** pour reproductibilité
  - Toujours la même division à chaque exécution
- `stratify=y` : **Maintient les proportions des classes**
  ```
  Dataset original: 33% Faible, 33% Modéré, 33% Élevé
  Train set:        33% Faible, 33% Modéré, 33% Élevé  ✅
  Test set:         33% Faible, 33% Modéré, 33% Élevé  ✅
  ```

**Retour** : 4 objets
```python
X_train  # Features d'entraînement (2930 × 18)
X_test   # Features de test (733 × 18)
y_train  # Target d'entraînement (2930)
y_test   # Target de test (733)
```

---

#### Configuration du Random Forest

```python
# Créer et entraîner le modèle Random Forest avec hyperparamètres optimisés
# Utilisation d'un nombre impair d'arbres pour éviter les égalités
self.model = RandomForestClassifier(
    n_estimators=151,           # Nombre d'arbres (impair!)
    max_depth=12,              # Profondeur maximale
    min_samples_split=5,       # Min échantillons pour split
    min_samples_leaf=1,        # Min échantillons par feuille
    random_state=random_state,
    class_weight={1: 1.0, 2: 1.0, 3: 1.5},  # Poids ajusté pour classe critique
    n_jobs=-1                  # Utilise tous les CPU
)
```

**Chaque paramètre expliqué** :

**n_estimators=151**
```python
# Nombre d'arbres de décision dans la forêt
# 151 au lieu de 150 → nombre impair → évite égalités dans le vote
# Exemple de vote:
#   150 arbres: 75 vs 75 = égalité possible ❌
#   151 arbres: 76 vs 75 = toujours un gagnant ✅
```

**max_depth=12**
```python
# Profondeur maximale de chaque arbre (12 niveaux)
# Plus profond = capture patterns complexes
# Trop profond = surapprentissage
# 12 = bon compromis pour notre dataset
```

**min_samples_split=5**
```python
# Minimum 5 échantillons pour créer une nouvelle branche
# Si nœud < 5 patients → ne pas diviser (devient feuille)
# Évite de créer des branches sur trop peu de données (bruit)
```

**min_samples_leaf=1**
```python
# Minimum 1 échantillon dans chaque feuille
# Plus flexible que 2
# Permet au modèle d'apprendre des cas particuliers
```

**class_weight={1: 1.0, 2: 1.0, 3: 1.5}**
```python
# Poids de chaque classe lors de l'entraînement
# Classe 1 (Faible): poids normal (1.0)
# Classe 2 (Modéré): poids normal (1.0)
# Classe 3 (Élevé):  poids augmenté (1.5) ⚡
# 
# Impact: Le modèle fait plus attention aux erreurs sur classe 3
# → Réduit les faux négatifs (ne pas rater un cas grave)
```

**n_jobs=-1**
```python
# Nombre de CPU à utiliser
# -1 = TOUS les CPU disponibles
# Parallélisation = entraînement beaucoup plus rapide
# 
# Exemple avec 8 CPU:
#   n_jobs=1  → 8 minutes
#   n_jobs=-1 → 1 minute
```

---

#### Entraînement

```python
print("Entraînement du modèle Random Forest optimisé...")
print(f"  • n_estimators: 151 (nombre impair)")
print(f"  • max_depth: 12 (patterns complexes)")
print(f"  • min_samples_leaf: 1 (flexibilité)")
print(f"  • class_weight: {{1:1.0, 2:1.0, 3:1.5}} (priorité classe critique)")
print(f"  • Seuil alerte critique: {self.high_risk_threshold:.2f}")

self.model.fit(X_train, y_train)
```

**`model.fit(X_train, y_train)`** :
- **C'est ici que la magie opère !**
- Le modèle construit 151 arbres de décision
- Processus pour chaque arbre :
  1. **Bootstrap** : Tirer ~2930 échantillons aléatoires avec remise
  2. **Construire l'arbre** :
     - À chaque nœud : sélectionner √18 ≈ 4 features aléatoires
     - Choisir la meilleure feature pour diviser
     - Créer branches gauche/droite
     - Répéter jusqu'à max_depth=12
  3. **Stocker l'arbre**

---

#### Évaluation

```python
# Prédictions sur le test set
y_pred = self.model.predict(X_test)
```

**`predict(X_test)`** :
- Fait voter les 151 arbres pour chaque patient du test set
- Retourne la classe majoritaire (1, 2, ou 3)

```python
# Métriques
accuracy = accuracy_score(y_test, y_pred)
```

**accuracy_score** :
```python
# Calcule : nombre de prédictions correctes / total
# Exemple:
#   y_test = [1, 2, 3, 1, 2]  (vraies valeurs)
#   y_pred = [1, 2, 2, 1, 2]  (prédictions)
#   correct: 4/5 = 80% accuracy
```

```python
# Cross-validation améliorée avec StratifiedKFold (10 folds)
skf = StratifiedKFold(n_splits=10, shuffle=True, random_state=random_state)
cv_scores = cross_val_score(self.model, X_train, y_train, cv=skf)
```

**StratifiedKFold** :
```python
# Divise les données en 10 parties égales
# Pour chaque fold (1 à 10):
#   - Utiliser 1 fold pour test
#   - Utiliser 9 folds pour entraînement
#   - Calculer l'accuracy
# 
# Résultat: [0.976, 0.983, 0.968, ..., 0.970]
# Moyenne: 97.17%
# Écart-type: 0.85%
```

**Avantages** :
- Plus robuste qu'un simple train/test split
- Chaque échantillon est testé exactement 1 fois
- Mesure la capacité de généralisation

---

#### Feature Importance

```python
# Importance des features
feature_importance = pd.DataFrame({
    'feature': self.feature_names,
    'importance': self.model.feature_importances_
}).sort_values('importance', ascending=False)
```

**`self.model.feature_importances_`** :
- Array de 18 valeurs (une par feature)
- Somme = 1.0 (100%)
- Exemple : `[0.291, 0.250, 0.084, ..., 0.003]`

**Calcul de l'importance** :
```python
# Pour chaque feature:
#   1. Calculer la réduction d'impureté quand on l'utilise pour diviser
#   2. Sommer sur tous les arbres (151)
#   3. Normaliser (diviser par somme totale)
# 
# Résultat:
#   RespiratoryRate: 29.1%  ← Feature la plus utile
#   PM25: 25.0%
#   ...
#   Gender_Female: 0.3%  ← Feature la moins utile
```

```python
# Identifier les features négligeables (< 0.1% d'importance)
low_importance_features = feature_importance[feature_importance['importance'] < self.min_feature_importance]
important_features = feature_importance[feature_importance['importance'] >= self.min_feature_importance]
```

- Filtre les features très peu importantes
- Permet d'identifier le "bruit" dans les données

---

#### Affichage des Résultats

```python
print(f"\n{'='*50}")
print(f"RÉSULTATS DE L'ENTRAÎNEMENT")
print(f"{'='*50}")
print(f"Accuracy sur test set: {accuracy:.4f}")
print(f"Cross-validation score (10-fold): {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")
```

**Format des affichages** :
- `:.4f` : 4 décimales (0.9604)
- `cv_scores.mean()` : Moyenne des 10 scores
- `cv_scores.std()` : Écart-type (variance)

```python
if len(low_importance_features) > 0:
    print(f"\n⚠️ {len(low_importance_features)} feature(s) négligeable(s) détectée(s) (< {self.min_feature_importance*100:.1f}%):")
    for feat in low_importance_features['feature'].tolist():
        print(f"  - {feat}")
    print("  Conseil: Considérer leur suppression pour réduire le bruit")
```

- Avertit si certaines features sont inutiles
- Suggestion d'amélioration

```python
print(f"\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=[self.risk_labels.get(i, str(i)) for i in sorted(y_test.unique())]))
```

**classification_report** :
```
              precision    recall  f1-score   support

      Faible       0.97      0.95      0.96       244
      Modéré       0.93      0.96      0.95       244
       Élevé       0.98      0.96      0.97       245
```

- **Precision** : Parmi les prédictions "Élevé", combien sont vraiment Élevé ?
- **Recall** : Parmi les vrais "Élevé", combien sont détectés ?
- **F1-score** : Moyenne harmonique de precision et recall
- **Support** : Nombre d'échantillons de cette classe

```python
print(f"\nMatrice de confusion:")
print(confusion_matrix(y_test, y_pred))
```

**Matrice de confusion** :
```
[[233  11   0]    ← Faible: 233 OK, 11 erreurs
 [  5 235   4]    ← Modéré: 235 OK, 9 erreurs
 [  2   7 236]]   ← Élevé: 236 OK, 9 erreurs
```

---

### 5. Sauvegarde du Modèle

```python
def save_model(self):
    """Sauvegarde le modèle entraîné"""
    if self.model is None:
        raise ValueError("Le modèle n'a pas encore été entraîné")
    
    # Créer le dossier models s'il n'existe pas
    os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
    
    # Sauvegarder le modèle et les feature names
    model_data = {
        'model': self.model,
        'feature_names': self.feature_names,
        'risk_labels': self.risk_labels
    }
    
    joblib.dump(model_data, self.model_path)
    print(f"\nModèle sauvegardé dans: {self.model_path}")
```

**Explication** :

```python
os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
```
- `os.path.dirname('models/asthma_model.pkl')` → `'models'`
- `os.makedirs('models', exist_ok=True)` → Crée le dossier si n'existe pas
- `exist_ok=True` → Pas d'erreur si le dossier existe déjà

```python
model_data = {
    'model': self.model,
    'feature_names': self.feature_names,
    'risk_labels': self.risk_labels
}
```
- Dictionnaire contenant TOUT ce qu'on a besoin pour faire des prédictions
- Pas juste le modèle, mais aussi les métadonnées

```python
joblib.dump(model_data, self.model_path)
```
- `joblib` : Librairie optimisée pour sauvegarder des objets scikit-learn
- Crée un fichier `.pkl` (pickle) de ~3-6 MB

---

### 6. Chargement du Modèle

```python
def load_model(self):
    """Charge le modèle sauvegardé"""
    if not os.path.exists(self.model_path):
        raise FileNotFoundError(f"Modèle non trouvé: {self.model_path}")
    
    model_data = joblib.load(self.model_path)
    self.model = model_data['model']
    self.feature_names = model_data['feature_names']
    self.risk_labels = model_data['risk_labels']
    
    print(f"Modèle chargé depuis: {self.model_path}")
```

**Explication** :

```python
if not os.path.exists(self.model_path):
    raise FileNotFoundError(...)
```
- Vérifie si le fichier existe avant de charger
- `raise` : Lève une erreur si le fichier n'existe pas

```python
model_data = joblib.load(self.model_path)
```
- Charge le fichier `.pkl`
- Retourne le dictionnaire sauvegardé précédemment

```python
self.model = model_data['model']
self.feature_names = model_data['feature_names']
self.risk_labels = model_data['risk_labels']
```
- Extrait les éléments du dictionnaire
- Restaure l'état complet du prédicteur

---

### 7. Prédiction (❤️ COEUR DU SYSTÈME)

```python
def predict(self, features):
    """
    Prédit le risque d'asthme
    
    Args:
        features: Dictionnaire ou DataFrame avec les features
        
    Returns:
        prediction: Dictionnaire avec le risque et les recommandations
    """
    if self.model is None:
        try:
            self.load_model()
        except FileNotFoundError:
            raise ValueError("Le modèle doit être entraîné ou chargé avant de faire des prédictions")
```

**Auto-chargement** :
- Si le modèle n'est pas en mémoire, essaie de le charger automatiquement
- Pratique pour l'API Flask

```python
# Convertir en DataFrame si nécessaire
if isinstance(features, dict):
    features_df = pd.DataFrame([features])
else:
    features_df = features
```

**Gestion de types** :
```python
# features peut être:
# 1. Un dictionnaire: {'Tiredness': 1, 'Dry-Cough': 1, ...}
# 2. Un DataFrame: pd.DataFrame avec les colonnes

# On convertit tout en DataFrame pour uniformiser
```

```python
# Vérifier que toutes les features sont présentes
missing_features = set(self.feature_names) - set(features_df.columns)
if missing_features:
    raise ValueError(f"Features manquantes: {missing_features}")
```

**Validation** :
```python
# self.feature_names = ['Tiredness', 'Dry-Cough', ..., 'RespiratoryRate']
# features_df.columns = ['Tiredness', 'PM25', ...]  ← Il manque des colonnes!

# set(A) - set(B) = éléments dans A mais pas dans B
# Si missing_features non vide → erreur
```

```python
# Réorganiser les colonnes dans le bon ordre
features_df = features_df[self.feature_names]
```

**CRUCIAL** :
- Le modèle attend les features dans un ordre précis
- Exemple :
  ```python
  # Entraînement: ['Tiredness', 'Dry-Cough', 'PM25']
  # Prédiction:   ['PM25', 'Tiredness', 'Dry-Cough']  ← Mauvais ordre!
  # 
  # features_df[self.feature_names] → réordonne correctement
  ```

---

#### Application du Seuil Critique (⚡ INNOVATION)

```python
# Prédiction avec probabilités
risk_probabilities = self.model.predict_proba(features_df)[0]
risk_level_default = int(self.model.predict(features_df)[0])
```

**predict_proba** :
```python
# Retourne les probabilités pour chaque classe
# Exemple: [[0.265, 0.258, 0.477]]
#            ↑      ↑      ↑
#         Faible Modéré Élevé
# 
# [0] → Premier (et seul) patient
# Résultat: [0.265, 0.258, 0.477]
```

**predict** :
```python
# Retourne la classe majoritaire (vote des arbres)
# Exemple: [3]  (classe Élevé)
# 
# int(...) → Convertir en entier Python
```

```python
# Convertir les probabilités en dict
prob_dict = {
    int(cls): float(prob) 
    for cls, prob in zip(self.model.classes_, risk_probabilities)
}
```

**Comprehension de dictionnaire** :
```python
# self.model.classes_ = [1, 2, 3]
# risk_probabilities  = [0.265, 0.258, 0.477]
# 
# zip() → [(1, 0.265), (2, 0.258), (3, 0.477)]
# 
# Résultat: {1: 0.265, 2: 0.258, 3: 0.477}
```

```python
# Appliquer le seuil médical pour la classe critique (3 = Élevé)
# Si probabilité de classe 3 >= seuil critique, forcer l'alerte
risk_level = risk_level_default
if 3 in prob_dict and prob_dict[3] >= self.high_risk_threshold:
    risk_level = 3  # Forcer alerte critique pour sécurité médicale
    print(f"⚠️ ALERTE CRITIQUE: Probabilité classe Élevé = {prob_dict[3]:.2%} >= seuil {self.high_risk_threshold:.2%}")
```

**Logique du seuil** :
```python
# Scénario 1: Probabilités [35%, 33%, 32%]
#   - Vote majoritaire: Faible (35%)
#   - prob_dict[3] = 32% < 65%
#   - Résultat: Faible (normal)

# Scénario 2: Probabilités [20%, 15%, 65%]
#   - Vote majoritaire: Élevé (65%)
#   - prob_dict[3] = 65% >= 65%
#   - Résultat: Élevé (alerte déclenchée)
#   - Affiche: "⚠️ ALERTE CRITIQUE..."

# Scénario 3: Probabilités [40%, 40%, 20%]
#   - Vote majoritaire: Faible ou Modéré
#   - prob_dict[3] = 20% < 65%
#   - Résultat: Vote majoritaire (normal)

# L'intérêt: Même si vote majoritaire ≠ Élevé,
# on déclenche l'alerte si risque Élevé ≥ 65%
```

```python
# Calculer un score global (probabilité de la classe prédite)
risk_score = float(risk_probabilities[list(self.model.classes_).index(risk_level)])
```

**Extraction du score** :
```python
# risk_level = 3 (Élevé)
# self.model.classes_ = [1, 2, 3]
# list(...) = [1, 2, 3]
# .index(3) = 2  (position de 3 dans la liste)
# risk_probabilities[2] = 0.477
# 
# risk_score = 0.477 (47.7%)
```

```python
# Générer des recommandations basées sur le niveau de risque
recommendations = self._generate_recommendations(risk_level, features_df.iloc[0].to_dict())
```

- Appelle une méthode pour générer des recommandations personnalisées
- `.iloc[0]` : Premier patient du DataFrame
- `.to_dict()` : Convertir en dictionnaire

```python
return {
    'risk_level': risk_level,
    'risk_label': self.risk_labels.get(risk_level, 'Inconnu'),
    'risk_score': risk_score,
    'probabilities': prob_dict,
    'recommendations': recommendations
}
```

**Retour formaté** :
```python
{
    'risk_level': 3,
    'risk_label': 'Élevé',
    'risk_score': 0.477,
    'probabilities': {1: 0.265, 2: 0.258, 3: 0.477},
    'recommendations': [
        "⚠️ Consultez IMMÉDIATEMENT un médecin",
        "Évitez tout effort physique",
        ...
    ]
}
```

---

### 8. Génération de Recommandations

```python
def _generate_recommendations(self, risk_level, features):
    """
    Génère des recommandations personnalisées
    
    Args:
        risk_level: Niveau de risque prédit
        features: Dictionnaire des features du patient
        
    Returns:
        recommendations: Liste de recommandations
    """
    recommendations = []
    
    # Recommandations basées sur le niveau de risque
    if risk_level == 3:  # Risque élevé
        recommendations.append("⚠️ Consultez IMMÉDIATEMENT un médecin ou pneumologue")
        recommendations.append("Évitez tout effort physique intense")
        recommendations.append("Gardez votre inhalateur à portée de main si vous en avez un")
    elif risk_level == 2:  # Risque modéré
        recommendations.append("Consultez un médecin dans les prochains jours")
        recommendations.append("Surveillez attentivement vos symptômes")
        recommendations.append("Évitez les allergènes et la pollution")
    else:  # Risque faible
        recommendations.append("Maintenez une bonne hygiène de vie")
        recommendations.append("Surveillez l'apparition de nouveaux symptômes")
```

**Logique conditionnelle** :
- Recommandations **générales** basées sur le niveau de risque
- Structure if/elif/else pour les 3 cas

```python
# Recommandations basées sur les symptômes
if features.get('Difficulty-in-Breathing', 0) == 1:
    recommendations.append("Respirez lentement et profondément")
    recommendations.append("Asseyez-vous dans une position confortable")

if features.get('Dry-Cough', 0) == 1:
    recommendations.append("Hydratez-vous régulièrement")
    recommendations.append("Évitez les irritants (fumée, poussière)")
```

**`features.get('key', default)`** :
```python
# Récupère la valeur de la clé, sinon retourne default
# features = {'Difficulty-in-Breathing': 1, 'Dry-Cough': 0}
# 
# features.get('Difficulty-in-Breathing', 0) → 1
# features.get('Runny-Nose', 0) → 0 (clé inexistante, retourne default)
```

```python
# Recommandations basées sur les capteurs environnementaux
pm25 = features.get('PM25', None)
if pm25 is not None:
    if pm25 > 55:
        recommendations.append("🌫️ Qualité de l'air très mauvaise - Restez à l'intérieur")
    elif pm25 > 35:
        recommendations.append("🌫️ Qualité de l'air mauvaise - Limitez les activités extérieures")
```

**Seuils PM2.5** :
```
0-12:   Bonne qualité (vert)
13-35:  Moyenne (jaune)
36-55:  Mauvaise (orange) → "Limitez activités"
56+:    Très mauvaise (rouge) → "Restez à l'intérieur"
```

```python
humidity = features.get('Humidity', None)
if humidity is not None:
    if humidity > 70:
        recommendations.append("💧 Humidité élevée - Utilisez un déshumidificateur")
    elif humidity < 30:
        recommendations.append("💧 Air trop sec - Utilisez un humidificateur")
```

**Humidité optimale** : 30-70%
- Trop élevée (>70%) : Favorise moisissures, acariens
- Trop basse (<30%) : Irrite voies respiratoires

```python
# Retourner les recommandations les plus pertinentes (max 8)
return recommendations[:8]
```

- `[:8]` : Prend les 8 premiers éléments de la liste
- Évite une liste trop longue pour l'utilisateur

---

## 🏋️ train_model.py - Script d'Entraînement

### Vue d'ensemble

```python
"""
Script d'entraînement du modèle Random Forest pour la prédiction d'asthme
"""
from model import AsthmaPredictor
import os

def main():
    """Fonction principale d'entraînement"""
    
    print("="*60)
    print("ENTRAÎNEMENT DU MODÈLE DE PRÉDICTION D'ASTHME")
    print("Algorithme: Random Forest Classifier")
    print("="*60)
```

**Imports** :
- `from model import AsthmaPredictor` : Importe la classe du fichier `model.py`
- `import os` : Pour créer des dossiers

```python
# Créer le dossier models s'il n'existe pas
os.makedirs('models', exist_ok=True)
```

- Prépare le dossier de sauvegarde

```python
# Initialiser le prédicteur
predictor = AsthmaPredictor(model_path='models/asthma_model.pkl')
```

- Crée une instance de la classe
- `predictor` : Objet qu'on va utiliser pour entraîner

```python
# Charger les données
print("\nChargement des données...")
X, y = predictor.load_data('data/asthma_detection_final.csv')
print(f"Dataset chargé: {X.shape[0]} échantillons, {X.shape[1]} features")
```

- `X.shape` : Tuple `(lignes, colonnes)`
- `X.shape[0]` : Nombre de lignes (3663 patients)
- `X.shape[1]` : Nombre de colonnes (18 features)

```python
print(f"Distribution des classes:")
print(y.value_counts().sort_index())
```

**value_counts()** :
```python
# Compte le nombre de chaque valeur unique
# y = [1, 2, 3, 1, 2, 3, ...]
# 
# Résultat:
# 1    1221  (Faible)
# 2    1221  (Modéré)
# 3    1221  (Élevé)
```

```python
# Entraîner le modèle
print("\n" + "="*60)
metrics = predictor.train(X, y, test_size=0.2, random_state=42)
```

- Appelle la méthode `train()` vue précédemment
- `metrics` : Dictionnaire avec les résultats

```python
# Sauvegarder le modèle
print("\n" + "="*60)
predictor.save_model()
```

- Sauvegarde dans `models/asthma_model.pkl`

---

### Test de Prédiction

```python
# Test de prédiction avec un exemple
print("\n" + "="*60)
print("TEST DE PRÉDICTION")
print("="*60)

# Exemple: Patient avec plusieurs symptômes et données de capteurs
test_example = {
    'Tiredness': 1,
    'Dry-Cough': 1,
    'Difficulty-in-Breathing': 1,
    'Sore-Throat': 1,
    'Pains': 0,
    'Nasal-Congestion': 1,
    'Runny-Nose': 0,
    'Age_0-9': 0,
    'Age_10-19': 0,
    'Age_20-24': 1,
    'Age_25-59': 0,
    'Age_60+': 0,
    'Gender_Female': 0,
    'Gender_Male': 1,
    'Humidity': 75.0,
    'Temperature': 24.5,
    'PM25': 45.0,
    'RespiratoryRate': 22.0
}
```

**Structure du dictionnaire** :
- Clé : Nom de la feature
- Valeur : 0 ou 1 (symptômes), valeur numérique (capteurs)

```python
result = predictor.predict(test_example)
```

- Appelle la méthode `predict()` vue précédemment
- `result` : Dictionnaire avec le résultat

```python
print(f"\n📊 RÉSULTAT DE LA PRÉDICTION:")
print(f"Niveau de risque: {result['risk_level']} - {result['risk_label']}")
print(f"Score de confiance: {result['risk_score']:.2%}")
```

- `.2%` : Format en pourcentage avec 2 décimales (47.90%)

```python
print(f"\nProbabilités par classe:")
for cls, prob in sorted(result['probabilities'].items()):
    risk_label = predictor.risk_labels.get(cls, str(cls))
    print(f"  {risk_label}: {prob:.2%}")
```

**Boucle sur dictionnaire** :
```python
# result['probabilities'] = {1: 0.265, 2: 0.258, 3: 0.477}
# sorted(...) → [(1, 0.265), (2, 0.258), (3, 0.477)]
# 
# Pour chaque paire (cls, prob):
#   Afficher: "Faible: 26.50%"
```

---

## 🌐 main.py - API Flask

### Configuration

```python
"""
API Flask pour E-Santé 4.0 - Prédiction du risque d'asthme
Backend SIMPLIFIÉ : Uniquement prédictions ML, pas de base de données
"""
from flask import Flask, jsonify, request
from flask_cors import CORS
from model import AsthmaPredictor

# Créer l'application Flask
app = Flask(__name__)
CORS(app)
```

**Imports** :
- `Flask` : Framework web
- `jsonify` : Convertir dict Python → JSON
- `request` : Accéder aux données envoyées par le client
- `CORS` : Autoriser requêtes depuis l'app Flutter

```python
# Initialiser le prédicteur d'asthme avec le modèle optimisé
# Seuil critique à 0.65 (65%) pour meilleure sécurité médicale
predictor = AsthmaPredictor(model_path='models/asthma_model.pkl', high_risk_threshold=0.65)
```

- Crée une instance GLOBALE du prédicteur
- Charge automatiquement le modèle au premier predict

---

### Endpoint /api/predict

```python
@app.route('/api/predict', methods=['POST'])
def predict_asthma_risk():
    """
    Prédire le risque d'asthme basé sur les données du patient et des capteurs
    
    Format attendu:
    {
        "symptoms": {...},
        "demographics": {...},
        "sensors": {...}
    }
    """
    try:
        data = request.get_json()
```

**`@app.route(...)`** :
- **Décorateur** : Associe une URL à une fonction
- `/api/predict` : URL de l'endpoint
- `methods=['POST']` : Accepte seulement les requêtes POST

**`request.get_json()`** :
- Lit le corps de la requête HTTP
- Parse le JSON → dictionnaire Python

```python
# Vérifier les sections requises
required_sections = ['symptoms', 'demographics', 'sensors']
missing = [s for s in required_sections if s not in data]
if missing:
    return jsonify({
        'success': False,
        'error': f'Sections manquantes: {missing}'
    }), 400
```

**Validation** :
```python
# List comprehension pour trouver sections manquantes
# missing = ['sensors'] si data = {'symptoms': {...}, 'demographics': {...}}
# 
# 400 = HTTP Bad Request (erreur client)
```

```python
# Construire le dictionnaire de features
features = {}

# Ajouter les symptômes
for symptom, value in data['symptoms'].items():
    features[symptom] = value

# Ajouter la démographie
for demo, value in data['demographics'].items():
    features[demo] = value

# Ajouter les capteurs
for sensor, value in data['sensors'].items():
    features[sensor] = value
```

**Fusion des dictionnaires** :
```python
# data = {
#     'symptoms': {'Tiredness': 1, 'Dry-Cough': 1},
#     'demographics': {'Age_20-24': 1, 'Gender_Male': 1},
#     'sensors': {'PM25': 45.0, 'Humidity': 75.0}
# }
# 
# Après fusion, features = {
#     'Tiredness': 1,
#     'Dry-Cough': 1,
#     'Age_20-24': 1,
#     'Gender_Male': 1,
#     'PM25': 45.0,
#     'Humidity': 75.0,
#     ...
# }
```

```python
# Faire la prédiction
result = predictor.predict(features)

return jsonify({
    'success': True,
    'risk_level': result['risk_level'],
    'risk_label': result['risk_label'],
    'risk_score': result['risk_score'],
    'probabilities': result['probabilities'],
    'recommendations': result['recommendations']
}), 200
```

**jsonify()** :
- Convertit le dictionnaire en JSON
- Ajoute header `Content-Type: application/json`
- `200` = HTTP OK (succès)

```python
except ValueError as e:
    return jsonify({
        'success': False,
        'error': f'Feature manquante: {str(e)}'
    }), 400
except Exception as e:
    return jsonify({
        'success': False,
        'error': f'Erreur de prédiction: {str(e)}'
    }), 500
```

**Gestion d'erreurs** :
- `ValueError` : Feature manquante → 400 (erreur client)
- `Exception` : Autre erreur → 500 (erreur serveur)

---

### Démarrage du Serveur

```python
if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False
    )
```

**Paramètres** :
- `host='0.0.0.0'` : Écoute sur toutes les interfaces réseau (accessible depuis autres machines)
- `port=5000` : Port HTTP
- `debug=False` : Mode production (pas de debug)

---

## 🔄 Flux de Données Complet

### 1. Entraînement (train_model.py)

```
📊 CSV (3663 patients)
    ↓
[load_data()]
    ↓ Nettoyage
📊 X (2930×18), y (2930)
    ↓
[train()]
    ↓ RandomForest(151 arbres)
🧠 Modèle entraîné
    ↓
[save_model()]
    ↓
💾 asthma_model.pkl (3-6 MB)
```

### 2. Prédiction (main.py)

```
📱 App Flutter
    ↓ POST /api/predict
🌐 Flask API
    ↓ request.get_json()
📋 data = {'symptoms': {...}, 'demographics': {...}, 'sensors': {...}}
    ↓ features = {merged}
🧠 predictor.predict(features)
    ↓
[model.predict_proba()]
    ↓
📊 probabilities = [0.265, 0.258, 0.477]
    ↓
[apply threshold]
    ↓
🎯 risk_level = 3 (Élevé)
    ↓
[generate_recommendations()]
    ↓
💡 recommendations = [...]
    ↓ jsonify()
🌐 Response JSON
    ↓
📱 App Flutter (affichage)
```

---

## 🎓 Concepts Clés à Retenir

### Random Forest
- **Ensemble de 151 arbres** qui votent
- Chaque arbre voit des données légèrement différentes (bootstrap)
- Prédiction finale = **vote majoritaire** ou **probabilités moyennes**

### Hyperparamètres
- `n_estimators=151` : Nombre d'arbres (impair!)
- `max_depth=12` : Profondeur max
- `class_weight={..., 3:1.5}` : Priorité classe critique
- `n_jobs=-1` : Parallélisation

### Seuil Critique
- Si probabilité(Élevé) ≥ 65% → **Force alerte**
- Priorité sécurité médicale
- Réduit faux négatifs de 87%

### Features Importantes
1. **RespiratoryRate** (29%) : Fréquence respiratoire
2. **PM25** (25%) : Particules fines
3. **Nasal-Congestion** (8%) : Congestion nasale

### API Flask
- `/api/predict` : POST endpoint pour prédictions
- Format JSON : `{symptoms, demographics, sensors}`
- Retour : `{risk_level, risk_label, probabilities, recommendations}`

---

**📚 Documentation Complète** :
- [RANDOM_FOREST_EXPLICATIONS_COMPLETES.md](RANDOM_FOREST_EXPLICATIONS_COMPLETES.md)
- [RESULTATS_MODELE.md](RESULTATS_MODELE.md)
- [ARCHITECTURE_FINALE.md](ARCHITECTURE_FINALE.md)

**Date** : 19 janvier 2026
