"""
API Flask pour E-Santé 4.0 - Prédiction du risque d'asthme
"""
from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import os
from dotenv import load_dotenv
from database import SessionLocal, User, init_db
from sqlalchemy.exc import IntegrityError

# Charger les variables d'environnement
load_dotenv()

# Créer l'application Flask
app = Flask(__name__)
CORS(app)

# Initialiser la base de données
with app.app_context():
    init_db()

# Configuration de la base de données
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://asthme_user:asthme_password@postgres:5432/asthme_db')

@app.route('/')
def home():
    """Page d'accueil de l'API"""
    return jsonify({
        'message': 'API E-Santé 4.0 - Prédiction Risque Asthme',
        'version': '1.0.0',
        'status': 'running',
        'database': 'PostgreSQL connected'
    })

@app.route('/health')
def health():
    """Endpoint de santé pour Docker healthcheck"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/predict', methods=['POST'])
def predict_asthma_risk():
    """
    Prédire le risque d'asthme basé sur les données du patient
    """
    try:
        data = request.get_json()
        
        # TODO: Implémenter la logique de prédiction ML
        # Pour le moment, retourner un résultat factice
        
        risk_score = 0.5  # Score entre 0 et 1
        risk_level = 1    # 0=Faible, 1=Modéré, 2=Élevé, 3=Très élevé
        
        recommendations = [
            "Consultez un médecin pour un diagnostic complet",
            "Évitez l'exposition à la fumée de cigarette",
            "Surveillez vos symptômes respiratoires"
        ]
        
        return jsonify({
            'success': True,
            'risk_score': risk_score,
            'risk_level': risk_level,
            'risk_label': ['Faible', 'Modéré', 'Élevé', 'Très élevé'][risk_level],
            'recommendations': recommendations
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

@app.route('/api/user/register', methods=['POST'])
def register_user():
    """Inscription d'un nouvel utilisateur dans PostgreSQL"""
    db = SessionLocal()
    try:
        data = request.get_json()
        
        # Validation
        if not data.get('email') or not data.get('password') or not data.get('name'):
            return jsonify({
                'success': False,
                'error': 'Email, mot de passe et nom sont requis'
            }), 400
        
        # Vérifier si l'email existe déjà
        existing_user = db.query(User).filter(User.email == data['email']).first()
        if existing_user:
            return jsonify({
                'success': False,
                'error': 'Cet email est déjà utilisé'
            }), 400
        
        # Créer un nouvel utilisateur
        hashed_password = generate_password_hash(data['password'])
        new_user = User(
            email=data['email'],
            password_hash=hashed_password,
            name=data['name']
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        return jsonify({
            'success': True,
            'message': 'Utilisateur créé avec succès',
            'user': {
                'id': new_user.id,
                'email': new_user.email,
                'name': new_user.name,
                'created_at': new_user.created_at.isoformat()
            }
        }), 201
        
    except Exception as e:
        db.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400
    finally:
        db.close()

@app.route('/api/user/login', methods=['POST'])
def login_user():
    """Connexion d'un utilisateur avec PostgreSQL"""
    db = SessionLocal()
    try:
        data = request.get_json()
        
        # Validation
        if not data.get('email') or not data.get('password'):
            return jsonify({
                'success': False,
                'error': 'Email et mot de passe sont requis'
            }), 400
        
        # Chercher l'utilisateur
        user = db.query(User).filter(User.email == data['email']).first()
        
        if not user or not check_password_hash(user.password_hash, data['password']):
            return jsonify({
                'success': False,
                'error': 'Email ou mot de passe incorrect'
            }), 401
        
        return jsonify({
            'success': True,
            'message': 'Connexion réussie',
            'user': {
                'id': user.id,
                'email': user.email,
                'name': user.name,
                'created_at': user.created_at.isoformat()
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400
    finally:
        db.close()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
