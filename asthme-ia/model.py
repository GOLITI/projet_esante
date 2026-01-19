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

class AsthmaPredictor:
    """Classe pour la prédiction du risque d'asthme"""
    
    def __init__(self, model_path='models/asthma_model.pkl', high_risk_threshold=0.443):
        """
        Initialise le prédicteur
        
        Args:
            model_path: Chemin vers le modèle sauvegardé
            high_risk_threshold: Seuil de probabilité pour déclencher alerte critique
                                 (0.443 = optimal Youden, basé sur analyse ROC)
        """
        self.model_path = model_path
        self.model = None
        self.feature_names = None
        self.high_risk_threshold = high_risk_threshold  # Seuil optimal Youden (analyse ROC)
        self.min_feature_importance = 0.001  # Filtrer features < 0.1% d'importance
        self.risk_labels = {
            1: 'Faible',
            2: 'Modéré',
            3: 'Élevé'
        }
        
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
            
        if 'Humidity' in df_clean.columns:
            # Humidité: 0-100%
            df_clean.loc[df_clean['Humidity'] < 0, 'Humidity'] = 30
            df_clean.loc[df_clean['Humidity'] > 100, 'Humidity'] = 70
            
        if 'PM25' in df_clean.columns:
            # PM2.5: 0-500 µg/m³ (valeurs réalistes)
            df_clean.loc[df_clean['PM25'] < 0, 'PM25'] = 0
            df_clean.loc[df_clean['PM25'] > 500, 'PM25'] = 500
            
        if 'AQI' in df_clean.columns:
            # AQI: 0-500
            df_clean.loc[df_clean['AQI'] < 0, 'AQI'] = 0
            df_clean.loc[df_clean['AQI'] > 500, 'AQI'] = 500
            
        if 'Heart_Rate' in df_clean.columns:
            # Fréquence cardiaque: 40-200 bpm
            df_clean.loc[df_clean['Heart_Rate'] < 40, 'Heart_Rate'] = 70
            df_clean.loc[df_clean['Heart_Rate'] > 200, 'Heart_Rate'] = 100
            
        if 'RespiratoryRate' in df_clean.columns:
            # Fréquence respiratoire: 10-40 respirations/min
            df_clean.loc[df_clean['RespiratoryRate'] < 10, 'RespiratoryRate'] = 16
            df_clean.loc[df_clean['RespiratoryRate'] > 40, 'RespiratoryRate'] = 25
        
        return df_clean
    
    def load_data(self, csv_path='data/asthma_detection_with_sensors.csv'):
        """
        Charge et prépare les données avec nettoyage des valeurs aberrantes
        
        Args:
            csv_path: Chemin vers le fichier CSV (avec ou sans capteurs)
            
        Returns:
            X, y: Features et target
        """
        # Charger le dataset
        df = pd.read_csv(csv_path)
        
        # Nettoyer les valeurs aberrantes des capteurs
        df = self._clean_sensor_data(df)
        
        # Séparer features et target
        X = df.drop('Asthma', axis=1)
        y = df['Asthma']
        
        # Sauvegarder les noms des features
        self.feature_names = X.columns.tolist()
        
        print(f"Features chargées: {len(self.feature_names)}")
        if 'Temperature' in self.feature_names:
            print("✓ Données de capteurs détectées (Température, Humidité, PM2.5, AQI, Fréquence cardiaque)")
        print("✓ Nettoyage des valeurs aberrantes effectué")
        
        return X, y
    
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
        
        # Créer et entraîner le modèle Random Forest avec hyperparamètres optimisés
        # Utilisation d'un nombre impair d'arbres pour éviter les égalités
        self.model = RandomForestClassifier(
            n_estimators=151,  # Nombre impair pour éviter égalités, augmenté pour plus de stabilité
            max_depth=12,  # Augmenté pour capturer plus de patterns complexes
            min_samples_split=5,
            min_samples_leaf=1,  # Réduit pour plus de flexibilité
            random_state=random_state,
            class_weight={1: 1.0, 2: 1.0, 3: 1.5},  # Poids ajusté pour classe critique "Élevé"
            n_jobs=-1  # Utilise tous les CPU
        )
        
        print("Entraînement du modèle Random Forest optimisé...")
        print(f"  • n_estimators: 151 (nombre impair)")
        print(f"  • max_depth: 12 (patterns complexes)")
        print(f"  • min_samples_leaf: 1 (flexibilité)")
        print(f"  • class_weight: {{1:1.0, 2:1.0, 3:1.5}} (priorité classe critique)")
        print(f"  • Seuil alerte critique: {self.high_risk_threshold:.2f}")
        
        self.model.fit(X_train, y_train)
        
        # Prédictions
        y_pred = self.model.predict(X_test)
        
        # Métriques
        accuracy = accuracy_score(y_test, y_pred)
        
        # Cross-validation améliorée avec StratifiedKFold (10 folds)
        skf = StratifiedKFold(n_splits=10, shuffle=True, random_state=random_state)
        cv_scores = cross_val_score(self.model, X_train, y_train, cv=skf)
        
        # Importance des features
        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        # Identifier les features négligeables (< 0.1% d'importance)
        low_importance_features = feature_importance[feature_importance['importance'] < self.min_feature_importance]
        important_features = feature_importance[feature_importance['importance'] >= self.min_feature_importance]
        
        print(f"\n{'='*50}")
        print(f"RÉSULTATS DE L'ENTRAÎNEMENT")
        print(f"{'='*50}")
        print(f"Accuracy sur test set: {accuracy:.4f}")
        print(f"Cross-validation score (10-fold): {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")
        print(f"\nTop 10 features importantes:")
        print(important_features.head(10))
        
        if len(low_importance_features) > 0:
            print(f"\n⚠️ {len(low_importance_features)} feature(s) négligeable(s) détectée(s) (< {self.min_feature_importance*100:.1f}%):")
            for feat in low_importance_features['feature'].tolist():
                print(f"  - {feat}")
            print("  Conseil: Considérer leur suppression pour réduire le bruit")
        
        print(f"\nClassification Report:")
        print(classification_report(y_test, y_pred, target_names=[self.risk_labels.get(i, str(i)) for i in sorted(y_test.unique())]))
        print(f"\nMatrice de confusion:")
        print(confusion_matrix(y_test, y_pred))
        
        metrics = {
            'accuracy': accuracy,
            'cv_mean': cv_scores.mean(),
            'cv_std': cv_scores.std(),
            'feature_importance': feature_importance.to_dict('records'),
            'classification_report': classification_report(y_test, y_pred, output_dict=True)
        }
        
        return metrics
    
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
    
    def load_model(self):
        """Charge le modèle sauvegardé"""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Modèle non trouvé: {self.model_path}")
        
        model_data = joblib.load(self.model_path)
        self.model = model_data['model']
        self.feature_names = model_data['feature_names']
        self.risk_labels = model_data['risk_labels']
        
        print(f"Modèle chargé depuis: {self.model_path}")
    
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
        
        # Convertir en DataFrame si nécessaire
        if isinstance(features, dict):
            features_df = pd.DataFrame([features])
        else:
            features_df = features
        
        # Vérifier que toutes les features sont présentes
        missing_features = set(self.feature_names) - set(features_df.columns)
        if missing_features:
            raise ValueError(f"Features manquantes: {missing_features}")
        
        # Réorganiser les colonnes dans le bon ordre
        features_df = features_df[self.feature_names]
        
        # Prédiction avec probabilités
        risk_probabilities = self.model.predict_proba(features_df)[0]
        risk_level_default = int(self.model.predict(features_df)[0])
        
        # Convertir les probabilités en dict
        prob_dict = {
            int(cls): float(prob) 
            for cls, prob in zip(self.model.classes_, risk_probabilities)
        }
        
        # Appliquer le seuil médical pour la classe critique (3 = Élevé)
        # Si probabilité de classe 3 >= seuil critique, forcer l'alerte
        risk_level = risk_level_default
        if 3 in prob_dict and prob_dict[3] >= self.high_risk_threshold:
            risk_level = 3  # Forcer alerte critique pour sécurité médicale
            print(f"⚠️ ALERTE CRITIQUE: Probabilité classe Élevé = {prob_dict[3]:.2%} >= seuil {self.high_risk_threshold:.2%}")
        
        # Calculer un score global (probabilité de la classe prédite)
        risk_score = float(risk_probabilities[list(self.model.classes_).index(risk_level)])
        
        # Générer des recommandations basées sur le niveau de risque
        recommendations = self._generate_recommendations(risk_level, features_df.iloc[0].to_dict())
        
        return {
            'risk_level': risk_level,
            'risk_label': self.risk_labels.get(risk_level, 'Inconnu'),
            'risk_score': risk_score,
            'probabilities': prob_dict,
            'recommendations': recommendations
        }
    
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
        
        # Recommandations basées sur les symptômes
        if features.get('Difficulty-in-Breathing', 0) == 1:
            recommendations.append("Respirez lentement et profondément")
            recommendations.append("Asseyez-vous dans une position confortable")
        
        if features.get('Dry-Cough', 0) == 1:
            recommendations.append("Hydratez-vous régulièrement")
            recommendations.append("Évitez les irritants (fumée, poussière)")
        
        if features.get('Tiredness', 0) == 1:
            recommendations.append("Reposez-vous suffisamment")
        
        # Recommandations basées sur les capteurs environnementaux
        pm25 = features.get('PM25', None)
        if pm25 is not None:
            if pm25 > 55:
                recommendations.append("🌫️ Qualité de l'air très mauvaise - Restez à l'intérieur")
            elif pm25 > 35:
                recommendations.append("🌫️ Qualité de l'air mauvaise - Limitez les activités extérieures")
        
        aqi = features.get('AQI', None)
        if aqi is not None and aqi > 100:
            recommendations.append("Utilisez un purificateur d'air si possible")
        
        humidity = features.get('Humidity', None)
        if humidity is not None:
            if humidity > 70:
                recommendations.append("💧 Humidité élevée - Utilisez un déshumidificateur")
            elif humidity < 30:
                recommendations.append("💧 Air trop sec - Utilisez un humidificateur")
        
        temperature = features.get('Temperature', None)
        if temperature is not None and temperature > 37.5:
            recommendations.append("🌡️ Température élevée - Consultez pour fièvre possible")
        
        heart_rate = features.get('Heart_Rate', None)
        if heart_rate is not None:
            if heart_rate > 100:
                recommendations.append("❤️ Fréquence cardiaque élevée - Reposez-vous et calmez-vous")
            elif heart_rate < 60:
                recommendations.append("❤️ Fréquence cardiaque basse - Consultez si persiste")
        
        # Recommandations générales
        recommendations.append("Évitez l'exposition à la fumée de cigarette")
        recommendations.append("Gardez votre environnement propre et aéré")
        
        # Retourner les recommandations les plus pertinentes (max 8)
        return recommendations[:8]
    
    def get_feature_importance(self):
        """
        Retourne l'importance des features
        
        Returns:
            DataFrame avec les features et leur importance
        """
        if self.model is None:
            raise ValueError("Le modèle doit être entraîné ou chargé")
        
        return pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
