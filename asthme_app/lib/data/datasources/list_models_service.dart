import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:asthme_app/core/constants/api_constants.dart';

/// Service pour lister les modèles Gemini disponibles
class ListModelsService {
  Future<void> listAvailableModels() async {
    try {
      print('🔍 Récupération de la liste des modèles disponibles...');
      print('API Key (premiers caractères): ${ApiConstants.geminiApiKey.substring(0, 10)}...');

      // Tester différents noms de modèles possibles
      final modelNames = [
        'gemini-pro',
        'models/gemini-pro',
        'gemini-1.0-pro',
        'models/gemini-1.0-pro',
        'gemini-1.5-pro',
        'models/gemini-1.5-pro',
        'gemini-1.5-flash',
        'models/gemini-1.5-flash',
      ];

      print('\n📋 Test de différents noms de modèles:\n');

      for (final modelName in modelNames) {
        try {
          print('Testing: $modelName');
          final model = GenerativeModel(
            model: modelName,
            apiKey: ApiConstants.geminiApiKey,
          );

          // Essayer d'envoyer un message simple
          final response = await model.generateContent([
            Content.text('Hello')
          ]).timeout(const Duration(seconds: 5));

          if (response.text != null) {
            print('✅ $modelName FONCTIONNE !');
            print('   Réponse: ${response.text?.substring(0, 50)}...\n');
            return; // Sortir dès qu'on trouve un modèle qui fonctionne
          }
        } catch (e) {
          print('❌ $modelName ne fonctionne pas');
          print('   Erreur: ${e.toString().substring(0, 100)}...\n');
        }
      }

      print('⚠️ Aucun modèle n\'a fonctionné. Vérifiez:');
      print('1. Votre clé API');
      print('2. Votre connexion internet');
      print('3. Les quotas de votre projet Google Cloud');

    } catch (e) {
      print('❌ Erreur générale: $e');
    }
  }
}

