import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:asthme_app/core/constants/api_constants.dart';
import 'package:asthme_app/data/models/chat_message.dart';

class ChatbotService {
  late final GenerativeModel _model;
  ChatSession? _chat;

  ChatbotService() {
    _initializeModel();
  }

  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: ApiConstants.geminiModel,
        apiKey: ApiConstants.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.text(
          '''Vous êtes PULSAR, un assistant intelligent spécialisé dans la gestion de l'asthme.

Votre rôle est d'aider les utilisateurs à:
- Comprendre l'asthme et ses symptômes
- Gérer leurs crises d'asthme
- Reconnaître les déclencheurs potentiels
- Suivre leur traitement
- Répondre à leurs questions sur la santé respiratoire

Règles importantes:
1. Répondez toujours en français de manière claire et empathique
2. Donnez des informations fiables et basées sur la science médicale
3. En cas de crise grave, rappelez toujours de consulter un médecin d'urgence
4. Soyez encourageant et positif dans vos réponses
5. Si vous n'êtes pas sûr d'une information médicale, conseillez de consulter un professionnel de santé
6. Gardez vos réponses concises mais complètes

Vous n'êtes pas un remplacement pour un médecin, mais un assistant pour aider dans la gestion quotidienne de l'asthme.''',
        ),
      );

      _chat = _model.startChat();
      print('✅ Chatbot initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du modèle: $e');
      rethrow;
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      if (_chat == null) {
        _chat = _model.startChat();
      }

      print('📤 Envoi du message: $message');

      // Ajouter un timeout de 30 secondes
      final response = await _chat!.sendMessage(Content.text(message))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('La requête a pris trop de temps. Vérifiez votre connexion internet.');
            },
          );

      print('✅ Réponse reçue');

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Désolé, je n\'ai pas pu générer une réponse. Veuillez réessayer.';
      }

      return text;
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      throw Exception('La requête a expiré. Vérifiez votre connexion internet.');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      print('Type d\'erreur: ${e.runtimeType}');

      // Réinitialiser le chat en cas d'erreur
      _chat = _model.startChat();

      // Retourner un message d'erreur plus explicite
      if (e.toString().contains('API key')) {
        throw Exception('Problème avec la clé API. Vérifiez votre configuration.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Problème de connexion réseau. Vérifiez votre internet.');
      } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
        throw Exception('Quota d\'API dépassé. Réessayez plus tard.');
      } else {
        throw Exception('Erreur inattendue: ${e.toString()}');
      }
    }
  }

  void resetChat() {
    try {
      _chat = _model.startChat();
      print('✅ Chat réinitialisé');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation: $e');
    }
  }

  Future<List<ChatMessage>> getWelcomeMessages() async {
    return [
      ChatMessage.assistant(
        'Bonjour ! 👋 Je suis PULSAR, votre assistant intelligent pour la gestion de l\'asthme.\n\n'
        'Je suis là pour vous aider à :\n'
        '• Comprendre vos symptômes\n'
        '• Gérer vos crises\n'
        '• Identifier les déclencheurs\n'
        '• Répondre à vos questions\n\n'
        'Comment puis-je vous aider aujourd\'hui ?',
      ),
    ];
  }
}

