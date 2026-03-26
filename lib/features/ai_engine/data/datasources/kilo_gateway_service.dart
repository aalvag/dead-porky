import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kilo AI Gateway Service
///
/// Provides unified access to hundreds of AI models through Kilo's
/// OpenAI-compatible gateway at https://api.kilo.ai/api/gateway
///
/// Supports streaming, tool calling, and smart model routing.
class KiloGatewayService {
  static const String _baseUrl = 'https://api.kilo.ai/api/gateway';

  late final Dio _dio;
  final String _apiKey;

  KiloGatewayService({String? apiKey})
    : _apiKey = apiKey ?? dotenv.env['KILO_API_KEY'] ?? '' {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false, // Don't log streaming responses
        logPrint: (msg) => print('[KiloGateway] $msg'),
      ),
    );
  }

  // ==================== Chat Completions ====================

  /// Send a chat completion request (non-streaming)
  ///
  /// [model] - Model ID (e.g., 'kilo/auto', 'anthropic/claude-sonnet-4.5', 'openai/gpt-5.2')
  /// [messages] - Conversation history
  /// [maxTokens] - Maximum tokens to generate
  /// [temperature] - Creativity (0.0 - 2.0)
  /// [tools] - Available tools/functions for the model
  Future<ChatCompletionResponse> chat({
    required List<ChatMessage> messages,
    String model = 'kilo/auto',
    int maxTokens = 2048,
    double temperature = 0.7,
    List<Tool>? tools,
    String? toolChoice,
  }) async {
    final body = {
      'model': model,
      'messages': messages.map((m) => m.toMap()).toList(),
      'max_tokens': maxTokens,
      'temperature': temperature,
      if (tools != null) 'tools': tools.map((t) => t.toMap()).toList(),
      if (toolChoice != null) 'tool_choice': toolChoice,
    };

    final response = await _dio.post('/chat/completions', data: body);
    return ChatCompletionResponse.fromMap(response.data);
  }

  /// Stream chat completion tokens as they arrive
  ///
  /// Returns a stream of text chunks that can be concatenated
  /// to form the complete response.
  Stream<String> streamChat({
    required List<ChatMessage> messages,
    String model = 'kilo/auto',
    int maxTokens = 2048,
    double temperature = 0.7,
    List<Tool>? tools,
  }) async* {
    final body = {
      'model': model,
      'messages': messages.map((m) => m.toMap()).toList(),
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': true,
      if (tools != null) 'tools': tools.map((t) => t.toMap()).toList(),
    };

    final response = await _dio.post<ResponseBody>(
      '/chat/completions',
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null) yield content;
          }
        } catch (e) {
          // Skip malformed chunks
          continue;
        }
      }
    }
  }

  // ==================== Health-Specific Methods ====================

  /// Analyze user's health data and provide personalized insights
  Future<String> analyzeHealthData({
    required Map<String, dynamic> userData,
    required String question,
    String model = 'kilo/auto',
  }) async {
    final systemPrompt = _buildHealthSystemPrompt(userData);

    final response = await chat(
      model: model,
      messages: [ChatMessage.system(systemPrompt), ChatMessage.user(question)],
      maxTokens: 1500,
      temperature: 0.3, // Lower temp for factual health advice
    );

    return response.content;
  }

  /// Generate personalized workout recommendations
  Future<String> generateWorkoutRecommendation({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> recentWorkouts,
    required List<String> availableEquipment,
    String model = 'kilo/auto',
  }) async {
    final prompt =
        '''
Basado en el perfil del usuario y sus entrenamientos recientes, genera una recomendación de entrenamiento personalizada.

PERFIL:
${jsonEncode(userProfile)}

ENTRENAMIENTOS RECIENTES:
${jsonEncode(recentWorkouts)}

EQUIPAMIENTO DISPONIBLE:
${availableEquipment.join(', ')}

Genera una rutina con ejercicios, series, repeticiones y descansos. Considera:
- Volumen semanal adecuado por grupo muscular
- Progresión respecto a entrenamientos anteriores
- Tiempo de recuperación
- Objetivos del usuario
''';

    final response = await chat(
      model: model,
      messages: [ChatMessage.user(prompt)],
      maxTokens: 2000,
      temperature: 0.5,
    );

    return response.content;
  }

  /// Analyze nutrition from meal description or photo analysis
  Future<NutritionAnalysis> analyzeNutrition({
    required String mealDescription,
    Map<String, dynamic>? userProfile,
    String model = 'kilo/auto',
  }) async {
    final prompt =
        '''
Analiza la siguiente comida y estima sus macronutrientes:

COMIDA: $mealDescription

${userProfile != null ? 'PERFIL DEL USUARIO: ${jsonEncode(userProfile)}' : ''}

Responde SOLO en formato JSON:
{
  "name": "nombre del plato",
  "calories": número,
  "protein": gramos,
  "carbs": gramos,
  "fat": gramos,
  "fiber": gramos,
  "confidence": 0.0-1.0,
  "notes": "observaciones nutricionales"
}
''';

    final response = await chat(
      model: model,
      messages: [ChatMessage.user(prompt)],
      maxTokens: 500,
      temperature: 0.2,
    );

    try {
      final json = jsonDecode(response.content) as Map<String, dynamic>;
      return NutritionAnalysis.fromMap(json);
    } catch (e) {
      return NutritionAnalysis(
        name: mealDescription,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        confidence: 0,
        notes: 'No se pudo analizar automáticamente',
      );
    }
  }

  /// Generate weekly health report
  Future<String> generateWeeklyReport({
    required Map<String, dynamic> weeklyData,
    String model = 'kilo/auto',
  }) async {
    final prompt =
        '''
Genera un reporte semanal de salud y bienestar basado en estos datos:

${jsonEncode(weeklyData)}

El reporte debe incluir:
1. Resumen de logros
2. Áreas de mejora
3. Recomendaciones específicas para la próxima semana
4. Comparativa con la semana anterior
5. Predicciones de progreso

Sé conciso, motivador y accionable.
''';

    final response = await chat(
      model: model,
      messages: [ChatMessage.user(prompt)],
      maxTokens: 2000,
      temperature: 0.4,
    );

    return response.content;
  }

  // ==================== Private Helpers ====================

  String _buildHealthSystemPrompt(Map<String, dynamic> userData) {
    return '''
Eres un asistente de salud y fitness personalizado dentro de la app Dead Porky.
Tu rol es analizar datos del usuario y proporcionar recomendaciones personalizadas.

DATOS DEL USUARIO:
${jsonEncode(userData)}

INSTRUCCIONES:
- Responde en español
- Sé conciso y directo (máximo 3 párrafos)
- Usa datos concretos del usuario para personalizar respuestas
- Si detectas anomalías en métricas de salud, alerta al usuario
- Recomienda consultar un profesional para temas médicos serios
- Sé motivador pero realista
- Usa emojis ocasionalmente para hacer las respuestas más amigables
''';
  }
}

