import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_real.dart';

// ==================== Entities ====================

class ChatMessage {
  final String id;
  final String role; // 'user', 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: const Uuid().v4(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';

  ChatMessage copyWith({String? content, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

// ==================== Chat State ====================

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ==================== Chat Notifier ====================

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  void addUserMessage(String content) {
    final userMsg = ChatMessage.user(content);
    final messages = List<ChatMessage>.from(state.messages)..add(userMsg);
    state = state.copyWith(messages: messages, isLoading: true);

    // Use real Kilo Gateway
    _streamRealResponse(content);
  }

  Future<void> _streamRealResponse(String userMessage) async {
    final gateway = KiloGatewayReal();

    // Build context for AI
    final systemContext = KiloGatewayReal.buildHealthContext(
      userName: 'Usuario',
      fitnessGoal: 'Mantener salud',
    );

    // Build message history
    final apiMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContext},
      ...state.messages.map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': userMessage},
    ];

    // Add empty assistant message for streaming
    final assistantMsg = ChatMessage.assistant('');
    final messagesWithAssistant = List<ChatMessage>.from(state.messages)
      ..add(assistantMsg);
    state = state.copyWith(messages: messagesWithAssistant);

    try {
      String fullContent = '';

      await for (final chunk in gateway.streamChat(messages: apiMessages)) {
        fullContent += chunk;
        final updatedMessages = List<ChatMessage>.from(state.messages);
        updatedMessages[updatedMessages.length - 1] = updatedMessages.last
            .copyWith(content: fullContent);
        state = state.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      // Fallback to simulated response if Kilo fails
      final fallback = _getFallbackResponse(userMessage);
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[updatedMessages.length - 1] = updatedMessages.last
          .copyWith(content: fallback);
      state = state.copyWith(messages: updatedMessages);
    }

    state = state.copyWith(isLoading: false);
  }

  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('hola') || lower.contains('buenos')) {
      return '¡Hola! Soy tu asistente de salud y bienestar. ¿En qué puedo ayudarte hoy? 💪';
    } else if (lower.contains('ejercicio') || lower.contains('entrenar')) {
      return '''Para tu entrenamiento de hoy te recomiendo:

🏋️ **Rutina de empuje (Push)**
1. Press de banca: 4x8-10
2. Press inclinado con mancuernas: 3x10-12
3. Aperturas: 3x12-15
4. Press militar: 4x8-10
5. Elevaciones laterales: 3x15-20
6. Extensión de tríceps: 3x12-15

Descanso entre series: 90-120 segundos''';
    } else if (lower.contains('comer') || lower.contains('nutrición')) {
      return '''🥗 **Plan nutricional sugerido**
- Desayuno: Avena con plátano y proteína (400 kcal)
- Almuerzo: Pollo con arroz y verduras (600 kcal)
- Cena: Salmón con batata y ensalada (500 kcal)

Macros: P: 150g | C: 250g | G: 70g''';
    }
    return 'Puedo ayudarte con ejercicios, nutrición, sueño y bienestar. ¿Qué te gustaría saber?';
  }

  Future<void> _simulateResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    String response;
    final lower = userMessage.toLowerCase();

    if (lower.contains('hola') || lower.contains('buenos')) {
      response =
          '¡Hola! Soy tu asistente de salud y bienestar. ¿En qué puedo ayudarte hoy? 💪';
    } else if (lower.contains('ejercicio') || lower.contains('entrenar')) {
      response = '''Para tu entrenamiento de hoy te recomiendo:

🏋️ **Rutina de empuje (Push)**
1. Press de banca: 4x8-10
2. Press inclinado con mancuernas: 3x10-12
3. Aperturas: 3x12-15
4. Press militar: 4x8-10
5. Elevaciones laterales: 3x15-20
6. Extensión de tríceps: 3x12-15

Descanso entre series: 90-120 segundos
¡Recuerda calentar bien antes de empezar! 🔥''';
    } else if (lower.contains('comer') ||
        lower.contains('comida') ||
        lower.contains('nutrición')) {
      response = '''Basado en tus objetivos, te recomiendo:

🥗 **Plan nutricional de hoy**
- **Desayuno**: Avena con plátano y proteína (400 kcal)
- **Almuerzo**: Pollo con arroz y verduras (600 kcal)
- **Merienda**: Yogur griego con frutos secos (200 kcal)
- **Cena**: Salmón con batata y ensalada (500 kcal)

**Macros objetivo**: P: 150g | C: 250g | G: 70g

¿Quieres que ajuste algo según tus preferencias? 🍽️''';
    } else if (lower.contains('dormir') || lower.contains('sueño')) {
      response = '''El sueño es fundamental para tu recuperación. Te recomiendo:

😴 **Higiene del sueño**
1. Dormir 7-9 horas por noche
2. Acostarte y despertar a la misma hora
3. Evitar pantallas 1 hora antes de dormir
4. Habitación fresca (18-20°C) y oscura
5. No cafeína después de las 14:00

Tu promedio actual es de 7.3 horas. ¡Vas bien! 💤''';
    } else if (lower.contains('peso') ||
        lower.contains('bajar') ||
        lower.contains('adelgazar')) {
      response = '''Para perder peso de forma saludable:

⚖️ **Recomendaciones**
1. **Déficit calórico**: 300-500 kcal diarias
2. **Proteína alta**: 2g por kg de peso corporal
3. **Entrenamiento de fuerza**: 3-4 veces por semana
4. **Cardio moderado**: 2-3 sesiones de 30 min
5. **Pasos diarios**: Mínimo 8,000

Tu TDEE estimado es ~2,400 kcal. Objetivo: 1,900-2,100 kcal.

¿Quieres que te prepare un plan más detallado? 📊''';
    } else if (lower.contains('gracias')) {
      response =
          '¡De nada! Estoy aquí para ayudarte en tu camino hacia una vida más saludable. ¿Necesitas algo más? 😊';
    } else {
      response =
          '''Entiendo tu consulta. Como tu asistente de salud personalizado, puedo ayudarte con:

💪 **Ejercicios y rutinas**
🥗 **Nutrición y alimentación**
😴 **Sueño y recuperación**
📊 **Análisis de tus métricas**
🎯 **Planificación de objetivos**

¿Sobre qué te gustaría que profundicemos?''';
    }

    // Simulate streaming effect
    final assistantMsg = ChatMessage.assistant('');
    final messages = List<ChatMessage>.from(state.messages)..add(assistantMsg);
    state = state.copyWith(messages: messages);

    // Stream characters
    String currentContent = '';
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      currentContent += response[i];
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[updatedMessages.length - 1] = updatedMessages.last
          .copyWith(content: currentContent);
      state = state.copyWith(messages: updatedMessages);
    }

    state = state.copyWith(isLoading: false);
  }

  void clearChat() {
    state = const ChatState();
  }
}

// ==================== Providers ====================

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

// ==================== Screen ====================

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).addUserMessage(text);
    _controller.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Asistente IA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
          ),

          // Loading indicator
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pensando...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Quick suggestions
          if (chatState.messages.isEmpty)
            _QuickSuggestions(
              onSuggestion: (text) {
                _controller.text = text;
                _sendMessage();
              },
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText:
                          'Pregunta sobre salud, ejercicios, nutrición...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: chatState.isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Asistente de Salud IA',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pregúntame sobre ejercicios, nutrición, sueño, o cualquier tema de salud y bienestar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Widgets ====================

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  final Function(String) onSuggestion;

  const _QuickSuggestions({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      '¿Qué ejercicio me recomiendas hoy?',
      '¿Qué debería comer después de entrenar?',
      '¿Cómo puedo mejorar mi sueño?',
      'Dame una rutina de piernas',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion, style: const TextStyle(fontSize: 12)),
            onPressed: () => onSuggestion(suggestion),
          );
        }).toList(),
      ),
    );
  }
}
