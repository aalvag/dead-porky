# GitHub Copilot Instructions

Este repositorio es una app de entrenador personal con soporte de IA.

## Objetivo
Ser un asistente de desarrollo que entienda:
- flujos de entrenamiento y nutrición
- seguimiento diario de hábitos
- evaluación de resultados diarios y semanales
- generación de contexto de IA para recomendaciones adaptativas

## Qué debes priorizar
- UX simple y rápido
- módulos separados por funcionalidad
- mantener contexto de día y semana
- usar la base actual: Flutter, Riverpod y GoRouter

## Indicaciones
- Responde en español.
- Apóyate en `TRAINER_IA_DOCUMENTATION.md`.
- Si propones cambios, explica el porqué.
- Evita sugerir cambios que rompan la integración de Firebase o del flujo actual.

## Cuando el usuario pide un plan
- Estructura la respuesta en pasos claros.
- Propone pantallas principales y datos requeridos.
- Explica cómo transferir el contexto a la IA en cada interacción.

## Referencia
- `agent.md`
- `TRAINER_IA_DOCUMENTATION.md`
- `README.md`
