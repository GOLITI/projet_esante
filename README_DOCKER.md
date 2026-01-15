# 🐳 Guide Docker - E-Santé 4.0

Ce guide explique comment utiliser Docker pour développer et déployer le projet E-Santé 4.0 en équipe.

## 📋 Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac/Linux)
- [Docker Compose](https://docs.docker.com/compose/install/) (généralement inclus avec Docker Desktop)

## 🚀 Démarrage rapide

### 1. Cloner le projet
```bash
git clone <votre-repo>
cd projet_esante
```

### 2. Lancer tous les services
```bash
docker-compose up -d
```

Cette commande va :
- ✅ Construire les images Docker pour le backend et le frontend
- ✅ Démarrer les conteneurs
- ✅ Configurer le réseau entre les services

### 3. Accéder aux services

- **Application Flutter (Frontend)** : http://localhost:8080
- **API Backend (Flask)** : http://localhost:5000
- **PostgreSQL** : localhost:5432
  - Base de données : `asthme_db`
  - Utilisateur : `asthme_user`
  - Mot de passe : `asthme_password`

## 🛠️ Commandes utiles

### Voir les logs
```bash
# Tous les services
docker-compose logs -f

# Backend uniquement
docker-compose logs -f backend

# Frontend uniquement
docker-compose logs -f frontend
```

### Arrêter les services
```bash
docker-compose down
```

### Reconstruire les images (après modification du code)
```bash
docker-compose up -d --build
```

### Arrêter et supprimer tout (y compris les volumes)
```bash
docker-compose down -v
```

### Redémarrer un service spécifique
```bash
docker-compose restart backend
docker-compose restart frontend
```

## 📁 Structure du projet

```
projet_esante/
├── asthme-ia/                # Backend Flask
│   ├── Dockerfile           # Configuration Docker backend
│   ├── .dockerignore        # Fichiers à exclure
│   ├── main.py              # Point d'entrée Flask
│   └── requirements.txt     # Dépendances Python (+ PostgreSQL)
│
├── asthme_app/              # Frontend Flutter
│   ├── Dockerfile           # Configuration Docker frontend
│   ├── .dockerignore        # Fichiers à exclure
│   └── pubspec.yaml         # Dépendances Flutter
│
├── docker-compose.yml       # Orchestration des services
├── init-db.sql              # Script d'initialisation PostgreSQL
├── .env.example             # Variables d'environnement (exemple)
└── README_DOCKER.md         # Ce fichier
```

## 🔧 Mode développement

Pour le développement avec rechargement automatique :

### Backend (Flask)
```bash
cd asthme-ia
docker-compose up backend
```

Le code est monté en volume, les changements sont détectés automatiquement.

### Frontend (Flutter)
Pour le développement Flutter, il est recommandé d'utiliser `flutter run` localement :
```bash
cd asthme_app
flutter run -d chrome
```

## 🏗️ Construire les images individuellement

### Backend uniquement
```bash
cd asthme-ia
docker build -t asthme-backend:latest .
docker run -p 5000:5000 asthme-backend:latest
```

### Frontend uniquement
```bash
cd asthme_app
docker build -t asthme-frontend:latest .
docker run -p 8080:8080 asthme-frontend:latest
```

## 🔍 Débogage

### Accéder au shell d'un conteneur
```bash
# PostgreSQL
docker exec -it asthme_postgres psql -U asthme_user -d asthme_db

# Backend
docker exec -it asthme_backend bash

# Frontend
docker exec -it asthme_frontend bash
```

### Commandes PostgreSQL utiles
```bash
# Se connecter à PostgreSQL
docker exec -it asthme_postgres psql -U asthme_user -d asthme_db

# Lister les tables
\dt

# Voir les utilisateurs
SELECT * FROM users;

# Exporter la base de données
docker exec asthme_postgres pg_dump -U asthme_user asthme_db > backup.sql

# Restaurer la base de données
docker exec -i asthme_postgres psql -U asthme_user asthme_db < backup.sql
```

### Vérifier l'état des conteneurs
```bash
docker ps
```

### Inspecter un conteneur
```bash
docker inspect asthme_backend
docker inspect asthme_frontend
```

### Vérifier le réseau
```bash
docker network ls
docker network inspect projet_esante_asthme_network
```

Créez un fichier `.env` à partir du modèle `.env.example` :

```bash
cp .env.example .env
```

Variables disponibles :
```env
# PostgreSQL
POSTGRES_DB=asthme_db
POSTGRES_USER=asthme_user
POSTGRES_PASSWORD=asthme_password

# Backend Flask
FLASK_ENV=production
DATABASE_URL=postgresql://asthme_user:asthme_password@postgres:5432/asthme_db

# Frontend
BACKEND_API_URL=http://backend:5000
```

⚠️ **Important** : Ne commitez JAMAIS le fichier `.env` avec les vraies credentials !_file:
  - .env
```

## 🚢 Déploiement en production

### 1. Construire pour la production
```bash
docker-compose -f docker-compose.yml build --no-cache
```

### 2. Pousser vers un registre Docker
```bash
docker tag asthme-backend:latest <votre-registry>/asthme-backend:latest
docker tag asthme-frontend:latest <votre-registry>/asthme-frontend:latest

docker push <votre-registry>/asthme-backend:latest
docker push <votre-registry>/asthme-frontend:latest
```

## 📊 Healthchecks

Le backend inclut un healthcheck automatique. Créez un endpoint `/health` dans `main.py` :

```python
@app.route('/health')
def health():
    return {'status': 'healthy'}, 200
```

## 🤝 Travail en équipe

### Partager les images

**Option 1 : Docker Hub**
```bash
docker login
docker push <votre-username>/asthme-backend:latest
```

**Option 2 : Fichier tar**
```bash
docker save -o asthme-backend.tar asthme-backend:latest
# Partager asthme-backend.tar
docker load -i asthme-backend.tar
```

### Bonnes pratiques
1. ✅ Commitez toujours les Dockerfile et docker-compose.yml
2. ✅ Ne commitez JAMAIS les `.env` avec des secrets
3. ✅ Utilisez `.dockerignore` pour optimiser la taille des images
4. ✅ Documentez les variables d'environnement nécessaires
docker-compose logs postgres
```

### Problème de connexion à PostgreSQL
```bash
# Vérifier que PostgreSQL est prêt
docker-compose logs postgres

# Tester la connexion
docker exec -it asthme_postgres pg_isready -U asthme_user

# Réinitialiser les données PostgreSQL
docker-compose down -v
docker-compose up -d

## ❓ Problèmes courants

### Port déjà utilisé
```bash
# Trouver le processus utilisant le port
netstat -ano | findstr :5000
# Ou changer le port dans docker-compose.yml
```

### Erreur de build
```bash
# Nettoyer le cache Docker
docker system prune -a
docker-compose build --no-cache
```

### Conteneur ne démarre pas
```bash
# Voir les logs d'erreur
docker-compose logs backend
```

## 📞 Support

Pour toute question, consultez :
- [Documentation Docker](https://docs.docker.com/)
- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Flask](https://flask.palletsprojects.com/)

---

**Date** : 15 janvier 2026  
**Version** : 1.0
