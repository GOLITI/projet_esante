import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/data/datasources/chatbot_service.dart';
import 'package:asthme_app/data/models/chat_message.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_event.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatbotService _chatbotService;

  ChatBloc({ChatbotService? chatbotService})
      : _chatbotService = chatbotService ?? ChatbotService(),
        super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatReset>(_onChatReset);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final welcomeMessages = await _chatbotService.getWelcomeMessages();
      emit(ChatLoaded(messages: welcomeMessages));
    } catch (e) {
      emit(ChatError('Erreur lors du démarrage du chat: $e'));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    final userMessage = ChatMessage.user(event.message);

    // Ajouter le message de l'utilisateur et un indicateur de chargement
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isSending: true,
    ));

    try {
      // Envoyer le message au service chatbot
      final responseText = await _chatbotService.sendMessage(event.message);
      final assistantMessage = ChatMessage.assistant(responseText);

      // Mettre à jour avec la réponse
      emit(ChatLoaded(
        messages: [...currentState.messages, userMessage, assistantMessage],
        isSending: false,
      ));
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur avec les détails
      print('Erreur chatbot: $e'); // Pour le debug
      
      // Nettoyer le message d'erreur
      String errorText = e.toString().replaceAll('Exception: ', '');
      
      final errorMessage = ChatMessage.assistant(
        '⚠️ $errorText\n\nVeuillez vérifier votre connexion ou réessayer plus tard.',
      );

      emit(ChatLoaded(
        messages: [...currentState.messages, userMessage, errorMessage],
        isSending: false,
      ));
    }
  }

  Future<void> _onChatReset(
    ChatReset event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    _chatbotService.resetChat();
    try {
      final welcomeMessages = await _chatbotService.getWelcomeMessages();
      emit(ChatLoaded(messages: welcomeMessages));
    } catch (e) {
      emit(ChatError('Erreur lors de la réinitialisation du chat: $e'));
    }
  }
}

