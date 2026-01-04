import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_event.dart';
import 'package:asthme_app/presentation/blocs/chat/chat_state.dart';
import 'package:asthme_app/presentation/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatBloc>().add(ChatMessageSent(message));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PULSAR Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatBloc>().add(ChatReset());
            },
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is ChatInitial) {
            return const Center(child: Text('Initialisation...'));
          }

          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C4DFF),
              ),
            );
          }

          if (state is ChatError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ChatBloc>().add(ChatStarted());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ChatLoaded) {
            return Column(
              children: [
                // Messages list
                Expanded(
                  child: state.messages.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun message',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return MessageBubble(message: message);
                          },
                        ),
                ),

                // Loading indicator when sending
                if (state.isSending)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF7C4DFF),
                          radius: 18,
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'En train d\'écrire...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Posez votre question...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                              enabled: !state.isSending,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE040FB),
                                Color(0xFF7C4DFF),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send),
                            color: Colors.white,
                            onPressed: state.isSending ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

