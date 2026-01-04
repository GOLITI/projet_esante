import 'package:equatable/equatable.dart';
import 'package:asthme_app/data/models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object> get props => [messages, isSending];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

