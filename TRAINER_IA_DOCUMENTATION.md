# Dead Porky - Entrenador Personal IA

## 1. Visión general

`Dead Porky` es una app de bienestar y fitness diseñada para que una IA actúe como entrenador personal. Su objetivo es combinar seguimiento diario de entrenamiento, nutrición, sueño, agua y métricas corporales con un asistente inteligente que ajuste recomendaciones en tiempo real.

### Propósito
- Permitir que el usuario registre de forma rápida y natural su día: entrenos, comidas, sueño, hidratación y medidas.
- Mantener un contexto dinámico que la IA pueda usar para evaluar cada día y cada semana.
- Ofrecer un flujo simple, evitando que el usuario tenga que pensar en categorías complejas.
- Ajustar el plan en función de lo que realmente hizo el usuario.

## 2. Flujo recomendado

### 2.1. Onboarding inicial
- Objetivo principal: pérdida de grasa, ganancia muscular, mantenimiento, salud general.
- Restricciones y preferencias: alergias, dieta, lesiones, horarios.
- Métricas clave: peso, grasa corporal, cintura, cadera, pecho, brazos, muslo.
- Nivel de actividad y experiencia.

### 2.2. Check-in diario
- Registrar lo siguiente de forma rápida:
  - Entrenamiento (tipo, duración, sensación)
  - Comida (desayuno, almuerzo, cena, snack)
  - Agua (vasos/litros)
  - Sueño (horas y calidad)
  - Peso
  - Medidas corporales opcionales
  - Estado general (energía, ánimo, estrés)

### 2.3. Revisión del día
- Comparar lo esperado con lo hecho.
- Evaluación inmediata de la IA:
  - ¿Cumplió con el entrenamiento?
  - ¿Comió equilibrado?
  - ¿Durmió suficiente?
  - ¿Tomó la cantidad de agua sugerida?
- Ajustes para el resto del día o para el plan de mañana.

### 2.4. Revisión semanal
- Resumen de tendencias:
  - pequeñas variaciones de peso
  - evolución del sueño
  - sesiones completadas
  - hidratación promedio
- Ajustes de plan macro:
  - más/sal menos cardio
  - incrementar fuerza
  - balancear macros

## 3. Módulos principales

### 3.1. Entrenamiento
- Registro de sesión con tipo y duración.
- Intensidad/personal feeling.
- Ejercicios principales.
- Meta semanal de sesiones.

### 3.2. Nutrición
- Registro de comidas por momento del día.
- Texto libre con opción de parsear macros.
- Registro rápido de platos frecuentes.
- Cálculo estimado de calorías/macros.

### 3.3. Sueño
- Horas dormidas.
- Calidad del sueño.
- Notas de recuperación.

### 3.4. Hidratación
- Conteo rápido de vasos/litros.
- Objetivo diario personalizable.

### 3.5. Peso y medidas
- Peso corporal.
- Medidas relevantes:
  - cintura
  - cadera
  - pecho
  - bíceps
  - pierna
- Evolución a lo largo de la semana.

### 3.6. Salud y estado general
- Estrés.
- Energía.
- Molestias o lesiones.
- Animo.

### 3.7. IA entrenadora
- Chat conversacional.
- Resumen de día.
- Recomendaciones adaptativas.
- Ajuste de plan diario/semanal.

## 4. Contexto de IA y prompt

### 4.1. Datos que deben llegar a la IA

- Objetivo del usuario.
- Metas semanales.
- Historial reciente (últimos 3-5 días).
- Estado actual del día.
- Cambios importantes y restricciones.

### 4.2. Estructura recomendada de contexto

```json
{
  "goals": {
    "primary": "perder grasa",
    "secondary": "mantener masa muscular"
  },
  "weekly_plan": {
    "strength": 3,
    "cardio": 2,
    "water_l": 2.5
  },
  "recent_days": [
    {"day": "Lunes", "training": "fuerza", "sleep_h": 7, "water_l": 1.8},
    {"day": "Martes", "training": "cardio", "sleep_h": 6.5, "water_l": 1.4}
  ],
  "today": {
    "meals": ["desayuno: avena + huevo", "almuerzo: pollo + vegetales"],
    "training": "fuerza 50min",
    "sleep_h": 6.5,
    "water_l": 1.2,
    "weight": 78.0
  },
  "request": "Ajusta mi plan para el resto del día y para mañana"
}
```

### 4.3. ¿Qué debe hacer la IA?
- Evaluar cumplimiento diario.
- Sugerir correcciones inmediatas.
- Ajustar el plan semanal.
- Recordar metas y restricciones.
- Explicar en lenguaje claro.

## 5. UX / Interfaz propuesta

### 5.1. Dashboard central
- Card de cumplimiento del día.
- Resumen de entrenamiento, comida, agua, sueño.
- Botón rápido para check-in.
- Acceso a la IA.

### 5.2. Check-in rápido
- Botones grandes y claros.
- Formularios simples.
- Opción de voz o texto libre.
- Plantillas prefijadas.

### 5.3. Revisión semanal
- Gráficos de tendencia.
- Indicadores de progreso.
- Mensaje de la IA con ajustes.

### 5.4. Asistente de IA
- Chat + resumen automático.
- Mensajes con recomendaciones.
- Capacidad de preguntar: “¿qué hice mal hoy?”.

## 6. Implementación técnica sugerida

### 6.1. Arquitectura modular
- `lib/features/auth`.
- `lib/features/dashboard`.
- `lib/features/exercises`.
- `lib/features/nutrition`.
- `lib/features/habits`.
- `lib/features/wearable`.
- `lib/features/health_metrics`.
- `lib/features/ai_assistant`.
- `lib/features/reports`.

### 6.2. Estado
- Riverpod para estado global.
- StateProviders para entradas de UI.
- Notifiers para plan y recomendaciones.

### 6.3. Persistencia
- Local DB para registros diarios y medidas.
- Firestore si se requiere backup / multi-dispositivo.
- Hash de eventos para historial de IA.

### 6.4. Contexto IA
- Guardar resumen diario y semanal en la base.
- Generar prompt antes de enviar a la IA.
- No reenviar historial completo en cada request.
- Mantener estado del usuario y metas en el prompt.

## 7. Ajustes para `agent.md` y Copilot

### 7.1. Propósito de `agent.md`
- Indicar a GitHub Copilot la misión del repositorio.
- Definir idioma, estilo, prioridades y límites.
- Ayudar a Copilot a responder como experto en este proyecto.

### 7.2. Uso recomendado
- `agent.md`: guía para el asistente de desarrollo.
- `TRAINER_IA_DOCUMENTATION.md`: documento vivo del producto.
- `copilot-instructions.md`: instrucciones específicas de Copilot Chat.

### 7.3. Qué pedirle al agente
- Revisar flujos y experiencia de usuario.
- Proponer pantallas o módulos.
- Escribir funciones de AI prompt management.
- Mantener coherencia con arquitectura actual.
- Priorizar UX sencillo y datos dinámicos.

## 8. Siguientes pasos

1. Documentar las pantallas clave.
2. Crear el modelo de datos para el registro diario.
3. Implementar el motor de contexto IA.
4. Añadir el asistente conversacional.
5. Validar con un flujo de ejemplo real: hoy, mañana, semana.

---

**Nota:** este documento debe mantenerse actualizado a medida que el proyecto evolucione. El objetivo es que cualquier desarrollador entienda rápidamente qué debe hacer la IA y cómo el usuario interactúa con ella.