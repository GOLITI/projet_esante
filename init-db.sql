-- Script d'initialisation de la base de données PostgreSQL pour E-Santé 4.0

-- Création de la table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des profils patients
CREATE TABLE IF NOT EXISTS patient_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    age INTEGER,
    gender VARCHAR(10),
    weight DECIMAL(5,2),
    height DECIMAL(5,2),
    bmi DECIMAL(4,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des évaluations d'asthme
CREATE TABLE IF NOT EXISTS asthma_assessments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    
    -- Antécédents
    family_asthma BOOLEAN DEFAULT FALSE,
    allergies BOOLEAN DEFAULT FALSE,
    
    -- Environnement
    smoking_exposure INTEGER DEFAULT 0, -- 0-2
    pollution_exposure INTEGER DEFAULT 0, -- 0-2
    
    -- Symptômes
    cough_level INTEGER DEFAULT 0, -- 0-3
    breathlessness_level INTEGER DEFAULT 0, -- 0-3
    wheezing_level INTEGER DEFAULT 0, -- 0-3
    
    -- Résultat
    risk_level INTEGER DEFAULT 0, -- 0-3 (Faible/Modéré/Élevé/Très élevé)
    risk_score DECIMAL(5,2),
    
    -- Métadonnées
    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des recommandations
CREATE TABLE IF NOT EXISTS recommendations (
    id SERIAL PRIMARY KEY,
    assessment_id INTEGER REFERENCES asthma_assessments(id) ON DELETE CASCADE,
    recommendation_text TEXT NOT NULL,
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table de l'historique des symptômes
CREATE TABLE IF NOT EXISTS symptom_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    symptom_date DATE NOT NULL,
    symptom_type VARCHAR(50) NOT NULL,
    severity INTEGER DEFAULT 0, -- 0-3
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_patient_profiles_user_id ON patient_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_asthma_assessments_user_id ON asthma_assessments(user_id);
CREATE INDEX IF NOT EXISTS idx_asthma_assessments_date ON asthma_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_recommendations_assessment_id ON recommendations(assessment_id);
CREATE INDEX IF NOT EXISTS idx_symptom_history_user_id ON symptom_history(user_id);
CREATE INDEX IF NOT EXISTS idx_symptom_history_date ON symptom_history(symptom_date);

-- Insertion de données de test (optionnel)
INSERT INTO users (email, password_hash, name) VALUES
    ('demo@pulsar.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyFVvNS0kKjy', 'Utilisateur Demo')
ON CONFLICT (email) DO NOTHING;

-- Message de succès
DO $$
BEGIN
    RAISE NOTICE 'Base de données initialisée avec succès !';
END $$;
