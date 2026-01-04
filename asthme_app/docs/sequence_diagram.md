 # Diagrammes de Séquence - E-Santé 4.0 (MVP - 1 mois)

## Vue d'ensemble
Ce document présente les 2 diagrammes de séquence essentiels pour le MVP : Connexion et Évaluation du risque d'asthme. Focus sur les interactions critiques sans complexité inutile.

---

## 1. Séquence : Connexion Simple

Processus de connexion basique avec validation locale ou Firebase.

```mermaid
sequenceDiagram
    actor User as 👤 Utilisateur
    participant UI as LoginScreen
    participant Bloc as AuthBloc
    participant Repo as AuthRepository
    participant DB as SQLite Database

    User->>UI: Saisit email + password
    User->>UI: Clique "Se connecter"
    
    UI->>Bloc: LoginEvent(email, password)
    activate Bloc
    
    Bloc->>Bloc: emit(AuthLoading)
    Bloc->>UI: AuthLoading
    UI->>UI: Affiche spinner
    
    Bloc->>Repo: login(email, password)
    activate Repo
    
    Repo->>DB: SELECT * WHERE email=?
    activate DB
    
    alt Utilisateur trouvé et mot de passe correct
        DB-->>Repo: UserRow
        deactivate DB
        
        Repo->>Repo: Vérifier mot de passe
        Repo-->>Bloc: User
        deactivate Repo
        
        Bloc->>Bloc: emit(Authenticated(user))
        Bloc-->>UI: Authenticated(user)
        deactivate Bloc
        
        UI->>UI: Navigate to HomeScreen
        UI->>User: ✅ Bienvenue {nom}
        
    else Échec authentification
        DB-->>Repo: null ou password incorrect
        deactivate DB
        Repo-->>Bloc: AuthException
        deactivate Repo
        
        Bloc->>Bloc: emit(AuthError("Email ou mot de passe incorrect"))
        Bloc-->>UI: AuthError
        deactivate Bloc
        
        UI->>User: ❌ Identifiants incorrects
    end
```

### Points clés :
- **Stockage local SQLite** : Pas de serveur d'authentification externe (MVP)
- **BLoC Pattern** : Gestion d'état simple
- **Validation basique** : Email format + password hash
- **3 états** : Loading → Authenticated/Error

---

## 2. Séquence : Évaluation Risque Asthme (Flux complet)

Processus complet de l'évaluation en 4 étapes avec prédiction ML.

