"""
Configuration de la base de données PostgreSQL avec SQLAlchemy
"""
import os
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, DECIMAL
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# URL de connexion PostgreSQL
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://asthme_user:asthme_password@postgres:5432/asthme_db')

# Créer le moteur SQLAlchemy
engine = create_engine(DATABASE_URL)

# Créer la session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base pour les modèles
Base = declarative_base()

# Modèle User
class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Modèle PatientProfile
class PatientProfile(Base):
    __tablename__ = 'patient_profiles'
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    age = Column(Integer)
    gender = Column(String(10))
    weight = Column(DECIMAL(5, 2))
    height = Column(DECIMAL(5, 2))
    bmi = Column(DECIMAL(4, 2))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Modèle AsthmaAssessment
class AsthmaAssessment(Base):
    __tablename__ = 'asthma_assessments'
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    family_asthma = Column(Boolean, default=False)
    allergies = Column(Boolean, default=False)
    smoking_exposure = Column(Integer, default=0)
    pollution_exposure = Column(Integer, default=0)
    cough_level = Column(Integer, default=0)
    breathlessness_level = Column(Integer, default=0)
    wheezing_level = Column(Integer, default=0)
    risk_level = Column(Integer, default=0)
    risk_score = Column(DECIMAL(5, 2))
    assessment_date = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

# Fonction pour obtenir une session DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Créer les tables (si elles n'existent pas)
def init_db():
    Base.metadata.create_all(bind=engine)
