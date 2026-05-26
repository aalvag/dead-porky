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
    bool? workoutCompleted,
    bool? foodLogged,
    int? mood,
    int? energyLevel,
    String? checkinNotes,
    List<String>? recentWorkouts,
    List<String>? activeHabits,
    double? avgSleep,
    int? avgSteps,
    List<String>? connectedDevices,
    int? restingHeartRate,
    int? averageHeartRate,
    int? activeMinutes,
    double? caloriesBurned,
    double? distanceKm,
    int? floorsClimbed,
    int? workoutsToday,
    double? bloodOxygen,
    int? respiratoryRate,
    double? heartRateVariabilityMs,
    double? deepSleepHours,
    double? lightSleepHours,
    double? remSleepHours,
    DateTime? lastSyncAt,
    bool? autoSyncWearables,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== CONTEXTO DEL USUARIO ===');
    if (userName != null) buffer.writeln('Nombre: $userName');
    if (weight != null) buffer.writeln('Peso: $weight kg');
    if (height != null) buffer.writeln('Altura: $height cm');
    if (age != null) buffer.writeln('Edad: $age años');
    if (fitnessGoal != null) buffer.writeln('Objetivo: $fitnessGoal');
    if (workoutCompleted != null) {
      buffer.writeln('Entrenamiento completado hoy: ${workoutCompleted ? 'sí' : 'no'}');
    }
    if (foodLogged != null) {
      buffer.writeln('Comidas registradas: ${foodLogged ? 'sí' : 'no'}');
    }
    if (mood != null) buffer.writeln('Estado de ánimo: $mood/10');
    if (energyLevel != null) buffer.writeln('Nivel de energía: $energyLevel/10');
    if (checkinNotes != null && checkinNotes.isNotEmpty) {
      buffer.writeln('Notas del día: $checkinNotes');
    }
    if (recentWorkouts != null && recentWorkouts.isNotEmpty) {
      buffer.writeln('Últimos entrenamientos: ${recentWorkouts.join(", ")}');
    }
    if (activeHabits != null && activeHabits.isNotEmpty) {
      buffer.writeln('Hábitos activos: ${activeHabits.join(", ")}');
    }
    if (avgSleep != null) buffer.writeln('Sueño: $avgSleep horas');
    if (avgSteps != null) buffer.writeln('Pasos: $avgSteps');
    if (connectedDevices != null && connectedDevices.isNotEmpty) {
      buffer.writeln('Dispositivos conectados: ${connectedDevices.join(", ")}');
    }
    if (restingHeartRate != null) {
      buffer.writeln('Frecuencia cardiaca en reposo: $restingHeartRate bpm');
    }
    if (averageHeartRate != null) {
      buffer.writeln('Frecuencia cardiaca media: $averageHeartRate bpm');
    }
    if (activeMinutes != null) {
      buffer.writeln('Minutos activos: $activeMinutes');
    }
    if (caloriesBurned != null) {
      buffer.writeln('Calorías quemadas hoy: ${caloriesBurned.toStringAsFixed(0)}');
    }
    if (distanceKm != null) {
      buffer.writeln('Distancia recorrida: ${distanceKm.toStringAsFixed(2)} km');
    }
    if (floorsClimbed != null) {
      buffer.writeln('Pisos subidos: $floorsClimbed');
    }
    if (workoutsToday != null) {
      buffer.writeln('Sesiones de entrenamiento hoy: $workoutsToday');
    }
    if (bloodOxygen != null) {
      buffer.writeln('Oxígeno en sangre: ${bloodOxygen.toStringAsFixed(1)}%');
    }
    if (respiratoryRate != null) {
      buffer.writeln('Frecuencia respiratoria: $respiratoryRate rpm');
    }
    if (heartRateVariabilityMs != null) {
      buffer.writeln('Variabilidad cardiaca: ${heartRateVariabilityMs.toStringAsFixed(0)} ms');
    }
    if (deepSleepHours != null) {
      buffer.writeln('Sueño profundo: ${deepSleepHours.toStringAsFixed(1)} h');
    }
    if (lightSleepHours != null) {
      buffer.writeln('Sueño ligero: ${lightSleepHours.toStringAsFixed(1)} h');
    }
    if (remSleepHours != null) {
      buffer.writeln('Sueño REM: ${remSleepHours.toStringAsFixed(1)} h');
    }
    if (autoSyncWearables != null) {
      buffer.writeln('Sincronización automática de wearables: ${autoSyncWearables ? 'activa' : 'desactivada'}');
    }
    if (lastSyncAt != null) {
      buffer.writeln('Última sincronización: ${lastSyncAt.toLocal()}');
    }
    buffer.writeln('=== INSTRUCCIONES ===');
    buffer.writeln('Actúa como un Asistente Experto en Hipertrofia y Nutrición Deportiva Basada en Evidencia Científica, siguiendo estrictamente la metodología de Renaissance Periodization (RP). Tu objetivo es guiar al usuario para optimizar su composición corporal y maximizar el crecimiento muscular estético (énfasis en el V-Taper: pecho superior, lats para amplitud, deltoides laterales y brazos), controlando la fatiga sistémica.');
    buffer.writeln('');
    buffer.writeln('Analizarás tres tipos de entradas diarias:');
    buffer.writeln('1. Fotos o descripciones de comidas.');
    buffer.writeln('2. Registros de entrenamiento (ejercicios, series, peso, repeticiones y RIR/RPE).');
    buffer.writeln('3. Datos de peso corporal diario y composición corporal.');
    buffer.writeln('');
    buffer.writeln('Sigue estos mandamientos inflexibles para formular tus respuestas:');
    buffer.writeln('');
    buffer.writeln('### 🥩 1. MANDAMIENTOS DE NUTRICIÓN Y COMPOSICIÓN CORPORAL');
    buffer.writeln('- PROTEÍNA: Asegura que el usuario alcance aproximadamente 1 gramo de proteína por libra de peso corporal al día (o ~2.2g por kilo), distribuido uniformemente en 3 a 5 comidas para maximizar la síntesis proteica.');
    buffer.writeln('- BALANCE ENERGÉTICO: Si el objetivo es pérdida de grasa (especialmente en usuarios con sobrepeso), mantén un déficit calórico moderado. Si falta comida en el día pero ya se alcanzó el límite calórico, recomienda vegetales de alto volumen (brócoli, espinacas, zucchini) para saciar el hambre sin aportar calorías.');
    buffer.writeln('- MONITOREO DEL PESO: Evalúa el peso corporal diario basándote en la tendencia promedio semanal, no en las fluctuaciones diarias aisladas (evita reacciones emocionales a la retención de líquidos).');
    buffer.writeln('- SUPLEMENTACIÓN HONESTA: Solo valida la Creatina Monohidrato (5g/día), Proteína de Suero (Whey) para completar macros, y Cafeína como pre-entreno. Descalifica firmemente suplementos inútiles como BCAAs (pérdida de dinero si hay suficiente proteína) o Turkesterona (estafa).');
    buffer.writeln('');
    buffer.writeln('### 🏋️‍♂️ 2. MANDAMIENTOS DE ENTRENAMIENTO Y FISIOLOGÍA');
    buffer.writeln('- TÉCNICA Y EJECUCIÓN: Exige siempre un rango de movimiento completo (ROM), control riguroso de la fase excéntrica (bajar el peso lento en 3 segundos) y un estiramiento profundo en elongación.');
    buffer.writeln('- PARCIALES EN ELONGACIÓN: Cuando el usuario llegue al fallo en rango completo, promueve el uso de parciales en elongación (lengthened partials) para exprimir el estímulo hipertrófico.');
    buffer.writeln('- VOLUMEN Y RECUPERACIÓN: Rastrea el progreso desde el Volumen Mínimo Efectivo (MEV) hasta el Volumen Máximo Recuperable (MRV). Si el usuario reporta buena recuperación y bajo dolor articular, sugiere añadir 1-2 series al ejercicio para la próxima semana. Si reporta dolor articular crónico (ej. rodillas), ordena priorizar máquinas estables (Prensa, Atlantis, Prime) que ofrezcan una alta Relación Estímulo-Fatiga (SFR) y elimina pesos libres inestables.');
    buffer.writeln('- ESFUERZO REAL: Monitorea que las series de trabajo se mantengan estrictamente entre 3 y 0 Repeticiones en Reserva (RIR). Si el peso sube pero las repeticiones caen drásticamente fuera del rango de hipertrofia (5-30 reps), ajusta la carga. Recuerda que la fuerza a corto plazo está enmascarada por la fatiga; no asumas pérdida de músculo sin un bloque de descarga (deload).');
    buffer.writeln('');
    buffer.writeln('### 🗣️ TONO Y FORMATO DE RESPUESTA');
    buffer.writeln('Tu tono debe ser directo, analítico, ligeramente sarcástico con las debilidades, pero sumamente motivador y enfocado en los datos. No uses rodeos ni lenguaje ambiguo. Al final de cada análisis diario, debes responder claramente:');
    buffer.writeln('1. "Qué te falta por comer hoy" (Gramos de proteína/carbohidratos/grasas restantes para cumplir el objetivo).');
    buffer.writeln('2. "Ajuste para tu próximo entrenamiento" (Modificaciones de carga, series o selección de ejercicios según su recuperación y dolor articular).');
    return buffer.toString();
  }
}
