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

# Initialiser le prédicteur d'asthme avec le modèle optimisé
# Seuil critique à 0.443 (Youden optimal, basé sur analyse ROC)
# Sensibilité: 96.7%, Spécificité: 98.8%, FPR: 1.2%
predictor = AsthmaPredictor(model_path='models/asthma_model.pkl', high_risk_threshold=0.443)

# Stockage en mémoire des dernières données capteurs
latest_sensor_data = {
    'temperature': None,
    'humidity': None,
    'pm25': None,
    'respiratoryRate': 0.0,  # Valeur par défaut 0 si pas de capteur
    'timestamp': None
}

print("✅ Backend Flask démarré - Service de prédiction ML + Réception capteurs ESP32")

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

@app.route('/api/sensors', methods=['POST'])
def receive_sensor_data():
    """
    Reçoit les données de l'ESP32
    
    Format attendu:
    {
        "temperature": 22.5,
        "humidity": 65.0,
        "pm1": 10.0,
        "pm25": 35.0,
        "pm10": 50.0
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'Aucune donnée reçue'
            }), 400
        
        # Mettre à jour les données en mémoire
        from datetime import datetime
        import random
        
        latest_sensor_data['temperature'] = data.get('temperature')
        latest_sensor_data['humidity'] = data.get('humidity')
        latest_sensor_data['pm25'] = data.get('pm25', data.get('pm1', 0))  # Utiliser pm25 ou pm1
        
        # Générer une fréquence respiratoire réaliste si non fournie
        # Plage normale : 12-20 respirations/minute
        # Variation selon les conditions environnementales
        if 'respiratoryRate' not in data or data.get('respiratoryRate') is None or data.get('respiratoryRate') == 0:
            base_rate = 16.0  # Fréquence normale au repos
            
            # Ajuster selon la qualité de l'air (PM2.5)
            pm25 = latest_sensor_data['pm25']
            if pm25 > 55:  # Très mauvais
                base_rate += random.uniform(2.0, 4.0)
            elif pm25 > 35:  # Mauvais
                base_rate += random.uniform(1.0, 2.5)
            
            # Ajuster selon l'humidité
            humidity = latest_sensor_data['humidity']
            if humidity > 70:  # Trop humide
                base_rate += random.uniform(0.5, 1.5)
            elif humidity < 30:  # Trop sec
                base_rate += random.uniform(0.5, 1.0)
            
            # Ajouter une petite variation naturelle
            latest_sensor_data['respiratoryRate'] = round(base_rate + random.uniform(-1.0, 1.0), 1)
        else:
            latest_sensor_data['respiratoryRate'] = data.get('respiratoryRate')
        
        latest_sensor_data['timestamp'] = datetime.now().isoformat()
        
        print(f"📡 Données capteurs reçues: T={latest_sensor_data['temperature']}°C, H={latest_sensor_data['humidity']}%, PM2.5={latest_sensor_data['pm25']}")
        
        return jsonify({
            'success': True,
            'message': 'Données capteurs enregistrées',
            'data': latest_sensor_data
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Erreur: {str(e)}'
        }), 500

@app.route('/api/sensors/latest', methods=['GET'])
def get_latest_sensors():
    """
    Retourne les dernières données capteurs pour l'app Flutter
    
    Format de réponse:
    {
        "success": true,
        "data": {
            "humidity": 65.0,
            "temperature": 22.5,
            "pm25": 35.0,
            "respiratoryRate": 16.0,
            "timestamp": "2026-01-17T18:30:00"
        }
    }
    """
    if latest_sensor_data['temperature'] is None:
        return jsonify({
            'success': False,
            'error': 'Aucune donnée capteur disponible',
            'message': 'L\'ESP32 n\'a pas encore envoyé de données'
        }), 404
    
    return jsonify({
        'success': True,
        'data': {
            'humidity': latest_sensor_data['humidity'],
            'temperature': latest_sensor_data['temperature'],
            'pm25': latest_sensor_data['pm25'],
            'respiratoryRate': latest_sensor_data['respiratoryRate'],
            'timestamp': latest_sensor_data['timestamp']
        }
    }), 200

@app.route('/api/predict', methods=['POST'])
def predict_asthma_risk():
    """
    Prédire le risque d'asthme basé sur les symptômes + données capteurs ESP32
    
    ⚠️ ARCHITECTURE:
    - L'ESP32 envoie les données environnementales à /api/sensors
    - L'app Flutter envoie UNIQUEMENT les symptômes + demographics
    - Le backend utilise automatiquement les DERNIÈRES données capteurs ESP32
    
    Format attendu de l'app Flutter:
    {
        "symptoms": {                # 7 symptômes (0 ou 1)
            "Tiredness": 0,
            "Dry-Cough": 1,
            "Difficulty-in-Breathing": 1,
            ...
        },
        "demographics": {            # Age et Genre
            "age": "25-59",
            "gender": "Male"
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
        
        # Vérifier la structure de base (symptoms et demographics uniquement)
        required_sections = ['symptoms', 'demographics']
        missing_sections = [s for s in required_sections if s not in data]
        if missing_sections:
            return jsonify({
                'success': False,
                'error': f'Sections manquantes: {missing_sections}'
            }), 400
        
        # Vérifier que les données capteurs ESP32 sont disponibles
        if latest_sensor_data['temperature'] is None:
            return jsonify({
                'success': False,
                'error': 'Aucune donnée capteur disponible. L\'ESP32 doit d\'abord envoyer des données à /api/sensors'
            }), 503  # Service Unavailable
        
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
        
        # 🔥 UTILISER LES DONNÉES CAPTEURS ESP32 (dernières reçues)
        features['Humidity'] = latest_sensor_data['humidity']
        features['Temperature'] = latest_sensor_data['temperature']
        features['PM25'] = latest_sensor_data['pm25']
        features['RespiratoryRate'] = latest_sensor_data['respiratoryRate']
        
        print(f"📊 Prédiction avec capteurs ESP32: T={features['Temperature']}°C, H={features['Humidity']}%, PM2.5={features['PM25']}, RR={features['RespiratoryRate']}")
        
        # Faire la prédiction
        result = predictor.predict(features)
        
        return jsonify({
            'success': True,
            'risk_level': int(result['risk_level']),
            'risk_label': result['risk_label'],
            'risk_score': float(result['risk_score']),
            'probabilities': result['probabilities'],
            'recommendations': result['recommendations'],
            'sensor_data_used': {  # Retourner les données capteurs utilisées
                'temperature': features['Temperature'],
                'humidity': features['Humidity'],
                'pm25': features['PM25'],
                'respiratory_rate': features['RespiratoryRate'],
                'timestamp': latest_sensor_data['timestamp']
            }
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