// ==================== Data Models ====================

class ChatMessage {
  final String role; // 'system', 'user', 'assistant', 'tool'
  final String content;
  final String? toolCallId;
  final List<ToolCall>? toolCalls;

  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.toolCalls,
  });

  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);
  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);
  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);
  factory ChatMessage.tool(String content, {required String toolCallId}) =>
      ChatMessage(role: 'tool', content: content, toolCallId: toolCallId);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'role': role, 'content': content};
    if (toolCallId != null) map['tool_call_id'] = toolCallId;
    if (toolCalls != null) {
      map['tool_calls'] = toolCalls!.map((tc) => tc.toMap()).toList();
    }
    return map;
  }
}

class ChatCompletionResponse {
  final String id;
  final String model;
  final String content;
  final int promptTokens;
  final int completionTokens;
  final List<ToolCall>? toolCalls;
  final String? finishReason;

  const ChatCompletionResponse({
    required this.id,
    required this.model,
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    this.toolCalls,
    this.finishReason,
  });

  factory ChatCompletionResponse.fromMap(Map<String, dynamic> map) {
    final choices = map['choices'] as List;
    final choice = choices[0] as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final usage = map['usage'] as Map<String, dynamic>?;

    return ChatCompletionResponse(
      id: map['id'] as String? ?? '',
      model: map['model'] as String? ?? '',
      content: message['content'] as String? ?? '',
      promptTokens: usage?['prompt_tokens'] as int? ?? 0,
      completionTokens: usage?['completion_tokens'] as int? ?? 0,
      toolCalls: (message['tool_calls'] as List?)
          ?.map((tc) => ToolCall.fromMap(tc as Map<String, dynamic>))
          .toList(),
      finishReason: choice['finish_reason'] as String?,
    );
  }
}

class Tool {
  final String type;
  final ToolFunction function;

  const Tool({this.type = 'function', required this.function});

  Map<String, dynamic> toMap() => {'type': type, 'function': function.toMap()};
}

class ToolFunction {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const ToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

class ToolCall {
  final String id;
  final String type;
  final String name;
  final String arguments;

  const ToolCall({
    required this.id,
    required this.type,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromMap(Map<String, dynamic> map) {
    final function = map['function'] as Map<String, dynamic>;
    return ToolCall(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'function',
      name: function['name'] as String? ?? '',
      arguments: function['arguments'] as String? ?? '{}',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'function': {'name': name, 'arguments': arguments},
  };
}

class NutritionAnalysis {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double confidence;
  final String notes;

  const NutritionAnalysis({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.confidence,
    required this.notes,
  });

  factory NutritionAnalysis.fromMap(Map<String, dynamic> map) {
    return NutritionAnalysis(
      name: map['name'] as String? ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'confidence': confidence,
    'notes': notes,
  };
}
