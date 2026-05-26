import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kilo AI Gateway Service
///
/// Provides unified access to hundreds of AI models through Kilo's
/// OpenAI-compatible gateway at https://api.kilo.ai/api/gateway
///
/// Supports streaming, tool calling, and smart model routing.
class KiloGatewayService {
  static const String _defaultKiloBaseUrl = 'https://api.kilo.ai/api/gateway';
  static const String _defaultGeminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  late final Dio _dio;
  late final Dio _geminiDio;
  final String _apiKey;
  final String _geminiApiKey;
  final String _geminiVisionModel;

  KiloGatewayService({String? apiKey, String? geminiApiKey})
    : _apiKey = apiKey ?? dotenv.env['KILO_API_KEY'] ?? '',
      _geminiApiKey = geminiApiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
      _geminiVisionModel =
          dotenv.env['GEMINI_VISION_MODEL'] ?? 'gemini-2.5-flash' {
    final kiloBaseUrl = dotenv.env['KILO_GATEWAY_URL'] ?? _defaultKiloBaseUrl;
    final geminiBaseUrl =
        dotenv.env['GEMINI_API_BASE_URL'] ?? _defaultGeminiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: kiloBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey.trim().isNotEmpty) 'Authorization': 'Bearer $_apiKey',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    _geminiDio = Dio(
      BaseOptions(
        baseUrl: geminiBaseUrl,
        headers: const {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false, // Don't log streaming responses
        logPrint: (msg) => log('[KiloGateway] $msg'),
      ),
    );

    _geminiDio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (msg) => log('[GeminiVision] $msg'),
      ),
    );
  }

  // ==================== Public Methods ====================

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
      ...?(tools != null
          ? {'tools': tools.map((t) => t.toMap()).toList()}
          : null),
      ...?(toolChoice != null ? {'tool_choice': toolChoice} : null),
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

  /// Analyze nutrition from meal description
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
      final json = _decodeJsonPayload(response.content);
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

  /// Analyze nutrition from a meal photo using a multimodal model.
  ///
  /// maxOutputTokens is set to 2000.
  /// Uses print() for ALL debug logging (not log()).
  Future<NutritionAnalysis> analyzeMealPhoto({
    required List<int> imageBytes,
    String? mealContext,
    Map<String, dynamic>? userProfile,
    String model = '',
    String mimeType = 'image/jpeg',
  }) async {
    if (!_hasGeminiApiKey) {
      throw StateError('Falta configurar GEMINI_API_KEY en .env.');
    }

    final effectiveModel = model.trim().isNotEmpty
        ? model.trim()
        : _geminiVisionModel;
    final resolvedMimeType = _normalizeImageMimeType(mimeType);
    final encodedImage = base64Encode(imageBytes);
    // Short, tight prompt to avoid Gemini thinking/reflection output
    final prompt = mealContext != null && mealContext.trim().isNotEmpty
        ? 'Analyze this food photo for: ${mealContext.trim()}. Return ONLY JSON: {"name":"dish","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"confidence":0.9,"notes":"observation"}'
        : 'Analyze this food photo. Return ONLY JSON: {"name":"dish","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"confidence":0.9,"notes":"observation"}';

    try {
      final response = await _geminiDio.post(
        '/models/$effectiveModel:generateContent',
        queryParameters: {'key': _geminiApiKey.trim()},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': resolvedMimeType,
                    'data': encodedImage,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 2000,
                'responseMimeType': 'application/json',
                'responseModalities': ['TEXT'],
              },
        },
      );

      print('[GeminiVision] Full response keys: '
          '${(response.data as Map<String, dynamic>).keys.join(", ")}');
      print('[GeminiVision] Full response data: ${response.data}');

      final content = _extractGeminiContent(
        response.data as Map<String, dynamic>,
      );
      final contentPreview = content.length > 500
          ? '${content.substring(0, 500)}... [TRUNCATED]'
          : content;
      print('[GeminiVision] Extracted content (first 500): $contentPreview');
      final json = _decodeJsonPayload(content);
      return NutritionAnalysis.fromMap(json);
    } on DioException catch (error) {
      if (_isQuotaExhausted(error)) {
        throw Exception(
          'Gemini alcanzó el límite de uso gratuito. '
          'Intenta de nuevo en unos minutos.',
        );
      }
      throw Exception(_describeGeminiError(error));
    } on FormatException catch (error) {
      print('[GeminiVision] FormatException: ${error.message}');
      throw Exception(
        'Gemini devolvió una respuesta con formato inválido. '
        'El modelo no generó JSON válido. Error: ${error.message}',
      );
    } catch (error) {
      print('[GeminiVision] Unexpected error: $error');
      throw Exception('Error inesperado al analizar la imagen: $error');
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

  /// Debug helper for safe logging
  String _truncateForLog(String text) {
    const limit = 300;
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}... [TRUNCATED ${text.length - limit} chars]';
  }

  /// Attempts to repair a JSON truncated by MAX_TOKENS by detecting
  /// the last unclosed value/array and appending the missing closure.
  String? _tryAppendClosingBrace(String text) {
    final trimmed = text.trim();
    // Already balanced?
    if (_isBalancedJson(trimmed)) return null;

    // Strategy: find the last unclosed string, object or array, and close it
    int openBraces = 0;
    int openBrackets = 0;
    bool inString = false;
    String? stringChar;
    int lastBalanced = -1;

    for (int i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (inString) {
        if (c == '\\') {
          i++; // skip escaped char
          continue;
        }
        if (c == stringChar) {
          inString = false;
          stringChar = null;
          lastBalanced = i;
        }
        continue;
      }
      if (c == '"' || c == "'") {
        inString = true;
        stringChar = c;
        continue;
      }
      if (c == '{') openBraces++;
      if (c == '}') openBraces--;
      if (c == '[') openBrackets++;
      if (c == ']') openBrackets--;
      if (openBraces == 0 && openBrackets == 0 && c == ',' && i + 1 < trimmed.length) {
        lastBalanced = i;
      }
    }

    if (openBraces > 0 || openBrackets > 0) {
      final sb = StringBuffer(trimmed);
      for (int i = 0; i < openBraces; i++) sb.write('}');
      for (int i = 0; i < openBrackets; i++) sb.write(']');
      return sb.toString();
    }

    return null;
  }

  bool _isBalancedJson(String text) {
    int depth = 0;
    bool inStr = false;
    String? strChar;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (inStr) {
        if (c == '\\') { i++; continue; }
        if (c == strChar) inStr = false;
        continue;
      }
      if (c == '"' || c == "'") { inStr = true; strChar = c; continue; }
      if (c == '{') depth++;
      if (c == '}') depth--;
    }
    return depth == 0;
  }

  String? _extractFinishReason(Map<String, dynamic> payload) {
    final candidates = payload['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) return null;
    return firstCandidate['finishReason'] as String?;
  }

  String _buildHealthSystemPrompt(Map<String, dynamic> userData) {
    return '''
Actúa como un Asistente Experto en Hipertrofia y Nutrición Deportiva Basada en Evidencia Científica, siguiendo estrictamente la metodología de Renaissance Periodization (RP). Tu objetivo es guiar al usuario para optimizar su composición corporal y maximizar el crecimiento muscular estético (énfasis en el V-Taper: pecho superior, lats para amplitud, deltoides laterales y brazos), controlando la fatiga sistémica.

DATOS DEL USUARIO:
${jsonEncode(userData)}

Analizarás tres tipos de entradas diarias:
1. Fotos o descripciones de comidas.
2. Registros de entrenamiento (ejercicios, series, peso, repeticiones y RIR/RPE).
3. Datos de peso corporal diario y composición corporal.

Sigue estos mandamientos inflexibles para formular tus respuestas:

### 🥩 1. MANDAMIENTOS DE NUTRICIÓN Y COMPOSICIÓN CORPORAL
- PROTEÍNA: Asegura que el usuario alcance aproximadamente 1 gramo de proteína por libra de peso corporal al día (o ~2.2g por kilo), distribuido uniformemente en 3 a 5 comidas para maximizar la síntesis proteica.
- BALANCE ENERGÉTICO: Si el objetivo es pérdida de grasa (especialmente en usuarios con sobrepeso), mantén un déficit calórico moderado. Si falta comida en el día pero ya se alcanzó el límite calórico, recomienda vegetales de alto volumen (brócoli, espinacas, zucchini) para saciar el hambre sin aportar calorías.
- MONITOREO DEL PESO: Evalúa el peso corporal diario basándote en la tendencia promedio semanal, no en las fluctuaciones diarias aisladas (evita reacciones emocionales a la retención de líquidos).
- SUPLEMENTACIÓN HONESTA: Solo valida la Creatina Monohidrato (5g/día), Proteína de Suero (Whey) para completar macros, y Cafeína como pre-entreno. Descalifica firmemente suplementos inútiles como BCAAs (pérdida de dinero si hay suficiente proteína) o Turkesterona (estafa).

### 🏋️‍♂️ 2. MANDAMIENTOS DE ENTRENAMIENTO Y FISIOLOGÍA
- TÉCNICA Y EJECUCIÓN: Exige siempre un rango de movimiento completo (ROM), control riguroso de la fase excéntrica (bajar el peso lento en 3 segundos) y un estiramiento profundo en elongación. 
- PARCIALES EN ELONGACIÓN: Cuando el usuario llegue al fallo en rango completo, promueve el uso de parciales en elongación (lengthened partials) para exprimir el estímulo hipertrófico.
- VOLUMEN Y RECUPERACIÓN: Rastrea el progreso desde el Volumen Mínimo Efectivo (MEV) hasta el Volumen Máximo Recuperable (MRV). Si el usuario reporta buena recuperación y bajo dolor articular, sugiere añadir 1-2 series al ejercicio para la próxima semana. Si reporta dolor articular crónico (ej. rodillas), ordena priorizar máquinas estables (Prensa, Atlantis, Prime) que ofrezcan una alta Relación Estímulo-Fatiga (SFR) y elimina pesos libres inestables.
- ESFUERZO REAL: Monitorea que las series de trabajo se mantengan estrictamente entre 3 y 0 Repeticiones en Reserva (RIR). Si el peso sube pero las repeticiones caen drásticamente fuera del rango de hipertrofia (5-30 reps), ajusta la carga. Recuerda que la fuerza a corto plazo está enmascarada por la fatiga; no asumas pérdida de músculo sin un bloque de descarga (deload).

### 🗣️ TONO Y FORMATO DE RESPUESTA
Tu tono debe ser directo, analítico, ligeramente sarcástico con las debilidades, pero sumamente motivador y enfocado en los datos. No uses rodeos ni lenguaje ambiguo. Al final de cada análisis diario, debes responder claramente:
1. "Qué te falta por comer hoy" (Gramos de proteína/carbohidratos/grasas restantes para cumplir el objetivo).
2. "Ajuste para tu próximo entrenamiento" (Modificaciones de carga, series o selección de ejercicios según su recuperación y dolor articular).
''';
  }

  bool get _hasGeminiApiKey {
    final key = _geminiApiKey.trim();
    return key.isNotEmpty && key != 'your_gemini_api_key_here';
  }

  // Methods called from inside analyzeMealPhoto() via _extractGeminiContent().
  // They are extracted from inside the method and placed here for clarity.

  /// Extracts the first usable text content from a Gemini API response payload.
  /// Handles MAX_TOKENS truncation by attempting brace repair, then falls back
  /// to extracting the first balanced JSON object.
  String _extractGeminiContent(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      throw Exception(error['message'] as String? ?? jsonEncode(error));
    }

    final candidates = payload['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini no devolvió candidatos.');
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      throw Exception('Gemini devolvió un candidato inválido.');
    }

    // Check finishReason early so MAX_TOKENS is caught before content extraction
    final finishReason = firstCandidate['finishReason'] as String?;
    if (finishReason == 'MAX_TOKENS') {
      print('[GeminiVision] finishReason=MAX_TOKENS — response truncated at first attempt');
    }

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      throw Exception('Gemini no devolvió contenido analizable.');
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini no devolvió partes de contenido.');
    }

    // Find first non-empty text part (skip thinking blocks)
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          print('[GeminiVision] Raw text from candidates (finishReason=$finishReason): ${_truncateForLog(text)}');

          // For MAX_TOKENS, attempt to repair by app closing brace
          if (finishReason == 'MAX_TOKENS') {
            final repaired = _tryAppendClosingBrace(text);
            if (repaired != null) {
              print('[GeminiVision] Repaired truncated MAX_TOKENS response');
              return repaired;
            }
          }

          // Find first balanced JSON block in case there is prose or extra chars
          final jsonMatch = _findFirstJsonObject(text);
          if (jsonMatch != null) {
            print('[GeminiVision] First JSON block found and extracted');
            return jsonMatch;
          }
          print('[GeminiVision] No JSON block found in candidates, returning raw');
          return text;
        }
      }
    }

    throw Exception('Gemini no devolvió texto utilizable.');
  }

  /// Checks if the error is a 429 quota exhaustion from Gemini.
  bool _isQuotaExhausted(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (statusCode != 429) return false;
    if (payload is Map<String, dynamic>) {
      final errorPayload = payload['error'];
      if (errorPayload is Map<String, dynamic>) {
        final status = errorPayload['status'] as String?;
        return status == 'RESOURCE_EXHAUSTED';
      }
    }
    // Also match by message text
    final message = error.message ?? '';
    return message.contains('429') || message.contains('RESOURCE_EXHAUSTED') || message.contains('quota');
  }

  /// Extracts a human-readable Gemini error message from a DioException.
  String _describeGeminiError(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;

    String? message;
    if (payload is Map<String, dynamic>) {
      final errorPayload = payload['error'];
      if (errorPayload is Map<String, dynamic>) {
        message = errorPayload['message'] as String?;
      }
    } else if (payload is String && payload.trim().isNotEmpty) {
      message = payload;
    }

    message ??= error.message;

    if (statusCode != null) {
      return 'Gemini $statusCode: $message';
    }

    return 'Gemini: $message';
  }

  /// Extracts the first complete JSON object from arbitrary text.
  /// Handles cases where Gemini returns prose + JSON, or returns
  /// truncated/corrupted output.
  String? _findFirstJsonObjectInRaw(String text) {
    final start = text.indexOf('{');
    if (start < 0) return null;

    int depth = 0;
    for (int i = start; i < text.length; i++) {
      final char = text[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  /// Attempts to repair JSON missing opening braces at the top level
  /// (e.g., bare key-value entries that should be wrapped in a new object).
  String? _tryRepairTopLevel(String text) {
    // Quick check: if text looks like it might be a partial object
    if (text.startsWith('"') || RegExp(r'^\w+\s*:').hasMatch(text)) {
      return '{$text}';
    }
    return null;
  }

  /// Extracts the first balanced JSON object from arbitrary text by scanning
  /// for the outermost balanced braces, starting from the first '{'.
  String? _findFirstJsonObject(String text) {
    final start = text.indexOf('{');
    if (start < 0) return null;

    int depth = 0;
    for (int i = start; i < text.length; i++) {
      final char = text[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  String _normalizeImageMimeType(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();

    switch (normalized) {
      case '':
      case 'application/octet-stream':
      case 'image/jpg':
      case 'image/jpeg':
        return 'image/jpeg';
      case 'image/png':
      case 'image/webp':
      case 'image/heic':
      case 'image/heif':
        return normalized;
      default:
        throw UnsupportedError('Formato de imagen no compatible: $mimeType');
    }
  }

  /// Decodes a JSON payload from raw Gemini text, applying repair strategies
  /// if the initial jsonDecode fails.
  ///
  /// Uses print() for logging (not log()).
  Map<String, dynamic> _decodeJsonPayload(String rawContent) {
    final trimmed = rawContent.trim();
    // Strip markdown code fences if present
    final fenced = trimmed.startsWith('```')
        ? trimmed
              .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
              .replaceFirst(RegExp(r'\s*```$'), '')
              .trim()
        : trimmed;

    print('[GeminiVision] Attempting jsonDecode on: $fenced');

    try {
      return jsonDecode(fenced) as Map<String, dynamic>;
    } on FormatException catch (e) {
      print('[GeminiVision] jsonDecode FAILED: ${e.message}, trying recovery...');
      // Step 1: try extracting a complete balanced JSON block
      final extracted = _findFirstJsonObjectInRaw(rawContent);
      if (extracted != null && extracted != fenced) {
        print('[GeminiVision] Found JSON block in raw, retrying decode');
        try {
          return jsonDecode(extracted) as Map<String, dynamic>;
        } on FormatException catch (e2) {
          print('[GeminiVision] Extracted block still invalid: ${e2.message}');
        }
      }
      // Step 2: if text is all prose (no '{' at all) look inside any "text" part sibling
      // Step 3: try top-level repair
      final repaired = _tryRepairTopLevel(fenced);
      if (repaired != null) {
        print('[GeminiVision] Repaired top-level JSON, retrying decode');
        return jsonDecode(repaired) as Map<String, dynamic>;
      }
      throw Exception(
        'Gemini devolvío texto sin JSON válido. '
        'Primeros 300 chars: ${rawContent.length > 300 ? rawContent.substring(0, 300) : rawContent}',
      );
    }
  }

}

// ==================== Data Models ====================

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

// ==================== Chat Types (internal only) ====================

class ChatCompletionResponse {
  final String id;
  final String content;
  final String? finishReason;

  ChatCompletionResponse({
    required this.id,
    required this.content,
    this.finishReason,
  });

  factory ChatCompletionResponse.fromMap(Map<String, dynamic> map) {
    final choices = map['choices'] as List?;
    final first = choices?.isNotEmpty == true ? choices!.first as Map : <String, dynamic>{};
    final message = first['message'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ChatCompletionResponse(
      id: map['id'] as String? ?? '',
      content: message['content'] as String? ?? '',
      finishReason: first['finishReason'] as String?,
    );
  }
}

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage._(this.role, this.content);

  factory ChatMessage.system(String content) => ChatMessage._('system', content);
  factory ChatMessage.user(String content) => ChatMessage._('user', content);
  factory ChatMessage.assistant(String content) => ChatMessage._('assistant', content);

  Map<String, dynamic> toMap() => {'role': role, 'content': content};
}

class Tool {
  final String type;
  final ToolFunction function;

  const Tool({required this.type, required this.function});

  Map<String, dynamic> toMap() => {
        'type': type,
        'function': function.toMap(),
      };
}

class ToolParameter {
  final String name;
  final String description;
  final String type;
  final bool required;

  const ToolParameter({
    required this.name,
    required this.description,
    required this.type,
    this.required = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type,
        if (required) 'required': true,
      };
}
