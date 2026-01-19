# 🔐 Guide de Sécurité pour GitHub

## ✅ Modifications apportées

### 1. Protection des clés API Gemini

**Avant** ❌ : La clé API était en dur dans le code
```dart
static const String geminiApiKey = 'AIzaSyA4rW08oCK_a7v2cjkLzEtX-b5VcQ3JG_Q';
```

**Après** ✅ : Utilisation de variables d'environnement
```dart
static const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'YOUR_API_KEY_HERE',
);
```

### 2. Fichiers créés

- ✅ `asthme_app/.env` - Contient vos clés réelles (NON COMMITÉ)
- ✅ `asthme_app/.env.example` - Template pour les autres développeurs (COMMITÉ)

### 3. `.gitignore` mis à jour

Ajout de la protection :
```
# 🔐 Fichiers sensibles - CRITIQUE
asthme_app/.env
asthme_app/.env.local
asthme_app/.env.*.local
*.env
!*.env.example
```

## 🚨 Avant de pousser sur GitHub

### Étape 1 : Vérifier les fichiers sensibles

```powershell
# Vérifier qu'aucun fichier sensible n'est tracké
git status

# Vérifier le contenu à commiter
git diff --cached
```

### Étape 2 : Supprimer la clé API de l'historique Git (si déjà commitée)

Si vous avez déjà commité la clé API, il faut nettoyer l'historique :

```powershell
# ATTENTION : Cette commande réécrit l'historique !
# À faire AVANT le premier push sur GitHub

# Supprimer le fichier de l'historique
git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch asthme_app/lib/core/constants/api_constants.dart" `
  --prune-empty --tag-name-filter cat -- --all

# Ou utiliser git-filter-repo (recommandé, plus rapide)
# pip install git-filter-repo
# git filter-repo --path asthme_app/lib/core/constants/api_constants.dart --invert-paths
```

### Étape 3 : Révoquer l'ancienne clé API

🔴 **CRITIQUE** : Comme votre clé API a été exposée dans le code, vous devez :

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Accéder à "APIs & Services" > "Credentials"
3. Trouver votre clé API : `AIzaSyA4rW08oCK_a7v2cjkLzEtX-b5VcQ3JG_Q`
4. **SUPPRIMER** ou **RÉGÉNÉRER** cette clé
5. Créer une nouvelle clé API
6. Mettre à jour le fichier `.env` avec la nouvelle clé

### Étape 4 : Vérifier avant le push

```powershell
# Vérifier qu'aucune clé n'est présente
git grep -i "AIza" 
git grep -i "GEMINI_API_KEY" 

# Vérifier les fichiers non suivis
git ls-files --others --exclude-standard

# Vérifier que .env est bien ignoré
git check-ignore asthme_app/.env
# Devrait afficher : asthme_app/.env
```

## 📤 Commandes pour pousser sur GitHub

```powershell
# Ajouter les fichiers sécurisés
git add .

# Commit avec message descriptif
git commit -m "🔐 Sécurisation des clés API - Migration vers .env"

# Premier push (si nouveau repo)
git branch -M main
git remote add origin https://github.com/votre-username/projet_esante.git
git push -u origin main

# Push suivants
git push
```

## 🛡️ Bonnes pratiques pour l'avenir

### 1. Ne jamais commiter de secrets

- ❌ Clés API
- ❌ Mots de passe
- ❌ Tokens d'authentification
- ❌ Certificats privés
- ❌ Chaînes de connexion à la base de données

### 2. Utiliser `.env` pour tous les secrets

```env
# Toujours dans .env, jamais dans le code
GEMINI_API_KEY=votre_cle
DATABASE_URL=votre_url
JWT_SECRET=votre_secret
```

### 3. Vérifier avant chaque commit

```powershell
# Créer un hook pre-commit pour vérifier
# .git/hooks/pre-commit
#!/bin/sh
if git diff --cached | grep -i "AIza" ; then
    echo "❌ ATTENTION : Clé API détectée !"
    exit 1
fi
```

### 4. Scanner le dépôt

Utilisez des outils pour détecter les secrets :

```powershell
# Installer gitleaks
# winget install gitleaks

# Scanner le repo
gitleaks detect --source . --verbose
```

## 📋 Checklist finale avant GitHub

- [ ] `.env` est dans `.gitignore`
- [ ] `.env.example` existe (sans vraies clés)
- [ ] `api_constants.dart` utilise `String.fromEnvironment()`
- [ ] Aucune clé API en dur dans le code
- [ ] `git grep "AIza"` ne retourne rien
- [ ] Ancienne clé API révoquée sur Google Cloud
- [ ] Nouvelle clé générée et dans `.env`
- [ ] Documentation mise à jour

## 🆘 En cas de fuite de clé API

Si vous avez accidentellement poussé une clé sur GitHub :

1. **IMMÉDIATEMENT** : Révoquer la clé sur Google Cloud Console
2. Générer une nouvelle clé
3. Nettoyer l'historique Git (voir Étape 2 ci-dessus)
4. Force push (si possible) : `git push --force`
5. Notifier votre équipe

## 📚 Ressources

- [GitHub - Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Google Cloud - API Keys best practices](https://cloud.google.com/docs/authentication/api-keys)
- [git-filter-repo](https://github.com/newren/git-filter-repo)

---

✅ **Votre projet est maintenant sécurisé pour GitHub !**
