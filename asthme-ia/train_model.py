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
    
    # Créer le dossier models s'il n'existe pas
    os.makedirs('models', exist_ok=True)
    
    # Initialiser le prédicteur avec seuil optimal Youden (0.443)
    # Basé sur analyse ROC: 96.7% sensibilité, 98.8% spécificité
    predictor = AsthmaPredictor(model_path='models/asthma_model.pkl', high_risk_threshold=0.443)
    
    # Charger les données
    print("\nChargement des données...")
    X, y = predictor.load_data('data/asthma_detection_final.csv')
    print(f"Dataset chargé: {X.shape[0]} échantillons, {X.shape[1]} features")
    print(f"Distribution des classes:")
    print(y.value_counts().sort_index())
    
    # Entraîner le modèle
    print("\n" + "="*60)
    metrics = predictor.train(X, y, test_size=0.2, random_state=42)
    
    # Sauvegarder le modèle
    print("\n" + "="*60)
    predictor.save_model()
    
    # Afficher l'importance des features
    print("\n" + "="*60)
    print("IMPORTANCE DES FEATURES")
    print("="*60)
    feature_importance = predictor.get_feature_importance()
    print(feature_importance)
    
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
    
    print("\nExemple de patient:")
    print("- Fatigue: Oui")
    print("- Toux sèche: Oui")
    print("- Difficulté respiratoire: Oui")
    print("- Mal de gorge: Oui")
    print("- Congestion nasale: Oui")
    print("- Âge: 20-24 ans")
    print("- Genre: Homme")
    print("\n📊 Capteurs:")
    print(f"- Humidité: {test_example['Humidity']}%")
    print(f"- Température: {test_example['Temperature']}°C")
    print(f"- Particules fines PM2.5: {test_example['PM25']} µg/m³")
    print(f"- Fréquence respiratoire: {test_example['RespiratoryRate']} respirations/min")
    
    result = predictor.predict(test_example)
    
    print(f"\n📊 RÉSULTAT DE LA PRÉDICTION:")
    print(f"Niveau de risque: {result['risk_level']} - {result['risk_label']}")
    print(f"Score de confiance: {result['risk_score']:.2%}")
    print(f"\nProbabilités par classe:")
    for cls, prob in sorted(result['probabilities'].items()):
        risk_label = predictor.risk_labels.get(cls, str(cls))
        print(f"  {risk_label}: {prob:.2%}")
    
    print(f"\n💡 RECOMMANDATIONS:")
    for i, rec in enumerate(result['recommendations'], 1):
        print(f"  {i}. {rec}")
    
    print("\n" + "="*60)
    print("✅ ENTRAÎNEMENT TERMINÉ AVEC SUCCÈS!")
    print("="*60)
    print(f"\nLe modèle est prêt à être utilisé dans l'API Flask.")
    print(f"Fichier du modèle: models/asthma_model.pkl")

if __name__ == '__main__':
    main()
