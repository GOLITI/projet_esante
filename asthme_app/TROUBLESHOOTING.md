# 🔧 Guide de dépannage - Chatbot PULSAR

## Problème: "Désolé, une erreur s'est produite"

### ✅ Corrections apportées

1. **Service chatbot amélioré** avec:
   - Meilleure gestion des erreurs
   - Logs de débogage dans la console
   - Réinitialisation automatique en cas d'erreur
   - Validation de la réponse

2. **Affichage des erreurs détaillées**
   - Le message d'erreur affiche maintenant les détails
   - Permet d'identifier rapidement le problème

### 🔍 Comment diagnostiquer

1. **Vérifier la console** après avoir envoyé un message
   - Cherchez les messages commençant par 📤, ✅ ou ❌
   - Les erreurs détaillées s'affichent dans la console

2. **Messages possibles**:
   - `✅ Chatbot initialisé avec succès` → Tout va bien
   - `📤 Envoi du message:` → Message en cours d'envoi
   - `✅ Réponse reçue` → Succès
   - `❌ Erreur lors de...` → Voir les détails qui suivent

### 🛠️ Solutions possibles

#### Si l'erreur mentionne "API Key"
- Vérifiez que la clé API est correcte dans `lib/core/constants/api_constants.dart`
- Vérifiez que la clé n'a pas expiré sur Google Cloud Console

#### Si l'erreur mentionne "Network" ou "Connection"
- Vérifiez votre connexion internet
- Vérifiez que l'API Gemini est accessible depuis votre réseau

#### Si l'erreur mentionne "Model not found"
- Le modèle `gemini-1.5-flash` est peut-être indisponible
- Essayez `gemini-pro` dans `api_constants.dart`

#### Si l'erreur mentionne "Rate limit" ou "Quota"
- Vous avez dépassé le quota gratuit de l'API
- Attendez quelques minutes ou vérifiez votre quota sur Google Cloud Console

### 📋 Checklist de vérification

- [ ] Connexion internet active
- [ ] Clé API correcte dans `api_constants.dart`
- [ ] Application relancée après modifications (`flutter run`)
- [ ] Console ouverte pour voir les logs
- [ ] Quota API non dépassé

### 🔄 Pour réinitialiser

1. Arrêtez l'application
2. Exécutez: `flutter clean`
3. Exécutez: `flutter pub get`
4. Relancez: `flutter run -d windows`

### 📞 Support

Si le problème persiste:
1. Copiez l'erreur complète de la console
2. Vérifiez la documentation Google AI: https://ai.google.dev/docs
3. Vérifiez que l'API Gemini est activée dans votre projet Google Cloud

### 🧪 Tester l'API manuellement

Pour tester si l'API fonctionne, vous pouvez utiliser le service de test:

```dart
import 'package:asthme_app/data/datasources/chatbot_test_service.dart';

// Dans votre code, ajoutez:
final testService = ChatbotTestService();
await testService.testConnection();
```

Cela affichera les détails de connexion dans la console.

