# Dead Porky

Dead Porky es una aplicación Flutter que actúa como un entrenador personal inteligente. El foco está en capturar el día a día del usuario (entrenamiento, comidas, sueño, hidratación, peso y medidas corporales) y usar una IA para ajustar recomendaciones y planificar mejoras.

## Objetivo
- Registrar datos de salud y rendimiento de forma rápida.
- Mantener contexto diario y semanal.
- Permitir que la IA revise el progreso y sugiera ajustes inmediatos.
- Ofrecer un flujo sencillo para que el usuario no pierda tiempo.

## Estructura del proyecto
- `lib/core`: temas, rutas y constantes.
- `lib/features`: módulos por dominio (auth, dashboard, ejercicio, nutrición, IA, etc.).
- `lib/shared`: servicios y utilidades comunes.
- `TRAINER_IA_DOCUMENTATION.md`: documentación del producto.
- `PROJECT_PLAN.md`: plan de desarrollo y roadmap.
- `agent.md`: configuración del agente de GitHub Copilot.
- `copilot-instructions.md`: instrucciones para Copilot Chat.

## Documentación
- [Trainer IA Documentation](TRAINER_IA_DOCUMENTATION.md)
- [Project Plan](PROJECT_PLAN.md)

## Próximos pasos
1. Definir el modelo de datos para el flujo diario.
2. Construir el dashboard inicial.
3. Implementar el registro de entrenamiento, comidas, agua y sueño.
4. Crear el asistente IA que use contexto relevante.