```mermaid
sequenceDiagram
    actor User as 👤 Utilisateur
    participant UI as AssessmentScreen
    participant Bloc as AssessmentBloc
    participant Repo as AssessmentRepository
    participant API as ML API (Flask)
    participant DB as SQLite

    %% DÉMARRAGE
    User->>UI: Clique "Nouveau test"
    UI->>Bloc: StartAssessmentEvent
    activate Bloc
    
    Bloc->>Repo: createAssessment(userId)
    Repo-->>Bloc: Assessment (vide)
    
    Bloc->>Bloc: emit(AssessmentStep1)
    Bloc-->>UI: Étape 1 - Profil
    deactivate Bloc
    
    %% ÉTAPE 1: PROFIL
    Note over User,UI: --- Étape 1: Profil (Âge, Sexe, IMC) ---
    User->>UI: Saisit âge=25, sexe=M, poids=70kg, taille=175cm
    UI->>UI: Calcule IMC = 22.9 (Normal)
    User->>UI: Clique "Suivant"
    
    UI->>Bloc: UpdateProfileEvent(data)
    activate Bloc
    Bloc->>Bloc: assessment.updateProfile(data)
    Bloc->>Bloc: emit(AssessmentStep2)
    Bloc-->>UI: Étape 2 - Antécédents
    deactivate Bloc
    
    %% ÉTAPE 2: ANTÉCÉDENTS
    Note over User,UI: --- Étape 2: Antécédents Médicaux ---
    User->>UI: Asthme familial: Oui
    User->>UI: Allergies: Oui
    User->>UI: Clique "Suivant"
    
    UI->>Bloc: UpdateMedicalHistoryEvent(data)
    activate Bloc
    Bloc->>Bloc: assessment.updateMedicalHistory(data)
    Bloc->>Bloc: emit(AssessmentStep3)
    Bloc-->>UI: Étape 3 - Environnement
    deactivate Bloc
    
    %% ÉTAPE 3: ENVIRONNEMENT
    Note over User,UI: --- Étape 3: Environnement ---
    User->>UI: Tabagisme: 2 (Exposition passive)
    User->>UI: Pollution: 2 (Élevée)
    User->>UI: Clique "Suivant"
    
    UI->>Bloc: UpdateEnvironmentEvent(data)
    activate Bloc
    Bloc->>Bloc: assessment.updateEnvironment(data)
    Bloc->>Bloc: emit(AssessmentStep4)
    Bloc-->>UI: Étape 4 - Symptômes
    deactivate Bloc
    
    %% ÉTAPE 4: SYMPTÔMES
    Note over User,UI: --- Étape 4: Symptômes (0-3) ---
    User->>UI: Toux: 2, Essoufflement: 1, Sifflements: 2
    User->>UI: Clique "Voir résultat"
    
    UI->>Bloc: SubmitAssessmentEvent(assessment)
    activate Bloc
    
    Bloc->>Bloc: emit(PredictionLoading)
    Bloc-->>UI: PredictionLoading
    UI->>UI: Affiche animation
    
    %% SAUVEGARDE LOCALE
    Bloc->>Repo: saveAssessment(assessment)
    activate Repo
    Repo->>DB: INSERT assessment
    DB-->>Repo: Success
    deactivate Repo
    
    %% PRÉDICTION ML
    Bloc->>API: POST /predict {assessment data}
    activate API
    
    Note right of API: Backend Flask<br/>asthme-ia/main.py<br/>Random Forest Model
    
    alt Prédiction réussie
        API->>API: Preprocessing
        API->>API: Prédiction RF
        API->>API: Génération recommandations
        API-->>Bloc: {riskLevel: 2, recommendations: [...]}
        deactivate API
        
        Bloc->>Repo: savePredictionResult(result)
        activate Repo
        Repo->>DB: INSERT result
        DB-->>Repo: Success
        deactivate Repo
        
        Bloc->>Bloc: emit(AssessmentCompleted(result))
        Bloc-->>UI: AssessmentCompleted
        deactivate Bloc
        
        UI->>UI: Navigate to ResultScreen
        UI->>UI: Affiche jauge risque
        UI->>User: 🎯 Risque MODÉRÉ (niveau 2/3)
        Note over User,UI: - Consulter un médecin<br/>- Éviter la fumée<br/>- Surveiller les symptômes
        
    else Erreur API
        API-->>Bloc: Error 500
        deactivate API
        
        Bloc->>Bloc: emit(AssessmentError("Erreur serveur"))
        Bloc-->>UI: AssessmentError
        deactivate Bloc
        
        UI->>User: ❌ Impossible de prédire<br/>Réessayer plus tard
    end
```

### Points clés :
- **4 étapes simples** : Profil → Antécédents → Environnement → Symptômes
- **Calcul IMC automatique** : Feedback immédiat
- **Sauvegarde progressive** : Données en local avant prédiction
- **API Flask** : Utilise le backend ML existant
- **Gestion erreur** : Affichage message si API indisponible
- **Résultat clair** : Niveau 0-3 + 3 recommandations

---

## Ce qui est EXCLU du MVP

❌ Diagrammes retirés (trop complexes pour 1 mois) :
- Inscription avec validation email
- Réinitialisation mot de passe
- Recherche centres de santé avec géolocalisation
- Notifications push
- Synchronisation cloud
- Mode offline avancé
- Export PDF
- Partage résultats
- Suivi symptômes quotidiens
- Gestion médicaments

---

## États et transitions simplifiés

### AuthBloc
```
Initial → Loading → Authenticated / AuthError
```

### AssessmentBloc
```
Initial → Step1 → Step2 → Step3 → Step4 → PredictionLoading → Completed / Error
```

---

