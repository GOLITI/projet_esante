# Dockerfile pour le backend ML (Flask API)
FROM python:3.12-slim

# Définir le répertoire de travail
WORKDIR /app

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copier les fichiers de dépendances
COPY requirements.txt .

# Mettre à jour pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY . .

# Exposer le port Flask (par défaut 5000)
EXPOSE 5000

# Variable d'environnement pour Flask
ENV FLASK_APP=main.py
ENV FLASK_ENV=production

# Commande de démarrage
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=5000"]
