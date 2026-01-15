# Chatbot PULSAR - Guide d'utilisation

## Implémentation réussie ✅

Le chatbot PULSAR a été implémenté avec succès dans votre application de gestion de l'asthme.

## Fonctionnalités

✨ **Assistant intelligent spécialisé en asthme**
- Répond aux questions sur l'asthme et ses symptômes
- Aide à gérer les crises d'asthme
- Identifie les déclencheurs potentiels
- Donne des conseils sur le traitement

🤖 **Technologie utilisée**
- Google Generative AI (Gemini 1.5 Flash)
- Architecture BLoC pour la gestion d'état
- Interface utilisateur moderne et intuitive

## Structure du code

```
lib/
├── core/
│   └── constants/
│       └── api_constants.dart          # Configuration API
├── data/
│   ├── datasources/
│   │   └── chatbot_service.dart        # Service chatbot
│   └── models/
│       └── chat_message.dart           # Modèle de message
└── presentation/
    ├── blocs/
    │   └── chat/
    │       ├── chat_bloc.dart          # Logique du chatbot
    │       ├── chat_event.dart         # Événements
    │       └── chat_state.dart         # États
    ├── screens/
    │   └── chat_screen.dart            # Écran du chatbot
    └── widgets/
        └── message_bubble.dart         # Widget de message
```

## Comment utiliser

1. **Accéder au chatbot** : Cliquez sur le bouton flottant "Chatbot" dans le dashboard (après connexion)

2. **Poser des questions** : Tapez votre question dans le champ de texte en bas de l'écran

3. **Recevoir des réponses** : PULSAR répondra de manière empathique et informative

4. **Nouvelle conversation** : Cliquez sur l'icône de rafraîchissement en haut à droite

## Exemples de questions

- "Quels sont les symptômes de l'asthme ?"
- "Comment gérer une crise d'asthme ?"
- "Quels sont les déclencheurs courants ?"
- "Que faire en cas de crise grave ?"
- "Comment utiliser mon inhalateur ?"

## Sécurité

⚠️ **Important** : Le chatbot est un assistant et ne remplace pas un médecin. En cas de crise grave, consultez immédiatement un professionnel de santé.

## Configuration API

La clé API Google Generative AI est configurée dans `lib/core/constants/api_constants.dart`

```dart
static const String geminiApiKey = 'AIzaSyD51lfcCRa_uv8pGBbs2Y6LPVQyPn7Cr0o';
static const String geminiModel = 'gemini-1.5-flash';
```

## Prochaines étapes

- [ ] Connexion à la base de données pour personnaliser les réponses
- [ ] Historique des conversations
- [ ] Suggestions de questions fréquentes
- [ ] Mode vocal pour les questions
- [ ] Alertes intelligentes basées sur les conversations

## Support

Pour toute question ou problème, consultez la documentation de Google Generative AI :
https://ai.google.dev/docs