**Version MVP** : 1.0  
**Complexité** : ⭐⭐ (Simplifiée)  
**Durée** : 1 mois```mermaid
sequenceDiagram
    actor User as 👤 Utilisateur
    participant UI as AssessmentScreen
    participant Bloc as AssessmentBloc
    participant CreateUC as CreateAssessmentUseCase
    participant SaveUC as SaveAssessmentUseCase
    participant PredictUC as PredictRiskUseCase
    participant AssRepo as AssessmentRepository
    participant PredRepo as PredictionRepository
    participant API as PredictionApi
    participant LocalDB as LocalStorage
    participant MLServer as 🤖 ML Backend

    %% ÉTAPE 1: Démarrage évaluation
    User->>UI: Clique "Nouveau test"
    UI->>Bloc: add(AssessmentStarted)
    activate Bloc
    
    Bloc->>CreateUC: execute()
    activate CreateUC
    CreateUC->>AssRepo: createAssessment()
    AssRepo-->>CreateUC: Right(Assessment)
    CreateUC-->>Bloc: Right(Assessment)
    deactivate CreateUC
    
    Bloc->>Bloc: emit(AssessmentInProgress(step: 1))
    Bloc->>UI: AssessmentInProgress state
    deactivate Bloc
    UI->>User: Affiche formulaire Étape 1 (Profil)
    
    %% ÉTAPE 2: Remplissage Profil
    Note over User,UI: --- Étape 1: Profil Personnel ---
    User->>UI: Saisit âge, sexe, poids, taille, ville
    UI->>UI: Calcule IMC automatiquement
    UI->>User: Affiche IMC: 24.5 (Normal)
    
    User->>UI: Clique "Suivant"
    UI->>Bloc: add(ProfileDataUpdated(profileData))
    activate Bloc
    Bloc->>Bloc: assessment.profileData = profileData
    Bloc->>Bloc: emit(AssessmentInProgress(step: 2))
    Bloc->>UI: État mis à jour
    deactivate Bloc
    UI->>User: Affiche Étape 2 (Antécédents)
    
    %% ÉTAPE 3: Antécédents médicaux
    Note over User,UI: --- Étape 2: Antécédents Médicaux ---
    User->>UI: Répond questions (famille, allergies, infections)
    User->>UI: Clique "Suivant"
    UI->>Bloc: add(MedicalHistoryUpdated(history))
    activate Bloc
    Bloc->>Bloc: assessment.medicalHistory = history
    Bloc->>Bloc: emit(AssessmentInProgress(step: 3))
    Bloc->>UI: État mis à jour
    deactivate Bloc
    UI->>User: Affiche Étape 3 (Environnement)
    
    %% ÉTAPE 4: Environnement
    Note over User,UI: --- Étape 3: Environnement ---
    User->>UI: Répond questions (tabac, fumée, pollution)
    User->>UI: Clique "Suivant"

---

**Version MVP** : 1.0  
**Complexité** : ⭐⭐ (Simplifiée)  
**Durée** : 1 mois    Note right of FCM: type: "sync_required"<br/>entity: "assessment"<br/>id: "abc123"
    
    FCM->>Tablet: Silent push notification
    deactivate FCM
    
    Server-->>Phone: 201 Created
    deactivate Server
    
    Phone->>User: ✅ "Test sauvegardé"
    
    %% ÉTAPE 2: Synchronisation tablette
    Note over Tablet: App en arrière-plan
    
    Tablet->>Tablet: Receive silent push
    Tablet->>Tablet: onBackgroundMessage()
    
    Tablet->>Server: GET /api/v1/assessments/abc123
    activate Server
    Server->>DB: SELECT assessment WHERE id = abc123
    DB-->>Server: Assessment data
    Server-->>Tablet: 200 OK + Assessment
    deactivate Server
    
    Tablet->>Tablet: Save to local DB
    Tablet->>Tablet: Update UI (if app open)
    
    %% ÉTAPE 3: Ouverture app tablette
    Note over User,Tablet: Plus tard...
    
    User->>Tablet: Ouvre app sur tablette
    Tablet->>Tablet: Check local data version
    
    Tablet->>Server: GET /api/v1/sync/status?last_sync=2025-12-23T08:00:00Z
    activate Server
    Server->>DB: Check updates since last_sync
    activate DB
    DB-->>Server: 1 new assessment, 2 updated articles
    deactivate DB
    Server-->>Tablet: SyncStatus(pending: 3)
    deactivate Server
    
    alt Synchronisation nécessaire
        Tablet->>User: 🔄 Banner "Synchronisation..."
        
        Tablet->>Server: GET /api/v1/sync/pull?since=2025-12-23T08:00:00Z
        activate Server
        Server->>DB: Fetch all changes
        DB-->>Server: Changes bundle
        Server-->>Tablet: 200 OK + Data bundle
        deactivate Server
        
        Tablet->>Tablet: Merge with local DB
        Tablet->>Tablet: Resolve conflicts (server wins)
        Tablet->>Tablet: Update last_sync timestamp
        
        Tablet->>User: ✅ "Synchronisé"
        Tablet->>User: Affiche données à jour
        
    else Déjà à jour
        Tablet->>User: Affiche données existantes
    end
    
    %% ÉTAPE 4: Conflit (édition simultanée)
    Note over Phone,Tablet: Scénario: Édition profil simultanée
    
    User->>Phone: Modifie ville → "Bouaké"
    User->>Tablet: Modifie ville → "Yamoussoukro"
    
    par Envoi simultané
        Phone->>Server: PATCH /users/me {city: "Bouaké"}
        activate Server
        Server->>DB: UPDATE users SET city='Bouaké', version=2
        Server-->>Phone: 200 OK (version: 2)
        deactivate Server
    and
        Tablet->>Server: PATCH /users/me {city: "Yamoussoukro"}
        activate Server
        Server->>Server: Detect version conflict
        Note right of Server: Request version: 1<br/>Current version: 2
        Server-->>Tablet: 409 Conflict
        deactivate Server
    end
    
    Tablet->>Server: GET /users/me
    activate Server
    Server-->>Tablet: User data (city: "Bouaké", version: 2)
    deactivate Server
    
    Tablet->>User: ⚠️ "Conflit. Données mises à jour depuis autre appareil"
    Tablet->>User: Affiche ville: "Bouaké" (serveur gagne)
    Note over User: Stratégie: Last-Write-Wins<br/>(serveur fait foi)
```

