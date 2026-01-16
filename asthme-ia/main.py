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

# Initialiser le prédicteur d'asthme
predictor = AsthmaPredictor(model_path='models/asthma_model.pkl')

print("✅ Backend Flask démarré - Service de prédiction ML uniquement")

@app.route('/')
def home():
    """Page d'accueil de l'API"""
    return jsonify({
        'message': 'API E-Santé 4.0 - Prédiction Risque Asthme',
        'version': '2.0.0',
        'status': 'running',
        'mode': 'ML Prediction Service (no database)',
        'capteurs': ['Humidité', 'Température', 'PM2.5', 'Fréquence Respiratoire']
    })

@app.route('/health')
def health():
    """Endpoint de santé"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/predict', methods=['POST'])
def predict_asthma_risk():
    """
    Prédire le risque d'asthme basé sur les données du patient et des capteurs
    
    Format attendu:
    {
        "symptoms": {...},           # 7 symptômes (0 ou 1)
        "demographics": {...},       # Age, Gender, BMI, etc.
        "sensors": {                 # 4 capteurs physiques
            "Humidity": 65.0,
            "Temperature": 22.5,
            "PM25": 35.2,
            "RespiratoryRate": 18.0
        }
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'Aucune donnée reçue'
            }), 400
        
        # Vérifier la structure de base
        required_sections = ['symptoms', 'demographics', 'sensors']
        missing_sections = [s for s in required_sections if s not in data]
        if missing_sections:
            return jsonify({
                'success': False,
                'error': f'Sections manquantes: {missing_sections}'
            }), 400
        
        # Combiner les features de base
        features = {}
        features.update(data['symptoms'])
        
        # Encoder les demographics en one-hot
        demographics = data['demographics']
        
        # Encoder l'âge
        age_categories = ['0-9', '10-19', '20-24', '25-59', '60+']
        for age_cat in age_categories:
            features[f'Age_{age_cat}'] = 1 if demographics.get('age') == age_cat else 0
        
        # Encoder le genre
        gender = demographics.get('gender', 'Male')
        features['Gender_Female'] = 1 if gender == 'Female' else 0
        features['Gender_Male'] = 1 if gender == 'Male' else 0
        
        # Ajouter les capteurs
        features.update(data['sensors'])
        
        # Faire la prédiction
        result = predictor.predict(features)
        
        return jsonify({
            'success': True,
            'risk_level': int(result['risk_level']),
            'risk_label': result['risk_label'],
            'risk_score': float(result['risk_score']),
            'probabilities': result['probabilities'],
            'recommendations': result['recommendations']
        }), 200
        
    except KeyError as e:
        return jsonify({
            'success': False,
            'error': f'Feature manquante: {str(e)}'
        }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Erreur de prédiction: {str(e)}'
        }), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False
    )
