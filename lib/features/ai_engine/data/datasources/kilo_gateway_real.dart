import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Real Kilo Gateway Service - connects to actual AI
class KiloGatewayReal {
  static const String _baseUrl = 'https://api.kilo.ai/api/gateway';

  late final Dio _dio;
  final String _apiKey;

  KiloGatewayReal({String? apiKey})
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
  }

  /// Stream chat with real Kilo Gateway
  Stream<String> streamChat({
    required List<Map<String, dynamic>> messages,
    String model = 'kilo/auto',
    int maxTokens = 2048,
    double temperature = 0.7,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': true,
        },
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
          } catch (_) {
            continue;
          }
        }
      }
    } catch (e) {
      yield 'Error: No se pudo conectar con el asistente. Verifica tu conexión.';
    }
  }

  /// Non-streaming chat
  Future<String> chat({
    required List<Map<String, dynamic>> messages,
    String model = 'kilo/auto',
    int maxTokens = 2048,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {'model': model, 'messages': messages, 'max_tokens': maxTokens},
      );

      final choices = response.data['choices'] as List;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] as String? ?? '';
      }
      return '';
    } catch (e) {
      return 'Error al conectar con el asistente.';
    }
  }

  /// Build health context for AI
  static String buildHealthContext({
    String? userName,
    double? weight,
    double? height,
    int? age,
    String? fitnessGoal,
    List<String>? recentWorkouts,
    List<String>? activeHabits,
    double? avgSleep,
    int? avgSteps,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== CONTEXTO DEL USUARIO ===');
    if (userName != null) buffer.writeln('Nombre: $userName');
    if (weight != null) buffer.writeln('Peso: $weight kg');
    if (height != null) buffer.writeln('Altura: $height cm');
    if (age != null) buffer.writeln('Edad: $age años');
    if (fitnessGoal != null) buffer.writeln('Objetivo: $fitnessGoal');
    if (recentWorkouts != null && recentWorkouts.isNotEmpty) {
      buffer.writeln('Últimos entrenamientos: ${recentWorkouts.join(", ")}');
    }
    if (activeHabits != null && activeHabits.isNotEmpty) {
      buffer.writeln('Hábitos activos: ${activeHabits.join(", ")}');
    }
    if (avgSleep != null) buffer.writeln('Sueño promedio: $avgSleep horas');
    if (avgSteps != null) buffer.writeln('Pasos promedio: $avgSteps');
    buffer.writeln('');
    buffer.writeln('=== INSTRUCCIONES ===');
    buffer.writeln('Eres un asistente de salud y fitness personalizado.');
    buffer.writeln('Responde en español, de forma concisa y motivadora.');
    buffer.writeln('Usa los datos del usuario para personalizar respuestas.');
    buffer.writeln('Usa emojis ocasionalmente.');
    return buffer.toString();
  }
}