### Points clés :
- **Sync automatique** : Sauvegarde cloud après chaque action
- **Push silencieux** : Notification autres devices via FCM
- **Merge intelligent** : Résolution conflits (server wins)
- **Versioning** : Détection conflits simultanés
- **Sync incrémentale** : Seulement changements depuis last_sync
- **Offline-first** : Sauvegarde locale prioritaire
- **Feedback utilisateur** : Banner synchronisation + résolution conflits

---

## Récapitulatif des patterns utilisés

### Patterns architecturaux
1. **Clean Architecture** : Séparation Domain/Data/Presentation
2. **Repository Pattern** : Abstraction accès données
3. **BLoC Pattern** : State management avec Events/States
4. **Use Case Pattern** : Encapsulation logique métier

### Patterns de communication
1. **Request-Response** : API REST synchrone
2. **Push Notifications** : Firebase Cloud Messaging
3. **Polling** : Vérification qualité air périodique
4. **Event-Driven** : State changes déclenchent actions UI

### Patterns de données
1. **DTO** : Models ↔ Entities conversion
2. **Caching** : Cache-Aside pattern (check cache first)
3. **Optimistic Updates** : UI update immédiat + sync async
4. **Conflict Resolution** : Last-Write-Wins ou Server-Wins

### Patterns de resilience
1. **Fallback** : Modèle ML local si API indisponible
2. **Retry** : Tentatives automatiques erreurs réseau
3. **Circuit Breaker** : Désactivation API si trop d'échecs
4. **Graceful Degradation** : Fonctionnalités limitées offline

---

**Version** : 1.0  
**Date** : 23 décembre 2025  
**Outil** : Mermaid.js  
**Format** : Markdown
