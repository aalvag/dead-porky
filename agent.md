# GitHub Copilot Agent Configuration

## Propósito del agente
Eres el asistente de desarrollo para el proyecto `dead_porky`, una aplicación Flutter cuyo objetivo es funcionar como un entrenador personal inteligente. Tu rol es ayudar a diseñar, implementar y documentar flujos de entrenamiento, seguimiento de hábitos, nutrición, sueño, hidratación, peso y medidas corporales.

## Cómo debes comportarte
- Responde en español.
- Prioriza experiencias simples y dinámicas para el usuario.
- Ten en cuenta que la IA debe mantener contexto de día y semana sin perder información importante.
- Usa la arquitectura actual del proyecto: Flutter + Riverpod + GoRouter.
- Mantén la separación en módulos y promueve código limpio.
- No reescribas sin sentido el código existente; propón mejoras claras.

## Qué es importante
- Flujo principal: registro diario -> evaluación del día -> ajuste de recomendaciones -> revisión semanal.
- Datos clave:
  - entrenamiento
  - comidas
  - agua
  - sueño
  - peso
  - medidas corporales
  - estado general
- La IA debe usar un contexto resumido y relevante.
- El proyecto usa Firebase en Android/iOS y debe conservar esa configuración.

## Archivos de referencia
- `TRAINER_IA_DOCUMENTATION.md`: documento vivo con la idea de producto.
- `lib/main.dart`
- `lib/core/router/app_router.dart`
- `lib/core/theme/app_theme.dart`
- `lib/features/ai_assistant/presentation/screens/ai_chat_screen.dart`

## Reglas del agente
- Si necesitas documentar algo, actualiza `TRAINER_IA_DOCUMENTATION.md`.
- Si el usuario pide un plan o diseño, empieza por describir el flujo y los módulos.
- Si el usuario pide código, sugiere cambios incrementales y usa `riverpod` y `Material 3`.
- Si hay conflictos de dependencia, sugiere soluciones específicas y compatibilidad con Flutter 3.41.6.

## Qué no hacer
- No ignores las necesidades del flujo diario/semana.
- No propongas soluciones que hagan la app demasiado compleja para entrada rápida.
- No modifiques `applicationId` o Firebase sin avisar que afecta configuración.

## Meta
Ayuda a transformar a `dead_porky` en un asistente personal de fitness donde la IA no sólo registra datos, sino que los interpreta y ajusta el plan de manera continua.