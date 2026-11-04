import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ai/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final userMessage = ChatMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final aiService = ref.read(aiServiceProvider);
      final reply = await aiService.ask(trimmed);

      final aiMessage = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
      return true;
    } catch (e) {
      final message = e is AiServiceException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> saveApiKey(String key) async {
    final aiService = ref.read(aiServiceProvider);
    await aiService.saveApiKey(key);
  }

  Future<String?> getApiKey() async {
    final aiService = ref.read(aiServiceProvider);
    return aiService.getApiKey();
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
