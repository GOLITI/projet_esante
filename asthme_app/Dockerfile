# Dockerfile pour l'application Flutter
FROM ubuntu:22.04

# Éviter les prompts interactifs lors de l'installation
ENV DEBIAN_FRONTEND=noninteractive

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Définir les variables d'environnement pour Flutter
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Télécharger et installer Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME && \
    flutter doctor && \
    flutter config --no-analytics

# Créer le répertoire de travail
WORKDIR /app

# Copier le fichier de configuration Flutter
COPY pubspec.yaml ./

# Télécharger les dépendances Flutter
RUN flutter pub get

# Copier tout le code source
COPY . .

# Exposer le port pour le serveur web
EXPOSE 8080

# Commande de démarrage (mode développement)
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
